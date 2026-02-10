-- Tema 1 (MySQL 8) — Esquema: universidad (alumnos, asignaturas, notas)
-- Solo creación (sin inserts / sin procedures).
--
-- Ejecutar (ejemplo Docker):
--   docker exec -i mysql8 mysql -uroot -prootpass < apuntes/tema1/schema_universidad.sql

CREATE DATABASE IF NOT EXISTS universidad
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE universidad;

CREATE TABLE IF NOT EXISTS alumno (
  id_alumno        INT NOT NULL AUTO_INCREMENT,
  dni              VARCHAR(12) NOT NULL,
  nombre           VARCHAR(60) NOT NULL,
  apellido1        VARCHAR(60) NOT NULL,
  apellido2        VARCHAR(60) NULL,
  email            VARCHAR(120) NOT NULL,
  fecha_nacimiento DATE NULL,
  fecha_alta       DATE NOT NULL DEFAULT (CURRENT_DATE),
  activo           BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (id_alumno),
  UNIQUE KEY uk_alumno_dni (dni),
  UNIQUE KEY uk_alumno_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS asignatura (
  id_asignatura INT NOT NULL AUTO_INCREMENT,
  codigo        VARCHAR(20) NOT NULL,
  nombre        VARCHAR(120) NOT NULL,
  creditos      DECIMAL(4,1) NOT NULL,
  curso         TINYINT NOT NULL,              -- 1..4
  semestre      TINYINT NOT NULL,              -- 1..2
  PRIMARY KEY (id_asignatura),
  UNIQUE KEY uk_asignatura_codigo (codigo),
  CONSTRAINT chk_asig_creditos CHECK (creditos > 0),
  CONSTRAINT chk_asig_curso CHECK (curso BETWEEN 1 AND 4),
  CONSTRAINT chk_asig_semestre CHECK (semestre IN (1,2))
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS nota (
  id_nota       INT NOT NULL AUTO_INCREMENT,
  id_alumno     INT NOT NULL,
  id_asignatura INT NOT NULL,
  convocatoria  ENUM('ORD','EXTRA') NOT NULL DEFAULT 'ORD',
  fecha         DATE NOT NULL DEFAULT (CURRENT_DATE),
  calificacion  DECIMAL(4,2) NOT NULL,         -- 0.00..10.00
  PRIMARY KEY (id_nota),
  UNIQUE KEY uk_nota_alumno_asig_conv (id_alumno, id_asignatura, convocatoria),
  KEY idx_nota_alumno (id_alumno),
  KEY idx_nota_asignatura (id_asignatura),
  CONSTRAINT fk_nota_alumno
    FOREIGN KEY (id_alumno) REFERENCES alumno(id_alumno)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_nota_asignatura
    FOREIGN KEY (id_asignatura) REFERENCES asignatura(id_asignatura)
    ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT chk_nota_rango CHECK (calificacion >= 0 AND calificacion <= 10)
) ENGINE=InnoDB;

