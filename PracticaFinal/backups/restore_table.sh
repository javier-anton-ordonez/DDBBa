#!/bin/bash
# Script para restaurar UNA tabla específica extraída
# Más seguro que restaurar manualmente

# Verificar argumentos
if [ $# -lt 1 ]; then
  echo "Restaurador de Tabla Individual"
  echo ""
  echo "Uso: $0 <archivo_tabla.sql> [--force]"
  echo ""
  echo "Ejemplos:"
  echo "  $0 extracted_Viaje_20260402_103000.sql"
  exit 1
fi

BACKUP_FILE=$1
CONTAINER_NAME="ride-db-master-1"
DB_NAME="ride_hailing_db"

echo "Restauración de Tabla Individual"

if [ ! -f "${BACKUP_FILE}" ]; then
  echo "ERROR: No se encuentra el archivo ${BACKUP_FILE}" >&2
  exit 1
fi

TABLE_NAME=$(grep -o "CREATE TABLE \`[^`]*\\`" "${BACKUP_FILE}" | head -1 | sed "s/CREATE TABLE \`\(.*\)\`/\1/")

if [ -z "$TABLE_NAME" ]; then
  echo "Advertencia: No se pudo detectar el nombre de la tabla"
  TABLE_NAME="[Desconocida]"
fi

echo "Archivo: ${BACKUP_FILE}"
echo "Tabla detectada: ${TABLE_NAME}"
echo "Base de datos: ${DB_NAME}"
echo "Contenedor: ${CONTAINER_NAME}"
echo ""


echo "[1/3] Verificando conexión con la base de datos..."
docker exec ${CONTAINER_NAME} mysql -uroot -prootpassword -e "SELECT 1" > /dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "ERROR: No se puede conectar a la base de datos" >&2
  echo "Verifica que el contenedor ${CONTAINER_NAME} esté corriendo" >&2
  exit 1
fi
echo "Conexión exitosa"

echo "[2/3] Haciendo backup de seguridad de la tabla actual..."
SAFETY_BACKUP="safety_backup_${TABLE_NAME}_$(date +%Y%m%d_%H%M%S).sql"
docker exec ${CONTAINER_NAME} mysqldump \
  -uroot -prootpassword \
  --single-transaction \
  ${DB_NAME} ${TABLE_NAME} \
  > "${SAFETY_BACKUP}" 2>/dev/null

if [ -s "${SAFETY_BACKUP}" ]; then
  echo "Backup de seguridad creado: ${SAFETY_BACKUP}"
else
  echo "No se pudo crear backup de seguridad (puede que la tabla no exista)"
  rm -f "${SAFETY_BACKUP}"
fi

echo "[3/3] Restaurando tabla desde ${BACKUP_FILE}..."
cat "${BACKUP_FILE}" | docker exec -i ${CONTAINER_NAME} mysql -uroot -prootpassword ${DB_NAME}

if [ $? -eq 0 ]; then
  echo "Tabla restaurada exitosamente"
  if [ -f "${SAFETY_BACKUP}" ]; then
    echo "Backup de seguridad guardado en: ${SAFETY_BACKUP}"
  fi
else
  echo "ERROR: Falló la restauración" >&2
  if [ -f "${SAFETY_BACKUP}" ]; then
    echo ""
    echo "Comando para revertir:"
    echo "  cat ${SAFETY_BACKUP} | docker exec -i ${CONTAINER_NAME} mysql -uroot -prootpassword ${DB_NAME}"
  fi
  exit 1
fi
