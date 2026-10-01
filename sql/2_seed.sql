-- 2. SEED DATA ( AI Generated )
-- ---------------------------------------------------------------------
-- helper number table (MySQL has no generate_series); dropped at the end
CREATE TABLE seq (n INT PRIMARY KEY);
INSERT INTO seq (n)
WITH RECURSIVE r (n) AS (SELECT 1 UNION ALL SELECT n + 1 FROM r WHERE n < 55)
SELECT n FROM r;

INSERT INTO customers (customer_id, full_name, email, phone, is_active) VALUES
 (1,'Omar Haddad','omar.haddad@example.com','+970590000001',TRUE),
 (2,'Lina Khalil','lina.khalil@example.com','+970590000002',TRUE),
 (3,'Yousef Nasser','yousef.nasser@example.com','+970590000003',FALSE),
 (4,'Sara Abdallah','sara.abdallah@example.com','+970590000004',TRUE),
 (5,'Khaled Mansour','khaled.mansour@example.com','+970590000005',TRUE),
 (6,'Noor Salameh','noor.salameh@example.com','+970590000006',TRUE),
 (7,'Ahmad Qasem','ahmad.qasem@example.com','+970590000007',TRUE),
 (8,'Rana Jaber','rana.jaber@example.com','+970590000008',TRUE),
 (9,'Tariq Zayed','tariq.zayed@example.com','+970590000009',FALSE),
 (10,'Dina Barakat','dina.barakat@example.com','+970590000010',TRUE),
 (11,'Fadi Awad','fadi.awad@example.com','+970590000011',TRUE),
 (12,'Maya Suleiman','maya.suleiman@example.com','+970590000012',TRUE),
 (13,'Hani Darwish','hani.darwish@example.com','+970590000013',TRUE),
 (14,'Reem Odeh','reem.odeh@example.com','+970590000014',TRUE),        -- never ordered
 (15,'Bassam Hamdan','bassam.hamdan@example.com','+970590000015',FALSE), -- never ordered
 (16,'Jana Shawa','jana.shawa@example.com','+970590000016',TRUE);       -- never ordered

-- every customer gets a default address; even-numbered customers get a 2nd one
INSERT INTO customer_addresses (customer_id, label, street, city, country, is_default)
SELECT customer_id, 'Home', CONCAT(customer_id * 7, ' Main Street'),
       CASE customer_id % 4 WHEN 0 THEN 'Amman' WHEN 1 THEN 'Hebron' WHEN 2 THEN 'Ramallah' ELSE 'Nablus' END,
       CASE customer_id % 4 WHEN 0 THEN 'Jordan' ELSE 'Palestine' END,
       TRUE
FROM customers;

INSERT INTO customer_addresses (customer_id, label, street, city, country, is_default)
SELECT customer_id, 'Work', CONCAT(customer_id * 3, ' Industrial Road'), 'Bethlehem', 'Palestine', FALSE
FROM customers WHERE customer_id % 2 = 0;

INSERT INTO vendors (vendor_id, vendor_name, email, is_active) VALUES
 (1,'TechNova Supply','sales@technova.example',TRUE),
 (2,'HomeHarbor','hello@homeharbor.example',TRUE),
 (3,'UrbanKart','contact@urbankart.example',TRUE),
 (4,'GreenLeaf Traders','info@greenleaf.example',TRUE),
 (5,'LegacyGoods','support@legacygoods.example',FALSE);   -- inactive vendor

INSERT INTO categories (category_id, category_name) VALUES
 (1,'Electronics'),(2,'Home & Kitchen'),(3,'Books'),
 (4,'Sports & Outdoors'),(5,'Beauty'),(6,'Toys & Games');

