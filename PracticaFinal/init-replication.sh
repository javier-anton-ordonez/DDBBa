#!/bin/bash
set -e

MASTER_HOST="db-master-1"
REPL_USER="replicator_user"
REPL_PASS="replicator_password"
ROOT_PASS="rootpassword"

wait_for_mysql() {
  local host=$1
  echo "Esperando a $host"
  until mysql -h "$host" -u root -p"$ROOT_PASS" -e "SELECT 1" &>/dev/null; do
    sleep 3
  done
  echo "Listo"
}

wait_for_mysql db-master-1
wait_for_mysql db-master-2
wait_for_mysql db-read-app
wait_for_mysql db-read-dashboard

echo "Configurando db-master-2"
mysql -h db-master-2 -u root -p"$ROOT_PASS" <<EOF
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_HOST',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION=1;
START SLAVE;
EOF

echo "Configurando db-read-app"
mysql -h db-read-app -u root -p"$ROOT_PASS" <<EOF
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_HOST',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION=1;
START SLAVE;
EOF

echo "Configurando db-read-dashboard"
mysql -h db-read-dashboard -u root -p"$ROOT_PASS" <<EOF
STOP SLAVE;
CHANGE MASTER TO
  MASTER_HOST='$MASTER_HOST',
  MASTER_USER='$REPL_USER',
  MASTER_PASSWORD='$REPL_PASS',
  MASTER_AUTO_POSITION=1;
START SLAVE;
EOF
