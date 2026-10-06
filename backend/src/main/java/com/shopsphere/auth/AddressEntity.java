package com.shopsphere.auth;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "Addresses")
@Getter
@Setter
public class AddressEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long userId;

    @Column(nullable = false, length = 40)
    private String label;

    @Column(nullable = false, length = 200)
    private String address;

    @Column(length = 100)
    private String apartment;

    @Column(nullable = false, length = 80)
    private String city;

    @Column(nullable = false, length = 20)
    private String postalCode;

    @Column(nullable = false, length = 60)
    private String country = "Sri Lanka";

    @Column(length = 20)
    private String phone;

    @Column(name = "is_default", nullable = false)
    private boolean defaultAddress;
}
