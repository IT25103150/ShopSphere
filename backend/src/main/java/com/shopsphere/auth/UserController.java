package com.shopsphere.auth;

import com.shopsphere.auth.AuthDtos.*;
import com.shopsphere.common.ApiException;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.bind.annotation.*;

/** Profile, password and saved-address endpoints for the logged-in user, plus a staff lookup by role. */
@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserRepository users;
    private final AddressRepository addresses;
    private final PasswordEncoder encoder;

    public UserController(UserRepository users, AddressRepository addresses, PasswordEncoder encoder) {
        this.users = users;
        this.addresses = addresses;
        this.encoder = encoder;
    }

    @GetMapping("/me")
    @Transactional(readOnly = true)
    public UserResponse me(@AuthenticationPrincipal AuthUser caller) {
        return UserResponse.of(load(caller));
    }

    @PutMapping("/me")
    @Transactional
    public UserResponse updateProfile(@AuthenticationPrincipal AuthUser caller, @Valid @RequestBody UpdateProfileRequest req) {
        UserEntity u = load(caller);
        u.setFirstName(req.firstName().trim());
        u.setLastName(req.lastName().trim());
        u.setPhone(AuthService.blankToNull(req.phone()));
        return UserResponse.of(u);
    }

    @PutMapping("/me/password")
    @Transactional
    public ResponseEntity<Void> changePassword(@AuthenticationPrincipal AuthUser caller, @Valid @RequestBody ChangePasswordRequest req) {
        UserEntity u = load(caller);
        if (!encoder.matches(req.currentPassword(), u.getPasswordHash())) {
            throw ApiException.badRequest("Current password is incorrect");
        }
        u.setPasswordHash(encoder.encode(req.newPassword()));
        return ResponseEntity.noContent().build();
    }

    /** e.g. GET /api/users?role=DELIVERY - used by the delivery-assignment screen. */
    @GetMapping
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    @Transactional(readOnly = true)
    public List<UserResponse> byRole(@RequestParam(defaultValue = "DELIVERY") String role) {
        return users.findByRoleNameAndActiveTrueOrderByFirstName(role.toUpperCase()).stream().map(UserResponse::of).toList();
    }

    // ---------- addresses ----------
    @GetMapping("/me/addresses")
    public List<AddressResponse> listAddresses(@AuthenticationPrincipal AuthUser caller) {
        return addresses.findByUserIdOrderByDefaultAddressDescIdAsc(caller.id()).stream().map(AddressResponse::of).toList();
    }

    @PostMapping("/me/addresses")
    @Transactional
    public ResponseEntity<AddressResponse> addAddress(@AuthenticationPrincipal AuthUser caller, @Valid @RequestBody AddressRequest req) {
        AddressEntity a = new AddressEntity();
        a.setUserId(caller.id());
        apply(a, req);
        boolean first = addresses.findByUserIdOrderByDefaultAddressDescIdAsc(caller.id()).isEmpty();
        if (req.defaultAddress() || first) {
            clearDefault(caller.id());
            a.setDefaultAddress(true);
        }
        return ResponseEntity.status(HttpStatus.CREATED).body(AddressResponse.of(addresses.save(a)));
    }

    @PutMapping("/me/addresses/{id}")
    @Transactional
    public AddressResponse updateAddress(@AuthenticationPrincipal AuthUser caller, @PathVariable Long id,
                                         @Valid @RequestBody AddressRequest req) {
        AddressEntity a = ownAddress(caller, id);
        apply(a, req);
        if (req.defaultAddress()) {
            clearDefault(caller.id());
            a.setDefaultAddress(true);
        }
        return AddressResponse.of(a);
    }

    @PostMapping("/me/addresses/{id}/default")
    @Transactional
    public AddressResponse makeDefault(@AuthenticationPrincipal AuthUser caller, @PathVariable Long id) {
        AddressEntity a = ownAddress(caller, id);
        clearDefault(caller.id());
        a.setDefaultAddress(true);
        return AddressResponse.of(a);
    }

    @DeleteMapping("/me/addresses/{id}")
    @Transactional
    public ResponseEntity<Void> deleteAddress(@AuthenticationPrincipal AuthUser caller, @PathVariable Long id) {
        AddressEntity a = ownAddress(caller, id);
        boolean wasDefault = a.isDefaultAddress();
        addresses.delete(a);
        addresses.flush();
        if (wasDefault) {
            addresses.findByUserIdOrderByDefaultAddressDescIdAsc(caller.id()).stream().findFirst()
                    .ifPresent(next -> next.setDefaultAddress(true));
        }
        return ResponseEntity.noContent().build();
    }

    private UserEntity load(AuthUser caller) {
        return users.findById(caller.id()).orElseThrow(() -> ApiException.notFound("User not found"));
    }

    private AddressEntity ownAddress(AuthUser caller, Long id) {
        return addresses.findByIdAndUserId(id, caller.id()).orElseThrow(() -> ApiException.notFound("Address not found"));
    }

    private void clearDefault(Long userId) {
        addresses.findByUserIdOrderByDefaultAddressDescIdAsc(userId).forEach(x -> x.setDefaultAddress(false));
        addresses.flush();
    }

    private void apply(AddressEntity a, AddressRequest r) {
        a.setLabel(r.label().trim());
        a.setAddress(r.address().trim());
        a.setApartment(AuthService.blankToNull(r.apartment()));
        a.setCity(r.city().trim());
        a.setPostalCode(r.postalCode().trim());
        a.setCountry(r.country().trim());
        a.setPhone(AuthService.blankToNull(r.phone()));
    }
}
