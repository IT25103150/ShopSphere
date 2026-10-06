package com.shopsphere.order;

import jakarta.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "Orders")
@Getter
@Setter
public class OrderEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true, length = 30)
    private String orderNumber;

    @Column(nullable = false)
    private Long userId;

    /** Items subtotal before any discount. */
    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal discountApplied = BigDecimal.ZERO;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal finalAmount;

    private Long promotionId;

    @Column(length = 20)
    private String couponCode;

    @Column(nullable = false, length = 30)
    private String status = OrderStatus.PENDING.name();

    @Column(nullable = false, length = 150)
    private String email;
    @Column(nullable = false, length = 60)
    private String firstName;
    @Column(nullable = false, length = 60)
    private String lastName;
    @Column(nullable = false, length = 200)
    private String address;
    @Column(length = 100)
    private String apartment;
    @Column(nullable = false, length = 80)
    private String city;
    @Column(nullable = false, length = 20)
    private String postalCode;
    @Column(nullable = false, length = 60)
    private String country;
    @Column(nullable = false, length = 20)
    private String phone;
    @Column(length = 20)
    private String secondaryPhone;

    @Column(nullable = false)
    private LocalDateTime createdDate = LocalDateTime.now();

    @Column(nullable = false)
    private LocalDateTime updatedDate = LocalDateTime.now();

    @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true)
    @JoinColumn(name = "order_id", nullable = false)
    private List<OrderItemEntity> items = new ArrayList<>();

    public OrderStatus statusEnum() {
        return OrderStatus.valueOf(status);
    }

    public String customerName() {
        return firstName + " " + lastName;
    }
}
