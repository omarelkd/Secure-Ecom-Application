-- Initial orders data
INSERT INTO orders (product_name, quantity, total_price, customer_username, status, created_at, updated_at) VALUES
('Laptop Dell XPS 15', 1, 1299.99, 'user', 'DELIVERED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('iPhone 15 Pro', 2, 1999.98, 'user', 'CONFIRMED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Samsung Galaxy S24', 1, 899.99, 'admin', 'SHIPPED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('MacBook Pro M3', 1, 2499.99, 'manager', 'PENDING', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP),
('Sony WH-1000XM5', 3, 1199.97, 'user', 'DELIVERED', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
