#!/bin/bash
# backup_mysql.sh

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/mysql"
RETENTION_DAYS=7

docker exec mysql8 mysqldump \
  -uroot -prootpass \
  --single-transaction \
  Conductor Usuario Informacion_Bancaria Telemetria \
  >backup_tablas_$(date +%Y%m%d).sql

# Verificar que se creó
if [ $? -eq 0 ]; then
  echo "Backup creado: backup_${FECHA}.sql"
else
  echo "ERROR: Backup falló" >&2
  exit 1
fi

# Borrar backups antiguos
find ${BACKUP_DIR} -name "backup_*.sql" -mtime +${RETENTION_DAYS} -delete
echo "Backups con más de ${RETENTION_DAYS} días eliminados"
