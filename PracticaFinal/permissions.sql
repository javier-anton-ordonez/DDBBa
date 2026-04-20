-- En este documento vamos a definir los permisos de Lectura y escritura de la base de datos


-- Acceso de las aplicaciones 
CREATE USER 'AppGeneral'@'%' IDENTIFIED BY 'AppGeneralContraseña';
CREATE USER 'AppDriver'@'%' IDENTIFIED BY 'AppDiverContraseña';

-- Acceso de los servicios programados por la empresa
CREATE USER 'Admin'@'127.0.0.1' IDENTIFIED BY 'AdminContraseña';
CREATE USER 'BackGroundJob'@'127.0.0.1' IDENTIFIED BY 'BackGroundJobContraseña';
CREATE USER 'PortalAnaliticas'@'127.0.0.1' IDENTIFIED BY 'AppGeneralContraseña';

-- Acceso de los desarrolladores de la empresa
CREATE USER 'Mehid'@'10.0.0.%' IDENTIFIED BY 'ChangeMe';
CREATE USER 'JuanDiego'@'10.0.0.%' IDENTIFIED BY 'ChangeMe';
CREATE USER 'Guillermo'@'10.0.0.%' IDENTIFIED BY 'ChangeMe';
CREATE USER 'Javier'@'10.0.0.%' IDENTIFIED BY 'ChangeMe';

-- Forzar cambio de contraseña para los desarrolladores
ALTER USER 'Mehid'@'10.0.0.%' PASSWORD EXPIRE;
ALTER USER 'JuanDiego'@'10.0.0.%' PASSWORD EXPIRE;
ALTER USER 'Javier'@'10.0.0.%' PASSWORD EXPIRE;
ALTER USER 'Guillermo'@'10.0.0.%' PASSWORD EXPIRE;

-- Forzar cambio de contraseña para el Administrador
ALTER USER 'Admin'@'127.0.0.1' PASSWORD EXPIRE;
-- Forzar cambio de contraseña para el deamon
ALTER USER 'BackGroundJob'@'127.0.0.1' PASSWORD EXPIRE;


-- Roles
CREATE ROLE 'Rol_Desarrollo', 'Rol_BackGroundJob', 'Rol_Analiticas', 'Rol_AppGeneral', 'Rol_AppConductores';

GRANT 'Rol_Desarrollo' TO 'Javier'@'10.0.0.%';
GRANT 'Rol_Desarrollo' TO 'Mehid'@'10.0.0.%';
GRANT 'Rol_Desarrollo' TO 'JuanDiego'@'10.0.0.%';
GRANT 'Rol_Desarrollo' TO 'Guillermo'@'10.0.0.%';

GRANT 'Rol_BackGroundJob' TO 'BackGroundJob'@'127.0.0.1';

GRANT 'Rol_Analiticas' TO 'PortalAnaliticas'@'127.0.0.1';

GRANT 'Rol_AppGeneral' TO 'AppGeneral'@'%'
GRANT 'Rol_AppConductores' TO 'AppDriver'@'%'

-- Permisos de los usuarios/roles

-- Permisos del PortalAnaliticas

GRANT SELECT ON ride_hailing_db.* TO 'Rol_Analiticas';
REVOKE SELECT ON ride_hailing_db.Informacion_Bancaria FROM 'Rol_Analiticas';

-- Permisos del BackGroundJob gestor de pagos

-- Escritura
GRANT INSERT, SELECT ON ride_hailing_db.Transacciones TO 'Rol_BackGroundJob';
-- Lectura
GRANT SELECT ON ride_hailing_db.Viaje TO 'Rol_BackGroundJob';
GRANT SELECT ON ride_hailing_db.Oferta TO 'Rol_BackGroundJob';
GRANT SELECT ON ride_hailing_db.Usuario TO 'Rol_BackGroundJob';

