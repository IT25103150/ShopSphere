package com.shopsphere.common;

import java.time.LocalDateTime;
import java.util.Map;

/** Uniform JSON error body returned for every failed request. */
public record ApiError(LocalDateTime timestamp, int status, String error, String message, String path,
                       Map<String, String> fieldErrors) {
}
