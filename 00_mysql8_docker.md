# Tema 0. MySQL 8 en Docker

## 0. Requisitos

- Docker Desktop (o Docker Engine) instalado
- Docker Compose disponible (`docker compose version`)

Comprobar:

```bash
docker --version
docker compose version
```

## 1. Opción recomendada: Docker Compose

### 1.1. Crear `compose.yaml`

En tu carpeta de proyecto, crea un archivo `compose.yaml` con este contenido:

<details>
<summary><code>compose.yaml</code></summary>

```yaml
services:
  mysql:
    image: mysql:8.0
    container_name: mysql8
    restart: unless-stopped
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: "rootpass"
      MYSQL_DATABASE: "universidad"
      MYSQL_USER: "app"
      MYSQL_PASSWORD: "apppass"
    command: ["--default-authentication-plugin=mysql_native_password"]
    volumes:
      - mysql_data:/var/lib/mysql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "-uroot", "-prootpass"]
      interval: 10s
      timeout: 5s
      retries: 10

volumes:
  mysql_data:
```

</details>

### 1.1.1. Explicación del `compose.yaml` (parte por parte)

| Elemento | Descripción |
| --- | --- |
| **`services`** | Define los “servicios” del proyecto (contenedores) que Compose va a crear y gestionar. |
| **`mysql`** | Nombre del servicio; se usa en comandos como `docker compose logs mysql` o `docker compose stop mysql`. |
| **`image: mysql:8.0`** | Imagen oficial que se descargará/ejecutará; `8.0` fija la versión mayor (evita sorpresas). |
| **`container_name: mysql8`** | Nombre explícito del contenedor; permite usar `docker exec -it mysql8 ...` directamente. |
| **`restart: unless-stopped`** | Si el contenedor se cae, Docker intentará reiniciarlo automáticamente; solo deja de reiniciarlo si lo paras tú explícitamente. |
| **`ports`** | Publica puertos del contenedor hacia tu máquina; **`"3306:3306"`** significa **host 3306 → contenedor 3306** (izquierda: puerto en tu máquina, derecha: puerto dentro del contenedor). |
| **`environment`** | Variables que la imagen oficial usa para inicializar MySQL en el primer arranque; define `MYSQL_ROOT_PASSWORD`, `MYSQL_DATABASE`, `MYSQL_USER` y `MYSQL_PASSWORD`. Importante: si ya existe el volumen con datos, estas variables no “reconfiguran” usuarios/BD automáticamente. |
| **`command: [...]`** | Argumentos extra pasados a `mysqld`; en este ejemplo se fuerza `mysql_native_password` para compatibilidad con clientes antiguos. |
| **`volumes`** | Monta almacenamiento persistente; **`mysql_data:/var/lib/mysql`** guarda datos en el volumen `mysql_data`, y los mantiene si recreas el contenedor. |
| **`healthcheck`** | Comprueba si el servicio está “sano”; usa `mysqladmin ping` con `interval`, `timeout` y `retries`. |
| **`volumes`** | Declara el volumen “nombrado” **`mysql_data`** que usan los servicios; Docker lo gestiona. |

Notas:

- `mysql_data` es un **volumen**: si borras el contenedor, los datos siguen.
- Credenciales del ejemplo:
  - root: `rootpass`
  - usuario app: `app` / `apppass`
  - base de datos: `universidad`

### 1.2. Arrancar el servicio

```bash
docker compose up -d
docker compose ps
docker compose logs -f mysql
```

### 1.3. Comprobar que MySQL está listo

```bash
docker exec -it mysql8 mysqladmin ping -h 127.0.0.1 -uroot -prootpass
```

Deberías ver algo como `mysqld is alive`.

## 2. Conectarse a MySQL

### 2.1. Conectar desde dentro del contenedor

```bash
docker exec -it mysql8 mysql -uroot -prootpass
```

Comando completo:

- `-it` significa “interactivo”: mantiene la conexión abierta y permite interactuar.
- `mysql` es el cliente de MySQL.
- `-uroot` es el usuario.
- `-prootpass` es la contraseña.

### 2.2. Conectar desde tu máquina (host)

Si tienes el cliente `mysql` instalado:

```bash
mysql -h 127.0.0.1 -P 3306 -uroot -p
```

(te pedirá la contraseña; usa `rootpass`).

### 2.3. Primeros comandos SQL útiles

```sql
SELECT VERSION();
SHOW DATABASES;
USE universidad;
SHOW TABLES;
```

## 3. Parar, arrancar y borrar

### 3.1. Parar/arrancar sin perder datos

```bash
docker compose stop mysql
docker compose start mysql
```

### 3.2. Bajar el proyecto sin borrar datos

```bash
docker compose down
```

### 3.3. Borrar TODO (incluye datos)

```bash
docker compose down -v
```

## 5. Problemas frecuentes (y solución rápida)

### 5.1. “Port 3306 already in use”

Tienes otro servicio usando el puerto. Opciones:

- Parar el otro servicio
- Cambiar el puerto del host (izquierda) en `ports`:

```yaml
ports:
  - "3307:3306"
```

Y conectar con `-P 3307`.

### 5.2. El contenedor reinicia en bucle

Mirar logs:

```bash
docker compose logs -f mysql
```

Causas típicas:

- contraseña root vacía (no permitida por defecto)
- volumen corrupto por apagados bruscos
- falta de espacio en disco

### 5.3. “Access denied”

Revisar usuario/host:

- `root` suele existir como `'root'@'%'` o `'root'@'localhost'` según configuración.
- Para conectar desde host con el puerto publicado, normalmente funciona, pero si no:
  - entra al contenedor como root y revisa:

```sql
SELECT user, host FROM mysql.user;
SHOW GRANTS FOR 'app'@'%';
```