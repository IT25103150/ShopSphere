package com.shopsphere.order;

import java.util.Collection;
import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface DeliveryAssignmentRepository extends JpaRepository<DeliveryAssignmentEntity, Long> {
    Optional<DeliveryAssignmentEntity> findFirstByShipmentIdOrderByIdDesc(Long shipmentId);

    List<DeliveryAssignmentEntity> findByShipmentIdIn(Collection<Long> shipmentIds);

    List<DeliveryAssignmentEntity> findByStaffIdOrderByAssignedDateDesc(Long staffId);
}
