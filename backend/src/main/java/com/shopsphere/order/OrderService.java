package com.shopsphere.order;

import com.shopsphere.auth.AuthUser;
import com.shopsphere.cart.PaymentRepository;
import com.shopsphere.common.ApiException;
import com.shopsphere.common.PageResponse;
import com.shopsphere.inventory.InventoryService;
import com.shopsphere.order.OrderDtos.*;
import com.shopsphere.product.ProductImageRepository;
import com.shopsphere.promotion.PromotionService;
import jakarta.persistence.criteria.Predicate;
import java.math.BigDecimal;
import java.security.SecureRandom;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** FR-03: orders and the order status state machine. */
@Service
public class OrderService {
    private static final SecureRandom RANDOM = new SecureRandom();

    private final OrderRepository orders;
    private final ShipmentRepository shipments;
    private final DeliveryAssignmentRepository assignments;
    private final PaymentRepository payments;
    private final ProductImageRepository images;
    private final InventoryService inventory;
    private final PromotionService promotions;
    private final ShipmentService shipmentService;

    public OrderService(OrderRepository orders, ShipmentRepository shipments, DeliveryAssignmentRepository assignments,
                        PaymentRepository payments, ProductImageRepository images, InventoryService inventory,
                        PromotionService promotions, ShipmentService shipmentService) {
        this.orders = orders;
        this.shipments = shipments;
        this.assignments = assignments;
        this.payments = payments;
        this.images = images;
        this.inventory = inventory;
        this.promotions = promotions;
        this.shipmentService = shipmentService;
    }

    /** One purchased line, priced by the server. */
    public record OrderLine(Long productId, String name, BigDecimal unitPrice, int quantity) {
    }

    // ------------------------------------------------------------------ create (called by checkout)
    @Transactional
    public OrderEntity createOrder(Long userId, ShippingAddress ship, List<OrderLine> lines, BigDecimal subtotal,
                                   BigDecimal discount, BigDecimal finalAmount, Long promotionId, String couponCode) {
        OrderEntity o = new OrderEntity();
        o.setOrderNumber(newOrderNumber());
        o.setUserId(userId);
        o.setTotalAmount(subtotal);
        o.setDiscountApplied(discount);
        o.setFinalAmount(finalAmount);
        o.setPromotionId(promotionId);
        o.setCouponCode(couponCode);
        o.setStatus(OrderStatus.CONFIRMED.name()); // payment already succeeded
        o.setEmail(ship.email());
        o.setFirstName(ship.firstName());
        o.setLastName(ship.lastName());
        o.setAddress(ship.address());
        o.setApartment(ship.apartment());
        o.setCity(ship.city());
        o.setPostalCode(ship.postalCode());
        o.setCountry(ship.country());
        o.setPhone(ship.phone());
        o.setSecondaryPhone(ship.secondaryPhone());
        for (OrderLine l : lines) {
            OrderItemEntity item = new OrderItemEntity();
            item.setProductId(l.productId());
            item.setProductName(l.name());
            item.setQuantity(l.quantity());
            item.setPriceAtOrder(l.unitPrice());
            o.getItems().add(item);
        }
        orders.saveAndFlush(o);
        shipmentService.createShipment(o);
        return o;
    }

    // ------------------------------------------------------------------ queries
    @Transactional(readOnly = true)
    public PageResponse<OrderResponse> getOrdersByUser(Long userId, int page, int size) {
        var result = orders.findByUserIdOrderByCreatedDateDesc(userId, PageRequest.of(page, Math.min(size, 50)));
        Map<Long, OrderResponse> mapped = toResponses(result.getContent()).stream().collect(Collectors.toMap(OrderResponse::id, r -> r));
        return PageResponse.of(result, o -> mapped.get(o.getId()));
    }

