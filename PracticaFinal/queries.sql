USE ride_hailing_db;


DELIMITER $$

CREATE TRIGGER trg_oferta_before_insert
BEFORE INSERT ON Oferta
FOR EACH ROW
BEGIN
    DECLARE v_usuario_estado VARCHAR(10);
    DECLARE v_precio_final   DOUBLE;

    SELECT Estado INTO v_usuario_estado
    FROM Usuario
    WHERE Id = NEW.UsuarioId;

    IF v_usuario_estado IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Oferta rechazada: el usuario no existe.';
    END IF;

    IF v_usuario_estado != 'Activo' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Oferta rechazada: el usuario no está activo.';
    END IF;

    IF NEW.Precio IS NULL OR NEW.Precio <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Oferta rechazada: el precio debe ser mayor que 0.';
    END IF;

    SET v_precio_final = NEW.Precio - IFNULL(NEW.Descuento, 0);
    IF v_precio_final < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Oferta rechazada: el descuento supera el precio base.';
    END IF;

    IF NEW.OrigenId = NEW.DestinoId THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Oferta rechazada: el origen y el destino no pueden ser iguales.';
    END IF;

    SET NEW.Descuento = IFNULL(NEW.Descuento, 0);
END$$


CREATE TRIGGER trg_viaje_before_aceptar
BEFORE UPDATE ON Viaje
FOR EACH ROW
BEGIN
    DECLARE v_viajes_activos    INT;
    DECLARE v_conductor_ocupado INT;
    DECLARE v_carnet_caducidad  DATETIME;
    DECLARE v_conductor_estado  VARCHAR(20);

    IF NEW.Estado = 'Aceptado' AND OLD.Estado = 'Solicitado' THEN

        SELECT COUNT(*) INTO v_viajes_activos
        FROM Viaje
        WHERE OfertaId = NEW.OfertaId
          AND Estado IN ('Aceptado', 'En curso')
          AND Id != NEW.Id;

        IF v_viajes_activos > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Oferta ya aceptada por otro conductor.';
        END IF;

        SELECT COUNT(*) INTO v_conductor_ocupado
        FROM Viaje
        WHERE ConductorId = NEW.ConductorId
          AND Estado IN ('Aceptado', 'En curso')
          AND Id != NEW.Id;

        IF v_conductor_ocupado > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El conductor ya tiene un viaje activo en curso.';
        END IF;

        SELECT FechaDeCaducidadPermiso, Estado
        INTO v_carnet_caducidad, v_conductor_estado
        FROM Conductor
        WHERE Id = NEW.ConductorId;

        IF v_conductor_estado IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El conductor asignado no existe.';
        END IF;

        IF v_conductor_estado != 'Activo' THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'El conductor no está activo.';
        END IF;

        IF v_carnet_caducidad IS NOT NULL AND v_carnet_caducidad < NOW() THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Viaje rechazado: el carnet de conducir del conductor está caducado.';
        END IF;

    END IF;
END$$


CREATE TRIGGER trg_usuario_before_delete
BEFORE DELETE ON Usuario
FOR EACH ROW
BEGIN
    DECLARE v_viajes_activos INT;

    SELECT COUNT(*) INTO v_viajes_activos
    FROM Viaje v
    JOIN Oferta o ON v.OfertaId = o.Id
    WHERE o.UsuarioId = OLD.Id
      AND v.Estado IN ('Solicitado', 'Aceptado', 'En curso');

    IF v_viajes_activos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar el usuario: tiene viajes activos en curso.';
    END IF;

END$$

	
CREATE TRIGGER trg_conductor_before_delete
BEFORE DELETE ON Conductor
FOR EACH ROW
BEGIN
    DECLARE v_viajes_activos INT;

    SELECT COUNT(*) INTO v_viajes_activos
    FROM Viaje
    WHERE ConductorId = OLD.Id
      AND Estado IN ('Aceptado', 'En curso');

    IF v_viajes_activos > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No se puede eliminar el conductor: tiene viajes activos. Espera a que finalicen.';
    END IF;

    IF OLD.VehiculoId IS NOT NULL THEN
        UPDATE Vehiculo
        SET Estado   = 'Disponible',
            Editado  = NOW()
        WHERE Id = OLD.VehiculoId;
    END IF;

END$$

	
CREATE TRIGGER trg_viaje_after_finalizado
AFTER UPDATE ON Viaje
FOR EACH ROW
BEGIN
    DECLARE v_precio_base    DOUBLE;
    DECLARE v_descuento      DOUBLE;
    DECLARE v_precio_final   DOUBLE;
    DECLARE v_importe_driver DOUBLE;

    DECLARE v_usuario_id       BIGINT;
    DECLARE v_conductor_usr_id BIGINT;

    DECLARE v_cuenta_usuario   BIGINT;
    DECLARE v_cuenta_conductor BIGINT;

    DECLARE v_new_id_t1 BIGINT;
    DECLARE v_new_id_t2 BIGINT;

    IF NEW.Estado = 'Finalizado' AND OLD.Estado != 'Finalizado' THEN

        SELECT Precio, IFNULL(Descuento, 0), UsuarioId
        INTO v_precio_base, v_descuento, v_usuario_id
        FROM Oferta
        WHERE Id = NEW.OfertaId;

        SET v_precio_final   = v_precio_base - v_descuento;
        SET v_importe_driver = v_precio_base * 0.80;

        SELECT Id INTO v_cuenta_usuario
        FROM Informacion_Bancaria
        WHERE UsuarioId = v_usuario_id
        LIMIT 1;

        IF v_cuenta_usuario IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'No se puede cerrar el viaje: el usuario no tiene cuenta bancaria registrada.';
        END IF;

        SELECT UsuarioId INTO v_conductor_usr_id
        FROM Conductor
        WHERE Id = NEW.ConductorId;

        SELECT Id INTO v_cuenta_conductor
        FROM Informacion_Bancaria
        WHERE UsuarioId = v_conductor_usr_id
        LIMIT 1;

        IF v_cuenta_conductor IS NULL THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'No se puede cerrar el viaje: el conductor no tiene cuenta bancaria registrada.';
        END IF;

        SET v_new_id_t1 = FLOOR(RAND() * 9000000000) + 1000000000;
        SET v_new_id_t2 = v_new_id_t1 + 1;

        INSERT INTO Transacciones (Id, Cantidad, Momento, CuentaId, ViajeId, Alta)
        VALUES (
            v_new_id_t1,
            -v_precio_final,
            NOW(),
            v_cuenta_usuario,
            NEW.Id,
            NOW()
        );

        INSERT INTO Transacciones (Id, Cantidad, Momento, CuentaId, ViajeId, Alta)
        VALUES (
            v_new_id_t2,
            v_importe_driver,
            NOW(),
            v_cuenta_conductor,
            NEW.Id,
            NOW()
        );

        UPDATE Telemetria
        SET NumeroViajes = NumeroViajes + 1,
            Editado      = NOW()
        WHERE UsuarioId = v_usuario_id;

    END IF;
END$$

DELIMITER ;

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
