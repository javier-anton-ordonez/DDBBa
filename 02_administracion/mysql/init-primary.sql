-- ============================================
-- Inicialización del PRIMARIO
-- ============================================

-- Crear usuario para replicación
CREATE USER IF NOT EXISTS 'repl_user'@'%' IDENTIFIED BY 'repl_pass';
GRANT REPLICATION SLAVE ON *.* TO 'repl_user'@'%';

-- Crear usuario para la aplicación (solo en primario, se replica)
CREATE USER IF NOT EXISTS 'app'@'%' IDENTIFIED BY 'apppass';
GRANT SELECT, INSERT, UPDATE, DELETE ON universidad.* TO 'app'@'%';

FLUSH PRIVILEGES;
