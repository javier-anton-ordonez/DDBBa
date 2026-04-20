#!/bin/bash
# Backup COMPLETO - Prioridad MEDIA
# Tablas: Conductor, Usuario, Informacion_Bancaria, Telemetria
# Frecuencia: 1 vez a la semana (domingos a las 3:00 AM)

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="~/backups/media"
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"
RETENTION_DAYS=21

mkdir -p ${BACKUP_DIR}

docker exec ${CONTAINER_NAME} mysqldump \
  -uroot -prootpassword \
  --single-transaction \
  --flush-logs \
  --master-data=2 \
  ${DB_NAME} Conductor Usuario Informacion_Bancaria Telemetria \
  >"${BACKUP_DIR}/full_M_${FECHA}.sql"

if [ $? -eq 0 ]; then
  echo "Backup completo creado: full_M_${FECHA}.sql"
else
  echo "ERROR: Backup falló" >&2
  exit 1
fi

find ${BACKUP_DIR} -name "full_M_*.sql" -mtime +${RETENTION_DAYS} -delete
echo "Limpieza completada (>${RETENTION_DAYS} días)"
