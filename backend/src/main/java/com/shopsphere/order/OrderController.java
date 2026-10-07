package com.shopsphere.order;

import com.shopsphere.auth.AuthUser;
import com.shopsphere.common.PageResponse;
import com.shopsphere.order.OrderDtos.*;
import jakarta.validation.Valid;
import java.time.LocalDate;
import java.util.List;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * Orders are created only by POST /api/checkout (payment, stock and coupon must succeed together),
 * so there is deliberately no raw "create order" endpoint here.
 */
@RestController
@RequestMapping("/api")
public class OrderController {
    private final OrderService orders;
    private final ShipmentService shipments;
    private final DeliveryService deliveries;

    public OrderController(OrderService orders, ShipmentService shipments, DeliveryService deliveries) {
        this.orders = orders;
        this.shipments = shipments;
        this.deliveries = deliveries;
    }

    @GetMapping("/orders")
    public PageResponse<OrderResponse> myOrders(@AuthenticationPrincipal AuthUser caller,
                                                @RequestParam(defaultValue = "0") int page,
                                                @RequestParam(defaultValue = "10") int size) {
        return orders.getOrdersByUser(caller.id(), Math.max(page, 0), Math.max(size, 1));
    }

    @GetMapping("/orders/manage")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF','WAREHOUSE')")
    public PageResponse<OrderResponse> manage(@RequestParam(required = false) String status,
                                              @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
                                              @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
                                              @RequestParam(required = false) String q,
                                              @RequestParam(defaultValue = "0") int page,
                                              @RequestParam(defaultValue = "15") int size) {
        return orders.getOrderHistory(status, from, to, q, Math.max(page, 0), Math.max(size, 1));
    }

    @GetMapping("/orders/{id}")
    public OrderDetailResponse get(@PathVariable Long id, @AuthenticationPrincipal AuthUser caller) {
        return orders.getOrderById(id, caller);
    }

    @PutMapping("/orders/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF','WAREHOUSE')")
    public OrderDetailResponse updateStatus(@PathVariable Long id, @Valid @RequestBody UpdateOrderStatusRequest req,
                                            @AuthenticationPrincipal AuthUser caller) {
        return orders.updateOrderStatus(id, req.newStatus(), caller);
    }

    @DeleteMapping("/orders/{id}")
    public OrderDetailResponse cancel(@PathVariable Long id, @AuthenticationPrincipal AuthUser caller) {
        return orders.cancelOrder(id, caller);
    }

    @GetMapping("/orders/{id}/shipment")
    public ShipmentResponse shipment(@PathVariable Long id, @AuthenticationPrincipal AuthUser caller) {
        return orders.getShipmentInfo(id, caller);
    }

    @GetMapping("/shipments")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public PageResponse<ShipmentResponse> shipments(@RequestParam(required = false) String status,
                                                    @RequestParam(defaultValue = "0") int page,
                                                    @RequestParam(defaultValue = "15") int size) {
        return shipments.listShipments(status, Math.max(page, 0), Math.max(size, 1));
    }

    @PutMapping("/shipments/{id}")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF','DELIVERY')")
    public ShipmentResponse updateShipment(@PathVariable Long id, @Valid @RequestBody UpdateStatusRequest req,
                                           @AuthenticationPrincipal AuthUser caller) {
        return shipments.updateShipmentStatus(id, req.status(), caller);
    }

    @PostMapping("/deliveries/assign")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF')")
    public ShipmentResponse assign(@Valid @RequestBody AssignDeliveryRequest req) {
        return deliveries.assignDelivery(req.shipmentId(), req.staffId());
    }

    @GetMapping("/deliveries/mine")
    @PreAuthorize("hasRole('DELIVERY')")
    public List<ShipmentResponse> mine(@AuthenticationPrincipal AuthUser caller) {
        return deliveries.getDeliveryAssignments(caller.id());
    }

    @PutMapping("/deliveries/{assignmentId}/status")
    @PreAuthorize("hasAnyRole('ADMIN','STAFF','DELIVERY')")
    public ShipmentResponse updateDelivery(@PathVariable Long assignmentId, @Valid @RequestBody UpdateStatusRequest req,
                                           @AuthenticationPrincipal AuthUser caller) {
        return deliveries.updateDeliveryStatus(assignmentId, req.status(), caller);
    }
}
