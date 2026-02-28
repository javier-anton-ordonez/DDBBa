-- PLAN DE BACKUP Y RECUPERACIÓN - RIDE HAILING DB
-- =======================================================
-- ARQUITECTURA: 4 NODOS (2 Maestros, 1 Lectura App, 1 Lectura Dashboard)
-- Este plan se ejecuta exclusivamente en el nodo: db-read-dashboard
-- =======================================================

-- 1. CLASIFICACIÓN DE DATOS Y FRECUENCIA
-- -------------------------------------------------------

-- NIVEL 1: CRÍTICO (Tiempo Real / Transaccional)
-- Frecuencia: Cada 1 hora (Incremental) + Diario (Completo)
-- Tablas:
--   - Viaje (Core del negocio: estado, conductor, pasajero)
--   - Transacciones (Pagos y cobros)
--   - Oferta (Histórico de precios y asignaciones)
--   - Posicion (Trazabilidad y seguridad)
--   - Telemetria (Datos de uso)

-- NIVEL 2: OPERATIVO (Cambios diarios)
-- Frecuencia: Diario (Completo) a las 03:00 AM (hora valle)
-- Tablas:
--   - Usuario (Perfiles)
--   - Conductor (Estado, documentación)
--   - Vehiculo (Flota)
--   - Informacion_Bancaria
--   - UsuarioUbicacion

-- NIVEL 3: ESTATICO (Configuración / Maestros)
-- Frecuencia: Semanal (Domingos 04:00 AM) o tras despliegues
-- Tablas:
--   - Roles, Permisos, RolesPermisos, RolesUsuario
--   - TipoUbicacion, Ubicacion (Callejero)
--   - Compania

-- 2. COMANDOS DE BACKUP (Para scripts automáticos/CRON)
-- -------------------------------------------------------

-- A) BACKUP NIVEL 1 (CRÍTICO)
-- mysqldump -h db-read-dashboard -u root -p$MYSQL_ROOT_PASSWORD \
--    --single-transaction --quick --lock-tables=false \
--    ride_hailing_db Viaje Transacciones Oferta Posicion Telemetria \
--    > /backups/hourly/critical_$(date +%F_%H).sql

-- B) BACKUP NIVEL 2 (OPERATIVO)
-- mysqldump -h db-read-dashboard -u root -p$MYSQL_ROOT_PASSWORD \
--    --single-transaction --quick --lock-tables=false \
--    ride_hailing_db Usuario Conductor Vehiculo Informacion_Bancaria UsuarioUbicacion \
--    > /backups/daily/operational_$(date +%F).sql

-- C) BACKUP NIVEL 3 (ESTÁTICO)
-- mysqldump -h db-read-dashboard -u root -p$MYSQL_ROOT_PASSWORD \
--    --single-transaction --quick --lock-tables=false \
--    ride_hailing_db Roles Permisos RolesPermisos RolesUsuario TipoUbicacion Ubicacion Compania \
--    > /backups/weekly/static_$(date +%F).sql

-- D) BACKUP COMPLETO (DISASTER RECOVERY - FULL)
-- mysqldump -h db-read-dashboard -u root -p$MYSQL_ROOT_PASSWORD \
--    --single-transaction --quick --lock-tables=false --routines --triggers --events \
--    ride_hailing_db > /backups/full/full_$(date +%F).sql

-- 3. PLAN DE RECUPERACIÓN (DISASTER RECOVERY)
-- -------------------------------------------------------
-- Escenario: Corrupción masiva o pérdida de ambos maestros.

-- Paso 1: Aislar el clúster (detener tráfico en balanceador).
-- Paso 2: Seleccionar un nodo maestro limpio (db-master-1).
-- Paso 3: Cargar backup FULL más reciente.
--    mysql -h db-master-1 -u root -p ride_hailing_db < /backups/full/full_LAST.sql
-- Paso 4: Cargar backups incrementales (CRÍTICOS) secuencialmente.
--    mysql -h db-master-1 -u root -p ride_hailing_db < /backups/hourly/critical_01.sql ...
-- Paso 5: Reconstruir la replicación.
--    (Resetear master status en db-master-2, db-read-app y db-read-dashboard y apuntar al nuevo master-1).
-- Paso 6: Validar consistencia y reanudar tráfico.

-- 4. JUSTIFICACIÓN TÉCNICA
-- -------------------------------------------------------
-- - Nodo de Backup Dedicado: Se usa 'db-read-dashboard' para evitar "I/O Wait" en los maestros.
-- - InnoDB Single Transaction: Permite backups consistentes sin bloquear tablas (Non-Locking Reads).
-- - Redundancia: Los backups se deben mover a almacenamiento externo (S3/Glacier) tras generarse.
