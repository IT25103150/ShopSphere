package com.shopsphere.common;

import org.springframework.http.HttpStatus;

public class DuplicateSkuException extends ApiException {
    public DuplicateSkuException(String sku) {
        super(HttpStatus.CONFLICT, "A product with SKU " + sku + " already exists");
    }
}
