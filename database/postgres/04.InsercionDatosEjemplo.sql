-- =====================================================
-- GESTOR FINANCIERO - MVP (PostgreSQL)
-- 04.InsercionDatosEjemplo.sql
-- Inserción de Usuario Demo, Cuentas, Movimientos, Metas y Transferencias
-- =====================================================

-- 1. CATEGORÍAS PREVIAS REQUERIDAS POR LOS DATOS DE EJEMPLO
INSERT INTO categoria_cuentas (categoria) VALUES 
('Ahorro'), ('Débito'), ('Efectivo'), ('Fondo de Emergencia')
ON CONFLICT (categoria) DO NOTHING;

INSERT INTO categoria_gastos (categoria) VALUES 
('Gastos de Vivienda'), ('Servicios Básicos'), ('Salud'), ('Deudas y Préstamos'),
('Ahorro e Inversión'), ('Seguros'), ('Alimentación'), ('Suscripciones Digitales'),
('Transporte'), ('Ocio y Entretenimiento'), ('Restaurantes y Cafeterías'),
('Ropa y Calzado'), ('Cuidado Personal'), ('Mascotas'), ('Hogar y Mantenimiento'),
('Regalos y Donaciones'), ('Viajes'), ('Otros Gastos')
ON CONFLICT (categoria) DO NOTHING;

INSERT INTO categoria_ingresos (categoria) VALUES 
('Sueldo'), ('Bonos y Comisiones'), ('Ingresos Freelance'), ('Devoluciones y Reembolsos'),
('Dividendos e Intereses'), ('Otros Ingresos'), ('Regalos Recibidos'), ('Venta de Bienes')
ON CONFLICT (categoria) DO NOTHING;

-- 2. USUARIO DEMO (Si no existe, se crea con contraseña 'demo' hasheada con BCrypt)
DO $$
DECLARE
    v_cli_id BIGINT;
BEGIN
    SELECT cod_cliente INTO v_cli_id FROM usuario WHERE usuario = 'demo';
    IF v_cli_id IS NULL THEN
        INSERT INTO cliente (ap_paterno, ap_materno, nombres)
        VALUES ('Demo', 'Finanzas', 'Usuario')
        RETURNING cod_cliente INTO v_cli_id;

        -- Password BCrypt para: demo1234 (cumple validación de mín. 8 caracteres)
        INSERT INTO usuario (usuario, clave, cod_cliente)
        VALUES ('demo', '$2a$10$HrXVuSubL75P2w2ajckAeuVP2PxEgiibDjmXU1lbVe/q.oGIyM/02', v_cli_id);
    END IF;
END $$;

-- 3. INSERCIÓN DE CUENTAS, MOVIMIENTOS, METAS Y TRANSFERENCIAS
DO $$
DECLARE
    v_cli         BIGINT;
    v_debito      BIGINT;
    v_ahorro      BIGINT;
    v_efec        BIGINT;
    v_cat         BIGINT;
    v_id_mov      BIGINT;
    v_tipo        BIGINT;
    v_laptop      BIGINT;
    v_viaje       BIGINT;
    v_fondo       BIGINT;
    v_curso       BIGINT;
    v_celu        BIGINT;
    c_en_progreso BIGINT;
