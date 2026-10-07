package com.shopsphere.inventory;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

public interface StockMovementRepository extends JpaRepository<StockMovementEntity, Long> {
    Page<StockMovementEntity> findByProductIdOrderByCreatedDateDescIdDesc(Long productId, Pageable pageable);
}
