package ma.enset.orderservice.repository;

import ma.enset.orderservice.entity.Order;
import ma.enset.orderservice.entity.Order.OrderStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrderRepository extends JpaRepository<Order, Long> {

    List<Order> findByCustomerUsername(String username);

    List<Order> findByStatus(OrderStatus status);

    List<Order> findByCustomerUsernameAndStatus(String username, OrderStatus status);
}
