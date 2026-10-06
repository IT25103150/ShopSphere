package com.shopsphere.auth;

import java.util.List;
import java.util.Optional;
import org.springframework.data.jpa.repository.JpaRepository;

public interface AddressRepository extends JpaRepository<AddressEntity, Long> {
    List<AddressEntity> findByUserIdOrderByDefaultAddressDescIdAsc(Long userId);

    Optional<AddressEntity> findByIdAndUserId(Long id, Long userId);
}
