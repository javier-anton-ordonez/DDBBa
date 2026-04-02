#!/bin/bash
# Backup INCREMENTAL con binlog - Prioridad ALTA
# Tablas: Oferta
# Frecuencia: 1 vez cada 12 horas

FECHA=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/home/javier/Documentos/DDBBa/PracticaFinal/backups/alta"
BINLOG_DIR="${BACKUP_DIR}/binlogs"
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"
RETENTION_DAYS=14

mkdir -p ${BINLOG_DIR}

BINLOG_FILE=$(docker exec ${CONTAINER_NAME} mysql -uroot -prootpassword -e "SHOW MASTER STATUS\G" | grep "File:" | awk '{print $2}')
BINLOG_POS=$(docker exec ${CONTAINER_NAME} mysql -uroot -prootpassword -e "SHOW MASTER STATUS\G" | grep "Position:" | awk '{print $2}')

echo "\033[32m[1/2]\033[0m Binlog actual: ${BINLOG_FILE} posición ${BINLOG_POS}"

docker exec ${CONTAINER_NAME} mysqlbinlog \
  --database=${DB_NAME} \
  --base64-output=DECODE-ROWS \
  --verbose \
  /var/lib/mysql/${BINLOG_FILE} |
  grep -E "(Oferta|^###|^#[0-9]{6}|^BINLOG|^BEGIN|^COMMIT|^SET)" \
    >"${BINLOG_DIR}/inc_A_${FECHA}.sql" 2>/dev/null

if [ $? -eq 0 ]; then
  echo "\033[32m[2/2]\033[0m Backup incremental creado: inc_A_${FECHA}.sql"

  echo "BINLOG_FILE=${BINLOG_FILE}" >"${BINLOG_DIR}/inc_A_${FECHA}.info"
  echo "BINLOG_POS=${BINLOG_POS}" >>"${BINLOG_DIR}/inc_A_${FECHA}.info"
  echo "BACKUP_DATE=${FECHA}" >>"${BINLOG_DIR}/inc_A_${FECHA}.info"
  echo "TABLES=Oferta" >>"${BINLOG_DIR}/inc_A_${FECHA}.info"
else
  echo "\033[31mAdvertencia\033[0m: No se pudieron extraer cambios del binlog"
fi

find ${BINLOG_DIR} -name "inc_A_*.sql" -mtime +${RETENTION_DAYS} -delete
find ${BINLOG_DIR} -name "inc_A_*.info" -mtime +${RETENTION_DAYS} -delete

echo "\033[32mBackup incremental completado\033[0m"
