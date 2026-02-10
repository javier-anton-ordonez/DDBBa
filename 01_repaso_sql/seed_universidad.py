import argparse
import os
import random
import string
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path
from typing import Iterable

import mysql.connector
from mysql.connector.connection import MySQLConnection
from tqdm import tqdm


@dataclass(frozen=True)
class DbConfig:
    host: str
    port: int
    user: str
    password: str
    database: str


DEFAULT_ASIGNATURAS: list[tuple[str, str, float, int, int]] = [
    ("BBDD1", "Bases de Datos I", 6.0, 2, 1),
    ("BBDD2", "Bases de Datos II", 6.0, 2, 2),
    ("SO", "Sistemas Operativos", 6.0, 2, 1),
    ("RED", "Redes", 6.0, 2, 2),
    ("IA", "Introducción a la IA", 6.0, 3, 1),
]


NOMBRES = ["Ana", "Luis", "María", "Carlos", "Lucía", "Javier", "Paula", "Sergio", "Marta", "Diego"]
APELLIDOS = [
    "Pérez",
    "Gómez",
    "Ruiz",
    "Sánchez",
    "Fernández",
    "López",
    "Martín",
    "Díaz",
    "Torres",
    "Navarro",
]


def env_config() -> DbConfig:
    return DbConfig(
        host=os.getenv("MYSQL_HOST", "127.0.0.1"),
        port=int(os.getenv("MYSQL_PORT", "3306")),
        user=os.getenv("MYSQL_USER", "root"),
        password=os.getenv("MYSQL_PASSWORD", "rootpass"),
        database=os.getenv("MYSQL_DATABASE", "universidad"),
    )


def connect_server(cfg: DbConfig, *, with_db: bool) -> MySQLConnection:
    return mysql.connector.connect(
        host=cfg.host,
        port=cfg.port,
        user=cfg.user,
        password=cfg.password,
        database=(cfg.database if with_db else None),
        autocommit=False,
    )


def apply_sql_file(cfg: DbConfig, sql_file: Path) -> None:
    """
    Ejecuta un fichero .sql desde Python (útil si NO quieres usar `docker exec` ni el cliente `mysql` del host).
    El fichero puede contener múltiples sentencias (CREATE DATABASE, USE, CREATE TABLE, ...).
    """
    sql_text = sql_file.read_text(encoding="utf-8")
    with connect_server(cfg, with_db=False) as conn:
        cur = conn.cursor()
        for _ in cur.execute(sql_text, multi=True):
            pass
        conn.commit()


def _ensure_schema_exists(cfg: DbConfig) -> None:
    """
    Este seeder asume que el esquema ya existe (creado con `schema_universidad.sql`).
    Lanza un error si faltan tablas.
    """
    required_tables = {"alumno", "asignatura", "nota"}
    with connect_server(cfg, with_db=True) as conn:
        cur = conn.cursor()
        cur.execute("SHOW TABLES")
        existing = {row[0] for row in cur.fetchall()}
    missing = sorted(required_tables - existing)
    if missing:
        raise RuntimeError(
            f"Faltan tablas en la BD '{cfg.database}': {', '.join(missing)}. "
            "Primero ejecuta apuntes/01_repaso_sql/schema_universidad.sql."
        )


def seed_asignaturas(cfg: DbConfig) -> int:
    with connect_server(cfg, with_db=True) as conn:
        cur = conn.cursor()
        cur.execute("SELECT COUNT(*) FROM asignatura")
        (count,) = cur.fetchone()
        if count and int(count) > 0:
            return 0

        cur.executemany(
            "INSERT INTO asignatura (codigo, nombre, creditos, curso, semestre) VALUES (%s,%s,%s,%s,%s)",
            DEFAULT_ASIGNATURAS,
        )
        conn.commit()
        return cur.rowcount


def _dni_random(rng: random.Random) -> str:
    digits = f"{rng.randrange(0, 100_000_000):08d}"
    letter = rng.choice(string.ascii_uppercase)
    return digits + letter


def _slug_simple(s: str) -> str:
    # suficiente para emails ejemplo, sin dependencias externas
    return (
        s.lower()
        .replace("á", "a")
        .replace("é", "e")
        .replace("í", "i")
        .replace("ó", "o")
        .replace("ú", "u")
        .replace("ñ", "n")
    )


def _rand_birthdate(rng: random.Random) -> date:
    # alumnado universitario típico: 18..30 (aprox)
    today = date.today()
    start = today - timedelta(days=30 * 365)
    end = today - timedelta(days=18 * 365)
    delta_days = (end - start).days
    return start + timedelta(days=rng.randrange(0, max(1, delta_days)))


