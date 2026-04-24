-- =============================================================
-- dashboard.sql — Métricas de negocio y de base de datos
-- Base de datos: ride_hailing_db
-- =============================================================
-- ÍNDICE:
--   SECCIÓN 1 — MÉTRICAS DE NEGOCIO
--     1.1  Resumen general del sistema
--     1.2  Viajes: volumen y distribución temporal
--     1.3  Tasa de aceptación (global, por conductor, por compañía)
--     1.4  Ingresos (por conductor, por compañía)
--     1.5  Tiempo medio de viaje (por conductor, por compañía)
--     1.6  Euros por minuto y euros por km (por conductor, por compañía)
--     1.7  Kilometraje medio y euros por km (por conductor, por compañía)
--     1.8  Valoraciones y calidad del servicio
--     1.9  Actividad de usuarios
--   SECCIÓN 2 — MÉTRICAS DE BASE DE DATOS
--     2.1  Tamaño y filas por tabla
--     2.2  Usuarios de base de datos activos
--     2.3  Estado de las conexiones del servidor
--     2.4  Caché de consultas y rendimiento
-- =============================================================

USE ride_hailing_db;


-- =============================================================
-- SECCIÓN 1 — MÉTRICAS DE NEGOCIO
-- =============================================================

-- -------------------------------------------------------------
-- 1.1  RESUMEN GENERAL DEL SISTEMA
-- Un vistazo rápido al estado actual de la plataforma.
-- -------------------------------------------------------------

SELECT
    (SELECT COUNT(*) FROM Usuario  WHERE Baja IS NULL)  AS usuarios_activos,
    (SELECT COUNT(*) FROM Conductor WHERE Estado = 'Activo') AS conductores_activos,
    (SELECT COUNT(*) FROM Vehiculo  WHERE Estado = 'Activo') AS vehiculos_activos,
    (SELECT COUNT(*) FROM Compania  WHERE Baja IS NULL)  AS companias_activas,
    (SELECT COUNT(*) FROM Oferta)                        AS total_ofertas,
    (SELECT COUNT(*) FROM Viaje WHERE Estado = 'Finalizado') AS viajes_finalizados,
    (SELECT COUNT(*) FROM Viaje WHERE Estado = 'En curso')   AS viajes_en_curso,
    (SELECT COUNT(*) FROM Viaje WHERE Estado = 'Cancelado')  AS viajes_cancelados,
    (SELECT ROUND(SUM(t.Cantidad), 2) FROM Transacciones t)  AS ingresos_totales_eur;


-- -------------------------------------------------------------
-- 1.2  VIAJES: VOLUMEN Y DISTRIBUCIÓN TEMPORAL
-- -------------------------------------------------------------

-- Viajes finalizados por mes
SELECT
    DATE_FORMAT(v.Inicio, '%Y-%m') AS mes,
    COUNT(*)                        AS total_viajes,
    ROUND(AVG(o.Precio - o.Descuento), 2) AS precio_medio_eur
FROM Viaje v
JOIN Oferta o ON v.OfertaId = o.Id
WHERE v.Estado = 'Finalizado'
GROUP BY mes
ORDER BY mes;


-- Viajes por franja horaria del día (para detectar horas pico)
-- 0-5 madrugada, 6-9 mañana temprana, 10-13 mañana, 14-17 tarde, 18-21 noche, 22-23 noche tardía
SELECT
    CASE
        WHEN HOUR(v.Inicio) BETWEEN  0 AND  5 THEN '00-05 Madrugada'
        WHEN HOUR(v.Inicio) BETWEEN  6 AND  9 THEN '06-09 Mañana temprana'
        WHEN HOUR(v.Inicio) BETWEEN 10 AND 13 THEN '10-13 Mañana'
        WHEN HOUR(v.Inicio) BETWEEN 14 AND 17 THEN '14-17 Tarde'
        WHEN HOUR(v.Inicio) BETWEEN 18 AND 21 THEN '18-21 Noche'
        ELSE                                        '22-23 Noche tardía'
    END                AS franja_horaria,
    COUNT(*)           AS total_viajes