BEGIN
    SELECT cod_cliente INTO v_cli FROM usuario WHERE usuario = 'demo';

    -- Crear Cuentas si no existen
    SELECT id_cuenta INTO v_debito FROM cuentas WHERE cod_cliente = v_cli AND nombre_cuenta = 'BCP Débito';
    IF v_debito IS NULL THEN
        SELECT id_categoria INTO v_cat FROM categoria_cuentas WHERE categoria = 'Débito';
        INSERT INTO cuentas (nombre_cuenta, cod_cliente, id_categoria, saldo)
        VALUES ('BCP Débito', v_cli, v_cat, 0) RETURNING id_cuenta INTO v_debito;
    END IF;

    SELECT id_cuenta INTO v_ahorro FROM cuentas WHERE cod_cliente = v_cli AND nombre_cuenta = 'Cuenta de Ahorro Ripley';
    IF v_ahorro IS NULL THEN
        SELECT id_categoria INTO v_cat FROM categoria_cuentas WHERE categoria = 'Ahorro';
        INSERT INTO cuentas (nombre_cuenta, cod_cliente, id_categoria, saldo)
        VALUES ('Cuenta de Ahorro Ripley', v_cli, v_cat, 0) RETURNING id_cuenta INTO v_ahorro;
    END IF;

    SELECT id_cuenta INTO v_efec FROM cuentas WHERE cod_cliente = v_cli AND nombre_cuenta = 'Billetera';
    IF v_efec IS NULL THEN
        SELECT id_categoria INTO v_cat FROM categoria_cuentas WHERE categoria = 'Efectivo';
        INSERT INTO cuentas (nombre_cuenta, cod_cliente, id_categoria, saldo)
        VALUES ('Billetera', v_cli, v_cat, 0) RETURNING id_cuenta INTO v_efec;
    END IF;

    -- Movimientos iniciales
    IF NOT EXISTS (SELECT 1 FROM movimientos WHERE id_cuenta IN (v_debito, v_ahorro, v_efec)) THEN
        -- Ingresos base de apertura para sostener operaciones y aportes
        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Otros Ingresos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Saldo inicial de ahorros', 1500, CURRENT_DATE - INTERVAL '60 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Fondo inicial efectivo', 200, CURRENT_DATE - INTERVAL '60 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        -- INGRESOS DEMO
        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Sueldo';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Sueldo septiembre', 2800, CURRENT_DATE - INTERVAL '55 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Sueldo octubre', 2800, CURRENT_DATE - INTERVAL '25 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Bonos y Comisiones';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Bono desempeño', 300, CURRENT_DATE - INTERVAL '30 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Ingresos Freelance';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Freelance diseño', 450, CURRENT_DATE - INTERVAL '12 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Devoluciones y Reembolsos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Devolución impuesto', 120, CURRENT_DATE - INTERVAL '45 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Dividendos e Intereses';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Intereses cuenta ahorro', 18, CURRENT_DATE - INTERVAL '20 days', v_ahorro) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Otros Ingresos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Depósito mensual', 600, CURRENT_DATE - INTERVAL '54 days', v_ahorro) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Depósito mensual', 600, CURRENT_DATE - INTERVAL '24 days', v_ahorro) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Regalos Recibidos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Regalo cumpleaños', 100, CURRENT_DATE - INTERVAL '35 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_ingresos WHERE categoria = 'Venta de Bienes';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('I', 'Venta de libros usados', 45, CURRENT_DATE - INTERVAL '10 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO ingresos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        -- GASTOS FIJOS
        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Gastos de Vivienda';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Alquiler cuarto', 900, CURRENT_DATE - INTERVAL '50 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Alquiler cuarto', 900, CURRENT_DATE - INTERVAL '20 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Servicios Básicos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Internet fibra', 80, CURRENT_DATE - INTERVAL '18 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Luz y agua', 95, CURRENT_DATE - INTERVAL '17 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Salud';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Seguro salud', 110, CURRENT_DATE - INTERVAL '28 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Deudas y Préstamos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Cuota tarjeta crédito', 200, CURRENT_DATE - INTERVAL '15 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Ahorro e Inversión';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Aporte fondo emergencia', 300, CURRENT_DATE - INTERVAL '22 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Seguros';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Seguro auto', 70, CURRENT_DATE - INTERVAL '40 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        -- GASTOS VARIABLES / OCIO / HOGAR
        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Alimentación';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Supermercado', 210, CURRENT_DATE - INTERVAL '40 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Supermercado', 185, CURRENT_DATE - INTERVAL '9 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Almuerzo', 14, CURRENT_DATE - INTERVAL '8 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Suscripciones Digitales';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Spotify', 17, CURRENT_DATE - INTERVAL '15 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Netflix', 35, CURRENT_DATE - INTERVAL '14 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Transporte';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Pasaje combi', 6, CURRENT_DATE - INTERVAL '7 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Taxi nocturno', 22, CURRENT_DATE - INTERVAL '1 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Ocio y Entretenimiento';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Cine con amigas', 38, CURRENT_DATE - INTERVAL '6 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Restaurantes y Cafeterías';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Salida a comer', 95, CURRENT_DATE - INTERVAL '5 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Café con leche', 12, CURRENT_DATE - INTERVAL '2 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Ropa y Calzado';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Zapatillas en oferta', 160, CURRENT_DATE - INTERVAL '3 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Cuidado Personal';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Corte de cabello', 30, CURRENT_DATE - INTERVAL '11 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Mascotas';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Alimento perro', 45, CURRENT_DATE - INTERVAL '13 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Hogar y Mantenimiento';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Foco y cortina', 40, CURRENT_DATE - INTERVAL '4 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Regalos y Donaciones';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Regalo para mamá', 80, CURRENT_DATE - INTERVAL '16 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Viajes';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Pasaje bus a provincia', 120, CURRENT_DATE - INTERVAL '33 days', v_debito) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);

        SELECT id_categoria INTO v_cat FROM categoria_gastos WHERE categoria = 'Otros Gastos';
        INSERT INTO movimientos (tipo, descripcion, monto, fecha, id_cuenta)
        VALUES ('G', 'Propina mesero', 10, CURRENT_DATE - INTERVAL '2 days', v_efec) RETURNING id_movimiento INTO v_id_mov;
        INSERT INTO gastos (id_movimiento, id_categoria) VALUES (v_id_mov, v_cat);
    END IF;

    -- Recalcular saldos provisionales de movimientos
    UPDATE cuentas c
       SET saldo = (SELECT COALESCE(SUM(CASE m.tipo WHEN 'I' THEN m.monto ELSE -m.monto END), 0)
                      FROM movimientos m
                     WHERE m.id_cuenta = c.id_cuenta)
     WHERE c.cod_cliente = v_cli;

    -- METAS FINANCIERAS Y APORTES
    SELECT id_estado INTO c_en_progreso FROM estado_metas WHERE estado = 'EN_PROGRESO';

    IF NOT EXISTS (SELECT 1 FROM metas WHERE cod_cliente = v_cli) THEN
        -- Laptop nueva
        SELECT id_tipo INTO v_tipo FROM tipo_metas WHERE tipo = 'Adquisicion de bienes';
        INSERT INTO metas (nombre_meta, monto_objetivo, saldo, fecha_limite, id_estado, id_tipo, cod_cliente)
        VALUES ('Laptop nueva', 3000, 0, CURRENT_DATE + INTERVAL '120 days', c_en_progreso, v_tipo, v_cli)
        RETURNING id_meta INTO v_laptop;

        -- Viaje a Cusco
        SELECT id_tipo INTO v_tipo FROM tipo_metas WHERE tipo = 'Ahorro';
        INSERT INTO metas (nombre_meta, monto_objetivo, saldo, fecha_limite, id_estado, id_tipo, cod_cliente)
        VALUES ('Viaje a Cusco', 1500, 0, CURRENT_DATE + INTERVAL '90 days', c_en_progreso, v_tipo, v_cli)
        RETURNING id_meta INTO v_viaje;

        -- Fondo de emergencia
        INSERT INTO metas (nombre_meta, monto_objetivo, saldo, fecha_limite, id_estado, id_tipo, cod_cliente)
        VALUES ('Fondo de emergencia', 5000, 0, CURRENT_DATE + INTERVAL '365 days', c_en_progreso, v_tipo, v_cli)
        RETURNING id_meta INTO v_fondo;

        -- Curso de inglés
        SELECT id_tipo INTO v_tipo FROM tipo_metas WHERE tipo = 'Inversion';
        INSERT INTO metas (nombre_meta, monto_objetivo, saldo, fecha_limite, id_estado, id_tipo, cod_cliente)
        VALUES ('Curso de inglés', 600, 0, CURRENT_DATE + INTERVAL '30 days', c_en_progreso, v_tipo, v_cli)
        RETURNING id_meta INTO v_curso;

        -- Celular nuevo
        SELECT id_tipo INTO v_tipo FROM tipo_metas WHERE tipo = 'Adquisicion de bienes';
        INSERT INTO metas (nombre_meta, monto_objetivo, saldo, fecha_limite, id_estado, id_tipo, cod_cliente)
        VALUES ('Celular nuevo', 1800, 0, CURRENT_DATE + INTERVAL '200 days', c_en_progreso, v_tipo, v_cli)
        RETURNING id_meta INTO v_celu;

        -- Aportes Laptop (el trigger trg_actualiza_saldo_meta actualiza saldo de la meta)
        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_laptop, v_debito, 400, CURRENT_DATE - INTERVAL '45 days', 'A');
        UPDATE cuentas SET saldo = saldo - 400 WHERE id_cuenta = v_debito;

        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_laptop, v_debito, 300, CURRENT_DATE - INTERVAL '30 days', 'A');
        UPDATE cuentas SET saldo = saldo - 300 WHERE id_cuenta = v_debito;

        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_laptop, v_debito, 300, CURRENT_DATE - INTERVAL '15 days', 'A');
        UPDATE cuentas SET saldo = saldo - 300 WHERE id_cuenta = v_debito;

        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_laptop, v_debito, 200, CURRENT_DATE - INTERVAL '5 days', 'A');
        UPDATE cuentas SET saldo = saldo - 200 WHERE id_cuenta = v_debito;

        -- Aportes Viaje
        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_viaje, v_ahorro, 600, CURRENT_DATE - INTERVAL '40 days', 'A');
        UPDATE cuentas SET saldo = saldo - 600 WHERE id_cuenta = v_ahorro;

        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_viaje, v_ahorro, 400, CURRENT_DATE - INTERVAL '10 days', 'A');
        UPDATE cuentas SET saldo = saldo - 400 WHERE id_cuenta = v_ahorro;

        -- Aportes Fondo de emergencia
        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_fondo, v_debito, 600, CURRENT_DATE - INTERVAL '50 days', 'A');
        UPDATE cuentas SET saldo = saldo - 600 WHERE id_cuenta = v_debito;

        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_fondo, v_debito, 500, CURRENT_DATE - INTERVAL '20 days', 'A');
        UPDATE cuentas SET saldo = saldo - 500 WHERE id_cuenta = v_debito;

        -- Aportes Curso
        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_curso, v_debito, 300, CURRENT_DATE - INTERVAL '20 days', 'A');
        UPDATE cuentas SET saldo = saldo - 300 WHERE id_cuenta = v_debito;

        INSERT INTO aportes_meta (id_meta, id_cuenta, monto, fecha, tipo) VALUES (v_curso, v_debito, 300, CURRENT_DATE - INTERVAL '3 days', 'A');
        UPDATE cuentas SET saldo = saldo - 300 WHERE id_cuenta = v_debito;
    END IF;

    -- TRANSFERENCIAS
    IF NOT EXISTS (SELECT 1 FROM transferencias WHERE id_cuentaog IN (v_debito, v_ahorro, v_efec)) THEN
        INSERT INTO transferencias (id_cuentaog, id_cuentades, monto, fecha)
        VALUES (v_debito, v_efec, 100, CURRENT_DATE - INTERVAL '12 days');
        UPDATE cuentas SET saldo = saldo - 100 WHERE id_cuenta = v_debito;
        UPDATE cuentas SET saldo = saldo + 100 WHERE id_cuenta = v_efec;

        INSERT INTO transferencias (id_cuentaog, id_cuentades, monto, fecha)
        VALUES (v_debito, v_ahorro, 150, CURRENT_DATE - INTERVAL '8 days');
        UPDATE cuentas SET saldo = saldo - 150 WHERE id_cuenta = v_debito;
        UPDATE cuentas SET saldo = saldo + 150 WHERE id_cuenta = v_ahorro;

        INSERT INTO transferencias (id_cuentaog, id_cuentades, monto, fecha)
        VALUES (v_ahorro, v_efec, 50, CURRENT_DATE - INTERVAL '4 days');
        UPDATE cuentas SET saldo = saldo - 50 WHERE id_cuenta = v_ahorro;
        UPDATE cuentas SET saldo = saldo + 50 WHERE id_cuenta = v_efec;

        INSERT INTO transferencias (id_cuentaog, id_cuentades, monto, fecha)
        VALUES (v_efec, v_debito, 30, CURRENT_DATE - INTERVAL '1 day');
        UPDATE cuentas SET saldo = saldo - 30 WHERE id_cuenta = v_efec;
        UPDATE cuentas SET saldo = saldo + 30 WHERE id_cuenta = v_debito;
    END IF;

END $$;
