package ma.enset.orderservice.dto;

import lombok.*;
import ma.enset.orderservice.entity.Order.OrderStatus;

import java.time.LocalDateTime;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrderResponse {

    private Long id;
    private String productName;
    private Integer quantity;
    private Double totalPrice;
    private String customerUsername;
    private OrderStatus status;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
}
