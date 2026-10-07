package com.shopsphere.inventory;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "Inventory")
@Getter
@Setter
public class InventoryEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private Long productId;

    @Column(nullable = false)
    private int quantity;

    @Column(nullable = false)
    private int reorderLevel = 10;

    @Column(nullable = false)
    private LocalDateTime lastUpdated = LocalDateTime.now();

    public boolean isLowStock() {
        return quantity < reorderLevel;
    }
}
