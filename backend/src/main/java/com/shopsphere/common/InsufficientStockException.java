package com.shopsphere.common;

import org.springframework.http.HttpStatus;

public class InsufficientStockException extends ApiException {
    public InsufficientStockException(String productName, int available) {
        super(HttpStatus.CONFLICT, available <= 0
                ? productName + " is out of stock"
                : "Only " + available + " unit(s) of " + productName + " available");
    }
}
