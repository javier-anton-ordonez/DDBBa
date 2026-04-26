USE ride_hailing_db;


-- 1) CONSULTAS OPERATIVAS (LECTURA)

-- 1.1 Historial de viajes de un rider (detalle completo)
-- Parametro de ejemplo:
SET @rider_id = 1;

SELECT
	v.Id AS viaje_id,
	v.Estado,
	v.Inicio,
	v.Fin,
	TIMESTAMPDIFF(MINUTE, v.Inicio, v.Fin) AS duracion_min,
	v.Nota,
	v.Comentario,
	o.Hora AS fecha_solicitud,
	ROUND(o.Precio - o.Descuento, 2) AS precio_final,
	CONCAT(uo.TipoAvenida, ' ', uo.Nombre, ', ', uo.Numero) AS origen,
	CONCAT(ud.TipoAvenida, ' ', ud.Nombre, ', ', ud.Numero) AS destino,
	CONCAT(uc.Nombre, ' ', uc.Apellido) AS conductor,
	c.Estado AS estado_conductor,
	co.Nombre AS compania
FROM Oferta o
JOIN Viaje v ON v.OfertaId = o.Id
LEFT JOIN Ubicacion uo ON uo.Id = o.OrigenId
LEFT JOIN Ubicacion ud ON ud.Id = o.DestinoId
LEFT JOIN Conductor c ON c.Id = v.ConductorId
LEFT JOIN Usuario uc ON uc.Id = c.UsuarioId
LEFT JOIN Compania co ON co.Id = c.EmpresaId
WHERE o.UsuarioId = @rider_id
ORDER BY o.Hora DESC;


-- 1.2 Ultima posicion conocida por conductor activo
SELECT
	c.Id AS conductor_id,
	CONCAT(u.Nombre, ' ', u.Apellido) AS conductor,
	co.Nombre AS compania,
	p.Latitud,
	p.Longitud,
	p.Hora AS ultima_posicion
FROM Conductor c
JOIN Usuario u ON u.Id = c.UsuarioId
JOIN Compania co ON co.Id = c.EmpresaId
JOIN Posicion p ON p.Id = (
	SELECT MAX(p2.Id)
	FROM Posicion p2
	WHERE p2.ConductorId = c.Id
)
WHERE c.Estado = 'Activo'
ORDER BY p.Hora DESC;


-- 1.3 Viajes activos para operaciones en tiempo real
SELECT
	v.Id AS viaje_id,
	v.Estado,
	o.Hora AS hora_solicitud,
	CONCAT(ur.Nombre, ' ', ur.Apellido) AS rider,
	CONCAT(uc.Nombre, ' ', uc.Apellido) AS conductor,
	co.Nombre AS compania,
	ROUND(o.Precio - o.Descuento, 2) AS precio_estimado
FROM Viaje v
JOIN Oferta o ON o.Id = v.OfertaId
JOIN Usuario ur ON ur.Id = o.UsuarioId
LEFT JOIN Conductor c ON c.Id = v.ConductorId
LEFT JOIN Usuario uc ON uc.Id = c.UsuarioId
LEFT JOIN Compania co ON co.Id = c.EmpresaId
WHERE v.Estado IN ('Solicitado', 'Aceptado', 'En curso')
ORDER BY o.Hora DESC;


-- 1.4 Ingresos netos por viaje (solo parte positiva = pago al conductor)
SELECT
	v.Id AS viaje_id,
	CONCAT(u.Nombre, ' ', u.Apellido) AS conductor,
	co.Nombre AS compania,
	ROUND(SUM(CASE WHEN t.Cantidad > 0 THEN t.Cantidad ELSE 0 END), 2) AS ingreso_conductor,
	ROUND(SUM(CASE WHEN t.Cantidad < 0 THEN t.Cantidad ELSE 0 END), 2) AS cargo_rider
FROM Viaje v
JOIN Conductor c ON c.Id = v.ConductorId
JOIN Usuario u ON u.Id = c.UsuarioId
JOIN Compania co ON co.Id = c.EmpresaId
JOIN Transacciones t ON t.ViajeId = v.Id
WHERE v.Estado = 'Finalizado'
GROUP BY v.Id, conductor, compania
ORDER BY v.Id DESC;