FROM Viaje v
WHERE v.Estado = 'Finalizado'
GROUP BY franja_horaria
ORDER BY MIN(HOUR(v.Inicio));


-- Viajes por día de la semana
SELECT
    DAYNAME(v.Inicio) AS dia_semana,
    COUNT(*) AS total_viajes
FROM Viaje v
WHERE v.Estado = 'Finalizado'
GROUP BY dia_semana, DAYOFWEEK(v.Inicio)
ORDER BY DAYOFWEEK(v.Inicio);


-- Viajes por estado (visión general del embudo)
SELECT
    Estado,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Viaje), 1) AS porcentaje
FROM Viaje
GROUP BY Estado
ORDER BY total DESC;


-- -------------------------------------------------------------
-- 1.3  TASA DE ACEPTACIÓN
-- Una oferta se considera "aceptada" cuando tiene un Viaje
-- asociado que no está en estado 'Solicitado'.
-- -------------------------------------------------------------

-- Tasa de aceptación global
SELECT
    COUNT(DISTINCT o.Id)                                              AS total_ofertas,
    COUNT(DISTINCT CASE WHEN v.Estado != 'Solicitado' THEN v.OfertaId END) AS ofertas_aceptadas,
    COUNT(DISTINCT CASE WHEN v.Estado  = 'Cancelado'  THEN v.OfertaId END) AS ofertas_canceladas,
    ROUND(
        COUNT(DISTINCT CASE WHEN v.Estado != 'Solicitado' THEN v.OfertaId END)
        * 100.0 / COUNT(DISTINCT o.Id), 1
    ) AS tasa_aceptacion_pct
FROM Oferta o
LEFT JOIN Viaje v ON v.OfertaId = o.Id;


-- Tasa de aceptación por conductor (top 15 por viajes realizados)
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)                    AS conductor,
    COUNT(v.Id)                                           AS viajes_totales,
    SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END) AS finalizados,
    SUM(CASE WHEN v.Estado = 'Cancelado'  THEN 1 ELSE 0 END) AS cancelados,
    ROUND(
        SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(v.Id), 1
    )                                                     AS tasa_finalizacion_pct
FROM Conductor c
JOIN Usuario u   ON c.UsuarioId  = u.Id
JOIN Viaje   v   ON v.ConductorId = c.Id
GROUP BY c.Id, conductor
ORDER BY viajes_totales DESC
LIMIT 15;


-- Tasa de aceptación por compañía
SELECT
    co.Nombre                                              AS compania,
    COUNT(v.Id)                                            AS viajes_totales,
    SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END) AS finalizados,
    SUM(CASE WHEN v.Estado = 'Cancelado'  THEN 1 ELSE 0 END) AS cancelados,
    ROUND(
        SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(v.Id), 1
    )                                                      AS tasa_finalizacion_pct
FROM Compania co
JOIN Conductor c ON c.EmpresaId   = co.Id
JOIN Viaje     v ON v.ConductorId = c.Id
GROUP BY co.Id, co.Nombre
ORDER BY tasa_finalizacion_pct DESC;


-- -------------------------------------------------------------
-- 1.4  INGRESOS
-- Usamos Transacciones para ingresos reales cobrados.
-- Usamos Oferta.Precio - Oferta.Descuento para precio pactado.
-- -------------------------------------------------------------

-- Ingresos reales por conductor (basado en Transacciones)
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido) AS conductor,
    co.Nombre                         AS compania,
    COUNT(DISTINCT v.Id)              AS viajes_finalizados,
    ROUND(SUM(t.Cantidad), 2)         AS ingresos_totales_eur,
    ROUND(AVG(t.Cantidad), 2)         AS ingreso_medio_por_viaje_eur
