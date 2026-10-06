package com.shopsphere.common;

import org.springframework.http.HttpStatus;

public class ProductNotFoundException extends ApiException {
    public ProductNotFoundException(Long id) {
        super(HttpStatus.NOT_FOUND, "Product " + id + " was not found");
    }
}
