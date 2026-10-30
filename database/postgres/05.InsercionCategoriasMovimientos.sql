-- =====================================================
-- GESTOR FINANCIERO - MVP (PostgreSQL)
-- 05.InsercionCategoriasMovimientos.sql
-- Inserción y clasificación de categorías (Fija / Variable)
-- =====================================================

-- 1. Agregar columna tipo a categoria_gastos si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categoria_gastos' AND column_name = 'tipo'
    ) THEN
        ALTER TABLE categoria_gastos ADD COLUMN tipo VARCHAR(50);
        ALTER TABLE categoria_gastos ADD CONSTRAINT ck_tipo_catgastos CHECK (tipo IN ('FIJA','VARIABLE'));
    END IF;
END $$;

-- 2. Agregar columna tipo a categoria_ingresos si no existe
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'categoria_ingresos' AND column_name = 'tipo'
    ) THEN
        ALTER TABLE categoria_ingresos ADD COLUMN tipo VARCHAR(50);
        ALTER TABLE categoria_ingresos ADD CONSTRAINT ck_tipo_catingresos CHECK (tipo IN ('FIJA','VARIABLE'));
    END IF;
END $$;

-- 3. Clasificación de categorías de gastos existentes
UPDATE categoria_gastos SET tipo = 'FIJA'     WHERE LOWER(categoria) = 'gastos de vivienda';
UPDATE categoria_gastos SET tipo = 'FIJA'     WHERE LOWER(categoria) = 'fijo';
UPDATE categoria_gastos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'variable';
UPDATE categoria_gastos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'ocio';
UPDATE categoria_gastos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'comidas';
UPDATE categoria_gastos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'compras no planificadas';
UPDATE categoria_gastos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'suscripciones';

-- Inserción / actualización de categorías adicionales de gastos
INSERT INTO categoria_gastos (categoria, tipo) VALUES
('Servicios Básicos',        'FIJA'),
('Alimentación',             'FIJA'),
('Transporte',               'FIJA'),
('Salud',                    'FIJA'),
('Educación',                'FIJA'),
('Seguros',                  'FIJA'),
('Deudas y Préstamos',       'FIJA'),
('Ahorro e Inversión',       'FIJA'),
('Impuestos',                'VARIABLE'),
('Restaurantes y Cafeterías','VARIABLE'),
('Ropa y Calzado',           'VARIABLE'),
('Cuidado Personal',         'VARIABLE'),
('Mascotas',                 'VARIABLE'),
('Hogar y Mantenimiento',    'VARIABLE'),
('Regalos y Donaciones',     'VARIABLE'),
('Viajes',                   'VARIABLE'),
('Suscripciones Digitales',  'VARIABLE'),
('Otros Gastos',             'VARIABLE')
ON CONFLICT (categoria) DO UPDATE SET tipo = EXCLUDED.tipo;

-- 4. Clasificación de categorías de ingresos existentes
UPDATE categoria_ingresos SET tipo = 'FIJA'     WHERE LOWER(categoria) = 'sueldo';
UPDATE categoria_ingresos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'propina / extra';
UPDATE categoria_ingresos SET tipo = 'VARIABLE' WHERE LOWER(categoria) = 'otros';

-- Inserción / actualización de categorías adicionales de ingresos
INSERT INTO categoria_ingresos (categoria, tipo) VALUES
('Bonos y Comisiones',       'VARIABLE'),
('Ingresos Freelance',       'VARIABLE'),
('Negocio Propio',           'VARIABLE'),
('Rentas',                   'VARIABLE'),
('Dividendos e Intereses',   'VARIABLE'),
('Devoluciones y Reembolsos','VARIABLE'),
('Venta de Bienes',          'VARIABLE'),
('Regalos Recibidos',        'VARIABLE'),
('Ayudas o Subsidios',       'VARIABLE')
ON CONFLICT (categoria) DO UPDATE SET tipo = EXCLUDED.tipo;
