package com.shopsphere.auth;

import com.shopsphere.auth.AuthDtos.*;
import com.shopsphere.common.ApiException;
import io.jsonwebtoken.Claims;
import java.util.Locale;
import org.springframework.http.HttpStatus;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {
    private final UserRepository users;
    private final RoleRepository roles;
    private final PasswordEncoder encoder;
    private final JwtService jwt;

    public AuthService(UserRepository users, RoleRepository roles, PasswordEncoder encoder, JwtService jwt) {
        this.users = users;
        this.roles = roles;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @Transactional
    public AuthResponse register(RegisterRequest req) {
        String email = req.email().trim().toLowerCase(Locale.ROOT);
        if (users.existsByEmailIgnoreCase(email)) {
            throw ApiException.conflict("An account with this email already exists");
        }
        UserEntity user = new UserEntity();
        user.setEmail(email);
        user.setPasswordHash(encoder.encode(req.password()));
        user.setFirstName(req.firstName().trim());
        user.setLastName(req.lastName().trim());
        user.setPhone(blankToNull(req.phone()));
        // public registration always creates a CUSTOMER; staff accounts are created by seeding/admins
        user.setRole(roles.findByName("CUSTOMER").orElseThrow(() -> new IllegalStateException("CUSTOMER role missing")));
        return tokens(users.save(user));
    }

    @Transactional(readOnly = true)
    public AuthResponse login(LoginRequest req) {
        UserEntity user = users.findByEmailIgnoreCase(req.email().trim())
                .orElseThrow(() -> new BadCredentialsException("bad credentials"));
        if (!user.isActive() || !encoder.matches(req.password(), user.getPasswordHash())) {
            throw new BadCredentialsException("bad credentials");
        }
        return tokens(user);
    }

    @Transactional(readOnly = true)
    public AuthResponse refresh(String refreshToken) {
        Claims claims = jwt.parse(refreshToken, "refresh");
        if (claims == null) {
            throw new ApiException(HttpStatus.UNAUTHORIZED, "Refresh token is invalid or expired");
        }
        UserEntity user = users.findById(jwt.extractUser(claims).id())
                .filter(UserEntity::isActive)
                .orElseThrow(() -> new ApiException(HttpStatus.UNAUTHORIZED, "Account is no longer available"));
        return tokens(user);
    }

    private AuthResponse tokens(UserEntity user) {
        return new AuthResponse(jwt.createAccessToken(user), jwt.createRefreshToken(user), "Bearer",
                jwt.accessTtlSeconds(), UserResponse.of(user));
    }

    static String blankToNull(String s) {
        return s == null || s.isBlank() ? null : s.trim();
    }
}