-- 2) OPERATIVA CON TRANSACCIONES

-- 2.1 Crear una nueva oferta + viaje en estado Solicitado
-- (flujo rider solicita viaje A -> B)
START TRANSACTION;

SET @nueva_oferta_id = (SELECT COALESCE(MAX(Id), 0) + 1 FROM Oferta);
SET @nuevo_viaje_id = (SELECT COALESCE(MAX(Id), 0) + 1 FROM Viaje);

SET @rider_id = 50;
SET @origen_id = 10;
SET @destino_id = 25;
SET @precio = 22.50;
SET @descuento = 0.00;

INSERT INTO Oferta (Id, Hora, Precio, Descuento, OrigenId, DestinoId, UsuarioId)
VALUES (@nueva_oferta_id, NOW(), @precio, @descuento, @origen_id, @destino_id, @rider_id);

INSERT INTO Viaje (Id, Inicio, Fin, Estado, Nota, Comentario, ConductorId, OfertaId)
VALUES (@nuevo_viaje_id, NULL, NULL, 'Solicitado', NULL, NULL, NULL, @nueva_oferta_id);

COMMIT;


-- 2.2 Concurrencia: primer conductor que acepta se queda el viaje
-- Esta es la consulta con lock (FOR UPDATE) requerida por la practica.
-- Ejecutar cada intento de aceptacion en una sesion distinta.
START TRANSACTION;

SET @oferta_a_aceptar = 120;
SET @conductor_que_intenta_aceptar = 7;

SELECT Id, Estado, ConductorId
FROM Viaje
WHERE OfertaId = @oferta_a_aceptar
FOR UPDATE;

UPDATE Viaje
SET
	ConductorId = @conductor_que_intenta_aceptar,
	Estado = 'Aceptado',
	Editado = NOW()
WHERE OfertaId = @oferta_a_aceptar
  AND Estado = 'Solicitado'
  AND ConductorId IS NULL;

-- Si ROW_COUNT() = 1, el conductor se queda el viaje
-- Si ROW_COUNT() = 0, otro conductor ya lo acepto antes
SELECT
	ROW_COUNT() AS filas_actualizadas,
	CASE
		WHEN ROW_COUNT() = 1 THEN 'aceptado'
		ELSE 'ya_aceptado'
	END AS resultado;

COMMIT;


-- 2.3 Iniciar viaje (de Aceptado -> En curso)
START TRANSACTION;

SET @viaje_en_marcha = 120;

UPDATE Viaje
SET
	Estado = 'En curso',
	Inicio = COALESCE(Inicio, NOW()),
	Editado = NOW()
WHERE Id = @viaje_en_marcha
  AND Estado = 'Aceptado';

SELECT ROW_COUNT() AS viaje_iniciado;

COMMIT;


-- 2.4 Finalizar viaje + registrar movimientos economicos
START TRANSACTION;

SET @viaje_a_finalizar = 120;

SELECT
	v.Id,
	o.UsuarioId AS rider_id,
	c.UsuarioId AS conductor_usuario_id,
	ROUND(o.Precio - o.Descuento, 2) AS importe_final,
	ROUND((o.Precio - o.Descuento) * 0.80, 2) AS importe_conductor
INTO
	@v_id,
	@rider_id_pago,
	@conductor_usuario_id_pago,
	@importe_final,
	@importe_conductor
FROM Viaje v
JOIN Oferta o ON o.Id = v.OfertaId
JOIN Conductor c ON c.Id = v.ConductorId
WHERE v.Id = @viaje_a_finalizar
FOR UPDATE;

SELECT Id INTO @cuenta_rider
FROM Informacion_Bancaria
WHERE UsuarioId = @rider_id_pago
LIMIT 1;

SELECT Id INTO @cuenta_conductor
FROM Informacion_Bancaria
WHERE UsuarioId = @conductor_usuario_id_pago
LIMIT 1;

