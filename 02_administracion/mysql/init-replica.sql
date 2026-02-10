-- ============================================
-- Inicialización de RÉPLICAS
-- ============================================

-- Las réplicas no necesitan crear usuarios ni datos
-- Todo se replicará desde el primario

-- Este archivo existe solo para que Docker no falle
-- si no encuentra scripts de inicialización

SELECT 'Réplica inicializada, esperando configuración de replicación...' AS status;
