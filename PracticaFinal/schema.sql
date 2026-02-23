-- :%s/`//g

-- MySQL database export
START TRANSACTION;
-- Tabla de Permisos del sistema

CREATE TABLE IF NOT EXISTS Permisos (
    id BIGINT NOT NULL,
    Nombre VARCHAR(50),
    PRIMARY KEY (id)
) COMMENT='Tabla de Permisos del sistema';


-- Tabla de Informacion bancaria del sistema

CREATE TABLE IF NOT EXISTS Informacion_Bancaria (
    id BIGINT NOT NULL,
    IBAN BIGINT,
    Dia INT,
    Mes INT,
  
    UsuarioId BIGINT,

  PRIMARY KEY (id)
) COMMENT='Tabla de Informacion bancaria del sistema';


-- Tabla de Roles del sistema

CREATE TABLE IF NOT EXISTS Roles (
    id BIGINT NOT NULL,
    Nombre VARCHAR(20),
    PRIMARY KEY (id)
) COMMENT='Tabla de Roles del sistema';



CREATE TABLE IF NOT EXISTS Viaje (
    id BIGINT NOT NULL,
    Inicio DATETIME,
    Fin DATETIME,
    -- Tiene que ser uno de los siguientes:
    -- Estado:
    -- - Solicitado
    -- - Aceptado
    -- - En curso
    -- - Finalizado
    -- - Cancelado
    Estado VARCHAR(20) COMMENT 'Tiene que ser uno de los siguientes: Estado: - Solicitado - Aceptado - En curso - Finalizado - Cancelado',
    Nota SMALLINT,
    Comentario VARCHAR(255),


    ConductorID BIGINT,
    OfertaID BIGINT,
    PRIMARY KEY (id)
);



CREATE TABLE IF NOT EXISTS TipoUbicacion (
    Id BIGINT,
    -- 'Historico', 'Trabajo', 'Casa'
    Nombre VARCHAR(10) COMMENT '''Historico'', ''Trabajo'', ''Casa'''
);


-- Tabla de Vehiculo del sistema

CREATE TABLE IF NOT EXISTS Vehiculo (
    id        BIGINT      NOT NULL,
    Matricula VARCHAR(7)  NOT NULL UNIQUE,
    Plazas    INT         NOT NULL,
    Marca     VARCHAR(50) NOT NULL,
    Modelo    VARCHAR(50) NOT NULL,
    Alta      DATETIME    NOT NULL,
    Estado    VARCHAR(20),
    Editado   DATETIME,
    Baja      DATETIME,
    PRIMARY KEY (id)
) COMMENT='Tabla de Vehiculo del sistema';


-- Tabla de Usuario del sistema

CREATE TABLE IF NOT EXISTS Usuario (
    id BIGINT NOT NULL,
    Name VARCHAR(50),
    Apellido VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    Numero VARCHAR(20) UNIQUE,
    Genero VARCHAR(10),
    PRIMARY KEY (id)
) COMMENT='Tabla de Usuario del sistema';


-- Tabla de Ubicacion del sistema

CREATE TABLE IF NOT EXISTS Ubicacion (
    id BIGINT NOT NULL,
    TipoAvenida VARCHAR(10),
    Nombre VARCHAR(10),
    Numero VARCHAR(10),
    Anadido DATETIME,
    PRIMARY KEY (id)
) COMMENT='Tabla de Ubicacion del sistema';



CREATE TABLE IF NOT EXISTS UsuarioUbicacion (
    UsuarioId BIGINT,
    UbicacionID BIGINT,
    
    UltimaVezUsada DATETIME,
    VecesUsada INT NOT NULL AUTO_INCREMENT,
    TipoID BIGINT
);


-- Tabla de Roles del sistema

CREATE TABLE IF NOT EXISTS RolesPermisos (
    RolID BIGINT NOT NULL,
    PermisosID BIGINT NOT NULL,

    PRIMARY KEY (RolID, PermisosID)
) COMMENT='Tabla de Roles del sistema';


-- Tabla de Conductores del sistema

CREATE TABLE IF NOT EXISTS Conductor (
    id BIGINT NOT NULL,
    -- Es la direccion del carnet
    CarnetDeConducir VARCHAR(50) COMMENT 'Es la direccion del carnet',
    Documentacion VARCHAR(20),
    Alta DATETIME,
    Estado VARCHAR(20),
    
    EmpresaID BIGINT,
    VehiculoID BIGINT,
    UsuarioId BIGINT UNIQUE,
    PRIMARY KEY (id)
) COMMENT='Tabla de Conductores del sistema';


-- Tabla de Informacion privada de los usuarios del sistema

CREATE TABLE IF NOT EXISTS Telemetria (
    id BIGINT NOT NULL,
    TiempoEnApp BIGINT,
    CookiesAceptadas TINYINT(1),
    UltimaVezConnectado DATETIME,
    NumeroViajes SMALLINT DEFAULT 0,
  
    UsuarioId BIGINT UNIQUE,
    PRIMARY KEY (id)
) COMMENT='Tabla de Informacion privada de los usuarios del sistema';


-- Tabla de Transacciones del sistema

CREATE TABLE IF NOT EXISTS Transacciones (
    id BIGINT NOT NULL,
    Cantidad DOUBLE,
    momento DATETIME,
  
    CuentaId BIGINT,
    ViajeId BIGINT,
    PRIMARY KEY (id)
) COMMENT='Tabla de Transacciones del sistema';


-- Tabla de Ofertas de viajes del sistema

CREATE TABLE IF NOT EXISTS Oferta (
    id BIGINT NOT NULL,
    Hora DATETIME,
    Precio DOUBLE,
    Descuento DOUBLE,
 
    OrigenId BIGINT,
    DestinoId BIGINT,
    UsuarioId BIGINT,
    PRIMARY KEY (id)
) COMMENT='Tabla de Ofertas de viajes del sistema';


-- Tabla de Companias relacionadas al sistema

CREATE TABLE IF NOT EXISTS Compania (
    id BIGINT NOT NULL,
    Nombre BIGINT,
    Logo VARCHAR(50),
    Email VARCHAR(50),
    Numero VARCHAR(20),
    PRIMARY KEY (id)
) COMMENT='Tabla de Companias relacionadas al sistema';


-- Tabla de Roles del sistema

CREATE TABLE IF NOT EXISTS RolesUsuario (
    RolID BIGINT NOT NULL,
    UsuarioId BIGINT NOT NULL,
    PRIMARY KEY (RolID, UsuarioId)
) COMMENT='Tabla de Roles del sistema';



CREATE TABLE IF NOT EXISTS Posicion (
    id BIGINT NOT NULL,
    Latitud VARCHAR(20),
    Longitud VARCHAR(20),
    Hora DATETIME,
  
    DriverID BIGINT,
    PRIMARY KEY (id)
);


-- Foreign key constraints
ALTER TABLE Conductor ADD CONSTRAINT fk_Conductor_EmpresaID FOREIGN KEY(EmpresaID) REFERENCES Compania(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Informacion_Bancaria ADD CONSTRAINT fk_Informacion_Bancaria_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Oferta ADD CONSTRAINT fk_Oferta_DestinoId FOREIGN KEY(DestinoId) REFERENCES Ubicacion(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Oferta ADD CONSTRAINT fk_Oferta_OrigenId FOREIGN KEY(OrigenId) REFERENCES Ubicacion(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Oferta ADD CONSTRAINT fk_Oferta_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesPermisos ADD CONSTRAINT fk_RolesPermisos_PermisosID FOREIGN KEY(PermisosID) REFERENCES Permisos(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesPermisos ADD CONSTRAINT fk_RolesPermisos_RolID FOREIGN KEY(RolID) REFERENCES Roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesUsuario ADD CONSTRAINT fk_RolesUsuario_RolID FOREIGN KEY(RolID) REFERENCES Roles(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesUsuario ADD CONSTRAINT fk_RolesUsuario_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Telemetria ADD CONSTRAINT fk_Telemetria_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE UsuarioUbicacion ADD CONSTRAINT fk_UsuarioUbicacion_TipoID FOREIGN KEY(TipoID) REFERENCES TipoUbicacion(Id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE Transacciones ADD CONSTRAINT fk_Transacciones_CuentaId FOREIGN KEY(CuentaId) REFERENCES Informacion_Bancaria(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Transacciones ADD CONSTRAINT fk_Transacciones_ViajeId FOREIGN KEY(ViajeId) REFERENCES Viaje(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Conductor ADD CONSTRAINT fk_Conductor_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE UsuarioUbicacion ADD CONSTRAINT fk_UsuarioUbicacion_UbicacionID FOREIGN KEY(UbicacionID) REFERENCES Ubicacion(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE UsuarioUbicacion ADD CONSTRAINT fk_UsuarioUbicacion_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Conductor ADD CONSTRAINT fk_Conductor_VehiculoID FOREIGN KEY(VehiculoID) REFERENCES Vehiculo(id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE Viaje ADD CONSTRAINT fk_Viaje_ConductorID FOREIGN KEY(ConductorID) REFERENCES Conductor(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Viaje ADD CONSTRAINT fk_Viaje_OfertaID FOREIGN KEY(OfertaID) REFERENCES Oferta(id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Posicion ADD CONSTRAINT fk_Posicion_DriverID FOREIGN KEY(DriverID) REFERENCES Conductor(id) ON UPDATE CASCADE ON DELETE CASCADE;

COMMIT;

