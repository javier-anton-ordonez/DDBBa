#!/bin/bash
# Backup COMPLETO - Prioridad ALTA
# Tablas: Oferta
# Frecuencia: 2 veces a la semana (lunes y jueves a las 3:00 AM)

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="~/backups/alta"
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"
RETENTION_DAYS=14

mkdir -p ${BACKUP_DIR}

docker exec ${CONTAINER_NAME} mysqldump \
  -uroot -prootpassword \
  --single-transaction \
  --flush-logs \
  --master-data=2 \
  ${DB_NAME} Oferta \
  >"${BACKUP_DIR}/full_A_${FECHA}.sql"

if [ $? -eq 0 ]; then
  echo "\033[32mBackup completo\033[0m creado: full_A_${FECHA}.sql"
else
  echo "\033[31mERROR\033[0m: Backup falló" >&2
  exit 1
fi

find ${BACKUP_DIR} -name "full_A_*.sql" -mtime +${RETENTION_DAYS} -delete
echo "Limpieza completada (>${RETENTION_DAYS} días)"
