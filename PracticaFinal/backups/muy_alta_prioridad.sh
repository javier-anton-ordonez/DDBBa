#!/bin/bash
# Backup COMPLETO - Prioridad MUY ALTA
# Tablas: Transacciones, Viaje
# Frecuencia: 1 vez al día (diario a las 3:00 AM)

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/javier/Documentos/DDBBa/PracticaFinal/backups/muy_alta"
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"
RETENTION_DAYS=7

mkdir -p ${BACKUP_DIR}

docker exec ${CONTAINER_NAME} mysqldump \
  -uroot -prootpassword \
  --single-transaction \
  --flush-logs \
  --master-data=2 \
  ${DB_NAME} Transacciones Viaje \
  >"${BACKUP_DIR}/full_MA_${FECHA}.sql"

if [ $? -eq 0 ]; then
  echo "Backup completo creado: full_MA_${FECHA}.sql"
else
  echo "ERROR: Backup falló" >&2
  exit 1
fi

find ${BACKUP_DIR} -name "full_MA_*.sql" -mtime +${RETENTION_DAYS} -delete
echo "Limpieza completada (>${RETENTION_DAYS} días)"
