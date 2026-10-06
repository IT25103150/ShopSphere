package com.shopsphere.auth;

/** The authenticated caller, extracted from the JWT and available via @AuthenticationPrincipal. */
public record AuthUser(Long id, String email, String role) {

    public boolean isAdminOrStaff() {
        return "ADMIN".equals(role) || "STAFF".equals(role);
    }
}
