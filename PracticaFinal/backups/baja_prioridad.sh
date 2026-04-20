#!/bin/bash
# Backup COMPLETO - Prioridad BAJA
# Tablas: Vehiculo, Compania, Ubicacion, Roles, Permisos
# Frecuencia: 1 vez al mes (día 1 a las 3:00 AM)

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="~/backups/baja"
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"
RETENTION_DAYS=60

mkdir -p ${BACKUP_DIR}

docker exec ${CONTAINER_NAME} mysqldump \
  -uroot -prootpassword \
  --single-transaction \
  --flush-logs \
  --master-data=2 \
  ${DB_NAME} Vehiculo Compania Ubicacion Roles Permisos \
  >"${BACKUP_DIR}/full_B_${FECHA}.sql"

if [ $? -eq 0 ]; then
  echo "Backup completo creado: full_B_${FECHA}.sql"
else
  echo "ERROR: Backup falló" >&2
  exit 1
fi

find ${BACKUP_DIR} -name "full_B_*.sql" -mtime +${RETENTION_DAYS} -delete
echo "Limpieza completada (>${RETENTION_DAYS} días)"
