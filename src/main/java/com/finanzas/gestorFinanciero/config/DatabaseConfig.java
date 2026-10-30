package com.finanzas.gestorFinanciero.config;

import com.zaxxer.hikari.HikariDataSource;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

import javax.sql.DataSource;
import java.net.URI;

@Configuration
public class DatabaseConfig {

    @Value("${spring.datasource.url:#{null}}")
    private String springUrl;

    @Value("${DB_URL:#{null}}")
    private String dbUrl;

    @Value("${DATABASE_URL:#{null}}")
    private String databaseUrl;

    @Value("${spring.datasource.username:financista}")
    private String username;

    @Value("${spring.datasource.password:financista}")
    private String password;

    @Bean
    @Primary
    public DataSource dataSource() {
        String rawUrl = (dbUrl != null && !dbUrl.isBlank()) ? dbUrl :
                ((databaseUrl != null && !databaseUrl.isBlank()) ? databaseUrl : springUrl);

        HikariDataSource ds = new HikariDataSource();
        ds.setDriverClassName("org.postgresql.Driver");

        if (rawUrl != null && (rawUrl.startsWith("postgres://") || rawUrl.startsWith("postgresql://")) && !rawUrl.startsWith("jdbc:")) {
            try {
                URI uri = new URI(rawUrl);
                String host = uri.getHost();
                int port = uri.getPort() > 0 ? uri.getPort() : 5432;
                String path = uri.getPath();
                String userInfo = uri.getUserInfo();
                if (userInfo != null && userInfo.contains(":")) {
                    String[] parts = userInfo.split(":", 2);
                    ds.setUsername(parts[0]);
                    ds.setPassword(parts[1]);
                } else {
                    ds.setUsername(username);
                    ds.setPassword(password);
                }
                String query = uri.getQuery();
                String sslParam = (query != null && query.contains("sslmode=")) ? "" : "?sslmode=require";
                if (query != null && !query.isBlank() && !query.contains("sslmode=")) {
                    sslParam = "?" + query + "&sslmode=require";
                } else if (query != null && !query.isBlank()) {
                    sslParam = "?" + query;
                }
                String jdbcUrl = "jdbc:postgresql://" + host + ":" + port + path + sslParam;
                ds.setJdbcUrl(jdbcUrl);
            } catch (Exception e) {
                ds.setJdbcUrl(rawUrl);
                ds.setUsername(username);
                ds.setPassword(password);
            }
        } else {
            ds.setJdbcUrl(rawUrl);
            ds.setUsername(username);
            ds.setPassword(password);
        }

        return ds;
    }
}