FROM Conductor c
JOIN Usuario      u  ON c.UsuarioId   = u.Id
JOIN Compania     co ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado'
JOIN Transacciones t ON t.ViajeId     = v.Id
GROUP BY c.Id, conductor, compania
ORDER BY ingresos_totales_eur DESC;


-- Ingresos reales por compañía
SELECT
    co.Nombre                      AS compania,
    ROUND(SUM(t.Cantidad), 2)      AS ingresos_totales_eur
FROM Compania co
JOIN Conductor    c  ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado'
JOIN Transacciones t ON t.ViajeId     = v.Id
GROUP BY co.Id, co.Nombre
ORDER BY ingresos_totales_eur DESC;


-- -------------------------------------------------------------
-- 1.5  TIEMPO MEDIO DE VIAJE
-- Calculado como minutos entre Inicio y Fin del Viaje.
-- -------------------------------------------------------------

-- Tiempo medio por conductor
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido) AS conductor,
    COUNT(v.Id)                       AS viajes_finalizados,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1) AS duracion_media_min,
    MIN(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin))           AS duracion_min_min,
    MAX(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin))           AS duracion_max_min
FROM Conductor c
JOIN Usuario u ON c.UsuarioId   = u.Id
JOIN Viaje   v ON v.ConductorId = c.Id
WHERE v.Estado = 'Finalizado'
  AND v.Fin IS NOT NULL
GROUP BY c.Id, conductor
ORDER BY duracion_media_min DESC;


-- Tiempo medio por compañía
SELECT
    co.Nombre                                                          AS compania,
    COUNT(v.Id)                                                        AS viajes_finalizados,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)             AS duracion_media_min,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)             AS duracion_min_min,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)             AS duracion_max_min
FROM Compania  co
JOIN Conductor c  ON c.EmpresaId   = co.Id
JOIN Viaje     v  ON v.ConductorId = c.Id
WHERE v.Estado = 'Finalizado'
  AND v.Fin IS NOT NULL
GROUP BY co.Id, co.Nombre
ORDER BY duracion_media_min;


-- -------------------------------------------------------------
-- 1.6  EUROS POR MINUTO Y EUROS POR KM
-- Relaciona los ingresos de cada viaje con su duración y distancia.
-- -------------------------------------------------------------

-- Euros por minuto por conductor
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido) AS conductor,
    co.Nombre                         AS compania,
    COUNT(v.Id)                       AS viajes,
    ROUND(SUM(t.Cantidad), 2)         AS ingresos_totales_eur,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0) AS minutos_totales,
    ROUND(
        SUM(t.Cantidad) / NULLIF(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0)
    , 3)                              AS eur_por_minuto
FROM Conductor c
JOIN Usuario      u  ON c.UsuarioId   = u.Id
JOIN Compania     co ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.Fin IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id
GROUP BY c.Id, conductor, compania
ORDER BY eur_por_minuto DESC;


-- Euros por minuto por compañía
SELECT
    co.Nombre                          AS compania,
    ROUND(SUM(t.Cantidad), 2)          AS ingresos_totales_eur,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0) AS minutos_totales,
    ROUND(
        SUM(t.Cantidad) / NULLIF(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0)
    , 3)                               AS eur_por_minuto
FROM Compania co
JOIN Conductor    c  ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.Fin IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id
GROUP BY co.Id, co.Nombre
ORDER BY eur_por_minuto DESC;


-- -------------------------------------------------------------
-- 1.7  KILOMETRAJE MEDIO Y EUROS POR KM
-- -------------------------------------------------------------

-- Kilometraje medio y euros/km por conductor
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)              AS conductor,
    co.Nombre                                       AS compania,
    COUNT(v.Id)                                     AS viajes,
    ROUND(AVG(v.DistanciaKm), 2)                   AS km_medio,
    ROUND(SUM(v.DistanciaKm), 2)                   AS km_totales,
    ROUND(SUM(t.Cantidad), 2)                       AS ingresos_totales_eur,
    ROUND(SUM(t.Cantidad) / NULLIF(SUM(v.DistanciaKm), 0), 3) AS eur_por_km