def _iter_alumnos_random(n: int, *, seed: int | None = None) -> Iterable[tuple[str, str, str, str, str, date]]:
    rng = random.Random(seed)

    used_dni: set[str] = set()
    used_email: set[str] = set()

    produced = 0
    while produced < n:
        nombre = rng.choice(NOMBRES)
        ap1 = rng.choice(APELLIDOS)
        ap2 = rng.choice(APELLIDOS)
        dni = _dni_random(rng)
        if dni in used_dni:
            continue

        suffix = f"{rng.randrange(0, 10_000):04d}"
        email = f"{_slug_simple(nombre)}.{_slug_simple(ap1)}.{suffix}@uni.local"
        if email in used_email:
            continue

        used_dni.add(dni)
        used_email.add(email)
        produced += 1
        yield (dni, nombre, ap1, ap2, email, _rand_birthdate(rng))


def seed_alumnos(cfg: DbConfig, n: int, *, batch_size: int = 10000, seed: int | None = None) -> int:
    if n <= 0:
        return 0

    inserted_total = 0
    with connect_server(cfg, with_db=True) as conn:
        cur = conn.cursor()
        stmt = """
            INSERT INTO alumno (dni, nombre, apellido1, apellido2, email, fecha_nacimiento)
            VALUES (%s,%s,%s,%s,%s,%s)
        """

        batch: list[tuple[str, str, str, str, str, date]] = []
        with tqdm(total=n, desc="Insertando alumnos", unit="alumno") as bar:
            for row in _iter_alumnos_random(n, seed=seed):
                batch.append(row)
                if len(batch) >= batch_size:
                    cur.executemany(stmt, batch)
                    inserted_total += cur.rowcount
                    conn.commit()
                    bar.update(len(batch))
                    batch.clear()

            if batch:
                cur.executemany(stmt, batch)
                inserted_total += cur.rowcount
                conn.commit()
                bar.update(len(batch))

    return inserted_total


def seed_notas(
    cfg: DbConfig, *, notas_por_alumno: int = 3, seed: int | None = None, batch_size: int = 10000
) -> int:
    rng = random.Random(seed)
    with connect_server(cfg, with_db=True) as conn:
        cur = conn.cursor()

        cur.execute("SELECT id_alumno FROM alumno")
        alumnos = [row[0] for row in cur.fetchall()]

        cur.execute("SELECT id_asignatura FROM asignatura")
        asignaturas = [row[0] for row in cur.fetchall()]

        if not alumnos or not asignaturas:
            return 0

        inserted_total = 0
        rows: list[tuple[int, int, str, float]] = []
        stmt = """
            INSERT IGNORE INTO nota (id_alumno, id_asignatura, convocatoria, calificacion)
            VALUES (%s,%s,%s,%s)
        """

        for id_alumno in tqdm(alumnos, desc="Generando notas", unit="alumno"):
            chosen = rng.sample(asignaturas, k=min(notas_por_alumno, len(asignaturas)))
            for id_asig in chosen:
                cal = round(rng.random() * 10.0, 2)
                rows.append((id_alumno, id_asig, "ORD", cal))

            if len(rows) >= batch_size:
                cur.executemany(stmt, rows)
                inserted_total += cur.rowcount
                conn.commit()
                rows.clear()

        if rows:
            cur.executemany(stmt, rows)
            inserted_total += cur.rowcount
            conn.commit()
        return inserted_total


def main() -> None:
    p = argparse.ArgumentParser(description="Crear BD universidad (MySQL) y generar datos aleatorios.")
    p.add_argument(
        "--apply-schema",
        action="store_true",
        help="Aplica el fichero SQL de esquema antes de sembrar (sin necesitar el cliente mysql).",
    )
    p.add_argument(
        "--schema-file",
        default=str(Path(__file__).with_name("schema_universidad.sql")),
        help="Ruta al fichero de esquema SQL (default: schema_universidad.sql junto al script).",
    )
    p.add_argument("--seed-asignaturas", action="store_true", help="Insertar asignaturas de ejemplo (si está vacío).")
    p.add_argument("--seed-alumnos", type=int, default=0, metavar="N", help="Insertar N alumnos aleatorios.")
    p.add_argument("--seed-notas", type=int, default=0, metavar="K", help="Insertar K notas aleatorias por alumno.")
    p.add_argument("--rng-seed", type=int, default=None, help="Semilla para reproducibilidad.")
    args = p.parse_args()

    cfg = env_config()
    if args.apply_schema:
        apply_sql_file(cfg, Path(args.schema_file))

    _ensure_schema_exists(cfg)

    if args.seed_asignaturas:
        seed_asignaturas(cfg)

    if args.seed_alumnos > 0:
        seed_alumnos(cfg, args.seed_alumnos, seed=args.rng_seed)

    if args.seed_notas > 0:
        seed_notas(cfg, notas_por_alumno=args.seed_notas, seed=args.rng_seed)


if __name__ == "__main__":
    main()

