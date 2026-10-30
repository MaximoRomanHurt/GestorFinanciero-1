-- =====================================================
-- 01.user_financista.sql (PostgreSQL)
-- =====================================================
-- NOTA PARA RENDER:
-- En PostgreSQL administrado de Render, la base de datos y el usuario
-- son aprovisionados automáticamente. No es necesario ejecutar este script en Render.
--
-- Para entorno de desarrollo local (ej. Docker / psql superuser):
-- =====================================================

DO
$do$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'financista') THEN
      CREATE ROLE financista WITH LOGIN PASSWORD 'financista' SUPERUSER CREATEDB;
   END IF;
END
$do$;
