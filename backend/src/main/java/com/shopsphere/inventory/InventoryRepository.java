package com.shopsphere.inventory;

import java.time.LocalDateTime;
import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface InventoryRepository extends JpaRepository<InventoryEntity, Long> {
    Optional<InventoryEntity> findByProductId(Long productId);

    /** Scalar read that always hits the database (never a stale cached entity). */
    @Query("select i.quantity from InventoryEntity i where i.productId = :productId")
    Optional<Integer> quantityOf(@Param("productId") Long productId);

    List<InventoryEntity> findByProductIdIn(Collection<Long> productIds);

    /** Products whose stock has dropped below their reorder level (lowest stock first). */
    @Query("select i from InventoryEntity i where i.quantity < i.reorderLevel order by i.quantity asc")
    List<InventoryEntity> findLowStockProducts();

    /**
     * Atomic, race-free decrement: the WHERE clause guarantees stock never goes negative even when two
     * customers check out at the same moment. Returns 0 if there was not enough stock.
     */
    @Modifying(flushAutomatically = true)
    @Query("update InventoryEntity i set i.quantity = i.quantity - :qty, i.lastUpdated = :now "
            + "where i.productId = :productId and i.quantity >= :qty")
    int decrease(@Param("productId") Long productId, @Param("qty") int qty, @Param("now") LocalDateTime now);

    @Modifying(flushAutomatically = true)
    @Query("update InventoryEntity i set i.quantity = i.quantity + :qty, i.lastUpdated = :now where i.productId = :productId")
    int increase(@Param("productId") Long productId, @Param("qty") int qty, @Param("now") LocalDateTime now);

    /** Admin listing joined with product info; the search matches product name or SKU. */
    @Query(value = "select i from InventoryEntity i, com.shopsphere.product.ProductEntity p "
            + "where p.id = i.productId and p.deleted = false "
            + "and (:lowOnly = false or i.quantity < i.reorderLevel) "
            + "and (:search = '' or lower(p.name) like lower(concat('%', :search, '%')) or lower(p.sku) like lower(concat('%', :search, '%')))",
            countQuery = "select count(i) from InventoryEntity i, com.shopsphere.product.ProductEntity p "
                    + "where p.id = i.productId and p.deleted = false "
                    + "and (:lowOnly = false or i.quantity < i.reorderLevel) "
                    + "and (:search = '' or lower(p.name) like lower(concat('%', :search, '%')) or lower(p.sku) like lower(concat('%', :search, '%')))")
    Page<InventoryEntity> search(@Param("search") String search, @Param("lowOnly") boolean lowOnly, Pageable pageable);
}