FROM Conductor c
JOIN Usuario      u  ON c.UsuarioId   = u.Id
JOIN Compania     co ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.DistanciaKm IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id
GROUP BY c.Id, conductor, compania
ORDER BY eur_por_km DESC;


-- Kilometraje medio y euros/km por compañía
SELECT
    co.Nombre                                        AS compania,
    COUNT(v.Id)                                      AS viajes,
    ROUND(AVG(v.DistanciaKm), 2)                    AS km_medio,
    ROUND(SUM(v.DistanciaKm), 2)                    AS km_totales,
    ROUND(SUM(t.Cantidad), 2)                        AS ingresos_totales_eur,
    ROUND(SUM(t.Cantidad) / NULLIF(SUM(v.DistanciaKm), 0), 3) AS eur_por_km
FROM Compania co
JOIN Conductor    c  ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.DistanciaKm IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id
GROUP BY co.Id, co.Nombre
ORDER BY eur_por_km DESC;


-- -------------------------------------------------------------
-- 1.7  VALORACIONES Y CALIDAD DEL SERVICIO
-- -------------------------------------------------------------

-- Nota media por conductor (solo viajes con valoración)
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido) AS conductor,
    co.Nombre                         AS compania,
    COUNT(v.Id)                       AS viajes_valorados,
    ROUND(AVG(v.Nota), 2)             AS nota_media,
    SUM(CASE WHEN v.Nota = 5 THEN 1 ELSE 0 END) AS cinco_estrellas,
    SUM(CASE WHEN v.Nota <= 2 THEN 1 ELSE 0 END) AS baja_valoracion
FROM Conductor c
JOIN Usuario u ON c.UsuarioId   = u.Id
JOIN Compania co ON c.EmpresaId = co.Id
JOIN Viaje   v ON v.ConductorId = c.Id
WHERE v.Nota IS NOT NULL
GROUP BY c.Id, conductor, compania
ORDER BY nota_media DESC;


-- Nota media por compañía
SELECT
    co.Nombre          AS compania,
    COUNT(v.Id)        AS viajes_valorados,
    ROUND(AVG(v.Nota), 2) AS nota_media
FROM Compania  co
JOIN Conductor c  ON c.EmpresaId   = co.Id
JOIN Viaje     v  ON v.ConductorId = c.Id
WHERE v.Nota IS NOT NULL
GROUP BY co.Id, co.Nombre
ORDER BY nota_media DESC;


-- Distribución de notas (1 a 5 estrellas)
SELECT
    CONCAT(v.Nota, ' estrellas') AS estrellas,
    COUNT(*)                     AS total_valoraciones
FROM Viaje v
WHERE v.Nota IS NOT NULL
GROUP BY v.Nota
ORDER BY v.Nota DESC;


-- -------------------------------------------------------------
-- 1.8  ACTIVIDAD DE USUARIOS
-- -------------------------------------------------------------

-- Top 10 usuarios más activos (por número de viajes)
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido) AS usuario,
    t.NumeroViajes                    AS viajes_registrados,
    ROUND(t.TiempoEnApp / 3600.0, 1) AS horas_en_app,
    t.UltimaVezConnectado             AS ultima_conexion
FROM Usuario    u
JOIN Telemetria t ON t.UsuarioId = u.Id
ORDER BY t.NumeroViajes DESC
LIMIT 10;


-- Usuarios registrados por mes
SELECT
    DATE_FORMAT(Alta, '%Y-%m') AS mes_alta,
    COUNT(*)                   AS nuevos_usuarios
FROM Usuario
GROUP BY mes_alta
ORDER BY mes_alta;


