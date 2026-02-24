# Diseño de base de datos.

## Indice
1. [Diseño Entidad Relación](#diseño-entidad-relación)
2. [Tablas](#tablas)
3. [Relaciones](#relaciones)

## Diseño Entidad Relación.
```mermaid
erDiagram
    Permisos {
        BIGINT id PK
        VARCHAR(50) Nombre
    }
    
    Informacion_Bancaria {
        BIGINT id PK
        BIGINT UsuarioId FK
        BIGINT IBAN
        INT Dia
        INT Mes
    }
    
    Roles {
        BIGINT id PK
        VARCHAR(20) Nombre
    }
    
    Viaje {
        BIGINT id PK
        DATETIME Inicio
        DATETIME Fin
        VARCHAR(20) Estado
        SMALLINT Nota
        VARCHAR(255) Comentario
        BIGINT ConductorID FK
        BIGINT OfertaID FK
    }
    
    TipoUbicacion {
        BIGINT Id PK
        VARCHAR(10) Nombre
    }
    
    Vehiculo {
        BIGINT id PK
        VARCHAR(7) Matricula UK
        INT Plazas
        VARCHAR(50) Marca
        VARCHAR(50) Modelo
        DATETIME Alta
        VARCHAR(20) Estado
        DATETIME Update
        DATETIME Baja
    }
    
    Usuario {
        BIGINT id PK
        VARCHAR(50) Name
        VARCHAR(50) Apellido
        VARCHAR(100) Email UK
        VARCHAR(20) Numero UK
        VARCHAR(10) Genero
    }
    
    Ubicacion {
        BIGINT id PK
        VARCHAR(10) TipoAvenida
        VARCHAR(10) Nombre
        VARCHAR(10) Numero
        DATETIME Anadido
    }
    
    UsuarioUbicacion {
        BIGINT UsuarioId FK
        BIGINT UbicacionID FK
        DATETIME UltimaVezUsada
        INT VecesUsada
        BIGINT TipoID FK
    }
    
    RolesPermisos {
        BIGINT RolID PK,FK
        BIGINT PermisosID PK,FK
    }
    
    Conductor {
        BIGINT id PK
        BIGINT VehiculoID FK
        VARCHAR(50) CarnetDeConducir
        VARCHAR(20) Documentacion
        DATETIME Alta
        VARCHAR(20) Estado
        BIGINT EmpresaID FK
        BIGINT UsuarioId FK,UK
    }
    
    Telemetria {
        BIGINT id PK
        BIGINT UsuarioId FK,UK
        BIGINT TiempoEnApp
        TINYINT(1) CookiesAceptadas
        DATETIME UltimaVezConnectado
        SMALLINT NumeroViajes
    }
    
    Transacciones {
        BIGINT id PK
        DOUBLE Cantidad
        BIGINT CuentaId FK
        DATETIME momento
        BIGINT ViajeId FK
    }
    
    Oferta {
        BIGINT id PK
        DATETIME Hora
        DOUBLE Precio
        DOUBLE Descuento
        BIGINT OrigenId FK
        BIGINT DestinoId FK
        BIGINT UsuarioId FK
    }
    
    Compania {
        BIGINT id PK
        BIGINT Nombre
        VARCHAR(50) Logo
        VARCHAR(50) Email
        VARCHAR(20) Numero
    }
    
    RolesUsuario {
        BIGINT RolID PK,FK
        BIGINT UsuarioId PK,FK
    }
    
    Posicion {
        BIGINT id PK
        VARCHAR(20) Latitud
        VARCHAR(20) Longitud
        DATETIME Hora
        BIGINT DriverID FK
    }
    
    %% Relaciones
    Conductor ||--o{ Compania : "EmpresaID"
    Usuario ||--o| Informacion_Bancaria : "tiene"
    Ubicacion ||--o{ Oferta : "DestinoId"
    Ubicacion ||--o{ Oferta : "OrigenId"
    Usuario ||--o{ Oferta : "solicita"
    Permisos ||--o{ RolesPermisos : "tiene"
    Roles ||--o{ RolesPermisos : "agrupa"
    Roles ||--o{ RolesUsuario : "asigna"
    Usuario ||--o{ RolesUsuario : "tiene"
    Usuario ||--o| Telemetria : "genera"
    UsuarioUbicacion }o--|| TipoUbicacion : "tipo"
    Informacion_Bancaria ||--o{ Transacciones : "realiza"
    Viaje ||--o{ Transacciones : "genera"
    Conductor ||--o| Usuario : "es"
    Ubicacion ||--o{ UsuarioUbicacion : "pertenece"
    Usuario ||--o{ UsuarioUbicacion : "usa"
    Conductor ||--o| Vehiculo : "conduce"
    Conductor ||--o{ Viaje : "realiza"
    Oferta ||--o{ Viaje : "origina"
    Conductor ||--o{ Posicion : "registra"
```


## Tablas.

### Usuario
   Esta es la tabla de usuario del sistema.
   Campos:
   - Id: Identificador en el sistema.
   - Name: Nombre del usuario.
   - Apellido: Apellido del usuario.
   - Email: Email del usuario.
   - Numero: Numero de teléfono del usuario.
   - Genero: Genero del usuario Hombre/Mujer/otro.
### Información Bancaria
   Tabla de la información bancaria de un usuario para hacer pagos y para sacar dinero.
   Campos:
   - Id: Identificador en el sistema.
   - UsuarioId: Foreign Key que referencia al usuario de quien es la cuenta.
   - IBAN: Es el IBAN de la cuenta.
   - Día: Es el día de caducidad de la tarjeta
   - Mes: Es el mes de caducidad de la cuenta.
### Roles
   Tabla de roles de la aplicación (Conductor, Pasajero, Administrador, Desarrollador).
   Campos.
   - Id: Identificador en el sistema.
   - Nombre: Nombre del rol.
### Permisos
   Tabla de permisos, si un rol solo tiene acceso a los permisos que se le asigne.
   Campos:
   - Id: Identificador en el sistema.
   - Nombre: Nombre del permiso.
### Telemetría
   Tabla de información captada de uso de la aplicación.
   Campos:
   - Id: Identificador en el sistema.
   - UsuarioId: El usuario del cual se ha recolectado esta información. 
   - TiempoEnApp: El tiempo que el usuario ha invertido en la aplicación.
   - CookiesAceptadas: Si a aceptado o declinado las cookies.
   - UltimaVezConnectado: La fecha y hora de ultima vez entrado en la aplicación.
   - NumeroViajes: Numero de viajes que ha solicitado un viaje.
### Ubicaciones
??? not found in the mermaid schema
### Oferta
   Tabla de solicitudes de viaje creadas por los usuarios.
   Campos:
   - Id: Identificador de la orferta.
   - Hora: hora de la solicitud.
   - Precio: Precio estimado de la solicitud.
   - Descuento: Descuento aplicado.
   - OrigenId: Ubicacion de origen.
   - DestinoId: Ubicacion de destino.
   - UsuarioId: Usuario que solicita el viaje.
### Viaje
   Tabla de viajes realizados en la plataforma a partir de una oferta.
   Campos:
   - Id: Identificador del viaje.
   - Inicio: Fecha y hora de inicio del viaje.
   - Fin: Fecha y hora de finalizacion del viaje.
   - Estado: Estado del viaje.
   - Nota: Calificacion del viaje.
   - Comentario: Comentario asociado al viaje.
   - ConductorID: Conductor que realiza el viaje.
   - OfertaID: Oferta asociada al viaje.
### Conductor
   Tabla de conductores registrados en la plataforma.
   Campos:
   - Id: Identificador del conductor.
   - VehiculoId: Vehiculo asociado al conductor
   - CarnetDeConducir: Numero del carnet de conducir (?).
   - Documentacion: Documentacion asociada al conductor (?).
   - Alta: Fecha de alta del conductor.
   - Estado: Estado del conductor.
   - EmpresaId: Compañia asociada al conductor.
   - UsuarioId: Usuario asociado al conductor.
### Vehículo
   Tabla de vehiculos disponibles en la plataforma para realizar viajes.
   Campos:
   - Id: Identificador del vehiculo.
   - Matricula: Matricula del vehiculo.
   - Plazas: Numero de plazas del vehiculo.
   - Marca: Marca del vehiculo.
   - Modelo: Modelo del vehiculo.
   - Alta: Fecha de alta del vehiculo.
   - Estado: Estado del vehiculo.
   - Update: Fecha y hora de la ultima actualizacion.
   - Baja: Fecha y hora de baja del vehiculo.
### Compañía
   Tabla de compañias asociadas a conductores
   Campos:
   - Id: Identificador de la compañia.
   - Nombre: Nombre de la de la compañia.
   - Logo: Logo de la compañia. (image in a data base ? how ? link ? URL ?)
   - Email: Correo electronico de la compañia.
   - Numero: Numero de contacto de la compañia.
### Ubicación
   Tabla de direcciones o lugares utilizados como origen, destino o ubicaciones guardadas por los usuarios.
   Campos:
   - Id: Identificador de la ubicacion.
   - TipoAvenida: Tipo de via (calle, avenida, etc.).
   - Nombre: Nombre de la calle o lugar.
   - Numero: Numero de la direccion.
   - Anadido: Fecha en la que se añadio la ubicacion.
### Transacciones
   Tabla de pagos registrados en el sistema.
   Campos:
   - Id: Identificador de la transaccion.
   - Cantidad: Importe de la transaccion.
   - CuentaId: (?) can't find what it is
   - Momento: Fecha y hora en la que se realizo la transaccion.
   - ViajeId: Viaje asociado a la transaccion.

## Relaciones. (Guille)

### Vehículo-Conductor
### Conductor-Compañía
### Conductor-Ubicación
### Conductor-Viaje
### Transacciones-Viaje
### Oferta-Viaje
### Ubicaciones-Oferta
### Usuario-Oferta
### Usuario-Telemetría
### Usuario-Información-bancaria
### Usuario-Roles
### Roles-Permisos



