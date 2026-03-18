### Relacion  1:N

```sql
-- Tabla padre
CREATE TABLE movilidad.empresa (
  id_empresa  BIGINT       NOT NULL AUTO_INCREMENT,
  PRIMARY KEY (id_empresa),
  UNIQUE KEY uk_empresa_cif (cif)
) ENGINE=InnoDB;
-- Añadir FK a la tabla hija
ALTER TABLE movilidad.conductor
  ADD COLUMN id_empresa BIGINT NOT NULL,
  ADD CONSTRAINT fk_conductor_empresa
    FOREIGN KEY (id_empresa)
    REFERENCES movilidad.empresa(id_empresa)
    ON UPDATE CASCADE
    ON DELETE RESTRICT;
```

```sql
ON DELETE RESTRICT   -- Error: no puedes borrar empresa con conductores
ON DELETE CASCADE    -- Borra la empresa Y todos sus conductores
ON DELETE SET NULL   -- Borra empresa, conductores quedan con id_empresa = NULL
```

N:N

```sql
-- Tabla intermedia (representa la relación N:N)
CREATE TABLE movilidad.conductor_vehiculo (
  id_conductor  BIGINT  NOT NULL,
  id_vehiculo   BIGINT  NOT NULL,
  fecha_hasta   DATE    NULL,        -- NULL = asignación vigente
  -- PK compuesta (incluye fecha para permitir reasignaciones)
  PRIMARY KEY (id_conductor, id_vehiculo, fecha_desde),
  -- FKs a ambas tablas
  CONSTRAINT fk_cv_conductor
    FOREIGN KEY (id_conductor)
    REFERENCES movilidad.conductor(id_conductor)
    ON UPDATE CASCADE ON DELETE RESTRICT,

  CONSTRAINT fk_cv_vehiculo
    FOREIGN KEY (id_vehiculo)
    REFERENCES movilidad.vehiculo(id_vehiculo)
    ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;
```

Indice = es una estructura de datos auxiliar para acelerar la busquedas en la tabla Mysql usa B-Tree -> O(log n)

Indices

```sql
-- Índice simple: acelera búsquedas por fecha_alta
CREATE INDEX idx_conductor_fecha_alta 
ON movilidad.conductor(fecha_alta);
-- Índice único: garantiza unicidad + acelera búsquedas
CREATE UNIQUE INDEX uk_conductor_email 
ON movilidad.conductor(email);
-- Índice compuesto: para consultas que filtran por ambas columnas
CREATE INDEX idx_viaje_estado_fecha 
ON movilidad.viaje(estado, created_at);
-- Índice al crear la tabla
CREATE TABLE movilidad.pasajero (
  
  PRIMARY KEY (id_pasajero),
  UNIQUE KEY uk_pasajero_email (email),
   idx_pasajero_ciudad (ciudad)
) ENGINE=InnoDB;
```

EXPLAIN SELECT * FROM conductor WHERE dni = '12345678A';
ve el plan ed ejecucion

```sql
-- Ver índices de una tabla
SHOW INDEX FROM movilidad.conductor;
-- Ver índices con información detallada
SELECT 
    INDEX_NAME,
    COLUMN_NAME,
    SEQ_IN_INDEX,
    NON_UNIQUE,
    CARDINALITY
FROM information_schema.STATISTICS
WHERE TABLE_SCHEMA = 'movilidad' 
  AND TABLE_NAME = 'conductor';

-- Eliminar un índice
DROP INDEX idx_conductor_fecha_alta ON movilidad.conductor;

-- Eliminar índice único
ALTER TABLE movilidad.conductor DROP INDEX uk_conductor_email;
```

Particionado 

```sql
-- La columna de partición DEBE estar en la PK
  PRIMARY KEY (id_viaje, created_at)
) ENGINE=InnoDB
PARTITION BY RANGE (YEAR(created_at)) (
  PARTITION p2023 VALUES LESS THAN (2024),
  PARTITION p2024 VALUES LESS THAN (2025),
  PARTITION p2025 VALUES LESS THAN (2026),
  PARTITION p2026 VALUES LESS THAN (2027),
  PARTITION pFuturo VALUES LESS THAN MAXVALUE
);
```
```sql
-- Ver particiones de una tabla
SELECT PARTITION_NAME, TABLE_ROWS, DATA_LENGTH
FROM information_schema.PARTITIONS
WHERE TABLE_SCHEMA = 'movilidad' AND TABLE_NAME = 'viaje';
-- Añadir nueva partición (antes de que llegue el año)
ALTER TABLE viaje REORGANIZE PARTITION pFuturo INTO (
  PARTITION p2027 VALUES LESS THAN (2028),
  PARTITION pFuturo VALUES LESS THAN MAXVALUE
);
-- Borrar partición completa (¡BORRA TODOS LOS DATOS!)
ALTER TABLE viaje DROP PARTITION p2023;
```

```sql
-- Dividir pFuturo para crear partición del próximo año
ALTER TABLE viaje REORGANIZE PARTITION pFuturo INTO (
  PARTITION p2027 VALUES LESS THAN (2028),
  PARTITION pFuturo VALUES LESS THAN MAXVALUE
);
-- Fusionar particiones antiguas (si quieres consolidar)
ALTER TABLE viaje REORGANIZE PARTITION p2023, p2024 INTO (
  PARTITION pHistorico VALUES LESS THAN (2025)
);
```

# 5
