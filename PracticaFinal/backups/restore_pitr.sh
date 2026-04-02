#!/bin/bash
# Script de restauración PITR (Point-in-Time Recovery)
# Restaura backup completo + cambios del binlog hasta un momento específico

BACKUP_DIR="./backups"
BINLOG_DIR="${BACKUP_DIR}/binlogs"
CONTAINER_NAME="ride-db-master-1"

if [ $# -lt 2 ]; then
  echo "Modo de uso: $0 <archivo_backup.sql> <fecha_hora_limite>"
  echo "Ejemplo: $0 full_Viaje_20260402_120000.sql '2026-04-02 11:30:00'"
  echo ""
  echo "O con posición de binlog:"
  echo "$0 <archivo_backup.sql> <binlog_file> <stop_position>"
  echo "Ejemplo: $0 full_Viaje_20260402_120000.sql mysql-bin.000001 12345"
  exit 1
fi

BACKUP_FILE=$1
PARAM2=$2
PARAM3=$3

echo "Restauración Point-in-Time Recovery"

echo "[1/2] Restaurando backup completo..."
if [ ! -f "${BACKUP_DIR}/${BACKUP_FILE}" ]; then
  echo "ERROR: No se encuentra ${BACKUP_FILE}" >&2
  exit 1
fi

cat "${BACKUP_DIR}/${BACKUP_FILE}" | docker exec -i ${CONTAINER_NAME} mysql -uroot -prootpassword

if [ $? -eq 0 ]; then
  echo "Backup completo restaurado"
else
  echo "ERROR: Falló la restauración del backup" >&2
  exit 1
fi

echo "[2/2] Aplicando cambios incrementales del binlog..."

if [ -z "$PARAM3" ]; then
  # Modo: fecha/hora
  STOP_DATETIME=$PARAM2
  echo "Aplicando cambios hasta: ${STOP_DATETIME}"

  # Buscar el archivo binlog correspondiente
  BINLOG_INFO=$(ls -t ${BINLOG_DIR}/binlog_info_*.txt | head -1)
  if [ -f "$BINLOG_INFO" ]; then
    BINLOG_FILE=$(grep "BINLOG_FILE=" $BINLOG_INFO | cut -d= -f2)

    docker exec ${CONTAINER_NAME} mysqlbinlog \
      --stop-datetime="${STOP_DATETIME}" \
      /var/lib/mysql/${BINLOG_FILE} |
      docker exec -i ${CONTAINER_NAME} mysql -uroot -prootpassword
  else
    echo "Advertencia: No se encontró información de binlog"
  fi
else
  # Modo: posición de binlog
  BINLOG_FILE=$PARAM2
  STOP_POS=$PARAM3
  echo "Aplicando cambios del ${BINLOG_FILE} hasta posición ${STOP_POS}"

  docker exec ${CONTAINER_NAME} mysqlbinlog \
    --stop-position=${STOP_POS} \
    /var/lib/mysql/${BINLOG_FILE} |
    docker exec -i ${CONTAINER_NAME} mysql -uroot -prootpassword
fi

if [ $? -eq 0 ]; then
  echo "Cambios incrementales aplicados"
else
  echo "Advertencia: Puede haber problemas al aplicar binlog"
fi

echo "Restauración PITR completada"
echo ""
echo "Verifica los datos con queries SQL"
