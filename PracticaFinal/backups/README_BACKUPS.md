# Guía de Backups por Prioridad - ride_hailing_db

## 📊 Estrategia de Backups

### Clasificación de Tablas por Prioridad

| Prioridad | Tablas | Backup Completo | Backup Incremental |
|-----------|--------|-----------------|-------------------|
| **MUY ALTA (MA)** | Transacciones, Viaje | 1 vez al día | 1 vez cada hora |
| **ALTA (A)** | Oferta | 2 veces a la semana | 1 vez cada 12 horas |
| **MEDIA (M)** | Conductor, Usuario, Informacion_Bancaria, Telemetria | 1 vez a la semana | 1 vez al día |
| **BAJA (B)** | Vehiculo, Compania, Ubicacion, Roles, Permisos | 1 vez al mes | 1 vez al día |

---

## 📁 Scripts Disponibles

### Backups COMPLETOS (con `mysqldump`)
- `muy_alta_prioridad.sh` - Backup completo de Transacciones y Viaje
- `alta_prioridad.sh` - Backup completo de Oferta
- `media_prioridad.sh` - Backup completo de Conductor, Usuario, Informacion_Bancaria, Telemetria
- `baja_prioridad.sh` - Backup completo de Vehiculo, Compania, Ubicacion, Roles, Permisos

### Backups INCREMENTALES (con binlog)
- `muy_alta_incremental.sh` - Cambios incrementales de Transacciones y Viaje
- `alta_incremental.sh` - Cambios incrementales de Oferta
- `media_incremental.sh` - Cambios incrementales de Conductor, Usuario, Informacion_Bancaria, Telemetria
- `baja_incremental.sh` - Cambios incrementales de Vehiculo, Compania, Ubicacion, Roles, Permisos

### Restauración
- `restore_pitr.sh` - Script para restauración Point-in-Time Recovery (restaura TODO un grupo)
- `extract_table.sh` - Extrae UNA tabla específica de un backup completo
- `restore_table.sh` - Restaura UNA tabla individual (RECOMENDADO)

---

## ⏰ Configuración de Crontab

Para automatizar los backups, edita el crontab:

```bash
crontab -e
```

Y añade las siguientes líneas:

```cron
# ============================================
# BACKUPS COMPLETOS
# ============================================

# MUY ALTA - Diario a las 3:00 AM
0 3 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/muy_alta_prioridad.sh >> /var/log/backup_ma_full.log 2>&1

# ALTA - Lunes y Jueves a las 3:00 AM
0 3 * * 1,4 /home/javier/Documentos/DDBBa/PracticaFinal/backups/alta_prioridad.sh >> /var/log/backup_a_full.log 2>&1

# MEDIA - Domingos a las 3:00 AM
0 3 * * 0 /home/javier/Documentos/DDBBa/PracticaFinal/backups/media_prioridad.sh >> /var/log/backup_m_full.log 2>&1

# BAJA - Día 1 de cada mes a las 3:00 AM
0 3 1 * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/baja_prioridad.sh >> /var/log/backup_b_full.log 2>&1

# ============================================
# BACKUPS INCREMENTALES (BINLOG)
# ============================================

# MUY ALTA - Cada hora
0 * * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/muy_alta_incremental.sh >> /var/log/backup_ma_inc.log 2>&1

# ALTA - Cada 12 horas (00:00 y 12:00)
0 0,12 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/alta_incremental.sh >> /var/log/backup_a_inc.log 2>&1

# MEDIA - Diario a las 23:00
0 23 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/media_incremental.sh >> /var/log/backup_m_inc.log 2>&1

# BAJA - Diario a las 23:30
30 23 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/baja_incremental.sh >> /var/log/backup_b_inc.log 2>&1
```

---

## 📂 Estructura de Directorios

Después de ejecutar los scripts, se crearán las siguientes carpetas:

```
backups/
├── muy_alta/
│   ├── full_MA_20260402_030000.sql
│   └── binlogs/
│       ├── inc_MA_20260402_040000.sql
│       └── inc_MA_20260402_040000.info
├── alta/
│   ├── full_A_20260402_030000.sql
│   └── binlogs/
│       ├── inc_A_20260402_120000.sql
│       └── inc_A_20260402_120000.info
├── media/
│   ├── full_M_20260402_030000.sql
│   └── binlogs/
│       ├── inc_M_20260402_230000.sql
│       └── inc_M_20260402_230000.info
└── baja/
    ├── full_B_20260401_030000.sql
    └── binlogs/
        ├── inc_B_20260402_233000.sql
        └── inc_B_20260402_233000.info
```

---

## 🔄 Escenarios de Restauración

### ⚠️ IMPORTANTE: Restauración Selectiva vs Completa

Cuando un backup agrupa múltiples tablas (ej: MUY ALTA = Transacciones + Viaje):
- **NO restaures el backup completo** si solo una tabla tiene problemas
- Usa `extract_table.sh` para extraer SOLO la tabla afectada
- Así **NO pierdes datos nuevos** de las otras tablas

---

### Escenario 1: Restaurar UNA tabla específica (RECOMENDADO)

**Situación:**
- Backup completo MUY ALTA: 03:00 AM (Transacciones + Viaje)
- DELETE accidental en `Viaje`: 10:30 AM
- `Transacciones` está perfecta y tiene datos nuevos ✅

**Pasos:**

**1. Extraer solo la tabla Viaje del backup completo**
```bash
cd /home/javier/Documentos/DDBBa/PracticaFinal/backups

./extract_table.sh muy_alta/full_MA_20260402_030000.sql Viaje
# Genera: extracted_Viaje_20260402_103000.sql
```

