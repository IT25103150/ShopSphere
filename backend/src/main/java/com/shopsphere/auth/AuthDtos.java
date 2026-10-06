package com.shopsphere.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;

/** Request/response records for authentication and the user profile. */
public final class AuthDtos {
    private AuthDtos() {
    }

    public static final String PHONE_REGEX = "^\\+?[0-9]{10,15}$";
    public static final String PASSWORD_REGEX = "^(?=.*[A-Za-z])(?=.*\\d).{8,72}$";
    public static final String PASSWORD_MESSAGE = "Password must be 8-72 characters and contain a letter and a number";

    public record RegisterRequest(
            @NotBlank(message = "Email is required") @Email(message = "Enter a valid email address") @Size(max = 150) String email,
            @NotBlank(message = "Password is required") @Pattern(regexp = PASSWORD_REGEX, message = PASSWORD_MESSAGE) String password,
            @NotBlank(message = "First name is required") @Size(max = 60) String firstName,
            @NotBlank(message = "Last name is required") @Size(max = 60) String lastName,
            @Pattern(regexp = "^$|" + PHONE_REGEX, message = "Phone must be 10-15 digits") String phone) {
    }

    public record LoginRequest(
            @NotBlank(message = "Email is required") @Email(message = "Enter a valid email address") String email,
            @NotBlank(message = "Password is required") String password) {
    }

    public record RefreshRequest(@NotBlank(message = "Refresh token is required") String refreshToken) {
    }

    public record UserResponse(Long id, String email, String firstName, String lastName, String phone, String role) {
        public static UserResponse of(UserEntity u) {
            return new UserResponse(u.getId(), u.getEmail(), u.getFirstName(), u.getLastName(), u.getPhone(),
                    u.getRole().getName());
        }
    }

    public record AuthResponse(String accessToken, String refreshToken, String tokenType, long expiresInSeconds,
                               UserResponse user) {
    }

    public record UpdateProfileRequest(
            @NotBlank(message = "First name is required") @Size(max = 60) String firstName,
            @NotBlank(message = "Last name is required") @Size(max = 60) String lastName,
            @Pattern(regexp = "^$|" + PHONE_REGEX, message = "Phone must be 10-15 digits") String phone) {
    }

    public record ChangePasswordRequest(
            @NotBlank(message = "Current password is required") String currentPassword,
            @NotBlank(message = "New password is required") @Pattern(regexp = PASSWORD_REGEX, message = PASSWORD_MESSAGE) String newPassword) {
    }

    public record AddressRequest(
            @NotBlank(message = "Label is required") @Size(max = 40) String label,
            @NotBlank(message = "Address is required") @Size(max = 200) String address,
            @Size(max = 100) String apartment,
            @NotBlank(message = "City is required") @Size(max = 80) String city,
            @NotBlank(message = "Postal code is required") @Size(max = 20) String postalCode,
            @NotBlank(message = "Country is required") @Size(max = 60) String country,
            @Pattern(regexp = "^$|" + PHONE_REGEX, message = "Phone must be 10-15 digits") String phone,
            boolean defaultAddress) {
    }

    public record AddressResponse(Long id, String label, String address, String apartment, String city,
                                  String postalCode, String country, String phone, boolean defaultAddress) {
        public static AddressResponse of(AddressEntity a) {
            return new AddressResponse(a.getId(), a.getLabel(), a.getAddress(), a.getApartment(), a.getCity(),
                    a.getPostalCode(), a.getCountry(), a.getPhone(), a.isDefaultAddress());
        }
    }
}
