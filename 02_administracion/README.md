# MySQL Replicación: 1 Primario + 2 Réplicas

Este ejemplo configura un cluster MySQL con replicación asíncrona:
- 1 servidor **primario** (escrituras)
- 2 servidores **réplica** (lecturas)

## Arquitectura

```
                    ┌─────────────────┐
                    │    PRIMARIO     │
                    │   (mysql-primary)│
                    │    Puerto 3306  │
                    └────────┬────────┘
                             │ binlog
              ┌──────────────┴──────────────┐
              ▼                              ▼
    ┌─────────────────┐            ┌─────────────────┐
    │   RÉPLICA 1     │            │   RÉPLICA 2     │
    │ (mysql-replica1)│            │ (mysql-replica2)│
    │   Puerto 3307   │            │   Puerto 3308   │
    └─────────────────┘            └─────────────────┘
```

## Uso

```bash
# Arrancar el cluster
docker compose up -d

# Ver logs
docker compose logs -f

# Conectar al primario
docker exec -it mysql-primary mysql -uroot -prootpass

# Conectar a réplica 1
docker exec -it mysql-replica1 mysql -uroot -prootpass

# Verificar estado de replicación en una réplica
docker exec -it mysql-replica1 mysql -uroot -prootpass -e "SHOW REPLICA STATUS\G"

# Parar todo
docker compose down -v
```

## Verificar que funciona

```sql
-- En el PRIMARIO: crear datos
USE universidad;
INSERT INTO alumno (dni, nombre, apellido1, email) 
VALUES ('TEST001', 'Test', 'Replicación', 'test@uni.es');

-- En una RÉPLICA: verificar que se replicó
USE universidad;
SELECT * FROM alumno WHERE dni = 'TEST001';
```

## Tunning aplicado

Ver `mysql/primary.cnf` y `mysql/replica.cnf` para los parámetros configurados.
