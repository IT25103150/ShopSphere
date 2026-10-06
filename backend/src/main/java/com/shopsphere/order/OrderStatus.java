package com.shopsphere.order;

import java.util.List;

/** PENDING -> CONFIRMED -> PROCESSING -> READY_FOR_DISPATCH -> DISPATCHED -> OUT_FOR_DELIVERY -> DELIVERED; cancel any time before DELIVERED. */
public enum OrderStatus {
    PENDING, CONFIRMED, PROCESSING, READY_FOR_DISPATCH, DISPATCHED, OUT_FOR_DELIVERY, DELIVERED, CANCELLED;

    public List<OrderStatus> next() {
        return switch (this) {
            case PENDING -> List.of(CONFIRMED, CANCELLED);
            case CONFIRMED -> List.of(PROCESSING, CANCELLED);
            case PROCESSING -> List.of(READY_FOR_DISPATCH, CANCELLED);
            case READY_FOR_DISPATCH -> List.of(DISPATCHED, CANCELLED);
            case DISPATCHED -> List.of(OUT_FOR_DELIVERY, CANCELLED);
            case OUT_FOR_DELIVERY -> List.of(DELIVERED, CANCELLED);
            case DELIVERED, CANCELLED -> List.of();
        };
    }

    public boolean canMoveTo(OrderStatus target) {
        return next().contains(target);
    }

    /** Customers may cancel only until the parcel leaves the warehouse. */
    public boolean customerCanCancel() {
        return this == PENDING || this == CONFIRMED || this == PROCESSING || this == READY_FOR_DISPATCH;
    }
}
