-- En este documento vamos a definir los permisos de Lectura y escritura de la base de datos


-- Acceso de las aplicaciones 
CREATE USER 'AppGeneral'@'%' IDENTIFIED BY 'AppGeneralContraseña';
CREATE USER 'AppDiver'@'%' IDENTIFIED BY 'AppDiverContraseña';

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


-- Permisos de los usuarios/roles

-- Permisos del PortalAnaliticas

GRANT SELECT ON Cabify.* TO 'Rol_Analiticas';

-- Permisos del BackGroundJob gestor de pagos
-- Escritura
GRANT INSERT, SELECT ON Cabify.Transacciones TO 'Rol_BackGroundJob';
-- Lectura
GRANT SELECT ON Cabify.Viaje TO 'Rol_BackGroundJob';
GRANT SELECT ON Cabify.Oferta TO 'Rol_BackGroundJob';
GRANT SELECT ON Cabify.Viaje TO 'Rol_BackGroundJob';
GRANT SELECT ON Cabify.Usuario TO 'Rol_BackGroundJob';

GRANT SELECT ON Cabify.Informacion_Bancaria TO 'Rol_BackGroundJob';

-- Permisos de las aplicaciones movil
-- Escritura

-- Lectura

-- Permisos del Admin
GRANT ALL PRIVILEGES ON *.* TO 'admin'@'127.0.0.1';
REVOKE SHUTDOWN ON *.* FROM 'admin'@'127.0.0.1';

-- Permisos de los desarrolladores

-- Lectura
GRANT SELECT, ALTER, CREATE, DELETE, UPDATE, INSERT, INDEX ON Cabify.* TO 'Rol_Desarrollo';

REVOKE UPDATE ON Cabify.Transacciones TO 'Rol_Desarrollo'; 

