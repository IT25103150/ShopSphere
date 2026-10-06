package com.shopsphere.order;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import lombok.Getter;
import lombok.Setter;

@Entity
@Table(name = "DeliveryAssignments")
@Getter
@Setter
public class DeliveryAssignmentEntity {
    public static final String ASSIGNED = "ASSIGNED";
    public static final String IN_PROGRESS = "IN_PROGRESS";
    public static final String COMPLETED = "COMPLETED";
    public static final String FAILED = "FAILED";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private Long shipmentId;

    @Column(nullable = false)
    private Long staffId;

    @Column(nullable = false)
    private LocalDateTime assignedDate = LocalDateTime.now();

    @Column(nullable = false, length = 20)
    private String status = ASSIGNED;
}
