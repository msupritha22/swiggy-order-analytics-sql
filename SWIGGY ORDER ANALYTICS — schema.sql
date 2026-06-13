-- ============================================================
--  SWIGGY ORDER ANALYTICS — schema.sql
--  Tables: cities, customers, restaurants, menu_items,
--          orders, order_items, delivery_agents, deliveries
-- ============================================================

DROP TABLE IF EXISTS deliveries;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS menu_items;
DROP TABLE IF EXISTS restaurants;
DROP TABLE IF EXISTS delivery_agents;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS cities;

-- 1. Cities
CREATE TABLE cities (
    city_id    INT PRIMARY KEY,
    city_name  VARCHAR(50) NOT NULL,
    state      VARCHAR(50) NOT NULL
);

-- 2. Customers
CREATE TABLE customers (
    customer_id    INT PRIMARY KEY,
    full_name      VARCHAR(100) NOT NULL,
    email          VARCHAR(100) UNIQUE NOT NULL,
    phone          VARCHAR(15),
    city_id        INT NOT NULL,
    registered_on  DATE NOT NULL,
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- 3. Restaurants
CREATE TABLE restaurants (
    restaurant_id      INT PRIMARY KEY,
    name               VARCHAR(100) NOT NULL,
    cuisine_type       VARCHAR(50)  NOT NULL,   -- 'North Indian','Chinese','Pizza','South Indian','Biryani'
    city_id            INT NOT NULL,
    avg_cost_for_two   DECIMAL(8,2),
    is_veg_only        BOOLEAN DEFAULT FALSE,
    opened_on          DATE,
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- 4. Menu Items
CREATE TABLE menu_items (
    item_id        INT PRIMARY KEY,
    restaurant_id  INT NOT NULL,
    item_name      VARCHAR(100) NOT NULL,
    category       VARCHAR(50),               -- 'Starter','Main Course','Dessert','Beverage'
    price          DECIMAL(8,2) NOT NULL,
    is_available   BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

-- 5. Orders
CREATE TABLE orders (
    order_id         INT PRIMARY KEY,
    customer_id      INT NOT NULL,
    restaurant_id    INT NOT NULL,
    order_status     VARCHAR(20) NOT NULL,    -- 'Delivered','Cancelled','Pending'
    order_time       DATETIME NOT NULL,
    total_amount     DECIMAL(10,2) NOT NULL,
    discount_amount  DECIMAL(8,2) DEFAULT 0,
    payment_method   VARCHAR(20),             -- 'UPI','Card','Cash','Wallet'
    customer_rating  INT CHECK (customer_rating BETWEEN 1 AND 5),
    FOREIGN KEY (customer_id)   REFERENCES customers(customer_id),
    FOREIGN KEY (restaurant_id) REFERENCES restaurants(restaurant_id)
);

-- 6. Order Items
CREATE TABLE order_items (
    order_item_id  INT PRIMARY KEY,
    order_id       INT NOT NULL,
    item_id        INT NOT NULL,
    quantity       INT NOT NULL DEFAULT 1,
    unit_price     DECIMAL(8,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (item_id)  REFERENCES menu_items(item_id)
);

-- 7. Delivery Agents
CREATE TABLE delivery_agents (
    agent_id      INT PRIMARY KEY,
    full_name     VARCHAR(100) NOT NULL,
    city_id       INT NOT NULL,
    joined_on     DATE NOT NULL,
    vehicle_type  VARCHAR(20),               -- 'Bike','Scooter','Cycle'
    is_active     BOOLEAN DEFAULT TRUE,
    FOREIGN KEY (city_id) REFERENCES cities(city_id)
);

-- 8. Deliveries
CREATE TABLE deliveries (
    delivery_id           INT PRIMARY KEY,
    order_id              INT NOT NULL UNIQUE,
    agent_id              INT NOT NULL,
    pickup_time           DATETIME,
    delivered_time        DATETIME,
    delivery_distance_km  DECIMAL(5,2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (agent_id) REFERENCES delivery_agents(agent_id)
);
