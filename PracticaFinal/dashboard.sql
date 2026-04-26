USE ride_hailing_db;

CREATE OR REPLACE VIEW v_usuarios_activos AS
SELECT COUNT(*) AS value
FROM Usuario
WHERE Baja IS NULL;

CREATE OR REPLACE VIEW v_conductores_activos AS
SELECT COUNT(*) AS value
FROM Conductor
WHERE Estado = 'Activo';

CREATE OR REPLACE VIEW v_viajes_finalizados AS
SELECT COUNT(*) AS value
FROM Viaje
WHERE Estado = 'Finalizado';

CREATE OR REPLACE VIEW v_ingresos_totales AS
SELECT ROUND(SUM(Cantidad), 2) AS value
FROM Transacciones
WHERE Cantidad > 0;

CREATE OR REPLACE VIEW v_nota_media_global AS
SELECT ROUND(AVG(Nota), 2) AS value
FROM Viaje
WHERE Nota IS NOT NULL;

-- 1.2  VIAJES: VOLUMEN Y DISTRIBUCIÓN TEMPORAL

CREATE OR REPLACE VIEW v_viajes_por_estado AS
SELECT
    Estado                                                          AS estado,
    COUNT(*)                                                        AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Viaje), 1)      AS porcentaje
FROM Viaje
GROUP BY Estado
ORDER BY total DESC;

CREATE OR REPLACE VIEW v_viajes_por_mes AS
SELECT
    DATE_FORMAT(v.Inicio, '%Y-%m')              AS mes,
    COUNT(*)                                     AS total_viajes,
    ROUND(AVG(o.Precio - o.Descuento), 2)       AS precio_medio_eur
FROM Viaje v
JOIN Oferta o ON v.OfertaId = o.Id
WHERE v.Estado = 'Finalizado'
GROUP BY mes
ORDER BY mes;

CREATE OR REPLACE VIEW v_viajes_por_franja_horaria AS
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

CREATE OR REPLACE VIEW v_viajes_por_dia_semana AS
SELECT
    DAYNAME(v.Inicio)   AS dia_semana,
    COUNT(*)            AS total_viajes
FROM Viaje v
WHERE v.Estado = 'Finalizado'
GROUP BY dia_semana, DAYOFWEEK(v.Inicio)
ORDER BY DAYOFWEEK(v.Inicio);

-- 1.3  TASA DE ACEPTACIÓN

CREATE OR REPLACE VIEW v_tasa_aceptacion AS
SELECT
    ROUND(
        COUNT(DISTINCT CASE WHEN v.Estado != 'Solicitado' THEN v.OfertaId END)
        * 100.0 / COUNT(DISTINCT o.Id), 1
    ) AS value
FROM Oferta o
LEFT JOIN Viaje v ON v.OfertaId = o.Id;

CREATE OR REPLACE VIEW v_tasa_aceptacion_por_conductor AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)                               AS conductor,
    COUNT(v.Id)                                                      AS viajes_totales,
    SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END)        AS finalizados,
    SUM(CASE WHEN v.Estado = 'Cancelado'  THEN 1 ELSE 0 END)        AS cancelados,
    ROUND(
        SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(v.Id), 1
    )                                                                AS tasa_finalizacion_pct
FROM Conductor c
JOIN Usuario u ON c.UsuarioId   = u.Id
JOIN Viaje   v ON v.ConductorId = c.Id
GROUP BY c.Id, conductor
ORDER BY viajes_totales DESC
LIMIT 15;

CREATE OR REPLACE VIEW v_tasa_aceptacion_por_compania AS
SELECT
    co.Nombre                                                        AS compania,
    COUNT(v.Id)                                                      AS viajes_totales,
    SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END)        AS finalizados,
    SUM(CASE WHEN v.Estado = 'Cancelado'  THEN 1 ELSE 0 END)        AS cancelados,
    ROUND(
        SUM(CASE WHEN v.Estado = 'Finalizado' THEN 1 ELSE 0 END)
        * 100.0 / COUNT(v.Id), 1
    )                                                                AS tasa_finalizacion_pct
FROM Compania co
JOIN Conductor c ON c.EmpresaId   = co.Id
JOIN Viaje     v ON v.ConductorId = c.Id
GROUP BY co.Id, co.Nombre
ORDER BY tasa_finalizacion_pct DESC;

-- 1.4  INGRESOS

CREATE OR REPLACE VIEW v_ingresos_por_compania AS
SELECT
    co.Nombre                           AS compania,
    COUNT(v.Id)                         AS viajes,
    ROUND(SUM(t.Cantidad), 2)           AS ingresos_eur,
    ROUND(AVG(t.Cantidad), 2)           AS media_por_viaje
FROM Compania co
JOIN Conductor    c  ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado'
JOIN Transacciones t ON t.ViajeId     = v.Id AND t.Cantidad > 0
GROUP BY co.Id, co.Nombre
ORDER BY ingresos_eur DESC;

