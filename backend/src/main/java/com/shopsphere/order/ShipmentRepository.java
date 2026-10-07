package com.shopsphere.order;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;

public interface ShipmentRepository extends JpaRepository<ShipmentEntity, Long>, JpaSpecificationExecutor<ShipmentEntity> {
    Optional<ShipmentEntity> findByOrderId(Long orderId);

    List<ShipmentEntity> findByOrderIdIn(Collection<Long> orderIds);
}
