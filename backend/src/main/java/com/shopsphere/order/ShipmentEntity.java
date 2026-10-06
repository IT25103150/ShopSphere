package com.shopsphere.order;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "Shipments")
@Getter
@Setter
public class ShipmentEntity {
    public static final String PREPARING = "PREPARING";
    public static final String DISPATCHED = "DISPATCHED";
    public static final String OUT_FOR_DELIVERY = "OUT_FOR_DELIVERY";
    public static final String DELIVERED = "DELIVERED";
    public static final String CANCELLED = "CANCELLED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private Long orderId;

    @Column(nullable = false, unique = true, length = 40)
    private String trackingNumber;

    @Column(nullable = false, length = 30)
    private String status = PREPARING;

    private LocalDate estimatedDelivery;

    @Column(nullable = false)
    private LocalDateTime createdDate = LocalDateTime.now();
}
