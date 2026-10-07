package com.shopsphere.inventory;

import com.shopsphere.auth.UserEntity;
import com.shopsphere.auth.UserRepository;
import com.shopsphere.common.ApiException;
import com.shopsphere.common.InsufficientStockException;
import com.shopsphere.common.PageResponse;
import com.shopsphere.common.ProductNotFoundException;
import com.shopsphere.inventory.InventoryDtos.*;
import com.shopsphere.product.ProductEntity;
import com.shopsphere.product.ProductRepository;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** FR-04: stock levels and the immutable stock-movement log. */
@Service
public class InventoryService {
    private final InventoryRepository inventory;
    private final StockMovementRepository movements;
    private final ProductRepository products;
    private final UserRepository users;

    public InventoryService(InventoryRepository inventory, StockMovementRepository movements,
                            ProductRepository products, UserRepository users) {
        this.inventory = inventory;
        this.movements = movements;
        this.products = products;
        this.users = users;
    }

    @Transactional(readOnly = true)
    public InventoryResponse getInventory(Long productId) {
        ProductEntity p = products.findById(productId).orElseThrow(() -> new ProductNotFoundException(productId));
        return toResponse(findInventory(productId), p);
    }

    @Transactional(readOnly = true)
    public PageResponse<InventoryResponse> getAllInventory(String search, boolean lowOnly, int page, int size) {
        var result = inventory.search(search == null ? "" : search.trim(), lowOnly,
                PageRequest.of(page, Math.min(size, 100), Sort.by("productId")));
        Map<Long, ProductEntity> byId = productsById(result.getContent().stream().map(InventoryEntity::getProductId).toList());
        return PageResponse.of(result, i -> toResponse(i, byId.get(i.getProductId())));
    }

    @Transactional(readOnly = true)
    public boolean checkAvailability(Long productId, int quantity) {
        return inventory.quantityOf(productId).map(q -> q >= quantity).orElse(false);
    }

    @Transactional(readOnly = true)
    public int availableStock(Long productId) {
        return inventory.quantityOf(productId).orElse(0);
    }

    /** Removes stock and logs the movement. Fails (409) instead of ever going negative. */
    @Transactional
    public void decreaseStock(Long productId, int quantity, String reason, Long userId) {
        if (quantity <= 0) {
            throw ApiException.badRequest("Quantity must be positive");
        }
        int updated = inventory.decrease(productId, quantity, LocalDateTime.now());
        if (updated == 0) {
            ProductEntity p = products.findById(productId).orElseThrow(() -> new ProductNotFoundException(productId));
            throw new InsufficientStockException(p.getName(), availableStock(productId));
        }
        log(productId, StockMovementEntity.OUT, -quantity, reason, userId);
    }

    @Transactional
    public void increaseStock(Long productId, int quantity, String reason, Long userId) {
        if (quantity <= 0) {
            throw ApiException.badRequest("Quantity must be positive");
        }
        inventory.quantityOf(productId).orElseThrow(() -> ApiException.notFound("No inventory record for product " + productId));
        inventory.increase(productId, quantity, LocalDateTime.now());
        log(productId, StockMovementEntity.IN, quantity, reason, userId);
    }

    /** Sets stock to an exact number (stock-take). Logged as an ADJUSTMENT with the signed difference. */
    @Transactional
    public InventoryResponse adjustStock(Long productId, AdjustStockRequest req, Long userId) {
        ProductEntity p = products.findById(productId).orElseThrow(() -> new ProductNotFoundException(productId));
        InventoryEntity inv = findInventory(productId);
        int delta = req.newQuantity() - inv.getQuantity();
        if (req.reorderLevel() != null) {
            inv.setReorderLevel(req.reorderLevel());
        }
        inv.setQuantity(req.newQuantity());
        inv.setLastUpdated(LocalDateTime.now());
        inventory.saveAndFlush(inv);
        if (delta != 0) {
            log(productId, StockMovementEntity.ADJUSTMENT, delta, req.reason().trim(), userId);
        }
        return toResponse(inv, p);
    }

    @Transactional
    public InventoryResponse restock(Long productId, StockMovementRequest req, Long userId) {
        ProductEntity p = products.findById(productId).orElseThrow(() -> new ProductNotFoundException(productId));
        increaseStock(productId, req.quantity(), req.reason().trim(), userId);
        return toResponse(findInventory(productId), p);
    }

    @Transactional(readOnly = true)
    public List<InventoryResponse> getLowStockProducts() {
        List<InventoryEntity> low = inventory.findLowStockProducts();
        Map<Long, ProductEntity> byId = productsById(low.stream().map(InventoryEntity::getProductId).toList());
        return low.stream().filter(i -> byId.containsKey(i.getProductId()))
                .map(i -> toResponse(i, byId.get(i.getProductId()))).toList();
    }

    @Transactional(readOnly = true)
    public PageResponse<StockMovementResponse> getStockMovementHistory(Long productId, int page, int size) {
        ProductEntity p = products.findById(productId).orElseThrow(() -> new ProductNotFoundException(productId));
        var result = movements.findByProductIdOrderByCreatedDateDescIdDesc(productId, PageRequest.of(page, Math.min(size, 100)));
        Set<Long> userIds = result.getContent().stream().map(StockMovementEntity::getCreatedBy)
                .filter(java.util.Objects::nonNull).collect(Collectors.toSet());
        Map<Long, String> names = new HashMap<>();
        users.findAllById(userIds).forEach(u -> names.put(u.getId(), u.getFullName()));
        return PageResponse.of(result, m -> new StockMovementResponse(m.getId(), m.getProductId(), p.getName(),
                m.getMovementType(), m.getQuantity(), m.getQuantityAfter(), m.getReason(),
                m.getCreatedBy() == null ? "System" : names.getOrDefault(m.getCreatedBy(), "User " + m.getCreatedBy()),
                m.getCreatedDate()));
    }

    /** Called when a product is created: makes its stock row and records the opening balance. */
    @Transactional
    public void initializeStock(Long productId, int quantity, Integer reorderLevel, Long userId) {
        InventoryEntity inv = new InventoryEntity();
        inv.setProductId(productId);
        inv.setQuantity(quantity);
        if (reorderLevel != null) {
            inv.setReorderLevel(reorderLevel);
        }
        inventory.save(inv);
        if (quantity > 0) {
            log(productId, StockMovementEntity.IN, quantity, "INITIAL_STOCK", userId);
        }
    }

    private void log(Long productId, String type, int signedQty, String reason, Long userId) {
        int after = inventory.quantityOf(productId).orElse(0);
        StockMovementEntity m = new StockMovementEntity();
        m.setProductId(productId);
        m.setMovementType(type);
        m.setQuantity(signedQty);
        m.setQuantityAfter(after);
        m.setReason(reason.length() > 200 ? reason.substring(0, 200) : reason);
        m.setCreatedBy(userId);
        movements.save(m);
    }

    private InventoryEntity findInventory(Long productId) {
        return inventory.findByProductId(productId)
                .orElseThrow(() -> ApiException.notFound("No inventory record for product " + productId));
    }

    private Map<Long, ProductEntity> productsById(List<Long> ids) {
        return products.findAllById(ids).stream().collect(Collectors.toMap(ProductEntity::getId, p -> p));
    }

    private InventoryResponse toResponse(InventoryEntity i, ProductEntity p) {
        return new InventoryResponse(i.getId(), i.getProductId(), p.getName(), p.getSku(), i.getQuantity(),
                i.getReorderLevel(), i.isLowStock(), i.getLastUpdated());
    }
}
