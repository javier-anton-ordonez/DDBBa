#!/bin/bash
# Script para extraer UNA tabla específica de un backup completo
# Útil cuando solo necesitas restaurar una tabla sin afectar las demás

# Verificar argumentos
if [ $# -lt 2 ]; then
  echo "==========================================="
  echo "Extractor de Tabla desde Backup Completo"
  echo "==========================================="
  echo ""
  echo "Uso: $0 <archivo_backup.sql> <nombre_tabla>"
  echo ""
  echo "Ejemplos:"
  echo "  $0 muy_alta/full_MA_20260402_030000.sql Viaje"
  echo "  $0 muy_alta/full_MA_20260402_030000.sql Transacciones"
  echo "  $0 media/full_M_20260402_030000.sql Usuario"
  echo ""
  echo "Tablas disponibles por prioridad:"
  echo "  MUY ALTA: Transacciones, Viaje"
  echo "  ALTA: Oferta"
  echo "  MEDIA: Conductor, Usuario, Informacion_Bancaria, Telemetria"
  echo "  BAJA: Vehiculo, Compania, Ubicacion, Roles, Permisos"
  exit 1
fi

BACKUP_FILE=$1
TABLE_NAME=$2
OUTPUT_FILE="extracted_${TABLE_NAME}_$(date +%Y%m%d_%H%M%S).sql"

echo "==========================================="
echo "Extrayendo tabla: ${TABLE_NAME}"
echo "Desde archivo: ${BACKUP_FILE}"
echo "==========================================="

# Verificar que el archivo existe
if [ ! -f "${BACKUP_FILE}" ]; then
  echo "✗ ERROR: No se encuentra el archivo ${BACKUP_FILE}" >&2
  exit 1
fi

# Extraer la definición de la tabla y sus datos
echo "[1/2] Extrayendo estructura y datos de la tabla..."

# Buscar desde DROP TABLE (si existe) o CREATE TABLE hasta UNLOCK TABLES
# Incluye también los INSERT INTO de esa tabla
{
  # Copiar el header del backup (configuraciones de MySQL)
  sed -n '1,/^-- Table structure/p' "${BACKUP_FILE}" | head -n 20
  
  echo ""
  echo "-- ============================================"
  echo "-- Tabla extraída: ${TABLE_NAME}"
  echo "-- Fecha extracción: $(date)"
  echo "-- ============================================"
  echo ""
  
  # Extraer DROP TABLE, CREATE TABLE y datos
  sed -n "/DROP TABLE.*\`${TABLE_NAME}\`/,/UNLOCK TABLES;/p" "${BACKUP_FILE}"
  
  # Si no encontró DROP TABLE, buscar solo CREATE TABLE
  if [ $? -ne 0 ]; then
    sed -n "/CREATE TABLE.*\`${TABLE_NAME}\`/,/UNLOCK TABLES;/p" "${BACKUP_FILE}"
  fi
  
} > "${OUTPUT_FILE}"

# Verificar que se extrajo algo
if [ -s "${OUTPUT_FILE}" ]; then
  FILE_SIZE=$(du -h "${OUTPUT_FILE}" | cut -f1)
  echo "[2/2] ✓ Tabla extraída exitosamente"
  echo ""
  echo "Archivo generado: ${OUTPUT_FILE}"
  echo "Tamaño: ${FILE_SIZE}"
  echo ""
  echo "==========================================="
  echo "Próximos pasos:"
  echo "==========================================="
  echo "1. Revisar el archivo generado:"
  echo "   less ${OUTPUT_FILE}"
  echo ""
  echo "2. Restaurar la tabla (¡CUIDADO! Sobrescribirá la tabla actual):"
  echo "   cat ${OUTPUT_FILE} | docker exec -i ride-db-master-1 mysql -uroot -prootpassword ride_hailing_db"
  echo ""
  echo "3. O usar el script de restauración:"
  echo "   ./restore_table.sh ${OUTPUT_FILE}"
  echo ""
else
  echo "✗ ERROR: No se pudo extraer la tabla ${TABLE_NAME}" >&2
  echo "Verifica que el nombre de la tabla sea correcto y exista en el backup" >&2
  rm -f "${OUTPUT_FILE}"
  exit 1
fi
