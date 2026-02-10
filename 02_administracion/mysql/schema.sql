-- ============================================
-- Schema de ejemplo: Universidad
-- ============================================

USE universidad;

CREATE TABLE IF NOT EXISTS alumno (
    id_alumno BIGINT NOT NULL AUTO_INCREMENT,
    dni VARCHAR(20) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    apellido1 VARCHAR(80) NOT NULL,
    apellido2 VARCHAR(80),
    email VARCHAR(120) NOT NULL,
    fecha_nacimiento DATE,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_alumno),
    UNIQUE KEY uk_alumno_dni (dni),
    UNIQUE KEY uk_alumno_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS profesor (
    id_profesor BIGINT NOT NULL AUTO_INCREMENT,
    dni VARCHAR(20) NOT NULL,
    nombre VARCHAR(80) NOT NULL,
    apellido1 VARCHAR(80) NOT NULL,
    apellido2 VARCHAR(80),
    email VARCHAR(120) NOT NULL,
    departamento VARCHAR(100),
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id_profesor),
    UNIQUE KEY uk_profesor_dni (dni),
    UNIQUE KEY uk_profesor_email (email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS asignatura (
    id_asignatura BIGINT NOT NULL AUTO_INCREMENT,
    codigo VARCHAR(20) NOT NULL,
    nombre VARCHAR(120) NOT NULL,
    creditos INT NOT NULL DEFAULT 6,
    curso INT NOT NULL,
    id_profesor BIGINT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_asignatura),
    UNIQUE KEY uk_asignatura_codigo (codigo),
    CONSTRAINT fk_asignatura_profesor FOREIGN KEY (id_profesor) 
        REFERENCES profesor(id_profesor) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS matricula (
    id_alumno BIGINT NOT NULL,
    id_asignatura BIGINT NOT NULL,
    curso_academico VARCHAR(9) NOT NULL,
    nota DECIMAL(4,2),
    convocatoria INT NOT NULL DEFAULT 1,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_alumno, id_asignatura, curso_academico),
    CONSTRAINT fk_matricula_alumno FOREIGN KEY (id_alumno) 
        REFERENCES alumno(id_alumno) ON DELETE CASCADE,
    CONSTRAINT fk_matricula_asignatura FOREIGN KEY (id_asignatura) 
        REFERENCES asignatura(id_asignatura) ON DELETE CASCADE
) ENGINE=InnoDB;

-- Datos de ejemplo
INSERT INTO alumno (dni, nombre, apellido1, apellido2, email, fecha_nacimiento) VALUES
('12345678A', 'Ana', 'García', 'López', 'ana.garcia@uni.es', '2000-03-15'),
('23456789B', 'Carlos', 'Martínez', 'Ruiz', 'carlos.martinez@uni.es', '1999-07-22'),
('34567890C', 'María', 'López', 'Fernández', 'maria.lopez@uni.es', '2001-01-10');

INSERT INTO profesor (dni, nombre, apellido1, email, departamento) VALUES
('98765432Z', 'Juan', 'Pérez', 'juan.perez@uni.es', 'Informática'),
('87654321Y', 'Laura', 'Sánchez', 'laura.sanchez@uni.es', 'Matemáticas');

INSERT INTO asignatura (codigo, nombre, creditos, curso, id_profesor) VALUES
('BD01', 'Bases de Datos', 6, 2, 1),
('PROG01', 'Programación', 6, 1, 1),
('MAT01', 'Matemáticas I', 6, 1, 2);
