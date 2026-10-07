package com.shopsphere.inventory;

import com.shopsphere.auth.AuthUser;
import com.shopsphere.common.PageResponse;
import com.shopsphere.inventory.InventoryDtos.*;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/** URL access (ADMIN, STAFF, WAREHOUSE) is enforced in SecurityConfig; changing stock is narrowed here. */
@RestController
@RequestMapping("/api/inventory")
public class InventoryController {
    private final InventoryService service;

    public InventoryController(InventoryService service) {
        this.service = service;
    }

    @GetMapping
    public PageResponse<InventoryResponse> list(@RequestParam(defaultValue = "") String search,
                                                @RequestParam(defaultValue = "false") boolean lowStockOnly,
                                                @RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "20") int size) {
        return service.getAllInventory(search, lowStockOnly, Math.max(page, 0), Math.max(size, 1));
    }

    @GetMapping("/low-stock")
    public List<InventoryResponse> lowStock() {
        return service.getLowStockProducts();
    }

    @GetMapping("/{productId}")
    public InventoryResponse get(@PathVariable Long productId) {
        return service.getInventory(productId);
    }

    @PutMapping("/{productId}")
    @PreAuthorize("hasAnyRole('ADMIN','WAREHOUSE')")
    public InventoryResponse adjust(@PathVariable Long productId, @Valid @RequestBody AdjustStockRequest req,
                                    @AuthenticationPrincipal AuthUser caller) {
        return service.adjustStock(productId, req, caller.id());
    }

    @PostMapping("/{productId}/restock")
    @PreAuthorize("hasAnyRole('ADMIN','WAREHOUSE')")
    public InventoryResponse restock(@PathVariable Long productId, @Valid @RequestBody StockMovementRequest req,
                                     @AuthenticationPrincipal AuthUser caller) {
        return service.restock(productId, req, caller.id());
    }

    @GetMapping("/{productId}/movements")
    public PageResponse<StockMovementResponse> movements(@PathVariable Long productId,
                                                         @RequestParam(defaultValue = "0") int page,
                                                         @RequestParam(defaultValue = "20") int size) {
        return service.getStockMovementHistory(productId, Math.max(page, 0), Math.max(size, 1));
    }
}
