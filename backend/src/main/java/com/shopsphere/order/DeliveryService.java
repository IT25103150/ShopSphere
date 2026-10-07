package com.shopsphere.order;

import com.shopsphere.auth.AuthUser;
import com.shopsphere.auth.UserEntity;
import com.shopsphere.auth.UserRepository;
import com.shopsphere.common.ApiException;
import com.shopsphere.order.OrderDtos.ShipmentResponse;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class DeliveryService {
    private final ShipmentRepository shipments;
    private final DeliveryAssignmentRepository assignments;
    private final UserRepository users;
    private final OrderService orderService;
    private final ShipmentService shipmentService;

    public DeliveryService(ShipmentRepository shipments, DeliveryAssignmentRepository assignments, UserRepository users,
                           OrderService orderService, ShipmentService shipmentService) {
        this.shipments = shipments;
        this.assignments = assignments;
        this.users = users;
        this.orderService = orderService;
        this.shipmentService = shipmentService;
    }

    /** Assigns (or re-assigns) a delivery person to a shipment. */
    @Transactional
    public ShipmentResponse assignDelivery(Long shipmentId, Long staffId) {
        ShipmentEntity s = shipments.findById(shipmentId).orElseThrow(() -> ApiException.notFound("Shipment not found"));
        if (ShipmentEntity.DELIVERED.equals(s.getStatus()) || ShipmentEntity.CANCELLED.equals(s.getStatus())) {
            throw ApiException.conflict("A " + s.getStatus().toLowerCase() + " shipment cannot be assigned");
        }
        UserEntity staff = users.findById(staffId).filter(u -> u.isActive() && "DELIVERY".equals(u.getRole().getName()))
                .orElseThrow(() -> ApiException.badRequest("Selected user is not an active delivery staff member"));
        DeliveryAssignmentEntity a = assignments.findFirstByShipmentIdOrderByIdDesc(shipmentId).orElseGet(DeliveryAssignmentEntity::new);
        a.setShipmentId(shipmentId);
        a.setStaffId(staff.getId());
        a.setAssignedDate(LocalDateTime.now());
        a.setStatus(ShipmentEntity.OUT_FOR_DELIVERY.equals(s.getStatus()) ? DeliveryAssignmentEntity.IN_PROGRESS : DeliveryAssignmentEntity.ASSIGNED);
        assignments.save(a);
        return shipmentService.toResponses(List.of(s)).get(0);
    }

    /** Delivery staff (or admin/staff) report progress: IN_PROGRESS, COMPLETED or FAILED. */
    @Transactional
    public ShipmentResponse updateDeliveryStatus(Long assignmentId, String status, AuthUser caller) {
        String target = status.trim().toUpperCase();
        if (!Set.of("IN_PROGRESS", "COMPLETED", "FAILED").contains(target)) {
            throw ApiException.badRequest("Status must be IN_PROGRESS, COMPLETED or FAILED");
        }
        DeliveryAssignmentEntity a = assignments.findById(assignmentId).orElseThrow(() -> ApiException.notFound("Assignment not found"));
        if (!caller.isAdminOrStaff() && !a.getStaffId().equals(caller.id())) {
            throw ApiException.forbidden("This delivery is not assigned to you");
        }
        ShipmentEntity s = shipments.findById(a.getShipmentId()).orElseThrow();
        OrderEntity order = orderService.find(s.getOrderId());
        OrderStatus current = order.statusEnum();
        switch (target) {
            case "IN_PROGRESS" -> {
                if (current == OrderStatus.DISPATCHED) {
                    orderService.transition(order, OrderStatus.OUT_FOR_DELIVERY);
                } else if (current != OrderStatus.OUT_FOR_DELIVERY) {
                    throw ApiException.conflict("The parcel has not been dispatched yet");
                }
                a.setStatus(DeliveryAssignmentEntity.IN_PROGRESS);
            }
            case "COMPLETED" -> {
                if (current != OrderStatus.OUT_FOR_DELIVERY) {
                    throw ApiException.conflict("Start the delivery before marking it delivered");
                }
                orderService.transition(order, OrderStatus.DELIVERED);
                a.setStatus(DeliveryAssignmentEntity.COMPLETED);
            }
            default -> a.setStatus(DeliveryAssignmentEntity.FAILED);
        }
        return shipmentService.toResponses(List.of(s)).get(0);
    }

    @Transactional(readOnly = true)
    public List<ShipmentResponse> getDeliveryAssignments(Long staffId) {
        List<ShipmentEntity> list = assignments.findByStaffIdOrderByAssignedDateDesc(staffId).stream()
                .map(a -> shipments.findById(a.getShipmentId()).orElse(null)).filter(java.util.Objects::nonNull).toList();
        return shipmentService.toResponses(list);
    }
}
