package com.shopsphere.order;

import jakarta.validation.constraints.NotBlank;
import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

public final class OrderDtos {
    private OrderDtos() {
    }

    public record OrderItemResponse(Long productId, String productName, String imagePath, int quantity,
                                    BigDecimal priceAtOrder, BigDecimal lineTotal) {
    }

    public record OrderResponse(Long id, String orderNumber, Long userId, String customerName, String customerEmail,
                                List<OrderItemResponse> items, int itemCount, BigDecimal totalAmount,
                                BigDecimal discountApplied, BigDecimal finalAmount, String couponCode, String status,
                                LocalDateTime createdDate, LocalDateTime updatedDate) {
    }

    public record ShippingAddress(String email, String firstName, String lastName, String address, String apartment,
                                  String city, String postalCode, String country, String phone, String secondaryPhone) {
    }

    public record PaymentInfo(String method, String cardBrand, String cardLast4, String status, String transactionId) {
    }

    public record DeliveryInfo(Long id, Long shipmentId, Long staffId, String staffName, String staffPhone,
                               String status, LocalDateTime assignedDate) {
    }

    public record ShipmentResponse(Long id, Long orderId, String orderNumber, String orderStatus, String trackingNumber,
                                   String status, LocalDate estimatedDelivery, LocalDateTime createdDate,
                                   String customerName, String customerPhone, String address, String city,
                                   DeliveryInfo delivery) {
    }

    public record OrderDetailResponse(OrderResponse order, ShippingAddress shipping, PaymentInfo payment,
                                      ShipmentResponse shipment, List<String> allowedNextStatuses, boolean canCancel) {
    }

    public record UpdateOrderStatusRequest(@NotBlank(message = "New status is required") String newStatus) {
    }

    public record AssignDeliveryRequest(@jakarta.validation.constraints.NotNull(message = "Shipment is required") Long shipmentId,
                                        @jakarta.validation.constraints.NotNull(message = "Delivery staff is required") Long staffId) {
    }

    public record UpdateStatusRequest(@NotBlank(message = "Status is required") String status) {
    }
}