    /** Back-office listing with filters (status, date range, order number / customer search). */
    @Transactional(readOnly = true)
    public PageResponse<OrderResponse> getOrderHistory(String status, LocalDate from, LocalDate to, String q, int page, int size) {
        Specification<OrderEntity> spec = (root, query, cb) -> cb.conjunction();
        if (status != null && !status.isBlank()) {
            spec = spec.and((r, qy, cb) -> cb.equal(r.get("status"), status.toUpperCase()));
        }
        if (from != null) {
            spec = spec.and((r, qy, cb) -> cb.greaterThanOrEqualTo(r.get("createdDate"), from.atStartOfDay()));
        }
        if (to != null) {
            spec = spec.and((r, qy, cb) -> cb.lessThan(r.get("createdDate"), to.plusDays(1).atStartOfDay()));
        }
        if (q != null && !q.isBlank()) {
            String like = "%" + q.trim().toLowerCase() + "%";
            spec = spec.and((r, qy, cb) -> {
                Predicate[] ps = {cb.like(cb.lower(r.get("orderNumber")), like), cb.like(cb.lower(r.get("email")), like),
                        cb.like(cb.lower(r.get("firstName")), like), cb.like(cb.lower(r.get("lastName")), like)};
                return cb.or(ps);
            });
        }
        var result = orders.findAll(spec, PageRequest.of(page, Math.min(size, 100), Sort.by("createdDate").descending().and(Sort.by("id").descending())));
        Map<Long, OrderResponse> mapped = toResponses(result.getContent()).stream().collect(Collectors.toMap(OrderResponse::id, r -> r));
        return PageResponse.of(result, o -> mapped.get(o.getId()));
    }

    @Transactional(readOnly = true)
    public OrderDetailResponse getOrderById(Long orderId, AuthUser caller) {
        OrderEntity o = find(orderId);
        requireView(o, caller);
        return toDetail(o, caller);
    }

    @Transactional(readOnly = true)
    public ShipmentResponse getShipmentInfo(Long orderId, AuthUser caller) {
        OrderEntity o = find(orderId);
        requireView(o, caller);
        ShipmentEntity s = shipments.findByOrderId(orderId).orElseThrow(() -> ApiException.notFound("This order has no shipment yet"));
        return shipmentService.toResponses(List.of(s)).get(0);
    }

    // ------------------------------------------------------------------ commands
    @Transactional
    public OrderDetailResponse updateOrderStatus(Long orderId, String newStatus, AuthUser caller) {
        OrderStatus target;
        try {
            target = OrderStatus.valueOf(newStatus.trim().toUpperCase());
        } catch (IllegalArgumentException ex) {
            throw ApiException.badRequest("Unknown order status: " + newStatus);
        }
        boolean warehouse = "WAREHOUSE".equals(caller.role());
        if (!caller.isAdminOrStaff() && !(warehouse && (target == OrderStatus.PROCESSING || target == OrderStatus.READY_FOR_DISPATCH))) {
            throw ApiException.forbidden("Your role cannot set the order to " + target);
        }
        OrderEntity o = find(orderId);
        transition(o, target);
        return toDetail(o, caller);
    }

    @Transactional
    public OrderDetailResponse cancelOrder(Long orderId, AuthUser caller) {
        OrderEntity o = find(orderId);
        boolean owner = o.getUserId().equals(caller.id());
        OrderStatus current = o.statusEnum();
        if (caller.isAdminOrStaff()) {
            // may cancel anything not yet delivered
        } else if (owner) {
            if (!current.customerCanCancel()) {
                throw ApiException.conflict("This order can no longer be cancelled because it is " + current.name().replace('_', ' ').toLowerCase());
            }
        } else {
            throw ApiException.forbidden("You cannot cancel this order");
        }
        transition(o, OrderStatus.CANCELLED);
        return toDetail(o, caller);
    }

    /** The single place that changes an order's status and applies every side effect. */
    @Transactional
    public void transition(OrderEntity o, OrderStatus target) {
        OrderStatus current = o.statusEnum();
        if (!current.canMoveTo(target)) {
            throw ApiException.conflict("Order " + o.getOrderNumber() + " cannot move from " + current + " to " + target);
        }
        Optional<ShipmentEntity> shipment = shipments.findByOrderId(o.getId());
        switch (target) {
            case CONFIRMED -> shipmentService.createShipment(o);
            case DISPATCHED, OUT_FOR_DELIVERY, DELIVERED -> shipment.ifPresent(s -> {
                s.setStatus(target.name());
                assignments.findFirstByShipmentIdOrderByIdDesc(s.getId()).ifPresent(a -> {
                    if (target == OrderStatus.OUT_FOR_DELIVERY && DeliveryAssignmentEntity.ASSIGNED.equals(a.getStatus())) {
                        a.setStatus(DeliveryAssignmentEntity.IN_PROGRESS);
                    } else if (target == OrderStatus.DELIVERED) {
                        a.setStatus(DeliveryAssignmentEntity.COMPLETED);
                    }
                });
            });
            case CANCELLED -> {
                o.getItems().forEach(i -> inventory.increaseStock(i.getProductId(), i.getQuantity(), "ORDER_CANCELLED: " + o.getOrderNumber(), null));
                payments.findByOrderId(o.getId()).stream().filter(p -> "SUCCESS".equals(p.getStatus())).forEach(p -> p.setStatus("REFUNDED"));
                shipment.ifPresent(s -> s.setStatus(ShipmentEntity.CANCELLED));
                promotions.releaseUsage(o.getId());
            }
            default -> { // PROCESSING, READY_FOR_DISPATCH: nothing besides the status itself
            }
        }
        o.setStatus(target.name());
        o.setUpdatedDate(LocalDateTime.now());
    }