GRANT SELECT ON ride_hailing_db.Informacion_Bancaria TO 'Rol_BackGroundJob';

-- Permisos de las aplicaciones movil
-- Escritura
GRANT INSERT, UPDATE ON ride_hailing_db.Usuario TO 'Rol_AppConductores', 'Rol_AppGeneral';
GRANT INSERT, UPDATE ON ride_hailing_db.Telemetria TO 'Rol_AppConductores', 'Rol_AppGeneral';
GRANT INSERT, UPDATE ON ride_hailing_db.Viaje TO 'Rol_AppConductores', 'Rol_AppGeneral';
GRANT INSERT, UPDATE ON ride_hailing_db.Informacion_Bancaria TO 'Rol_AppConductores', 'Rol_AppGeneral';

GRANT INSERT on ride_hailing_db.Oferta TO 'Rol_AppGeneral';
GRANT INSERT on ride_hailing_db.Ubicacion TO 'Rol_AppGeneral';

GRANT INSERT on ride_hailing_db.Conductor TO 'Rol_AppConductores';
GRANT INSERT on ride_hailing_db.Vehiculo TO 'Rol_AppConductores';
GRANT INSERT on ride_hailing_db.Posicion TO 'Rol_AppConductores';

-- Lectura
GRANT SELECT ON ride_hailing_db.* TO 'Rol_AppGeneral';
GRANT SELECT ON ride_hailing_db.* TO 'Rol_AppConductores';

REVOKE SELECT ON ride_hailing_db.Transacciones FROM 'Rol_AppConductores';
REVOKE SELECT ON ride_hailing_db.Transacciones FROM 'Rol_AppGeneral';
REVOKE SELECT ON ride_hailing_db.Informacion_Bancaria FROM 'Rol_AppConductores';
REVOKE SELECT ON ride_hailing_db.Informacion_Bancaria FROM 'Rol_AppGeneral';
-- Permisos del Admin
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'127.0.0.1';
REVOKE SHUTDOWN ON *.* FROM 'admin'@'127.0.0.1';

-- Permisos de los desarrolladores

-- Lectura
GRANT SELECT, ALTER, CREATE, DELETE, UPDATE, INSERT, INDEX ON ride_hailing_db.* TO 'Rol_Desarrollo';

-- REVOKE UPDATE ON ride_hailing_db.Transacciones FROM 'Rol_Desarrollo'; 


-- Views

-- Vistas para el dashboard
CREATE VIEW v_usuario_dashboard AS                                                                                                          
SELECT id, Nombre, Apellido, Genero                                                                                                           
FROM Usuario;

-- USUARIOS DE INFRAESTRUCTURA (NECESARIOS PARA LA ARQUITECTURA 4 NODOS)

-- 1. Usuario de Replicación (Vital para sincronizar los nodos)
CREATE USER IF NOT EXISTS 'replicator_user'@'%' IDENTIFIED BY 'replicator_password';
GRANT REPLICATION SLAVE ON *.* TO 'replicator_user'@'%';

-- 2. Usuarios definidos en docker-compose.yaml
-- Usuario para Escritura (Nodos Maestros)
CREATE USER IF NOT EXISTS 'app_user'@'%' IDENTIFIED BY 'app_password';
GRANT INSERT, UPDATE, DELETE, SELECT ON ride_hailing_db.* TO 'app_user'@'%';

-- Usuario para Lectura App (Nodo db-read-app)
CREATE USER IF NOT EXISTS 'app_reader'@'%' IDENTIFIED BY 'reader_password';
GRANT SELECT ON ride_hailing_db.* TO 'app_reader'@'%';

-- Usuario para Dashboard (Nodo db-read-dashboard)
CREATE USER IF NOT EXISTS 'dashboard_user'@'%' IDENTIFIED BY 'dashboard_password';
GRANT SELECT ON ride_hailing_db.* TO 'dashboard_user'@'%';

FLUSH PRIVILEGES;

