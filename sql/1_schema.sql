-- 1. SCHEMA
-- ---------------------------------------------------------------------
CREATE DATABASE e_commerce;

USE e_commerce;

CREATE TABLE customers (
    customer_id  INT AUTO_INCREMENT PRIMARY KEY,
    full_name    VARCHAR(100) NOT NULL,
    email        VARCHAR(150) NOT NULL UNIQUE,
    phone        VARCHAR(30),
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 1:M  customer -> addresses (a customer can have several delivery addresses)
CREATE TABLE customer_addresses (
    address_id   INT AUTO_INCREMENT PRIMARY KEY,
    customer_id  INT          NOT NULL,
    label        VARCHAR(30)  NOT NULL,
    street       VARCHAR(150) NOT NULL,
    city         VARCHAR(80)  NOT NULL,
    country      VARCHAR(60)  NOT NULL,
    is_default   BOOLEAN      NOT NULL DEFAULT FALSE,
    -- lets orders reference (address, customer) so an order can never ship
    -- to somebody else's address
    CONSTRAINT uq_address_customer UNIQUE (address_id, customer_id),
    CONSTRAINT fk_addr_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE CASCADE
);

CREATE TABLE vendors (
    vendor_id    INT AUTO_INCREMENT PRIMARY KEY,
    vendor_name  VARCHAR(100) NOT NULL UNIQUE,
    email        VARCHAR(150) NOT NULL UNIQUE,
    is_active    BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE categories (
    category_id   INT AUTO_INCREMENT PRIMARY KEY,
    category_name VARCHAR(80) NOT NULL UNIQUE
);

-- 1:M  vendor -> products
CREATE TABLE products (
    product_id    INT AUTO_INCREMENT PRIMARY KEY,
    vendor_id     INT           NOT NULL,
    product_name  VARCHAR(150)  NOT NULL,
    sku           VARCHAR(40)   NOT NULL UNIQUE,
    current_price DECIMAL(10,2) NOT NULL,
    stock_qty     INT           NOT NULL DEFAULT 0,
    is_active     BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at    DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_vendor_product UNIQUE (vendor_id, product_name),
    CONSTRAINT chk_product_price CHECK (current_price >= 0),
    CONSTRAINT chk_product_stock CHECK (stock_qty >= 0),
    CONSTRAINT fk_product_vendor FOREIGN KEY (vendor_id)
        REFERENCES vendors(vendor_id) ON DELETE RESTRICT
);

-- M:N  products <-> categories
CREATE TABLE product_categories (
    product_id  INT NOT NULL,
    category_id INT NOT NULL,
    PRIMARY KEY (product_id, category_id),
    CONSTRAINT fk_pc_product  FOREIGN KEY (product_id)  REFERENCES products(product_id)    ON DELETE CASCADE,
    CONSTRAINT fk_pc_category FOREIGN KEY (category_id) REFERENCES categories(category_id) ON DELETE CASCADE
);

-- 1:M  product -> price history
CREATE TABLE price_history (
    price_history_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id       INT           NOT NULL,
    price            DECIMAL(10,2) NOT NULL,
    effective_from   DATETIME      NOT NULL,
    effective_to     DATETIME      NULL, -- if effective_to is NULL, then it's the current price
    CONSTRAINT chk_price_value  CHECK (price >= 0),
    CONSTRAINT chk_price_period CHECK (effective_to IS NULL OR effective_to > effective_from),
    CONSTRAINT uq_price_start   UNIQUE (product_id, effective_from),
    CONSTRAINT fk_ph_product FOREIGN KEY (product_id)
        REFERENCES products(product_id) ON DELETE CASCADE
);

CREATE TABLE orders (
    order_id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_id         INT         NOT NULL,
    shipping_address_id INT         NOT NULL,
    status              VARCHAR(20) NOT NULL,
    order_date          DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_order_status CHECK (status IN ('Pending','Completed','Cancelled')),
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_order_address FOREIGN KEY (shipping_address_id, customer_id)
        REFERENCES customer_addresses (address_id, customer_id)
);

-- M:N  orders <-> products
CREATE TABLE order_items (
    order_item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id      INT           NOT NULL,
    product_id    INT           NOT NULL,
    quantity      INT           NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL,
    CONSTRAINT uq_order_product UNIQUE (order_id, product_id),
    CONSTRAINT chk_item_qty   CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price >= 0),
    CONSTRAINT fk_item_order   FOREIGN KEY (order_id)   REFERENCES orders(order_id)     ON DELETE CASCADE,
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE RESTRICT
);

-- 1:M  order -> payments (retries / refunds create more rows)
CREATE TABLE payments (
    payment_id   INT AUTO_INCREMENT PRIMARY KEY,
    order_id     INT           NOT NULL,
    amount       DECIMAL(10,2) NOT NULL,
    method       VARCHAR(30)   NOT NULL,
    status       VARCHAR(20)   NOT NULL,
    payment_date DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_pay_amount CHECK (amount >= 0),
    CONSTRAINT chk_pay_status CHECK (status IN ('Completed','Failed','Refunded')),
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE RESTRICT
);

-- 1:1  order -> shipment (UNIQUE on the FK enforces one-to-one)
CREATE TABLE shipments (
    shipment_id     INT AUTO_INCREMENT PRIMARY KEY,
    order_id        INT          NOT NULL UNIQUE,
    carrier         VARCHAR(50)  NOT NULL,
    tracking_number VARCHAR(50)  NOT NULL UNIQUE,
    status          VARCHAR(20)  NOT NULL,
    shipped_at      DATETIME     NOT NULL,
    delivered_at    DATETIME     NULL,
    CONSTRAINT chk_ship_status CHECK (status IN ('Shipped','Delivered')),
    CONSTRAINT chk_delivery CHECK 
    (
        (status = 'Delivered' AND delivered_at IS NOT NULL AND delivered_at >= shipped_at)
		OR
        (status = 'Shipped'   AND delivered_at IS NULL)
	),
    CONSTRAINT fk_ship_order FOREIGN KEY (order_id)
        REFERENCES orders(order_id) ON DELETE CASCADE
);

CREATE TABLE reviews (
    review_id   INT AUTO_INCREMENT PRIMARY KEY,
    product_id  INT          NOT NULL,
    customer_id INT          NOT NULL,
    rating      SMALLINT     NOT NULL,
    comment     VARCHAR(500),
    created_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_one_review UNIQUE (product_id, customer_id),
    CONSTRAINT chk_rating CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT fk_rev_product  FOREIGN KEY (product_id)  REFERENCES products(product_id)   ON DELETE CASCADE,
    CONSTRAINT fk_rev_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE
);