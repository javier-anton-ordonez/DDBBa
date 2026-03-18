**1:N** FK en tabla hija | **N:N** Tabla intermedia con 2 FKs + PK compuesta
```sql
ALTER TABLE conductor ADD COLUMN id_empresa BIGINT NOT NULL,
  ADD CONSTRAINT fk_c_e FOREIGN KEY (id_empresa) REFERENCES empresa(id_empresa)
  ON UPDATE CASCADE ON DELETE RESTRICT; -- RESTRICT=error | CASCADE=borra hijos | SET NULL=NULL
CREATE TABLE conductor_vehiculo (id_conductor BIGINT, id_vehiculo BIGINT,
  PRIMARY KEY (id_conductor,id_vehiculo),
  FOREIGN KEY (id_conductor) REFERENCES conductor(id_conductor),
  FOREIGN KEY (id_vehiculo) REFERENCES vehiculo(id_vehiculo)) ENGINE=InnoDB;
```
**ÍNDICES** B-Tree O(log n) | Simple, UNIQUE(unicidad+velocidad), Compuesto(filtros múltiples)
```sql
CREATE INDEX idx_fecha ON conductor(fecha_alta);
CREATE UNIQUE INDEX uk_email ON conductor(email);
CREATE INDEX idx_comp ON viaje(estado,created_at);
SHOW INDEX FROM conductor; -- ver | DROP INDEX idx_fecha ON conductor; -- borrar
EXPLAIN SELECT * FROM conductor WHERE dni='12345678A'; -- plan ejecución
```
**PARTICIONADO** Columna partición en PK. REORGANIZE p/ añadir. DROP borra datos.
```sql
PRIMARY KEY (id_viaje,created_at) PARTITION BY RANGE (YEAR(created_at)) (
  PARTITION p2024 VALUES LESS THAN (2025), PARTITION pFuturo VALUES LESS THAN MAXVALUE);
SELECT PARTITION_NAME,TABLE_ROWS FROM information_schema.PARTITIONS WHERE TABLE_NAME='viaje';
ALTER TABLE viaje REORGANIZE PARTITION pFuturo INTO (PARTITION p2027 VALUES LESS THAN (2028), PARTITION pFuturo VALUES LESS THAN MAXVALUE);
ALTER TABLE viaje DROP PARTITION p2023; -- ¡BORRA!
ALTER TABLE viaje REORGANIZE PARTITION p2023,p2024 INTO (PARTITION pHist VALUES LESS THAN (2025)); -- fusionar
```