**2. Revisar el archivo extraído (opcional)**
```bash
less extracted_Viaje_20260402_103000.sql
```

**3. Restaurar solo esa tabla**
```bash
./restore_table.sh extracted_Viaje_20260402_103000.sql
# Te pedirá confirmación y creará un backup de seguridad automáticamente
```

**4. Verificar datos**
```sql
docker exec -it ride-db-master-1 mysql -uroot -prootpassword ride_hailing_db
SELECT COUNT(*) FROM Viaje;
SELECT * FROM Viaje ORDER BY id DESC LIMIT 10;
```

**✅ Resultado:** `Viaje` restaurada a las 03:00 AM, `Transacciones` intacta con todos sus datos nuevos

---

### Escenario 2: Restaurar TODO un grupo de prioridad (CUIDADO)

**Situación:**
- Necesitas restaurar TODAS las tablas de una prioridad
- Ejemplo: Corrupción completa de MUY ALTA (Transacciones + Viaje)

**⚠️ ADVERTENCIA:** Esto SOBRESCRIBE todas las tablas del grupo

**Pasos:**

```bash
cd /home/javier/Documentos/DDBBa/PracticaFinal/backups

# Restaurar backup completo directamente
cat muy_alta/full_MA_20260402_030000.sql | \
  docker exec -i ride-db-master-1 mysql -uroot -prootpassword ride_hailing_db

# Verificar
docker exec -it ride-db-master-1 mysql -uroot -prootpassword ride_hailing_db -e \
  "SELECT 'Transacciones' as tabla, COUNT(*) as filas FROM Transacciones 
   UNION ALL 
   SELECT 'Viaje', COUNT(*) FROM Viaje;"
```

---

### Escenario 3: Restauración PITR (Point-in-Time con binlog)

**Situación:**
- Necesitas restaurar hasta un momento EXACTO antes del error
- Tienes backups incrementales con binlog

**Pasos:**

**1. Identificar el momento del error en el binlog**
```bash
docker exec ride-db-master-1 mysqlbinlog \
  --start-datetime="2026-04-02 10:25:00" \
  --stop-datetime="2026-04-02 10:35:00" \
  /var/lib/mysql/mysql-bin.000001 | grep -A5 -B5 "DELETE FROM Viaje"
```

**2. Restaurar backup completo + binlog hasta antes del error**
```bash
# Opción A: Por fecha/hora
./restore_pitr.sh muy_alta/full_MA_20260402_030000.sql '2026-04-02 10:29:00'

# Opción B: Por posición de binlog (más preciso)
./restore_pitr.sh muy_alta/full_MA_20260402_030000.sql mysql-bin.000001 12345
```

**3. Verificar datos**
```sql
USE ride_hailing_db;
SELECT COUNT(*) FROM Viaje;
SELECT * FROM Viaje WHERE created_at > '2026-04-02 10:29:00';
```

**⚠️ NOTA:** Este método restaura TODAS las tablas del grupo hasta ese momento

---

## 🔍 Verificación de Binlog

Antes de usar los scripts, verifica que el binlog esté activo:

```bash
docker exec ride-db-master-1 mysql -uroot -prootpassword -e "SHOW VARIABLES LIKE 'log_bin';"
docker exec ride-db-master-1 mysql -uroot -prootpassword -e "SHOW VARIABLES LIKE 'binlog_format';"
docker exec ride-db-master-1 mysql -uroot -prootpassword -e "SHOW BINARY LOGS;"
```

Debe mostrar:
- `log_bin`: ON
- `binlog_format`: ROW
- Lista de archivos binlog disponibles

---

## 📊 RPO y RTO por Prioridad

| Prioridad | RPO (pérdida máxima datos) | RTO (tiempo recuperación) |
|-----------|----------------------------|---------------------------|
| MUY ALTA  | 1 hora | 30 minutos |
| ALTA      | 12 horas | 1-2 horas |
| MEDIA     | 24 horas | 2-4 horas |
| BAJA      | 1 día | 4-8 horas |

---

## 🧪 Prueba Manual de Scripts

Antes de configurar el cron, prueba manualmente cada script:

```bash
cd /home/javier/Documentos/DDBBa/PracticaFinal/backups

# Probar backup completo Muy Alta
./muy_alta_prioridad.sh

# Probar backup incremental Muy Alta
./muy_alta_incremental.sh

# Verificar archivos creados
ls -lh muy_alta/
ls -lh muy_alta/binlogs/
```

---

## ⚠️ Notas Importantes

1. **Los backups incrementales con `grep`** filtran el binlog por nombre de tabla, pero pueden no capturar TODAS las transacciones relacionadas si hay triggers o FK con otras tablas.

2. **Retención de backups:**
   - MUY ALTA: 7 días
   - ALTA: 14 días
   - MEDIA: 21 días
   - BAJA: 60 días

3. **Espacio en disco:** Monitorea el uso de disco regularmente, especialmente los binlogs.

4. **Pruebas de restauración:** Haz pruebas de restauración periódicas en un entorno de TEST para validar que los backups funcionan correctamente.

---

## 📞 Comandos Útiles

```bash
# Ver logs de cron
tail -f /var/log/backup_ma_full.log

# Ver tamaño de backups
du -sh backups/*

# Listar todos los backups
find backups/ -name "*.sql" -ls

# Eliminar backups antiguos manualmente
find backups/ -name "*.sql" -mtime +30 -delete
```
