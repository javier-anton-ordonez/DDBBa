# Ejemplos de Uso - Scripts de Backup y Restauración

## 📋 Backups Manuales

### Ejecutar backup completo de Muy Alta prioridad
```bash
cd /home/javier/Documentos/DDBBa/PracticaFinal/backups
./muy_alta_prioridad.sh
```

### Ejecutar backup incremental
```bash
./muy_alta_incremental.sh
```

### Ver archivos generados
```bash
ls -lh muy_alta/
ls -lh muy_alta/binlogs/
```

---

## 🔍 Restauración de UNA Tabla (Método Recomendado)

### Caso: Solo se dañó la tabla "Viaje", "Transacciones" está bien

```bash
cd /home/javier/Documentos/DDBBa/PracticaFinal/backups

# 1. Extraer solo la tabla Viaje
./extract_table.sh muy_alta/full_MA_20260402_030000.sql Viaje

# Salida:
# ✓ Tabla extraída exitosamente
# Archivo generado: extracted_Viaje_20260402_103000.sql

# 2. Restaurar solo esa tabla
./restore_table.sh extracted_Viaje_20260402_103000.sql

# Te preguntará:
# ¿Estás seguro de continuar? (escribe 'SI' para confirmar): SI

# ✓ Backup de seguridad creado: safety_backup_Viaje_20260402_103000.sql
# ✓ Tabla restaurada exitosamente
```

**Resultado:** Solo `Viaje` fue restaurada, `Transacciones` mantiene sus datos nuevos ✅

---

## 🔄 Restauración PITR (Point-in-Time)

### Caso: DELETE accidental a las 10:30, quieres volver a las 10:29

```bash
cd /home/javier/Documentos/DDBBa/PracticaFinal/backups

# 1. Buscar el DELETE en el binlog
docker exec ride-db-master-1 mysqlbinlog \
  --start-datetime="2026-04-02 10:25:00" \
  --stop-datetime="2026-04-02 10:35:00" \
  /var/lib/mysql/mysql-bin.000001 | grep -B5 -A5 "DELETE"

# Salida ejemplo:
# #260402 10:30:15 server id 1  end_log_pos 12345
# ### DELETE FROM `ride_hailing_db`.`Viaje`
# ### WHERE
# ###   @1=12345 /* id */

# 2. Restaurar hasta ANTES del DELETE (posición 12344)
./restore_pitr.sh muy_alta/full_MA_20260402_030000.sql mysql-bin.000001 12344

# O por fecha/hora:
./restore_pitr.sh muy_alta/full_MA_20260402_030000.sql '2026-04-02 10:29:59'
```

**⚠️ IMPORTANTE:** Este método restaura TODAS las tablas del grupo (Transacciones + Viaje)

---

## 📊 Verificación después de Restaurar

```bash
# Conectar a la base de datos
docker exec -it ride-db-master-1 mysql -uroot -prootpassword ride_hailing_db

# Verificar conteos
SELECT 'Viaje' as tabla, COUNT(*) as filas FROM Viaje
UNION ALL
SELECT 'Transacciones', COUNT(*) FROM Transacciones;

# Ver últimos registros
SELECT * FROM Viaje ORDER BY id DESC LIMIT 10;

# Verificar por fecha
SELECT COUNT(*) FROM Viaje WHERE created_at > '2026-04-02 03:00:00';
```

---

## 🧪 Comparación de Métodos

| Escenario | Método | Comando | Afecta |
|-----------|--------|---------|--------|
| Solo Viaje dañada | `extract_table.sh` + `restore_table.sh` | `./extract_table.sh full_MA.sql Viaje` | Solo Viaje ✅ |
| Todas las tablas MA dañadas | Restore directo | `cat full_MA.sql \| docker exec...` | Transacciones + Viaje ⚠️ |
| DELETE a las 10:30, PITR a 10:29 | `restore_pitr.sh` | `./restore_pitr.sh full_MA.sql '10:29:00'` | Transacciones + Viaje ⚠️ |

---

## 💡 Tips

### 1. Siempre haz un backup de seguridad antes de restaurar
```bash
# El script restore_table.sh lo hace automáticamente
# Genera: safety_backup_Viaje_YYYYMMDD_HHMMSS.sql
```

### 2. Prueba en un entorno de TEST primero
```bash
# Si tienes otro contenedor de prueba:
cat extracted_Viaje_20260402.sql | docker exec -i mysql-test mysql -uroot -p testdb
```

### 3. Lista todos tus backups disponibles
```bash
find backups/ -name "full_*.sql" -printf "%T@ %Tc %p\n" | sort -n | tail -10
```

### 4. Ver qué tablas hay en un backup
```bash
grep "CREATE TABLE" muy_alta/full_MA_20260402_030000.sql
```

---

## 🚨 Troubleshooting

### Error: "No se puede conectar a la base de datos"
```bash
# Verificar que el contenedor está corriendo
docker ps | grep ride-db-master-1

# Si no está corriendo:
cd /home/javier/Documentos/DDBBa/PracticaFinal
docker-compose up -d db-master-1
```

### Error: "No se encontró la tabla en el backup"
```bash
# Verificar qué tablas hay en el backup
grep "CREATE TABLE" muy_alta/full_MA_20260402_030000.sql

# Asegúrate de escribir el nombre exacto (case-sensitive):
# ✅ Correcto: Viaje
# ❌ Incorrecto: viaje, VIAJE
```

### La restauración es muy lenta
```bash
# Los backups grandes pueden tardar. Para ver progreso:
# En otra terminal:
docker exec -it ride-db-master-1 mysql -uroot -prootpassword -e "SHOW PROCESSLIST;"
```