UPDATE Viaje
SET
	Estado = 'Finalizado',
	Fin = NOW(),
	Editado = NOW()
WHERE Id = @v_id
  AND Estado IN ('En curso', 'Aceptado');

SET @tx_id_1 = (SELECT COALESCE(MAX(Id), 0) + 1 FROM Transacciones);
SET @tx_id_2 = @tx_id_1 + 1;

INSERT INTO Transacciones (Id, Cantidad, Momento, CuentaId, ViajeId)
VALUES
(@tx_id_1, -@importe_final, NOW(), @cuenta_rider, @v_id),
(@tx_id_2,  @importe_conductor, NOW(), @cuenta_conductor, @v_id);

COMMIT;


-- 2.5 Cancelar viaje de forma segura
START TRANSACTION;

SET @viaje_a_cancelar = 121;
SET @motivo_cancelacion = 'Cancelado por el usuario';

UPDATE Viaje
SET
	Estado = 'Cancelado',
	Comentario = @motivo_cancelacion,
	Editado = NOW()
WHERE Id = @viaje_a_cancelar
  AND Estado IN ('Solicitado', 'Aceptado', 'En curso');

SELECT ROW_COUNT() AS viaje_cancelado;

COMMIT;


-- 3) UPDATES / DELETES DE OPERATIVA

-- 3.1 Actualizar datos de contacto de usuario
SET @usuario_update = 12;
UPDATE Usuario
SET
	Numero = '+34600999112',
	Editado = NOW()
WHERE Id = @usuario_update
  AND Baja IS NULL;


-- 3.2 Baja logica de conductor
SET @conductor_baja = 20;
UPDATE Conductor
SET
	Estado = 'Inactivo',
	Baja = NOW(),
	Editado = NOW()
WHERE Id = @conductor_baja
  AND Baja IS NULL;


-- 3.3 Limpieza de posiciones antiguas (delete fisico)
DELETE FROM Posicion
WHERE Hora < DATE_SUB(NOW(), INTERVAL 30 DAY);


-- 4) CONSULTAS DE CONTROL / AUDITORIA BASICA

-- 4.1 Detectar viajes en estado incoherente
SELECT
	v.Id,
	v.Estado,
	v.Inicio,
	v.Fin,
	v.ConductorId
FROM Viaje v
WHERE
	(v.Estado = 'Solicitado' AND v.ConductorId IS NOT NULL)
	OR (v.Estado IN ('Aceptado', 'En curso', 'Finalizado') AND v.ConductorId IS NULL)
	OR (v.Estado = 'Finalizado' AND v.Fin IS NULL);


-- 4.2 Ofertas con viaje y conductor asignado (resumen para auditoria)
SELECT
	o.Id AS oferta_id,
	o.Hora,
	CONCAT(ur.Nombre, ' ', ur.Apellido) AS rider,
	v.Id AS viaje_id,
	v.Estado,
	CONCAT(uc.Nombre, ' ', uc.Apellido) AS conductor,
	co.Nombre AS compania
FROM Oferta o
LEFT JOIN Usuario ur ON ur.Id = o.UsuarioId
LEFT JOIN Viaje v ON v.OfertaId = o.Id
LEFT JOIN Conductor c ON c.Id = v.ConductorId
LEFT JOIN Usuario uc ON uc.Id = c.UsuarioId
LEFT JOIN Compania co ON co.Id = c.EmpresaId
ORDER BY o.Hora DESC;


-- 4.3 Conteo de transacciones por viaje finalizado (esperado = 2)
SELECT
	v.Id AS viaje_id,
	COUNT(t.Id) AS total_transacciones,
	ROUND(SUM(t.Cantidad), 2) AS suma_transacciones
FROM Viaje v
LEFT JOIN Transacciones t ON t.ViajeId = v.Id
WHERE v.Estado = 'Finalizado'
GROUP BY v.Id
HAVING COUNT(t.Id) <> 2 OR ABS(SUM(t.Cantidad)) > 0.05
ORDER BY v.Id;


-- Cambiar la particion de Posicion
