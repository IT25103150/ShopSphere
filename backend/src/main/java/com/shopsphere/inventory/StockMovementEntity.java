package com.shopsphere.inventory;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "StockMovements")
@Getter
@Setter
public class StockMovementEntity {
    public static final String IN = "IN";
    public static final String OUT = "OUT";
    public static final String ADJUSTMENT = "ADJUSTMENT";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long productId;

    @Column(nullable = false, length = 20)
    private String movementType;

    /** Signed change: negative when stock leaves the warehouse. */
    @Column(nullable = false)
    private int quantity;

    @Column(nullable = false)
    private int quantityAfter;

    @Column(nullable = false, length = 200)
    private String reason;

    private Long createdBy;

    @Column(nullable = false)
    private LocalDateTime createdDate = LocalDateTime.now();
}