    // ------------------------------------------------------------------ helpers
    public OrderEntity find(Long id) {
        return orders.findById(id).orElseThrow(() -> ApiException.notFound("Order " + id + " was not found"));
    }

    private void requireView(OrderEntity o, AuthUser caller) {
        boolean ok = o.getUserId().equals(caller.id()) || caller.isAdminOrStaff() || "WAREHOUSE".equals(caller.role());
        if (!ok && "DELIVERY".equals(caller.role())) {
            ok = shipments.findByOrderId(o.getId())
                    .flatMap(s -> assignments.findFirstByShipmentIdOrderByIdDesc(s.getId()))
                    .map(a -> a.getStaffId().equals(caller.id())).orElse(false);
        }
        if (!ok) {
            throw ApiException.forbidden("You do not have access to this order");
        }
    }

    private OrderDetailResponse toDetail(OrderEntity o, AuthUser caller) {
        OrderResponse base = toResponses(List.of(o)).get(0);
        var ship = new ShippingAddress(o.getEmail(), o.getFirstName(), o.getLastName(), o.getAddress(), o.getApartment(),
                o.getCity(), o.getPostalCode(), o.getCountry(), o.getPhone(), o.getSecondaryPhone());
        PaymentInfo pay = payments.findFirstByOrderIdOrderByIdDesc(o.getId())
                .map(p -> new PaymentInfo(p.getPaymentMethod(), p.getCardBrand(), p.getCardLast4(), p.getStatus(), p.getTransactionId()))
                .orElse(null);
        ShipmentResponse shipment = shipments.findByOrderId(o.getId()).map(s -> shipmentService.toResponses(List.of(s)).get(0)).orElse(null);
        OrderStatus st = o.statusEnum();
        List<String> next = new ArrayList<>();
        if (caller.isAdminOrStaff()) {
            st.next().forEach(n -> next.add(n.name()));
        } else if ("WAREHOUSE".equals(caller.role())) {
            st.next().stream().filter(n -> n == OrderStatus.PROCESSING || n == OrderStatus.READY_FOR_DISPATCH).forEach(n -> next.add(n.name()));
        }
        boolean canCancel = caller.isAdminOrStaff() ? st.canMoveTo(OrderStatus.CANCELLED)
                : o.getUserId().equals(caller.id()) && st.customerCanCancel();
        return new OrderDetailResponse(base, ship, pay, shipment, next, canCancel);
    }

    private List<OrderResponse> toResponses(List<OrderEntity> list) {
        Set<Long> productIds = list.stream().flatMap(o -> o.getItems().stream()).map(OrderItemEntity::getProductId).collect(Collectors.toSet());
        Map<Long, String> imageByProduct = new HashMap<>();
        if (!productIds.isEmpty()) {
            images.findByProductIdInOrderByIdDesc(productIds).forEach(i -> imageByProduct.putIfAbsent(i.getProductId(), i.getImagePath()));
        }
        return list.stream().map(o -> {
            List<OrderItemResponse> items = o.getItems().stream().map(i -> new OrderItemResponse(i.getProductId(), i.getProductName(),
                    imageByProduct.get(i.getProductId()), i.getQuantity(), i.getPriceAtOrder(),
                    i.getPriceAtOrder().multiply(BigDecimal.valueOf(i.getQuantity())))).toList();
            return new OrderResponse(o.getId(), o.getOrderNumber(), o.getUserId(), o.customerName(), o.getEmail(), items,
                    items.stream().mapToInt(OrderItemResponse::quantity).sum(), o.getTotalAmount(), o.getDiscountApplied(),
                    o.getFinalAmount(), o.getCouponCode(), o.getStatus(), o.getCreatedDate(), o.getUpdatedDate());
        }).toList();
    }

    private String newOrderNumber() {
        String date = LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE);
        String number;
        do {
            number = "SS-" + date + "-" + String.format("%05d", RANDOM.nextInt(100000));
        } while (orders.existsByOrderNumber(number));
        return number;
    }
}
