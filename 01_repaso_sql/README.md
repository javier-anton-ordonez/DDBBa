# Tema 1 — Scripts (MySQL)

## Crear BD `universidad` + tablas (alumno/asignatura/nota) y generar alumnos aleatorios

Este tema incluye:

- Un script MySQL de esquema (`schema_universidad.sql`)
- Un script python3 (`seed_universidad.py`)

### Paso 1: SQL (crear tablas)

Ejecuta el script de esquema (solo creación):

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -prootpass < apuntes/tema1/schema_universidad.sql
```

Si no tienes instalado el cliente `mysql` en tu máquina, puedes aplicar el esquema desde python3 usando `--apply-schema`.

### Paso 2: python3 (seeder)

El seeder asume que ya existen las tablas (`schema_universidad.sql`).

Instalar dependencias:

```bash
python3 -m pip install -r apuntes/tema1/requirements.txt
```

Ejecutar (por defecto conecta a `127.0.0.1:3306` como `root/rootpass`):

```bash
python3 apuntes/tema1/seed_universidad.py --seed-asignaturas --seed-alumnos 200 --seed-notas 3 --rng-seed 123
```

Alternativa (aplicar esquema + seed en un único comando, sin cliente `mysql`):

```bash
python3 apuntes/tema1/seed_universidad.py --apply-schema --seed-asignaturas --seed-alumnos 200 --seed-notas 3 --rng-seed 123
```

Variables de entorno (si tu configuración es distinta):

- `MYSQL_HOST` (default `127.0.0.1`)
- `MYSQL_PORT` (default `3306`)
- `MYSQL_USER` (default `root`)
- `MYSQL_PASSWORD` (default `rootpass`)
- `MYSQL_DATABASE` (default `universidad`)

## Experimento: probar la eficacia de los índices

Objetivo: ver (1) un **plan de ejecución** malo (escaneo completo) y (2) cómo mejora al crear un índice adecuado.

### Paso 0: generar un volumen grande de datos

Elige un tamaño que tu máquina aguante (empieza por 50k alumnos).

```bash
python3 apuntes/tema1/seed_universidad.py --apply-schema --seed-asignaturas --seed-alumnos 50000 --seed-notas 5 --rng-seed 123
```

### Paso 1: identificar una consulta lenta (sin índice)

Conecta al cliente MySQL:

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -prootpass
```

Usa la BD:

```sql
USE universidad;
```

Consulta típica sin índice (filtrando y ordenando por `calificacion`, que inicialmente **no** tiene índice):

```sql
SELECT *
FROM nota
WHERE calificacion >= 5
ORDER BY calificacion DESC;
```

Ver el plan (MySQL 8):

```sql
EXPLAIN
SELECT *
FROM nota
WHERE calificacion >= 5
ORDER BY calificacion DESC;
```

Si tu MySQL soporta `EXPLAIN ANALYZE`, mejor (da tiempos reales):

```sql
EXPLAIN ANALYZE
SELECT *
FROM nota
WHERE calificacion >= 5
ORDER BY calificacion DESC;
```

### Paso 2: añadir el índice y repetir

Crear índice:

```sql
CREATE INDEX idx_nota_calificacion ON nota(calificacion);
```

Repetir `EXPLAIN` / `EXPLAIN ANALYZE` y la consulta:

```sql
EXPLAIN
SELECT *
FROM nota
WHERE calificacion >= 5
ORDER BY calificacion DESC;

SELECT *
FROM nota
WHERE calificacion >= 5
ORDER BY calificacion DESC;

```

> Nota: si la condición es poco selectiva (p. ej. `>= 5`), MySQL puede seguir usando
> full scan + filesort aunque exista el índice. Para ver claramente el uso del índice,
> prueba una condición más selectiva (p. ej. `>= 9`):
>
> ```sql
> EXPLAIN FORMAT=JSON
> SELECT *
> FROM nota
> WHERE calificacion >= 9
> ORDER BY calificacion DESC;
> ```
>
> Señales en el JSON:
> - **full scan**: `"access_type": "ALL"` y `"using_filesort": true`
> - **con índice**: `"access_type": "range"`, `"key": "idx_nota_calificacion"` y `"using_filesort": false`

### Qué deberías observar

- Antes del índice: el plan suele mostrar `type=ALL` (escaneo completo) sobre `nota`.
- Después del índice: debería aparecer `type=range` usando `idx_nota_calificacion` (menos filas leídas).

### Extensión (más realista): join + agregación

Sin índice en `calificacion`, esta consulta suele costar bastante más:

```sql
SELECT a.apellido1, AVG(n.calificacion) AS media
FROM alumno a
JOIN nota n ON n.id_alumno = a.id_alumno
WHERE n.calificacion >= 5
GROUP BY a.apellido1;
```

Haz `EXPLAIN` antes y después de `idx_nota_calificacion` para comparar.