# Gestor Financiero - Migración a PostgreSQL y Despliegue en Render

Sistema integral de gestión de finanzas personales desarrollado con Spring Boot y Thymeleaf, migrado desde Oracle a PostgreSQL para despliegue automatizado en la nube (Render).

---

## 🛠️ Stack Tecnológico

- **Lenguaje:** Java 25 (Eclipse Temurin 25)
- **Framework:** Spring Boot 4.1.1
- **Persistencia:** Spring Data JPA / Hibernate 7
- **Base de Datos:** PostgreSQL 16+
- **Seguridad:** Spring Security con BCrypt
- **Frontend:** Thymeleaf + AdminLTE 3 + FontAwesome
- **Contenedores:** Docker (construcción multi-stage)
- **Plataforma Cloud:** Render (Web Service Docker + PostgreSQL administrado)

---

## 📂 Scripts de Base de Datos (PostgreSQL)

Los scripts adaptados para PostgreSQL se encuentran en la carpeta [`database/postgres/`](database/postgres/).
Deben ejecutarse estrictamente en el siguiente orden:

1. **`01.user_financista.sql`** *(Opcional en Render)*: Crea el rol `financista` para entornos locales. En Render este usuario ya viene creado.
2. **`02.bd_financista.sql`**: Estructura de tablas base (`categoria_cuentas`, `categoria_gastos`, `categoria_ingresos`, `cliente`, `usuario`, `cuentas`, `transferencias`, `movimientos`, `ingresos`, `gastos`, `opciones`), constraints, índices y menú dinámico.
3. **`03.bd_Modulo de Metas Financieras.sql`**: Tablas `tipo_metas`, `estado_metas`, `metas`, `aportes_meta`, procedimiento `sp_vencer_metas()` y funciones + triggers PL/pgSQL (`trg_valida_fecha_meta`, `trg_valida_fecha_aportes_meta`, `trg_actualiza_saldo_meta`).
4. **`04.InsercionDatosEjemplo.sql`**: Creación del cliente y usuario demo con hash BCrypt, cuentas de ejemplo, 37 movimientos, 5 metas financieras con aportes y 4 transferencias.
5. **`05.InsercionCategoriasMovimientos.sql`**: Clasificación de categorías fijas/variables y catálogo ampliado de ingresos y gastos.

> **Usuario Demo sembrado:**
> - **Usuario:** `demo`
> - **Contraseña:** `demo1234`

---

## 🔐 Variables de Entorno

La aplicación lee su configuración mediante variables de entorno:

| Variable | Descripción | Ejemplo / Valor en Render |
| :--- | :--- | :--- |
| `PORT` | Puerto HTTP donde escucha la app | Proporcionado automáticamente por Render (ej. `10000` u `8080`) |
| `DB_URL` | URL de conexión JDBC a PostgreSQL | `jdbc:postgresql://dpg-xxxx-a:5432/gestor_financiero?sslmode=require` |
| `DB_USER` | Usuario de la base de datos | `financista` o el usuario asignado por Render |
| `DB_PASSWORD` | Contraseña de la base de datos | Contraseña asignada por Render |

> **Nota de compatibilidad:** Si no defines `DB_URL` de forma completa, puedes definir por separado `DB_HOST`, `DB_PORT` y `DB_NAME`.

---

## 🔄 Conversión de URL de Render a Formato JDBC

Render proporciona la URL de conexión en formato URI estándar:
```text
postgres://usuario:password@dpg-cxxxxxxx-a.oregon-postgres.render.com/gestor_financiero_db
```

El driver JDBC de Java (`org.postgresql.Driver`) requiere el protocolo `jdbc:postgresql://` y el parámetro de SSL:
```text
jdbc:postgresql://dpg-cxxxxxxx-a.oregon-postgres.render.com:5432/gestor_financiero_db?sslmode=require
```

