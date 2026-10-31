# Gestor Financiero - Conexión a Oracle Cloud Autonomous Database

Sistema integral de gestión de finanzas personales desarrollado con **Java 25**, **Spring Boot 4.1.1**, **Spring Data JPA**, **Spring Security** y **Thymeleaf + AdminLTE 3**, configurado para desplegarse en **Render** y conectarse directamente a una base de datos **Oracle Cloud Autonomous Database (ATP)** mediante conexión segura **TLS (TCPS)**.

---

## ☁️ Arquitectura de Conexión a Oracle Cloud (TLS)

La aplicación se conecta a una instancia gestionada de **Oracle Autonomous Database en Oracle Cloud Infrastructure (OCI)** en la región **US East (Ashburn)** utilizando **TLS One-Way (puerto 1521)** sin necesidad de gestionar archivos wallet locales.

### 1. Cadena de Conexión JDBC (TNS descriptor TCPS):

```text
jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-ashburn-1.oraclecloud.com))(connect_data=(service_name=g858bd2d2d5daee_gestorfinanzas_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))
```

### 2. Componentes de la Conexión:
- **Driver JDBC:** `com.oracle.database.jdbc:ojdbc17` (Driver oficial de Oracle para Java 17/21/25).
- **Librerías de Seguridad TLS/PKI:** `oraclepki`, `osdt_cert` y `osdt_core` incluidas en el [`pom.xml`](pom.xml) para resolver la validación criptográfica de certificados X.509 de Oracle Cloud (`ssl_server_dn_match=yes`).
- **Protocolo:** `TCPS` (TCP con cifrado SSL/TLS en tránsito).
- **Servicio OCI:** `g858bd2d2d5daee_gestorfinanzas_high.adb.oraclecloud.com` (perfil `HIGH` optimizado para concurrencia de operaciones financieras).
- **Resiliencia:** `retry_count=20` y `retry_delay=3` segundos para reintentos transparentes ante fluctuaciones de red.

---

## ⚙️ Configuración de la Aplicación (`application.properties`)

La configuración se administra de forma desacoplada y segura mediante variables de entorno:

```properties
server.port=${PORT:8080}
spring.application.name=gestorFinanciero

spring.datasource.url=${DB_URL:jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-ashburn-1.oraclecloud.com))(connect_data=(service_name=g858bd2d2d5daee_gestorfinanzas_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))}
spring.datasource.username=${DB_USER:FINANCISTA}
spring.datasource.password=${DB_PASSWORD}
spring.datasource.driver-class-name=oracle.jdbc.OracleDriver

spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.OracleDialect
spring.jpa.show-sql=false
```

---

## 🔐 Variables de Entorno Requeridas en Render

Al crear el **Web Service** en Render, configura las siguientes variables en la pestaña **Environment**:

| Variable | Descripción | Valor |
| :--- | :--- | :--- |
| **`DB_URL`** | Cadena de conexión JDBC TCPS a Oracle Cloud | `jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-ashburn-1.oraclecloud.com))(connect_data=(service_name=g858bd2d2d5daee_gestorfinanzas_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))` |
| **`DB_USER`** | Usuario de la base de datos en Oracle Cloud | `FINANCISTA` |
| **`DB_PASSWORD`** | Contraseña del usuario en Oracle Cloud | `Finanzas2026@` |

> **Nota:** Render inyecta automáticamente la variable `PORT` (por ejemplo `10000`). Gracias a `server.port=${PORT:8080}`, Spring Boot se adaptará automáticamente a dicho puerto sin necesidad de configuración adicional.

---

## 🚀 Despliegue en Render (Paso a Paso)

1. En [Render Dashboard](https://dashboard.render.com/), haz clic en **New +** -> **Web Service**.
2. Conecta tu repositorio de GitHub: `GestorFinanciero`.
3. Selecciona la rama: **`oracle-cloud`**.
4. En los ajustes del servicio:
   - **Name:** `gestor-financiero`
   - **Runtime:** `Docker`
   - **Root Directory:** *(Dejar completamente vacío)*
   - **Dockerfile Path:** `./Dockerfile`
   - **Plan:** `Free`
5. En la sección **Environment Variables**, añade `DB_URL`, `DB_USER` y `DB_PASSWORD` según la tabla anterior.
6. Haz clic en **Create Web Service**.
7. Render compilará el proyecto usando el `Dockerfile` multi-stage con Java 25, arrancará el servidor y se conectará de inmediato a tu base de datos Oracle Cloud.