-- 30 products, 6 per vendor. product_id % 6 decides the primary category:
-- 1=Electronics 2=Home 3=Books 4=Sports 5=Beauty 0=Toys
INSERT INTO products (product_id, vendor_id, product_name, sku, current_price, stock_qty, is_active) VALUES
 (1,1,'Wireless Earbuds Pro','SKU-001',79.99,120,TRUE),
 (2,1,'Stainless Cookware Set','SKU-002',129.50,45,TRUE),
 (3,1,'SQL Performance Tuning Guide','SKU-003',39.90,200,TRUE),
 (4,1,'Premium Yoga Mat','SKU-004',29.99,0,TRUE),           -- out of stock
 (5,1,'Vitamin C Face Serum','SKU-005',24.50,300,TRUE),
 (6,1,'Castle Building Blocks','SKU-006',49.00,60,TRUE),
 (7,2,'Smart LED Desk Lamp','SKU-007',34.99,150,TRUE),
 (8,2,'Air Fryer 5L','SKU-008',99.00,35,TRUE),
 (9,2,'Clean Architecture Handbook','SKU-009',44.50,80,TRUE),
 (10,2,'Adjustable Dumbbell Pair','SKU-010',149.00,12,TRUE),
 (11,2,'Argan Hair Oil','SKU-011',18.75,220,TRUE),
 (12,2,'Remote Control Racing Car','SKU-012',59.90,40,TRUE),
 (13,3,'Portable Bluetooth Speaker','SKU-013',54.00,95,TRUE),
 (14,3,'Memory Foam Pillow','SKU-014',42.00,70,TRUE),
 (15,3,'Designing Data Systems','SKU-015',59.99,55,TRUE),
 (16,3,'Trekking Backpack 40L','SKU-016',89.00,25,TRUE),
 (17,3,'Organic Body Lotion','SKU-017',15.25,400,TRUE),
 (18,3,'Strategy Board Game','SKU-018',36.50,0,TRUE),       -- out of stock
 (19,4,'USB-C Fast Charger','SKU-019',22.00,500,TRUE),
 (20,4,'Bamboo Cutting Board','SKU-020',19.90,150,TRUE),
 (21,4,'Cooking with Spices','SKU-021',27.00,110,TRUE),
 (22,4,'Insulated Water Bottle','SKU-022',21.50,260,TRUE),
 (23,4,'Natural Soap Bundle','SKU-023',12.99,320,TRUE),
 (24,4,'Wooden Puzzle 1000pc','SKU-024',31.75,18,TRUE),
 (25,5,'Mechanical Keyboard','SKU-025',109.00,30,TRUE),
 (26,5,'Ceramic Dinner Set','SKU-026',89.90,15,TRUE),
 (27,5,'Classic Poetry Collection','SKU-027',17.50,75,FALSE),
 (28,5,'Camping Tent 4-Person','SKU-028',199.00,8,FALSE),   -- never sold
 (29,5,'Luxury Perfume 100ml','SKU-029',139.00,22,FALSE),    -- never sold
 (30,5,'Vintage Chess Set','SKU-030',75.00,0,FALSE);         -- never sold

-- primary category + a second category for every 3rd product (M:N coverage)
INSERT INTO product_categories (product_id, category_id)
SELECT product_id, CASE WHEN product_id % 6 = 0 THEN 6 ELSE product_id % 6 END FROM products;

INSERT INTO product_categories (product_id, category_id)
SELECT product_id, (product_id % 6) + 1 FROM products
WHERE product_id % 3 = 0 AND (product_id % 6) + 1 <> CASE WHEN product_id % 6 = 0 THEN 6 ELSE product_id % 6 END;

-- price history: previous price (-10%) until 2026-03-01, then current price
INSERT INTO price_history (product_id, price, effective_from, effective_to)
SELECT product_id, ROUND(current_price * 0.90, 2), '2025-01-01 00:00:00', '2026-03-01 00:00:00' FROM products;
INSERT INTO price_history (product_id, price, effective_from, effective_to)
SELECT product_id, current_price, '2026-03-01 00:00:00', NULL FROM products;

-- 55 orders, ~5 days apart ending 5 days ago.
-- Customers 1-3 only order early (=> lapsed); customers 14-16 never order.
-- i%7=0 -> Cancelled, else i%5=0 -> Pending, else Completed.
INSERT INTO orders (order_id, customer_id, shipping_address_id, status, order_date)
SELECT s.i, s.customer_id,
       (SELECT CASE WHEN s.i % 2 = 0 THEN MAX(a.address_id) ELSE MIN(a.address_id) END
          FROM customer_addresses a WHERE a.customer_id = s.customer_id),
       CASE WHEN s.i % 7 = 0 THEN 'Cancelled' WHEN s.i % 5 = 0 THEN 'Pending' ELSE 'Completed' END,
       CAST(CURRENT_DATE AS DATETIME) - INTERVAL ((56 - s.i) * 5) DAY + INTERVAL 10 HOUR
