-- 3. QUERIES
-- =====================================================================

-- Q1: List all customers who have placed at least one order, ordered by order count descending.
-- Returns: CustomerId, CustomerName, NumberOfOrders
SELECT c.customer_id AS CustomerId,
       c.full_name   AS CustomerName,
       COUNT(*)      AS NumberOfOrders
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
ORDER BY NumberOfOrders DESC;


-- Q2: Identify all products that have never been included in any customer order.
-- Returns: ProductId, ProductName, VendorName
SELECT p.product_id   AS ProductId,
       p.product_name AS ProductName,
       v.vendor_name  AS VendorName
FROM products p
JOIN vendors v ON v.vendor_id = p.vendor_id
WHERE p.product_id NOT IN (SELECT product_id FROM order_items);


-- Q3: Calculate total completed orders, items sold, and gross revenue for every vendor.
-- Returns: VendorId, VendorName, TotalOrders, TotalItemsSold, TotalRevenue
SELECT v.vendor_id   AS VendorId,
       v.vendor_name AS VendorName,
       COUNT(DISTINCT o.order_id)      AS TotalOrders,
       SUM(oi.quantity)                AS TotalItemsSold,
       SUM(oi.quantity * oi.unit_price) AS TotalRevenue
FROM vendors v
JOIN products p     ON p.vendor_id = v.vendor_id
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY v.vendor_id, v.vendor_name;


-- Q4: Find the top 10 customers based on cumulative spending from completed orders.
-- Returns: CustomerId, CustomerName, TotalOrders, TotalSpent
SELECT c.customer_id AS CustomerId,
       c.full_name   AS CustomerName,
       COUNT(DISTINCT o.order_id)       AS TotalOrders,
       SUM(oi.quantity * oi.unit_price) AS TotalSpent
FROM customers c
JOIN orders o       ON o.customer_id = c.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY c.customer_id, c.full_name
ORDER BY TotalSpent DESC
LIMIT 10;


-- Q5: Find customers with historical orders who have not placed any order in the last 90 days.
-- Returns: CustomerId, CustomerName, LastOrderDate
SELECT c.customer_id AS CustomerId,
       c.full_name   AS CustomerName,
       MAX(o.order_date) AS LastOrderDate
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
GROUP BY c.customer_id, c.full_name
HAVING MAX(o.order_date) < CURRENT_DATE - INTERVAL 90 DAY;


-- [Q6 AI ASSISTED] 
-- VIEW = a saved query with a name. It gives units sold per product.
-- Q6: Find the highest-selling product (by units sold) for each vendor. Handle ties cleanly.
-- Returns: VendorName, ProductName, UnitsSold
CREATE OR REPLACE VIEW product_sales 
AS SELECT p.vendor_id, p.product_id, p.product_name, SUM(oi.quantity) AS units_sold
FROM products p
JOIN order_items oi ON oi.product_id = p.product_id
JOIN orders o       ON o.order_id = oi.order_id
WHERE o.status = 'Completed'
GROUP BY p.vendor_id, p.product_id, p.product_name;

SELECT v.vendor_name AS VendorName,
       ps.product_name AS ProductName,
       ps.units_sold   AS UnitsSold
FROM product_sales ps
JOIN vendors v ON v.vendor_id = ps.vendor_id
WHERE ps.units_sold = (SELECT MAX(x.units_sold)
                       FROM product_sales x
                       WHERE x.vendor_id = ps.vendor_id);



-- [Q7 AI ASSISTED] 
-- Q7: Determine the 2nd most expensive product in each category using window functions.
-- Returns: CategoryName, ProductName, Price
-- The brief REQUIRES a window function here, so this one can't be avoided.
-- DENSE_RANK() numbers rows 1,2,3... by price, restarting for each category
-- (PARTITION BY = "restart per group"). Then we keep rank 2.
SELECT category_name AS CategoryName,
       product_name  AS ProductName,
       current_price AS Price
