package com.shopsphere.auth;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.Date;
import javax.crypto.SecretKey;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

/** Creates and validates signed JWT access / refresh tokens. */
@Component
public class JwtService {
    private static final String TYPE = "type";
    private final SecretKey key;
    private final Duration accessTtl;
    private final Duration refreshTtl;

    public JwtService(@Value("${shopsphere.jwt.secret}") String secret,
                      @Value("${shopsphere.jwt.access-minutes}") long accessMinutes,
                      @Value("${shopsphere.jwt.refresh-days}") long refreshDays) {
        this.key = Keys.hmacShaKeyFor(secret.getBytes(StandardCharsets.UTF_8));
        this.accessTtl = Duration.ofMinutes(accessMinutes);
        this.refreshTtl = Duration.ofDays(refreshDays);
    }

    public String createAccessToken(UserEntity user) {
        return build(user, "access", accessTtl);
    }

    public String createRefreshToken(UserEntity user) {
        return build(user, "refresh", refreshTtl);
    }

    public long accessTtlSeconds() {
        return accessTtl.toSeconds();
    }

    private String build(UserEntity user, String type, Duration ttl) {
        Instant now = Instant.now();
        return Jwts.builder()
                .subject(user.getEmail())
                .claim("uid", user.getId())
                .claim("role", user.getRole().getName())
                .claim(TYPE, type)
                .issuedAt(Date.from(now))
                .expiration(Date.from(now.plus(ttl)))
                .signWith(key)
                .compact();
    }

    /** Returns the claims if the token is valid and of the expected type, otherwise null. */
    public Claims parse(String token, String expectedType) {
        try {
            Claims claims = Jwts.parser().verifyWith(key).build().parseSignedClaims(token).getPayload();
            return expectedType.equals(claims.get(TYPE, String.class)) ? claims : null;
        } catch (JwtException | IllegalArgumentException ex) {
            return null;
        }
    }

    public AuthUser extractUser(Claims claims) {
        return new AuthUser(claims.get("uid", Long.class), claims.getSubject(), claims.get("role", String.class));
    }
}
