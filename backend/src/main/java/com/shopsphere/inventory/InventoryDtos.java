package com.shopsphere.inventory;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;
import java.time.LocalDateTime;

public final class InventoryDtos {
    private InventoryDtos() {
    }

    public record InventoryResponse(Long id, Long productId, String productName, String sku, int quantity,
                                    int reorderLevel, boolean isLowStock, LocalDateTime lastUpdated) {
    }

    /** Sets stock to an exact value (stock-take / correction). */
    public record AdjustStockRequest(
            @NotNull(message = "New quantity is required") @Min(value = 0, message = "Quantity cannot be negative")
            @Max(value = 1_000_000, message = "Quantity is too large") Integer newQuantity,
            @NotBlank(message = "A reason is required") @Size(max = 150, message = "Reason must be at most 150 characters") String reason,
            @Min(value = 0, message = "Reorder level cannot be negative") Integer reorderLevel) {
    }

    /** Adds received stock (restock). */
    public record StockMovementRequest(
            @NotNull(message = "Quantity is required") @Min(value = 1, message = "Quantity must be at least 1")
            @Max(value = 1_000_000, message = "Quantity is too large") Integer quantity,
            @NotBlank(message = "A reason is required") @Size(max = 150, message = "Reason must be at most 150 characters") String reason) {
    }

    public record StockMovementResponse(Long id, Long productId, String productName, String movementType,
                                        int quantity, int quantityAfter, String reason, String createdBy,
                                        LocalDateTime createdDate) {
    }
}
