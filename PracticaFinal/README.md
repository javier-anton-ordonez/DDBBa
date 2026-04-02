# Instrucciones para levantar la base de datos.

El comando de docker para levantar la base de datos con todas sus copias es:
``` bash
docker compose -f docker-compose.yaml up -d --build
```
Alternativa si esta instalado en como un programa distinto:

``` bash
docker-compose -f docker-compose.yaml up -d --build
```

# Para meter los datos en la base de datos:

``` bash
docker exec -i ride-db-master-1 mysql -uroot -prootpassword ride_hailing_db < data.sql
```

# Para automatizar los backups, edita el crontab:

```bash
crontab -e
```

Y añade las siguientes líneas:

```cron
# BACKUPS COMPLETOS

# MUY ALTA - Diario a las 3:00 AM
0 3 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/muy_alta_prioridad.sh >> /var/log/backup_ma_full.log 2>&1

# ALTA - Lunes y Jueves a las 3:00 AM
0 3 * * 1,4 /home/javier/Documentos/DDBBa/PracticaFinal/backups/alta_prioridad.sh >> /var/log/backup_a_full.log 2>&1

# MEDIA - Domingos a las 3:00 AM
0 3 * * 0 /home/javier/Documentos/DDBBa/PracticaFinal/backups/media_prioridad.sh >> /var/log/backup_m_full.log 2>&1

# BAJA - Día 1 de cada mes a las 3:00 AM
0 3 1 * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/baja_prioridad.sh >> /var/log/backup_b_full.log 2>&1

# BACKUPS INCREMENTALES (BINLOG)

# MUY ALTA - Cada hora
0 * * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/muy_alta_incremental.sh >> /var/log/backup_ma_inc.log 2>&1

# ALTA - Cada 12 horas (00:00 y 12:00)
0 0,12 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/alta_incremental.sh >> /var/log/backup_a_inc.log 2>&1

# MEDIA - Diario a las 23:00
0 23 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/media_incremental.sh >> /var/log/backup_m_inc.log 2>&1

# BAJA - Diario a las 23:30
30 23 * * * /home/javier/Documentos/DDBBa/PracticaFinal/backups/baja_incremental.sh >> /var/log/backup_b_inc.log 2>&1
```

