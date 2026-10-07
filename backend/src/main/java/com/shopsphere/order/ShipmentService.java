package com.shopsphere.order;

import com.shopsphere.auth.AuthUser;
import com.shopsphere.auth.UserEntity;
import com.shopsphere.auth.UserRepository;
import com.shopsphere.common.ApiException;
import com.shopsphere.common.PageResponse;
import com.shopsphere.order.OrderDtos.*;
import java.time.LocalDate;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.context.annotation.Lazy;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class ShipmentService {
    private static final Set<String> SETTABLE = Set.of("DISPATCHED", "OUT_FOR_DELIVERY", "DELIVERED");

    private final ShipmentRepository shipments;
    private final DeliveryAssignmentRepository assignments;
    private final OrderRepository orders;
    private final UserRepository users;
    private final OrderService orderService;

    public ShipmentService(ShipmentRepository shipments, DeliveryAssignmentRepository assignments, OrderRepository orders,
                           UserRepository users, @Lazy OrderService orderService) {
        this.shipments = shipments;
        this.assignments = assignments;
        this.orders = orders;
        this.users = users;
        this.orderService = orderService;
    }

    /** Created automatically when an order is confirmed. */
    @Transactional
    public ShipmentEntity createShipment(OrderEntity order) {
        return shipments.findByOrderId(order.getId()).orElseGet(() -> {
            ShipmentEntity s = new ShipmentEntity();
            s.setOrderId(order.getId());
            s.setTrackingNumber("TRK" + String.format("%06d", order.getId()) + "LK");
            s.setEstimatedDelivery(LocalDate.now().plusDays(5));
            return shipments.save(s);
        });
    }

    @Transactional(readOnly = true)
    public PageResponse<ShipmentResponse> listShipments(String status, int page, int size) {
        Specification<ShipmentEntity> spec = (r, q, cb) -> cb.conjunction();
        if (status != null && !status.isBlank()) {
            spec = spec.and((r, q, cb) -> cb.equal(r.get("status"), status.toUpperCase()));
        }
        var result = shipments.findAll(spec, PageRequest.of(page, Math.min(size, 100), Sort.by("id").descending()));
        Map<Long, ShipmentResponse> mapped = toResponses(result.getContent()).stream().collect(Collectors.toMap(ShipmentResponse::id, r -> r));
        return PageResponse.of(result, s -> mapped.get(s.getId()));
    }

    /** Moves the shipment (and therefore the order) forward: DISPATCHED -> OUT_FOR_DELIVERY -> DELIVERED. */
    @Transactional
    public ShipmentResponse updateShipmentStatus(Long shipmentId, String status, AuthUser caller) {
        String target = status.trim().toUpperCase();
        if (!SETTABLE.contains(target)) {
            throw ApiException.badRequest("Shipment status must be one of " + SETTABLE);
        }
        ShipmentEntity s = shipments.findById(shipmentId).orElseThrow(() -> ApiException.notFound("Shipment not found"));
        if ("DELIVERY".equals(caller.role())) {
            boolean mine = assignments.findFirstByShipmentIdOrderByIdDesc(shipmentId).map(a -> a.getStaffId().equals(caller.id())).orElse(false);
            if (!mine) {
                throw ApiException.forbidden("This shipment is not assigned to you");
            }
        } else if (!caller.isAdminOrStaff()) {
            throw ApiException.forbidden("Your role cannot update shipments");
        }
        orderService.transition(orderService.find(s.getOrderId()), OrderStatus.valueOf(target));
        return toResponses(List.of(s)).get(0);
    }

    @Transactional(readOnly = true)
    public List<ShipmentResponse> toResponses(List<ShipmentEntity> list) {
        if (list.isEmpty()) {
            return List.of();
        }
        Map<Long, OrderEntity> orderById = orders.findAllById(list.stream().map(ShipmentEntity::getOrderId).toList())
                .stream().collect(Collectors.toMap(OrderEntity::getId, o -> o));
        Map<Long, DeliveryAssignmentEntity> assignmentByShipment = new HashMap<>();
        assignments.findByShipmentIdIn(list.stream().map(ShipmentEntity::getId).toList())
                .forEach(a -> assignmentByShipment.merge(a.getShipmentId(), a, (x, y) -> x.getId() > y.getId() ? x : y));
        Map<Long, UserEntity> staff = users.findAllById(assignmentByShipment.values().stream().map(DeliveryAssignmentEntity::getStaffId).collect(Collectors.toSet()))
                .stream().collect(Collectors.toMap(UserEntity::getId, u -> u));
        return list.stream().map(s -> {
            OrderEntity o = orderById.get(s.getOrderId());
            DeliveryAssignmentEntity a = assignmentByShipment.get(s.getId());
            DeliveryInfo d = a == null ? null : new DeliveryInfo(a.getId(), s.getId(), a.getStaffId(),
                    staff.containsKey(a.getStaffId()) ? staff.get(a.getStaffId()).getFullName() : "Unknown",
                    staff.containsKey(a.getStaffId()) ? staff.get(a.getStaffId()).getPhone() : null, a.getStatus(), a.getAssignedDate());
            return new ShipmentResponse(s.getId(), s.getOrderId(), o.getOrderNumber(), o.getStatus(), s.getTrackingNumber(),
                    s.getStatus(), s.getEstimatedDelivery(), s.getCreatedDate(), o.customerName(), o.getPhone(),
                    o.getAddress() + (o.getApartment() == null ? "" : ", " + o.getApartment()), o.getCity(), d);
        }).toList();
    }
}