FROM (SELECT c.category_name, p.product_name, p.current_price,
			DENSE_RANK() 
			OVER 
			(
				PARTITION BY c.category_name 
                ORDER BY p.current_price DESC
			) AS price_rank
		  FROM categories c
		  JOIN product_categories pc ON pc.category_id = c.category_id
		  JOIN products p            ON p.product_id = pc.product_id
	  ) ranked
WHERE price_rank = 2;


-- [Q8 AI ASSISTED] 
-- Q8: Find pair combinations of distinct products purchased within the same order.
-- Returns: ProductA, ProductB, TimesBoughtTogether
-- Join order_items to ITSELF: a = first item, b = second item, same order.
-- a.product_id < b.product_id keeps each pair once (A-B, not also B-A)
-- and stops a product pairing with itself.
SELECT pa.product_name AS ProductA,
       pb.product_name AS ProductB,
       COUNT(*)        AS TimesBoughtTogether
FROM order_items a
JOIN order_items b ON b.order_id = a.order_id
                  AND a.product_id < b.product_id
JOIN products pa ON pa.product_id = a.product_id
JOIN products pb ON pb.product_id = b.product_id
GROUP BY pa.product_name, pb.product_name
ORDER BY TimesBoughtTogether DESC;



-- [Q9 AI ASSISTED and SOLVED] 
-- Q9: Calculate monthly total revenue, previous month's revenue, and MoM growth percentage.
-- Returns: Year, Month, Revenue, PreviousMonthRevenue, GrowthPercentage
-- Step 1: a VIEW with one row per month.
CREATE OR REPLACE VIEW monthly_revenue AS
SELECT YEAR(o.order_date)  AS yr,
       MONTH(o.order_date) AS mth,
       SUM(oi.quantity * oi.unit_price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.status = 'Completed'
GROUP BY YEAR(o.order_date), MONTH(o.order_date);

-- Step 2: LAG(revenue) = "the revenue from the previous row" (last month).
-- Growth % = (this month - last month) / last month * 100.
-- The first month has no previous month, so it shows NULL. That is correct.
SELECT yr AS `Year`,
       mth AS `Month`,
       revenue AS Revenue,
       prev_revenue AS PreviousMonthRevenue,
       ROUND((revenue - prev_revenue) / prev_revenue * 100, 2) AS GrowthPercentage
FROM (SELECT yr, mth, revenue,
             LAG(revenue) OVER (ORDER BY yr, mth) AS prev_revenue
      FROM monthly_revenue) t
ORDER BY yr, mth;


-- [Q10 AI ASSISTED and SOLVED] 
-- Q10: Generate a performance matrix: revenue, AOV, order count, average rating, and unsold product count.
-- Returns: VendorName, TotalRevenue, AverageOrderValue, AvgRating, UnsoldProductCount
-- Instead of joining everything at once (which multiplies rows and 
-- gives wrong numbers), each column is its OWN small subquery for that vendor.
SELECT v.vendor_name AS VendorName,

       -- total revenue (completed orders)
       (SELECT SUM(oi.quantity * oi.unit_price)
        FROM order_items oi
        JOIN orders o   ON o.order_id = oi.order_id
        JOIN products p ON p.product_id = oi.product_id
        WHERE p.vendor_id = v.vendor_id AND o.status = 'Completed') AS TotalRevenue,

       -- average order value = revenue / number of orders
       (SELECT ROUND(SUM(oi.quantity * oi.unit_price) / COUNT(DISTINCT o.order_id), 2)
        FROM order_items oi
        JOIN orders o   ON o.order_id = oi.order_id
        JOIN products p ON p.product_id = oi.product_id
        WHERE p.vendor_id = v.vendor_id AND o.status = 'Completed') AS AverageOrderValue,

       -- average review rating of this vendor's products
       (SELECT ROUND(AVG(r.rating), 2)
        FROM reviews r
        JOIN products p ON p.product_id = r.product_id
        WHERE p.vendor_id = v.vendor_id) AS AvgRating,

       -- how many of this vendor's products were never ordered
       (SELECT COUNT(*)
        FROM products p
        WHERE p.vendor_id = v.vendor_id
          AND p.product_id NOT IN (SELECT product_id FROM order_items)) AS UnsoldProductCount
FROM vendors v;