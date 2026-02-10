#!/bin/bash
# ============================================
# Script para configurar la replicación
# ============================================

set -e

echo "=== Esperando a que todos los servidores estén listos ==="
sleep 10

echo "=== Configurando RÉPLICA 1 ==="
mysql -h mysql-replica1 -uroot -prootpass <<EOF
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'mysql-primary',
    SOURCE_USER = 'repl_user',
    SOURCE_PASSWORD = 'repl_pass',
    SOURCE_AUTO_POSITION = 1;

START REPLICA;
EOF

echo "=== Configurando RÉPLICA 2 ==="
mysql -h mysql-replica2 -uroot -prootpass <<EOF
STOP REPLICA;
RESET REPLICA ALL;

CHANGE REPLICATION SOURCE TO
    SOURCE_HOST = 'mysql-primary',
    SOURCE_USER = 'repl_user',
    SOURCE_PASSWORD = 'repl_pass',
    SOURCE_AUTO_POSITION = 1;

START REPLICA;
EOF

echo "=== Esperando a que la replicación se establezca ==="
sleep 5

echo ""
echo "=== Estado de RÉPLICA 1 ==="
mysql -h mysql-replica1 -uroot -prootpass -e "SHOW REPLICA STATUS\G" | grep -E "(Replica_IO_Running|Replica_SQL_Running|Seconds_Behind)"

echo ""
echo "=== Estado de RÉPLICA 2 ==="
mysql -h mysql-replica2 -uroot -prootpass -e "SHOW REPLICA STATUS\G" | grep -E "(Replica_IO_Running|Replica_SQL_Running|Seconds_Behind)"

echo ""
echo "=== Verificando datos replicados ==="
echo "Alumnos en PRIMARIO:"
mysql -h mysql-primary -uroot -prootpass -e "SELECT COUNT(*) as total FROM universidad.alumno"

echo "Alumnos en RÉPLICA 1:"
mysql -h mysql-replica1 -uroot -prootpass -e "SELECT COUNT(*) as total FROM universidad.alumno"

echo "Alumnos en RÉPLICA 2:"
mysql -h mysql-replica2 -uroot -prootpass -e "SELECT COUNT(*) as total FROM universidad.alumno"

echo ""
echo "============================================"
echo "  REPLICACIÓN CONFIGURADA CORRECTAMENTE"
echo "============================================"
echo ""
echo "Puertos:"
echo "  - Primario:  localhost:3306"
echo "  - Réplica 1: localhost:3307"
echo "  - Réplica 2: localhost:3308"
echo ""
