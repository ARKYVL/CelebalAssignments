use week3;
CREATE TABLE sales_data (
    row_id INT PRIMARY KEY,
    order_id VARCHAR(50),
    order_date DATE,
    ship_date DATE,
    ship_mode VARCHAR(50),
    customer_id VARCHAR(50),
    customer_name VARCHAR(100),
    segment VARCHAR(50),
    country VARCHAR(100),
    city VARCHAR(100),
    state VARCHAR(100),
    postal_code VARCHAR(20),      
    region VARCHAR(50),
    product_id VARCHAR(50),
    category VARCHAR(50),
    sub_category VARCHAR(50),
    product_name VARCHAR(255),    
    sales DECIMAL(10, 2),        
    quantity INT,
    discount DECIMAL(4, 2),       
    profit DECIMAL(10, 4)         
);
select * from sales_data;
-- 1. Create Customers Table
CREATE TABLE customers AS
SELECT DISTINCT 
    `Customer ID` AS customer_id, 
    `Customer Name` AS customer_name, 
    Segment AS segment
FROM sales_data;

-- 2. Create Products Table
CREATE TABLE products AS
SELECT DISTINCT 
    `Product ID` AS product_id, 
    Category AS category, 
    `Sub-Category` AS sub_category, 
    `Product Name` AS product_name
FROM sales_data;

-- 3. Create Orders Table
CREATE TABLE orders AS
SELECT DISTINCT 
    row_id, 
    `Order ID` AS order_id, 
    `Order Date` AS order_date, 
    `Ship Date` AS ship_date, 
    `Ship Mode` AS ship_mode, 
    `Customer ID` AS customer_id, 
    `Product ID` AS product_id, 
    Sales AS sales, 
    Quantity AS quantity, 
    Discount AS discount, 
    Profit AS profit
FROM sales_data;
SELECT order_id, sales 
FROM orders 
WHERE sales > (
    SELECT AVG(sales) 
    FROM orders
);
SELECT customer_id, order_id, sales
FROM orders o1
WHERE sales = (
    SELECT MAX(sales) 
    FROM orders o2 
    WHERE o1.customer_id = o2.customer_id
);

-- error because a lot of time goes into running it

WITH CustomerTotalSales AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT * FROM CustomerTotalSales;

WITH CustomerTotalSales AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT customer_id, total_sales
FROM CustomerTotalSales
WHERE total_sales > (
    SELECT AVG(total_sales) 
    FROM CustomerTotalSales
);

SELECT customer_id, 
       SUM(sales) AS total_sales,
       RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
FROM orders
GROUP BY customer_id;
SELECT customer_id, order_id, order_date, sales,
       ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date ASC) AS order_sequence
FROM orders;

WITH RankedCustomers AS (
    SELECT customer_id, 
           SUM(sales) AS total_sales,
           RANK() OVER (ORDER BY SUM(sales) DESC) AS sales_rank
    FROM orders
    GROUP BY customer_id
)
SELECT * FROM RankedCustomers 
WHERE sales_rank <= 3;

-- MINI PROJECT



SELECT 
    c.customer_name, 
    SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_sales DESC
LIMIT 5;


SELECT 
    c.customer_name, 
    SUM(o.sales) AS total_sales
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
ORDER BY total_sales ASC
LIMIT 5;

SELECT 
    c.customer_name, 
    COUNT(DISTINCT o.order_id) as total_orders
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name
HAVING COUNT(DISTINCT o.order_id) = 1;


WITH CustomerTotalSales AS (
    SELECT customer_id, SUM(sales) AS total_sales
    FROM orders
    GROUP BY customer_id
)
SELECT 
    c.customer_name, 
    cts.total_sales
FROM customers c
JOIN CustomerTotalSales cts ON c.customer_id = cts.customer_id
WHERE cts.total_sales > (
    SELECT AVG(total_sales) 
    FROM CustomerTotalSales
);


SELECT 
    c.customer_name, 
    MAX(o.sales) AS highest_order_value
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_name;