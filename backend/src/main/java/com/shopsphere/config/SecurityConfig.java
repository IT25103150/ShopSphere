package com.shopsphere.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.shopsphere.auth.JwtAuthFilter;
import com.shopsphere.common.ApiError;
import java.time.LocalDateTime;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

@Configuration
@EnableWebSecurity
@EnableMethodSecurity
public class SecurityConfig {

    @Bean
    SecurityFilterChain filterChain(HttpSecurity http, JwtAuthFilter jwtFilter, ObjectMapper mapper) throws Exception {
        http.csrf(AbstractHttpConfigurer::disable)
                .cors(Customizer.withDefaults())
                .sessionManagement(s -> s.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .exceptionHandling(e -> e
                        .authenticationEntryPoint((req, res, ex) -> writeError(mapper, res, HttpStatus.UNAUTHORIZED,
                                "Authentication is required", req.getRequestURI()))
                        .accessDeniedHandler((req, res, ex) -> writeError(mapper, res, HttpStatus.FORBIDDEN,
                                "You do not have permission to perform this action", req.getRequestURI())))
                .authorizeHttpRequests(a -> a
                        .requestMatchers(HttpMethod.OPTIONS, "/**").permitAll()
                        .requestMatchers("/error", "/actuator/health/**", "/images/**").permitAll()
                        // auth
                        .requestMatchers("/api/auth/**").permitAll()
                        // catalogue is public to read, admin-only to change
                        .requestMatchers(HttpMethod.GET, "/api/products/**", "/api/categories/**", "/api/brands/**").permitAll()
                        .requestMatchers("/api/products/**", "/api/categories/**", "/api/brands/**").hasRole("ADMIN")
                        // promotions: coupon validation is public, everything else admin
                        .requestMatchers(HttpMethod.POST, "/api/promotions/validate").permitAll()
                        .requestMatchers("/api/promotions/**").hasRole("ADMIN")
                        // shopping
                        .requestMatchers("/api/cart/**", "/api/checkout/**").hasAnyRole("CUSTOMER", "STAFF")
                        // back office
                        .requestMatchers("/api/inventory/**").hasAnyRole("ADMIN", "STAFF", "WAREHOUSE")
                        .requestMatchers("/api/analytics/**", "/api/reports/**").hasRole("ADMIN")
                        // orders, shipments, deliveries and profile: authenticated here, rules refined with @PreAuthorize
                        .anyRequest().authenticated())
                .addFilterBefore(jwtFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    private void writeError(ObjectMapper mapper, jakarta.servlet.http.HttpServletResponse res, HttpStatus status,
                            String message, String path) throws java.io.IOException {
        res.setStatus(status.value());
        res.setContentType(MediaType.APPLICATION_JSON_VALUE);
        mapper.writeValue(res.getOutputStream(), new ApiError(LocalDateTime.now(), status.value(),
                status.getReasonPhrase(), message, path, Map.of()));
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    /** Authentication is done by JwtAuthFilter; this stops Spring generating a random default user. */
    @Bean
    UserDetailsService userDetailsService() {
        return username -> {
            throw new UsernameNotFoundException("Password login is handled by AuthService");
        };
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource(
            @Value("${shopsphere.cors.allowed-origins}") String origins) {
        CorsConfiguration cfg = new CorsConfiguration();
        cfg.setAllowedOrigins(Arrays.stream(origins.split(",")).map(String::trim).toList());
        cfg.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"));
        cfg.setAllowedHeaders(List.of("*"));
        cfg.setExposedHeaders(List.of("Content-Disposition"));
        cfg.setMaxAge(3600L);
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", cfg);
        return source;
    }
}