-- Usuarios inactivos (sin viajes en los últimos 30 días)
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido) AS usuario,
    t.UltimaVezConnectado,
    DATEDIFF(NOW(), t.UltimaVezConnectado) AS dias_inactivo
FROM Usuario    u
JOIN Telemetria t ON t.UsuarioId = u.Id
WHERE t.UltimaVezConnectado < DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND u.Baja IS NULL
ORDER BY dias_inactivo DESC;


-- =============================================================
-- SECCIÓN 2 — MÉTRICAS DE BASE DE DATOS
-- =============================================================

-- -------------------------------------------------------------
-- 2.1  TAMAÑO Y NÚMERO DE FILAS POR TABLA
-- Útil para monitorizar el crecimiento de la base de datos.
-- -------------------------------------------------------------

SELECT
    table_name                              AS tabla,
    table_rows                              AS filas_estimadas,
    ROUND(data_length  / 1024 / 1024, 3)   AS datos_mb,
    ROUND(index_length / 1024 / 1024, 3)   AS indices_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 3) AS total_mb
FROM information_schema.tables
WHERE table_schema = 'ride_hailing_db'
ORDER BY (data_length + index_length) DESC;


-- -------------------------------------------------------------
-- 2.2  USUARIOS DE BASE DE DATOS Y SUS PRIVILEGIOS
-- Permite verificar que los permisos son los correctos.
-- -------------------------------------------------------------

SELECT
    User    AS usuario_db,
    Host    AS host_permitido,
    account_locked AS cuenta_bloqueada,
    password_expired AS contrasena_expirada
FROM mysql.user
WHERE User NOT IN ('root', 'mysql.sys', 'mysql.infoschema', 'mysql.session')
ORDER BY User;


-- -------------------------------------------------------------
-- 2.3  ESTADO DE LAS CONEXIONES DEL SERVIDOR
-- Monitorización en tiempo real de quién está conectado.
-- -------------------------------------------------------------

-- Conexiones activas agrupadas por usuario y estado
SELECT
    User             AS usuario,
    Host             AS host,
    db               AS base_datos,
    Command          AS comando,
    COUNT(*)         AS num_conexiones,
    MAX(Time)        AS tiempo_max_seg
FROM information_schema.processlist
GROUP BY User, Host, db, Command
ORDER BY num_conexiones DESC;


-- Variables clave de rendimiento del servidor
SELECT
    Variable_name AS variable,
    Variable_value AS valor
FROM performance_schema.global_status
WHERE Variable_name IN (
    'Connections',           -- total conexiones desde que arrancó
    'Max_used_connections',  -- pico máximo de conexiones simultáneas
    'Threads_connected',     -- conexiones activas ahora mismo
    'Queries',               -- total queries ejecutadas
    'Slow_queries',          -- queries que superaron long_query_time
    'Innodb_buffer_pool_reads',     -- lecturas de disco (malas: caché fría)
    'Innodb_buffer_pool_read_requests', -- lecturas desde caché (buenas)
    'Uptime'                 -- segundos que lleva corriendo el servidor
)
ORDER BY Variable_name;


-- -------------------------------------------------------------
-- 2.4  RENDIMIENTO DE LA CACHÉ (InnoDB Buffer Pool)
-- Un hit rate > 99% indica que la caché está bien dimensionada.
-- -------------------------------------------------------------

SELECT
    disco.Variable_value                                       AS lecturas_disco,
    cache.Variable_value                                       AS lecturas_cache,
    ROUND(
        (1 - disco.Variable_value / NULLIF(cache.Variable_value, 0)) * 100
    , 2)                                                       AS hit_rate_pct
FROM
    (SELECT Variable_value FROM performance_schema.global_status
     WHERE Variable_name = 'Innodb_buffer_pool_reads') disco,
    (SELECT Variable_value FROM performance_schema.global_status
     WHERE Variable_name = 'Innodb_buffer_pool_read_requests') cache;