CREATE OR REPLACE VIEW v_ingresos_por_conductor AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)   AS conductor,
    co.Nombre                           AS compania,
    COUNT(DISTINCT v.Id)                AS viajes_finalizados,
    ROUND(SUM(t.Cantidad), 2)           AS ingresos_totales_eur,
    ROUND(AVG(t.Cantidad), 2)           AS ingreso_medio_por_viaje_eur
FROM Conductor c
JOIN Usuario      u  ON c.UsuarioId   = u.Id
JOIN Compania     co ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado'
JOIN Transacciones t ON t.ViajeId     = v.Id AND t.Cantidad > 0
GROUP BY c.Id, conductor, compania
ORDER BY ingresos_totales_eur DESC;

-- 1.5  TIEMPO MEDIO DE VIAJE

CREATE OR REPLACE VIEW v_duracion_media_por_conductor AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)                               AS conductor,
    COUNT(v.Id)                                                      AS viajes_finalizados,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)           AS duracion_media_min,
    MIN(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin))                     AS duracion_min_min,
    MAX(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin))                     AS duracion_max_min
FROM Conductor c
JOIN Usuario u ON c.UsuarioId   = u.Id
JOIN Viaje   v ON v.ConductorId = c.Id
WHERE v.Estado = 'Finalizado' AND v.Fin IS NOT NULL
GROUP BY c.Id, conductor
ORDER BY duracion_media_min DESC;

CREATE OR REPLACE VIEW v_duracion_media_por_compania AS
SELECT
    co.Nombre                                                        AS compania,
    COUNT(v.Id)                                                      AS viajes_finalizados,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)           AS duracion_media_min,
    ROUND(MIN(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)           AS duracion_min_min,
    ROUND(MAX(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 1)           AS duracion_max_min
FROM Compania  co
JOIN Conductor c ON c.EmpresaId   = co.Id
JOIN Viaje     v ON v.ConductorId = c.Id
WHERE v.Estado = 'Finalizado' AND v.Fin IS NOT NULL
GROUP BY co.Id, co.Nombre
ORDER BY duracion_media_min;

-- 1.6  EUROS POR MINUTO Y EUROS POR KM

CREATE OR REPLACE VIEW v_eur_por_minuto_por_conductor AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)                               AS conductor,
    co.Nombre                                                        AS compania,
    COUNT(v.Id)                                                      AS viajes,
    ROUND(SUM(t.Cantidad), 2)                                        AS ingresos_totales_eur,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0)           AS minutos_totales,
    ROUND(SUM(t.Cantidad) / NULLIF(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0), 3) AS eur_por_minuto
FROM Conductor c
JOIN Usuario      u  ON c.UsuarioId   = u.Id
JOIN Compania     co ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.Fin IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id AND t.Cantidad > 0
GROUP BY c.Id, conductor, compania
ORDER BY eur_por_minuto DESC;

CREATE OR REPLACE VIEW v_eur_por_minuto_por_compania AS
SELECT
    co.Nombre                                                        AS compania,
    ROUND(SUM(t.Cantidad), 2)                                        AS ingresos_totales_eur,
    ROUND(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0)           AS minutos_totales,
    ROUND(SUM(t.Cantidad) / NULLIF(SUM(TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin)), 0), 3) AS eur_por_minuto
FROM Compania co
JOIN Conductor    c  ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.Fin IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id AND t.Cantidad > 0
GROUP BY co.Id, co.Nombre
ORDER BY eur_por_minuto DESC;

-- 1.7  KILOMETRAJE MEDIO Y EUROS POR KM

CREATE OR REPLACE VIEW v_km_y_eur_por_km_por_conductor AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)                               AS conductor,
    co.Nombre                                                        AS compania,
    COUNT(v.Id)                                                      AS viajes,
    ROUND(AVG(v.DistanciaKm), 2)                                    AS km_medio,
    ROUND(SUM(v.DistanciaKm), 2)                                    AS km_totales,
    ROUND(SUM(t.Cantidad), 2)                                        AS ingresos_totales_eur,
    ROUND(SUM(t.Cantidad) / NULLIF(SUM(v.DistanciaKm), 0), 3)      AS eur_por_km
FROM Conductor c
JOIN Usuario      u  ON c.UsuarioId   = u.Id
JOIN Compania     co ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.DistanciaKm IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id AND t.Cantidad > 0
GROUP BY c.Id, conductor, compania
ORDER BY eur_por_km DESC;

CREATE OR REPLACE VIEW v_km_y_eur_por_km_por_compania AS
SELECT
    co.Nombre                                                        AS compania,
    COUNT(v.Id)                                                      AS viajes,
    ROUND(AVG(v.DistanciaKm), 2)                                    AS km_medio,
    ROUND(SUM(v.DistanciaKm), 2)                                    AS km_totales,
    ROUND(SUM(t.Cantidad), 2)                                        AS ingresos_totales_eur,
    ROUND(SUM(t.Cantidad) / NULLIF(SUM(v.DistanciaKm), 0), 3)      AS eur_por_km
