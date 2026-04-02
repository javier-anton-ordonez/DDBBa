#!/bin/bash
# Backup INCREMENTAL con binlog - Prioridad MEDIA
# Tablas: Conductor, Usuario, Informacion_Bancaria, Telemetria
# Frecuencia: 1 vez al día

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/javier/Documentos/DDBBa/PracticaFinal/backups/media"
BINLOG_DIR="${BACKUP_DIR}/binlogs"
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"
RETENTION_DAYS=21

mkdir -p ${BINLOG_DIR}

BINLOG_FILE=$(docker exec ${CONTAINER_NAME} mysql -uroot -prootpassword -e "SHOW MASTER STATUS\G" | grep "File:" | awk '{print $2}')
BINLOG_POS=$(docker exec ${CONTAINER_NAME} mysql -uroot -prootpassword -e "SHOW MASTER STATUS\G" | grep "Position:" | awk '{print $2}')

echo "[1/2] Binlog actual: ${BINLOG_FILE} posición ${BINLOG_POS}"

docker exec ${CONTAINER_NAME} mysqlbinlog \
  --database=${DB_NAME} \
  --base64-output=DECODE-ROWS \
  --verbose \
  /var/lib/mysql/${BINLOG_FILE} |
  grep -E "(Conductor|Usuario|Informacion_Bancaria|Telemetria|^###|^#[0-9]{6}|^BINLOG|^BEGIN|^COMMIT|^SET)" \
    >"${BINLOG_DIR}/inc_M_${FECHA}.sql" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "[2/2] Backup incremental creado: inc_M_${FECHA}.sql"

  echo "BINLOG_FILE=${BINLOG_FILE}" >"${BINLOG_DIR}/inc_M_${FECHA}.info"
  echo "BINLOG_POS=${BINLOG_POS}" >>"${BINLOG_DIR}/inc_M_${FECHA}.info"
  echo "BACKUP_DATE=${FECHA}" >>"${BINLOG_DIR}/inc_M_${FECHA}.info"
  echo "TABLES=Conductor,Usuario,Informacion_Bancaria,Telemetria" >>"${BINLOG_DIR}/inc_M_${FECHA}.info"
else
  echo "Advertencia: No se pudieron extraer cambios del binlog"
fi

find ${BINLOG_DIR} -name "inc_M_*.sql" -mtime +${RETENTION_DAYS} -delete
find ${BINLOG_DIR} -name "inc_M_*.info" -mtime +${RETENTION_DAYS} -delete

echo "Backup incremental completado"