FROM (SELECT n AS i,
             CASE WHEN n <= 10 THEN ((n - 1) % 3) + 1 ELSE ((n * 3) % 10) + 4 END AS customer_id
      FROM seq WHERE n <= 55) s;

-- 4 items per order. i%4=0 -> single-vendor order, otherwise mixed vendors.
-- Products 28-30 are excluded so they stay "never ordered". Price = price valid on order date.
INSERT INTO order_items (order_id, product_id, quantity, unit_price)
SELECT g.order_id, g.product_id, g.qty, ph.price
FROM (SELECT x.i AS order_id,
             CASE WHEN x.i % 4 = 0 THEN (x.i % 5) * 6 + ((x.i + x.j) % 6) + 1
                  ELSE ((x.i * 4 + x.j * 7) % 30) + 1 END AS product_id,
             ((x.i + x.j) % 3) + 1 AS qty
      FROM (SELECT s1.n AS i, s2.n - 1 AS j
            FROM seq s1 JOIN seq s2 ON s2.n <= 4) x) g
JOIN orders o         ON o.order_id = g.order_id
JOIN price_history ph ON ph.product_id = g.product_id
                     AND o.order_date >= ph.effective_from
                     AND (ph.effective_to IS NULL OR o.order_date < ph.effective_to)
WHERE g.product_id NOT IN (28, 29, 30)
ORDER BY g.order_id, g.product_id;

-- payments: Completed for completed orders; cancelled ones are Refunded or Failed;
-- pending ones are Failed (even ids) or have no payment yet (odd ids)
INSERT INTO payments (order_id, amount, method, status, payment_date)
SELECT o.order_id, t.total,
       ELT((o.order_id % 4) + 1, 'Card', 'PayPal', 'Bank Transfer', 'Cash on Delivery'),
       CASE o.status
            WHEN 'Completed' THEN 'Completed'
            WHEN 'Cancelled' THEN CASE WHEN (o.order_id DIV 7) % 2 = 0 THEN 'Refunded' ELSE 'Failed' END
            ELSE 'Failed' END,
       o.order_date + INTERVAL 5 MINUTE
FROM orders o
JOIN (SELECT order_id, SUM(quantity * unit_price) AS total FROM order_items GROUP BY order_id) t
  ON t.order_id = o.order_id
WHERE NOT (o.status = 'Pending' AND o.order_id % 2 = 1);

-- shipments for completed orders: most Delivered, every 8th still Shipped
INSERT INTO shipments (order_id, carrier, tracking_number, status, shipped_at, delivered_at)
SELECT order_id,
       CASE order_id % 3 WHEN 0 THEN 'DHL' WHEN 1 THEN 'Aramex' ELSE 'LogesTech' END,
       CONCAT('TRK', LPAD(CAST(order_id AS CHAR), 6, '0')),
       CASE WHEN order_id % 8 = 0 THEN 'Shipped' ELSE 'Delivered' END,
       order_date + INTERVAL 1 DAY,
       CASE WHEN order_id % 8 = 0 THEN NULL ELSE order_date + INTERVAL 4 DAY END
FROM orders WHERE status = 'Completed';

-- reviews: a subset of purchased products in completed orders (one per customer+product)
INSERT INTO reviews (product_id, customer_id, rating, comment, created_at)
SELECT oi.product_id, o.customer_id,
       ((MIN(o.order_id) + oi.product_id) % 5) + 1,
       'Seeded review', MIN(o.order_date) + INTERVAL 7 DAY
FROM order_items oi
JOIN orders o ON o.order_id = oi.order_id
WHERE o.status = 'Completed' AND (o.order_id + oi.product_id) % 3 = 0
GROUP BY oi.product_id, o.customer_id;

DROP TABLE seq;