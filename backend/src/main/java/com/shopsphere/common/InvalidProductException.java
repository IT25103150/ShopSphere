package com.shopsphere.common;

import org.springframework.http.HttpStatus;

public class InvalidProductException extends ApiException {
    public InvalidProductException(String message) {
        super(HttpStatus.BAD_REQUEST, message);
    }
}