FROM Compania co
JOIN Conductor    c  ON c.EmpresaId   = co.Id
JOIN Viaje        v  ON v.ConductorId = c.Id AND v.Estado = 'Finalizado' AND v.DistanciaKm IS NOT NULL
JOIN Transacciones t ON t.ViajeId     = v.Id AND t.Cantidad > 0
GROUP BY co.Id, co.Nombre
ORDER BY eur_por_km DESC;

-- 1.8  VALORACIONES Y CALIDAD DEL SERVICIO

CREATE OR REPLACE VIEW v_nota_media_por_conductor AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)                               AS conductor,
    co.Nombre                                                        AS compania,
    COUNT(v.Id)                                                      AS viajes_valorados,
    ROUND(AVG(v.Nota), 2)                                           AS nota_media,
    SUM(CASE WHEN v.Nota = 5 THEN 1 ELSE 0 END)                    AS cinco_estrellas,
    SUM(CASE WHEN v.Nota <= 2 THEN 1 ELSE 0 END)                   AS baja_valoracion
FROM Conductor c
JOIN Usuario  u  ON c.UsuarioId  = u.Id
JOIN Compania co ON c.EmpresaId  = co.Id
JOIN Viaje    v  ON v.ConductorId = c.Id
WHERE v.Nota IS NOT NULL
GROUP BY c.Id, conductor, compania
ORDER BY nota_media DESC;

CREATE OR REPLACE VIEW v_nota_media_por_compania AS
SELECT
    co.Nombre                       AS compania,
    COUNT(v.Id)                     AS viajes_valorados,
    ROUND(AVG(v.Nota), 2)          AS nota_media
FROM Compania  co
JOIN Conductor c ON c.EmpresaId   = co.Id
JOIN Viaje     v ON v.ConductorId = c.Id
WHERE v.Nota IS NOT NULL
GROUP BY co.Id, co.Nombre
ORDER BY nota_media DESC;

CREATE OR REPLACE VIEW v_distribucion_notas AS
SELECT
    CONCAT(v.Nota, ' estrellas')    AS estrellas,
    COUNT(*)                        AS total_valoraciones
FROM Viaje v
WHERE v.Nota IS NOT NULL
GROUP BY v.Nota
ORDER BY v.Nota DESC;

-- 1.9  ACTIVIDAD DE USUARIOS

CREATE OR REPLACE VIEW v_top_usuarios_activos AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)   AS usuario,
    t.NumeroViajes                       AS viajes_registrados,
    ROUND(t.TiempoEnApp / 3600.0, 1)   AS horas_en_app,
    t.UltimaVezConnectado               AS ultima_conexion
FROM Usuario    u
JOIN Telemetria t ON t.UsuarioId = u.Id
ORDER BY t.NumeroViajes DESC
LIMIT 10;

CREATE OR REPLACE VIEW v_nuevos_usuarios_por_mes AS
SELECT
    DATE_FORMAT(Alta, '%Y-%m')  AS mes_alta,
    COUNT(*)                    AS nuevos_usuarios
FROM Usuario
GROUP BY mes_alta
ORDER BY mes_alta;

CREATE OR REPLACE VIEW v_usuarios_inactivos AS
SELECT
    CONCAT(u.Nombre, ' ', u.Apellido)           AS usuario,
    t.UltimaVezConnectado,
    DATEDIFF(NOW(), t.UltimaVezConnectado)       AS dias_inactivo
FROM Usuario    u
JOIN Telemetria t ON t.UsuarioId = u.Id
WHERE t.UltimaVezConnectado < DATE_SUB(NOW(), INTERVAL 30 DAY)
  AND u.Baja IS NULL
ORDER BY dias_inactivo DESC;


-- SECCIÓN 2 — MÉTRICAS DE BASE DE DATOS

-- 2.1  TAMAÑO Y NÚMERO DE FILAS POR TABLA

CREATE OR REPLACE VIEW v_tamano_tablas AS
SELECT
    table_name                                                          AS tabla,
    table_rows                                                          AS filas_estimadas,
    ROUND(data_length  / 1024 / 1024, 3)                               AS datos_mb,
    ROUND(index_length / 1024 / 1024, 3)                               AS indices_mb,
    ROUND((data_length + index_length) / 1024 / 1024, 3)              AS total_mb
FROM information_schema.tables
WHERE table_schema = 'ride_hailing_db'
ORDER BY (data_length + index_length) DESC;

-- 2.2  CONEXIONES ACTIVAS

CREATE OR REPLACE VIEW v_conexiones_activas AS
SELECT
    User            AS usuario,
    Host            AS host,
    db              AS base_datos,
    Command         AS comando,
    COUNT(*)        AS num_conexiones,
    MAX(Time)       AS tiempo_max_seg
FROM information_schema.processlist
GROUP BY User, Host, db, Command
ORDER BY num_conexiones DESC;