### Regla de transformación:
1. Reemplazar el prefijo `postgres://` por `jdbc:postgresql://`.
2. Remover las credenciales `usuario:password@` de la URL (estas se pasan en `DB_USER` y `DB_PASSWORD`).
3. Añadir el puerto `:5432` tras el host si no viene explícito.
4. Agregar el parámetro `?sslmode=require` al final.

---

## 🚀 Guía de Despliegue Paso a Paso en Render

### Paso 1: Crear la Base de Datos PostgreSQL en Render
1. Inicia sesión en [Render Dashboard](https://dashboard.render.com/).
2. Haz clic en **New +** y selecciona **PostgreSQL**.
3. Configura:
   - **Name:** `gestor-financiero-db`
   - **Database:** `gestor_financiero`
   - **User:** `financista`
   - **Plan:** `Free`
4. Haz clic en **Create Database** y espera a que su estado sea **Available**.

---

### Paso 2: Inicializar los Scripts SQL con `psql`
Copia la **External Database URL** desde la página de tu base de datos en Render (tiene la forma `postgres://financista:pass@dpg-xxxx.oregon-postgres.render.com/gestor_financiero`).

Abre una terminal en tu computadora dentro de la raíz de este proyecto y ejecuta los scripts en orden:

```bash
# 1. Tablas y catálogos base
psql "<EXTERNAL_DATABASE_URL>" -f database/postgres/02.bd_financista.sql

# 2. Módulo de metas, funciones y triggers
psql "<EXTERNAL_DATABASE_URL>" -f "database/postgres/03.bd_Modulo de Metas Financieras.sql"

# 3. Datos de ejemplo y usuario demo
psql "<EXTERNAL_DATABASE_URL>" -f database/postgres/04.InsercionDatosEjemplo.sql

# 4. Clasificación de categorías
psql "<EXTERNAL_DATABASE_URL>" -f database/postgres/05.InsercionCategoriasMovimientos.sql
```

*(Si usas DBeaver, pgAdmin u otra interfaz gráfica, conéctate usando los datos de la External Database URL y ejecuta los 4 archivos en el mismo orden).*

---

### Paso 3: Crear el Web Service en Render
1. En el Dashboard de Render, haz clic en **New +** y selecciona **Web Service**.
2. Conecta tu repositorio de GitHub: `GestorFinanciero`.
3. Selecciona la rama **`migracion-postgresql`**.
4. Configura los parámetros:
   - **Name:** `gestor-financiero`
   - **Runtime:** `Docker`
   - **Plan:** `Free`

---

### Paso 4: Configurar Variables de Entorno en el Web Service
En la pestaña **Environment** del Web Service, añade las siguientes variables:

1. **`DB_URL`**:
   Usa el **Hostname** de la base de datos de Render (**Internal Database URL** recomendada para menor latencia):
   ```text
   jdbc:postgresql://<INTERNAL_HOST>:5432/gestor_financiero?sslmode=require
   ```
2. **`DB_USER`**:
   El usuario de tu base de datos en Render (ej. `financista`).
3. **`DB_PASSWORD`**:
   La contraseña asignada por Render a tu base de datos.

---

### Paso 5: Despliegue y Verificación
1. Haz clic en **Create Web Service** (o **Manual Deploy** -> **Deploy latest commit**).
2. Render construirá la imagen usando el `Dockerfile` multi-stage y arrancará la aplicación.
3. Una vez finalizado el build, abre la URL pública generada por Render (ej. `https://gestor-financiero-xxxx.onrender.com`).
4. Inicia sesión con el usuario de prueba:
   - **Usuario:** `demo`
   - **Clave:** `demo1234`
5. Verifica que carguen tus cuentas, movimientos, metas y transferencias.

---

## ⚡ Despliegue Rápido con `render.yaml` (Blueprint)
Este repositorio incluye un archivo [`render.yaml`](render.yaml) configurado. Puedes ir a **Blueprints** en Render, seleccionar este repositorio y Render creará tanto la base de datos como el servicio web vinculando sus variables de entorno automáticamente.
