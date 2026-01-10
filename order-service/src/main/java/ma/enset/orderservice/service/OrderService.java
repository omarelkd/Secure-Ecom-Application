package ma.enset.orderservice.service;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import ma.enset.orderservice.dto.OrderRequest;
import ma.enset.orderservice.dto.OrderResponse;
import ma.enset.orderservice.entity.Order;
import ma.enset.orderservice.entity.Order.OrderStatus;
import ma.enset.orderservice.repository.OrderRepository;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
@Transactional
public class OrderService {

    private final OrderRepository orderRepository;

    public List<OrderResponse> getAllOrders() {
        log.info("Fetching all orders");
        return orderRepository.findAll()
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public OrderResponse getOrderById(Long id) {
        log.info("Fetching order with id: {}", id);
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));
        return mapToResponse(order);
    }

    public List<OrderResponse> getOrdersByUsername(String username) {
        log.info("Fetching orders for user: {}", username);
        return orderRepository.findByCustomerUsername(username)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public List<OrderResponse> getOrdersByStatus(OrderStatus status) {
        log.info("Fetching orders with status: {}", status);
        return orderRepository.findByStatus(status)
                .stream()
                .map(this::mapToResponse)
                .collect(Collectors.toList());
    }

    public OrderResponse createOrder(OrderRequest request, String username) {
        log.info("Creating new order for user: {}", username);
        
        Order order = Order.builder()
                .productName(request.getProductName())
                .quantity(request.getQuantity())
                .totalPrice(request.getTotalPrice())
                .customerUsername(username)
                .status(OrderStatus.PENDING)
                .build();

        Order savedOrder = orderRepository.save(order);
        log.info("Order created successfully with id: {}", savedOrder.getId());
        
        return mapToResponse(savedOrder);
    }

    public OrderResponse updateOrderStatus(Long id, OrderStatus status) {
        log.info("Updating order {} status to: {}", id, status);
        
        Order order = orderRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Order not found with id: " + id));

        order.setStatus(status);
        Order updatedOrder = orderRepository.save(order);
        
        log.info("Order status updated successfully");
        return mapToResponse(updatedOrder);
    }

    public void deleteOrder(Long id) {
        log.info("Deleting order with id: {}", id);
        
        if (!orderRepository.existsById(id)) {
            throw new RuntimeException("Order not found with id: " + id);
        }
        
        orderRepository.deleteById(id);
        log.info("Order deleted successfully with id: {}", id);
    }

    private OrderResponse mapToResponse(Order order) {
        return OrderResponse.builder()
                .id(order.getId())
                .productName(order.getProductName())
                .quantity(order.getQuantity())
                .totalPrice(order.getTotalPrice())
                .customerUsername(order.getCustomerUsername())
                .status(order.getStatus())
                .createdAt(order.getCreatedAt())
                .updatedAt(order.getUpdatedAt())
                .build();
    }
}
