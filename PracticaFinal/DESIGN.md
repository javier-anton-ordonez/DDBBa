# Diseño de base de datos.

## Indice
1. [Diseño Entidad Relación](#diseño-entidad-relación)
2. [Tablas](#tablas)
3. [Relaciones](#relaciones)

## Diseño Entidad Relación.
```mermaid
erDiagram
    Permisos {
        BIGINT Id PK
        VARCHAR(50) Nombre
        DATETIME Alta
        DATETIME Editado
    }
    
    Informacion_Bancaria {
        BIGINT Id PK
        BIGINT IBAN
        INT Dia
        INT Mes
        BIGINT UsuarioId FK
        DATETIME Alta
        DATETIME Editado
    }
    
    Roles {
        BIGINT Id PK
        VARCHAR(20) Nombre
        DATETIME Alta
        DATETIME Editado
    }
    
    Viaje {
        BIGINT Id PK
        DATETIME Inicio
        DATETIME Fin
        VARCHAR(20) Estado
        SMALLINT Nota
        VARCHAR(255) Comentario
        DATETIME Alta
        DATETIME Editado
        BIGINT ConductorId FK
        BIGINT OfertaId FK
    }
    
    TipoUbicacion {
        BIGINT Id PK
        VARCHAR(10) Nombre
        DATETIME Alta
        DATETIME Editado
    }
    
    Vehiculo {
        BIGINT Id PK
        VARCHAR(7) Matricula UK
        INT Plazas
        VARCHAR(50) Marca
        VARCHAR(50) Modelo
        VARCHAR(20) Estado
        DATETIME Alta
        DATETIME Editado
        DATETIME Baja
    }
    
    Usuario {
        BIGINT Id PK
        VARCHAR(50) Nombre
        VARCHAR(50) Apellido
        VARCHAR(100) Email UK
        VARCHAR(20) Numero UK
        VARCHAR(10) Genero
        VARCHAR(10) Estado
        DATETIME Alta
        DATETIME Editado
        DATETIME Baja
    }
    
    Ubicacion {
        BIGINT Id PK
        VARCHAR(10) TipoAvenida
        VARCHAR(10) Nombre
        VARCHAR(10) Numero
        DATETIME Alta
        DATETIME Editado
    }
    
    UsuarioUbicacion {
        BIGINT UsuarioId FK
        BIGINT UbicacionId FK
        DATETIME UltimaVezUsada
        INT VecesUsada
        BIGINT TipoId FK
    }
    
    RolesPermisos {
        BIGINT RolId PK_FK
        BIGINT PermisosId PK_FK
    }
    
    Conductor {
        BIGINT Id PK
        VARCHAR(50) CarnetDeConducir
        VARCHAR(20) Documentacion
        VARCHAR(20) Estado
        DATETIME FechaDeCaducidadPermiso
        DATETIME Alta
        DATETIME Editado
        DATETIME Baja
        BIGINT EmpresaId FK
        BIGINT VehiculoId FK
        BIGINT UsuarioId FK,UK
    }
    
    Telemetria {
        BIGINT Id PK
        BIGINT TiempoEnApp
        TINYINT CookiesAceptadas
        DATETIME UltimaVezConnectado
        SMALLINT NumeroViajes
        DATETIME Alta
        DATETIME Editado
        BIGINT UsuarioId FK,UK
    }
    
    Transacciones {
        BIGINT Id PK
        DOUBLE Cantidad
        DATETIME Momento
        DATETIME Alta
        DATETIME Editado
        BIGINT CuentaId FK
        BIGINT ViajeId FK
    }
    
    Oferta {
        BIGINT Id PK
        DATETIME Hora
        DOUBLE Precio
        DOUBLE Descuento
        DATETIME Alta
        DATETIME Editado
        DATETIME Baja
        BIGINT OrigenId FK
        BIGINT DestinoId FK
        BIGINT UsuarioId FK
    }
    
    Compania {
        BIGINT Id PK
        BIGINT Nombre
        VARCHAR(50) Logo
        VARCHAR(50) Email
        VARCHAR(20) Numero
        DATETIME Alta
        DATETIME Editado
        DATETIME Baja
    }
    
    RolesUsuario {
        BIGINT RolId PK_FK
        BIGINT UsuarioId PK_FK
    }
    
    Posicion {
        BIGINT Id PK
        VARCHAR(20) Latitud
        VARCHAR(20) Longitud
        DATETIME Hora
        BIGINT ConductorId FK
    }
    
    %% Relaciones (desde tabla con FK hacia tabla referenciada)
    Informacion_Bancaria }o--|| Usuario : "UsuarioId"
    Conductor }o--|| Compania : "EmpresaId"
    Conductor }o--|| Vehiculo : "VehiculoId"
    Conductor ||--|| Usuario : "UsuarioId"
    Telemetria ||--|| Usuario : "UsuarioId"
    Oferta }o--|| Ubicacion : "OrigenId"
    Oferta }o--|| Ubicacion : "DestinoId"
    Oferta }o--|| Usuario : "UsuarioId"
    RolesPermisos }o--|| Permisos : "PermisosId"
    RolesPermisos }o--|| Roles : "RolId"
    RolesUsuario }o--|| Roles : "RolId"
    RolesUsuario }o--|| Usuario : "UsuarioId"
    UsuarioUbicacion }o--|| TipoUbicacion : "TipoId"
    UsuarioUbicacion }o--|| Ubicacion : "UbicacionId"
    UsuarioUbicacion }o--|| Usuario : "UsuarioId"
    Transacciones }o--|| Informacion_Bancaria : "CuentaId"
    Transacciones }o--|| Viaje : "ViajeId"
    Viaje }o--|| Conductor : "ConductorId"
    Viaje }o--|| Oferta : "OfertaId"
    Posicion }o--|| Conductor : "ConductorId"
```


## Tablas.

### Usuario
   Esta es la tabla de usuario del sistema.
   Campos:
   - Id: Identificador en el sistema.
   - Nombre: Nombre del usuario.
   - Apellido: Apellido del usuario.
   - Email: Email del usuario.
   - Numero: Numero de teléfono del usuario.
   - Genero: Genero del usuario Hombre/Mujer/otro.
   - Estado: Estado del usuario en el sistema.
   - Alta: Fecha de alta del usuario.
   - Editado: Fecha de última edición.
   - Baja: Fecha de baja del usuario.
### Información Bancaria
   Tabla de la información bancaria de un usuario para hacer pagos y para sacar dinero.
   Campos:
   - Id: Identificador en el sistema.
   - IBAN: Es el IBAN de la cuenta.
   - Día: Es el día de caducidad de la tarjeta
   - Mes: Es el mes de caducidad de la cuenta.
   - UsuarioId: Foreign Key que referencia al usuario de quien es la cuenta.
   - Alta: Fecha de alta de la cuenta.
   - Editado: Fecha de última edición.
### Roles
   Tabla de roles de la aplicación (Conductor, Pasajero, Administrador, Desarrollador).
   Campos.
   - Id: Identificador en el sistema.
   - Nombre: Nombre del rol.
   - Alta: Fecha de alta del rol.
   - Editado: Fecha de última edición.
### Permisos
   Tabla de permisos, si un rol solo tiene acceso a los permisos que se le asigne.
   Campos:
   - Id: Identificador en el sistema.
   - Nombre: Nombre del permiso.
   - Alta: Fecha de alta del permiso.
   - Editado: Fecha de última edición.
### Telemetría
   Tabla de información captada de uso de la aplicación.
   Campos:
   - Id: Identificador en el sistema.
   - TiempoEnApp: El tiempo que el usuario ha invertido en la aplicación.
   - CookiesAceptadas: Si a aceptado o declinado las cookies.
   - UltimaVezConnectado: La fecha y hora de ultima vez entrado en la aplicación.
   - NumeroViajes: Numero de viajes que ha solicitado un viaje.
   - Alta: Fecha de alta del registro.
   - Editado: Fecha de última edición.
   - UsuarioId: El usuario del cual se ha recolectado esta información.
### Ubicaciones
   Tabla de direcciones o lugares utilizados como origen, destino o ubicaciones guardadas por los usuarios.
   Campos:
   - Id: Identificador de la ubicación.
   - TipoAvenida: Tipo de via (calle, avenida, etc.).
   - Nombre: Nombre de la calle o lugar.
   - Numero: Numero de la dirección.
   - Alta: Fecha en la que se añadió la ubicación.
   - Editado: Fecha de última edición.
### Oferta
   Tabla de solicitudes de viaje creadas por los usuarios.
   Campos:
   - Id: Identificador de la oferta.
   - Hora: hora de la solicitud.
   - Precio: Precio estimado de la solicitud.
   - Descuento: Descuento aplicado.
   - Alta: Fecha de alta de la oferta.
   - Editado: Fecha de última edición.
   - Baja: Fecha de baja de la oferta.
   - OrigenId: Ubicación de origen.
   - DestinoId: Ubicación de destino.
   - UsuarioId: Usuario que solicita el viaje.
### Viaje
   Tabla de viajes realizados en la plataforma a partir de una oferta.
   Campos:
   - Id: Identificador del viaje.
   - Inicio: Fecha y hora de inicio del viaje.
   - Fin: Fecha y hora de finalización del viaje.
   - Estado: Estado del viaje.
   - Nota: Calificación del viaje.
   - Comentario: Comentario asociado al viaje.
   - Alta: Fecha de alta del viaje.
   - Editado: Fecha de última edición.
   - ConductorId: Conductor que realiza el viaje.
   - OfertaId: Oferta asociada al viaje.
### Conductor
   Tabla de conductores registrados en la plataforma.
   Campos:
   - Id: Identificador del conductor.
   - CarnetDeConducir: Ubicación del fichero del carnet de conducir.
   - Documentacion: Documentación de identidad asociada al conductor.
   - Estado: Estado del conductor.
   - FechaDeCaducidadPermiso: Fecha de caducidad del permiso de conducir.
   - Alta: Fecha de alta del conductor.
   - Editado: Fecha de última edición.
   - Baja: Fecha de baja del conductor.
   - EmpresaId: compañía asociada al conductor.
   - VehiculoId: vehículo asociado al conductor.
   - UsuarioId: Usuario asociado al conductor.
### Vehículo
   Tabla de vehículos disponibles en la plataforma para realizar viajes.
   Campos:
   - Id: Identificador del vehículo.
   - Matricula: Matricula del vehículo.
   - Plazas: Numero de plazas del vehículo.
   - Marca: Marca del vehículo.
   - Modelo: Modelo del vehículo.
   - Estado: Estado del vehículo.
   - Alta: Fecha de alta del vehículo.
   - Editado: Fecha y hora de la ultima actualización.
   - Baja: Fecha y hora de baja del vehículo.
### Compañía
   Tabla de compañías asociadas a conductores
   Campos:
   - Id: Identificador de la compañía.
   - Nombre: Nombre de la de la compañía.
   - Logo: Logo de la compañía, guardado en la url de la imagen.
   - Email: Correo electrónico de la compañía.
   - Numero: Numero de contacto de la compañía.
   - Alta: Fecha de alta de la compañía.
   - Editado: Fecha de última edición.
   - Baja: Fecha de baja de la compañía.
### Posicion
   Tabla de la posición en tiempo real de un conductor.
   Campos:
   - Id: Identificador del campo en la base de datos.
   - Latitud: Latitud de la posición.
   - Longitud: Longitud de la posición.
   - Hora: La hora a la que se ha cogido.
   - ConductorId: Id del conductor a que refiere esta ubicación.
### Transacciones
   Tabla de pagos registrados en el sistema.
   Campos:
   - Id: Identificador de la transacción.
   - Cantidad: Importe de la transacción.
   - Momento: Fecha y hora en la que se realizo la transacción.
   - Alta: Fecha de alta de la transacción.
   - Editado: Fecha de última edición.
   - CuentaId: Cuenta bancaria asociada a la transacción.
   - ViajeId: Viaje asociado a la transacción.

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



