-- :%s/`//g

-- MySQL database export
START TRANSACTION;
-- Tabla de Permisos del sistema

CREATE TABLE IF NOT EXISTS Permisos (
    Id BIGINT NOT NULL,
    Nombre VARCHAR(50),
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Permisos del sistema';


-- Tabla de Informacion bancaria del sistema

CREATE TABLE IF NOT EXISTS Informacion_Bancaria (
    Id BIGINT NOT NULL,
    IBAN BIGINT,
    Dia INT,
    Mes INT,
  
    UsuarioId BIGINT,

    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
  PRIMARY KEY (Id)
) COMMENT='Tabla de Informacion bancaria del sistema';


-- Tabla de Roles del sistema

CREATE TABLE IF NOT EXISTS Roles (
    Id BIGINT NOT NULL,
    Nombre VARCHAR(20),

    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Roles del sistema';



CREATE TABLE IF NOT EXISTS Viaje (
    Id BIGINT NOT NULL,
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

    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,

    ConductorId BIGINT,
    OfertaId BIGINT,
    PRIMARY KEY (Id)
);



CREATE TABLE IF NOT EXISTS TipoUbicacion (
    Id BIGINT,

    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    -- 'Historico', 'Trabajo', 'Casa'
    Nombre VARCHAR(10) COMMENT '''Historico'', ''Trabajo'', ''Casa''',
    PRIMARY KEY (Id)
);


-- Tabla de Vehiculo del sistema

CREATE TABLE IF NOT EXISTS Vehiculo (
    Id        BIGINT      NOT NULL,
    Matricula VARCHAR(7)  NOT NULL UNIQUE,
    Plazas    INT         NOT NULL,
    Marca     VARCHAR(50) NOT NULL,
    Modelo    VARCHAR(50) NOT NULL,
    Estado    VARCHAR(20),
  
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    Baja      DATETIME,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Vehiculo del sistema';


-- Tabla de Usuario del sistema

CREATE TABLE IF NOT EXISTS Usuario (
    Id BIGINT NOT NULL,
    Nombre VARCHAR(50),
    Apellido VARCHAR(50),
    Email VARCHAR(100) UNIQUE,
    Numero VARCHAR(20) UNIQUE,
    Genero VARCHAR(10),
    Estado VARCHAR(10),
    
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    Baja      DATETIME,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Usuario del sistema';


-- Tabla de Ubicacion del sistema

CREATE TABLE IF NOT EXISTS Ubicacion (
    Id BIGINT NOT NULL,
    TipoAvenida VARCHAR(10),
    Nombre VARCHAR(10),
    Numero VARCHAR(10),

    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Ubicacion del sistema';



CREATE TABLE IF NOT EXISTS UsuarioUbicacion (
    UsuarioId BIGINT,
    UbicacionId BIGINT,
    
    UltimaVezUsada DATETIME,
    VecesUsada INT NOT NULL DEFAULT 0,
    TipoId BIGINT,
    PRIMARY KEY (UsuarioId, UbicacionId)
);


-- Tabla de Roles del sistema

CREATE TABLE IF NOT EXISTS RolesPermisos (
    RolId BIGINT NOT NULL,
    PermisosId BIGINT NOT NULL,

    PRIMARY KEY (RolId, PermisosId)
) COMMENT='Tabla de Roles del sistema';


-- Tabla de Conductores del sistema

CREATE TABLE IF NOT EXISTS Conductor (
    Id BIGINT NOT NULL,
    -- Es la direccion del carnet
    CarnetDeConducir VARCHAR(50) COMMENT 'Es la direccion del carnet',
    Documentacion VARCHAR(20),
    Estado VARCHAR(20),
    FechaDeCaducidadPermiso DATETIME,
    
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    Baja      DATETIME,
    
    EmpresaId BIGINT,
    VehiculoId BIGINT,
    UsuarioId BIGINT UNIQUE,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Conductores del sistema';


-- Tabla de Informacion privada de los usuarios del sistema

CREATE TABLE IF NOT EXISTS Telemetria (
    Id BIGINT NOT NULL,
    TiempoEnApp BIGINT,
    CookiesAceptadas TINYINT(1),
    UltimaVezConnectado DATETIME,
    NumeroViajes SMALLINT DEFAULT 0,
  
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,

    UsuarioId BIGINT UNIQUE,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Informacion privada de los usuarios del sistema';


-- Tabla de Transacciones del sistema

CREATE TABLE IF NOT EXISTS Transacciones (
    Id BIGINT NOT NULL,
    Cantidad DOUBLE,
    Momento DATETIME,
  
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    
    CuentaId BIGINT,
    ViajeId BIGINT,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Transacciones del sistema';


-- Tabla de Ofertas de viajes del sistema

CREATE TABLE IF NOT EXISTS Oferta (
    Id BIGINT NOT NULL,
    Hora DATETIME,
    Precio DOUBLE,
    Descuento DOUBLE,
 
    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    Baja      DATETIME,

    OrigenId BIGINT,
    DestinoId BIGINT,
    UsuarioId BIGINT,
    PRIMARY KEY (Id)
) COMMENT='Tabla de Ofertas de viajes del sistema';


-- Tabla de Companias relacionadas al sistema

CREATE TABLE IF NOT EXISTS Compania (
    Id BIGINT NOT NULL,
    Nombre BIGINT,
    Logo VARCHAR(50),
    Email VARCHAR(50),
    Numero VARCHAR(20),

    Alta      DATETIME    NOT NULL,
    Editado   DATETIME,
    Baja      DATETIME,

    PRIMARY KEY (Id)
) COMMENT='Tabla de Companias relacionadas al sistema';


-- Tabla de Roles del sistema

CREATE TABLE IF NOT EXISTS RolesUsuario (
    RolId BIGINT NOT NULL,
    UsuarioId BIGINT NOT NULL,
    PRIMARY KEY (RolId, UsuarioId)
) COMMENT='Tabla de Roles del sistema';



CREATE TABLE IF NOT EXISTS Posicion (
    Id BIGINT NOT NULL,
    Latitud VARCHAR(20),
    Longitud VARCHAR(20),
    Hora DATETIME,
  
    ConductorId BIGINT,
    PRIMARY KEY (Id)
);


-- Foreign key constraints
ALTER TABLE Conductor ADD CONSTRAINT fk_Conductor_EmpresaId FOREIGN KEY(EmpresaId) REFERENCES Compania(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Informacion_Bancaria ADD CONSTRAINT fk_Informacion_Bancaria_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(Id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Oferta ADD CONSTRAINT fk_Oferta_DestinoId FOREIGN KEY(DestinoId) REFERENCES Ubicacion(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Oferta ADD CONSTRAINT fk_Oferta_OrigenId FOREIGN KEY(OrigenId) REFERENCES Ubicacion(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Oferta ADD CONSTRAINT fk_Oferta_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesPermisos ADD CONSTRAINT fk_RolesPermisos_PermisosId FOREIGN KEY(PermisosId) REFERENCES Permisos(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesPermisos ADD CONSTRAINT fk_RolesPermisos_RolId FOREIGN KEY(RolId) REFERENCES Roles(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesUsuario ADD CONSTRAINT fk_RolesUsuario_RolId FOREIGN KEY(RolId) REFERENCES Roles(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE RolesUsuario ADD CONSTRAINT fk_RolesUsuario_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(Id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Telemetria ADD CONSTRAINT fk_Telemetria_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(Id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE UsuarioUbicacion ADD CONSTRAINT fk_UsuarioUbicacion_TipoId FOREIGN KEY(TipoId) REFERENCES TipoUbicacion(Id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE Transacciones ADD CONSTRAINT fk_Transacciones_CuentaId FOREIGN KEY(CuentaId) REFERENCES Informacion_Bancaria(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Transacciones ADD CONSTRAINT fk_Transacciones_ViajeId FOREIGN KEY(ViajeId) REFERENCES Viaje(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Conductor ADD CONSTRAINT fk_Conductor_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE UsuarioUbicacion ADD CONSTRAINT fk_UsuarioUbicacion_UbicacionId FOREIGN KEY(UbicacionId) REFERENCES Ubicacion(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE UsuarioUbicacion ADD CONSTRAINT fk_UsuarioUbicacion_UsuarioId FOREIGN KEY(UsuarioId) REFERENCES Usuario(Id) ON UPDATE CASCADE ON DELETE CASCADE;
ALTER TABLE Conductor ADD CONSTRAINT fk_Conductor_VehiculoId FOREIGN KEY(VehiculoId) REFERENCES Vehiculo(Id) ON UPDATE CASCADE ON DELETE SET NULL;
ALTER TABLE Viaje ADD CONSTRAINT fk_Viaje_ConductorId FOREIGN KEY(ConductorId) REFERENCES Conductor(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Viaje ADD CONSTRAINT fk_Viaje_OfertaId FOREIGN KEY(OfertaId) REFERENCES Oferta(Id) ON UPDATE CASCADE ON DELETE RESTRICT;
ALTER TABLE Posicion ADD CONSTRAINT fk_Posicion_ConductorId FOREIGN KEY(ConductorId) REFERENCES Conductor(Id) ON UPDATE CASCADE ON DELETE CASCADE;

COMMIT;

