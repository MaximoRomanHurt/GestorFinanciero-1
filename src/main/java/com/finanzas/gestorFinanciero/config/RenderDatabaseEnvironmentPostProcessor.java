package com.finanzas.gestorFinanciero.config;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.env.EnvironmentPostProcessor;
import org.springframework.core.env.ConfigurableEnvironment;
import org.springframework.core.env.MapPropertySource;

import java.net.URI;
import java.util.HashMap;
import java.util.Map;

public class RenderDatabaseEnvironmentPostProcessor implements EnvironmentPostProcessor {

    @Override
    public void postProcessEnvironment(ConfigurableEnvironment environment, SpringApplication application) {
        String rawUrl = environment.getProperty("DB_URL");
        if (rawUrl == null || rawUrl.isBlank()) {
            rawUrl = environment.getProperty("DATABASE_URL");
        }
        if (rawUrl == null || rawUrl.isBlank()) {
            rawUrl = environment.getProperty("spring.datasource.url");
        }

        if (rawUrl != null && (rawUrl.startsWith("postgres://") || rawUrl.startsWith("postgresql://")) && !rawUrl.startsWith("jdbc:")) {
            try {
                URI uri = new URI(rawUrl);
                String host = uri.getHost();
                int port = uri.getPort() > 0 ? uri.getPort() : 5432;
                String path = uri.getPath();
                String query = uri.getQuery();
                String ssl = (query != null && query.contains("sslmode=")) ? "" : "?sslmode=require";
                if (query != null && !query.isBlank() && !query.contains("sslmode=")) {
                    ssl = "?" + query + "&sslmode=require";
                } else if (query != null && !query.isBlank()) {
                    ssl = "?" + query;
                }

                String jdbcUrl = "jdbc:postgresql://" + host + ":" + port + path + ssl;

                Map<String, Object> props = new HashMap<>();
                props.put("spring.datasource.url", jdbcUrl);
                props.put("DB_URL", jdbcUrl);
                props.put("DATABASE_URL", jdbcUrl);

                String userInfo = uri.getUserInfo();
                if (userInfo != null && userInfo.contains(":")) {
                    String[] parts = userInfo.split(":", 2);
                    props.put("spring.datasource.username", parts[0]);
                    props.put("spring.datasource.password", parts[1]);
                    props.put("DB_USER", parts[0]);
                    props.put("DB_PASSWORD", parts[1]);
                }

                environment.getPropertySources().addFirst(new MapPropertySource("renderDatabaseFix", props));
            } catch (Exception ignored) {
            }
        }
    }
}
