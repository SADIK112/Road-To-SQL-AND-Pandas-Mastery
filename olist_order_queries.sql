
-- Show all orders
SELECT * FROM olist_orders_dataset;
-- How many total orders are there?
SELECT COUNT(*) FROM olist_orders_dataset;
-- List all the distict order status?
SELECT DISTINCT order_status FROM olist_orders_dataset;
-- How many distinct order statuses are there?
SELECT COUNT(DISTINCT order_status) FROM olist_orders_dataset;
-- How many orders are in each order status?
SELECT order_status, COUNT(*) AS orders_count
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY orders_count DESC;
-- How many orders were delivered?
SELECT order_status, COUNT(*) AS orders_count
FROM olist_orders_dataset
GROUP BY order_status
HAVING order_status = 'delivered';
-- How many unique customers placed orders?
SELECT COUNT(DISTINCT customer_id) FROM olist_orders_dataset;
-- What’s the most common order status?
SELECT order_status
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY COUNT(*) DESC
LIMIT 1;
-- What’s the earliest and latest order purchase date?
SELECT
    MIN(order_purchase_timestamp::TIMESTAMP) AS earliest_date,
    MAX(order_purchase_timestamp::TIMESTAMP) AS latest_date
FROM olist_orders_dataset;
-- How many orders were delivered late? (Delivered date > estimated delivery date)
SELECT COUNT(*) FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
    AND order_delivered_customer_date::TIMESTAMP > order_estimated_delivery_date::TIMESTAMP;
-- How many orders have missing delivery timestamps?
SELECT COUNT(*) FROM olist_orders_dataset
WHERE order_delivered_customer_date IS NULL;
-- List all possible combinations of order status and delivery status presence.
SELECT 
    CASE 
        WHEN order_status = 'delivered' OR order_delivered_customer_date IS NOT NULL THEN 'Delivered'
        ELSE 'Not delivered'
    END AS delivery_status,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY delivery_status;
-- What is the average delivery time (in days) for delivered orders?
WITH delivery_time_record AS (
    SELECT 
        (order_delivered_customer_date::DATE - order_approved_at::DATE) AS delivery_days
    FROM olist_orders_dataset
    WHERE order_approved_at::TIMESTAMP IS NOT NULL
        AND order_delivered_customer_date::TIMESTAMP IS NOT NULL
        AND order_status = 'delivered'
)
SELECT ROUND(AVG(delivery_days)::numeric, 2) FROM delivery_time_record;
-- How many orders were placed each month?
SELECT
    TO_CHAR(order_approved_at, 'YYYY-MM') as approved_month,
    COUNT(*) AS total_orders
FROM olist_orders_dataset
WHERE order_approved_at IS NOT NULL 
GROUP BY approved_month
ORDER BY approved_month;
-- Which day had the most orders?
SELECT
    CAST(order_approved_at AS DATE) AS order_date,
    COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_approved_at IS NOT NULL
GROUP BY order_date
ORDER BY order_count DESC
LIMIT 1;
-- How many orders were canceled after being shipped?
SELECT COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_status = 'canceled'
    AND order_delivered_customer_date IS NOT NULL;
-- What is the average time between order purchase and order approval?
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (order_approved_at::TIMESTAMP - order_purchase_timestamp::TIMESTAMP)) / (3600 * 24)), 2) AS average_time
FROM olist_orders_dataset
WHERE order_approved_at IS NOT NULL
    AND order_purchase_timestamp IS NOT NULL
    AND order_approved_at::TIMESTAMP > order_purchase_timestamp::TIMESTAMP;
-- What is the distribution of order statuses by month?
SELECT
    TO_CHAR(order_purchase_timestamp::TIMESTAMP, 'YYYY-MM') AS review_month,
    order_status,
    COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY review_month, order_status
ORDER BY review_month, order_count;
-- List customers who placed more than 5 orders.
SELECT
    customer_id,
    COUNT(*) AS order_count
FROM olist_orders_dataset
GROUP BY customer_id
HAVING COUNT(*) > 5;
-- Which customers placed multiple orders on the same day?
SELECT
    customer_id,
    CAST(order_purchase_timestamp AS DATE) AS order_date,
    COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_purchase_timestamp IS NOT NULL
GROUP BY customer_id, order_date
HAVING COUNT(*) > 1
ORDER BY order_count DESC;
-- How many orders were delivered in less than 3 days?
SELECT COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_approved_at::TIMESTAMP IS NOT NULL
    AND order_delivered_customer_date::TIMESTAMP IS NOT NULL
    AND (order_delivered_customer_date::DATE - order_approved_at::DATE) < 3; 
-- How many orders are still waiting for approved?
SELECT COUNT(*) AS order_count
FROM olist_orders_dataset
WHERE order_purchase_timestamp::TIMESTAMP IS NOT NULL
    AND order_approved_at::TIMESTAMP IS NULL;
-- Which month had the highest delivery delays on average?
SELECT
    TO_CHAR(order_approved_at, 'YYYY-MM') AS order_month,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date::TIMESTAMP - order_estimated_delivery_date::TIMESTAMP)) / 86400), 2) AS avg_delay_days,
    COUNT(*) AS delayed_orders
FROM olist_orders_dataset
WHERE 
    order_approved_at IS NOT NULL
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
    AND order_delivered_customer_date::TIMESTAMP > order_estimated_delivery_date::TIMESTAMP
GROUP BY order_month
ORDER BY avg_delay_days DESC
LIMIT 1;
-- Which customer had the highest average delivery time?
SELECT
    customer_id,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_delivered_customer_date::TIMESTAMP - order_approved_at::TIMESTAMP)) / (3600 * 24)), 2) AS avg_delivery_days
FROM olist_orders_dataset
WHERE order_delivered_customer_date::TIMESTAMP IS NOT NULL
    AND order_approved_at::TIMESTAMP IS NOT NULL
GROUP BY customer_id
ORDER BY avg_delivery_days DESC
LIMIT 1;
-- Rank customers by number of delivered orders.
WITH customer_delivered_orders AS (
    SELECT
        customer_id,
        COUNT(*) AS delivered_order_count
    FROM olist_orders_dataset
    WHERE order_status = 'delivered'
    GROUP BY customer_id
)
SELECT
    customer_id,
    delivered_order_count,
    DENSE_RANK() OVER (
        ORDER BY delivered_order_count DESC
    ) AS rank_customer
FROM customer_delivered_orders;
-- What is the percentage of orders delivered on or before the estimated delivery date?
WITH orders_stats AS (
    SELECT 
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date IS NOT NULL
            AND order_estimated_delivery_date IS NOT NULL 
            AND order_delivered_customer_date <= order_estimated_delivery_date
        ) AS timely_delivered_orders,
        COUNT(*) AS total_orders
    FROM olist_orders_dataset
)
SELECT 
    timely_delivered_orders,
    total_orders,
    CASE 
        WHEN total_orders = 0 THEN 0 
        ELSE (timely_delivered_orders::FLOAT / total_orders) * 100 
    END AS perc_of_timely_delivered_orders
FROM orders_stats;
-- What’s the average delivery delay by order status?
SELECT
    order_status,
    ROUND(AVG(EXTRACT(EPOCH FROM(order_delivered_customer_date::TIMESTAMP - order_estimated_delivery_date::TIMESTAMP)) / (3600 * 24)), 2) AS avg_delay
FROM olist_orders_dataset
WHERE order_delivered_customer_date::TIMESTAMP IS NOT NULL
    AND order_estimated_delivery_date::TIMESTAMP IS NOT NULL
    AND order_delivered_customer_date::TIMESTAMP > order_estimated_delivery_date::TIMESTAMP
GROUP BY order_status
ORDER BY avg_delay DESC;
-- Find top 5 dates with the most delayed deliveries.
SELECT
    CAST(order_approved_at AS DATE) AS order_date,
    ROUND(AVG(EXTRACT(EPOCH FROM(order_delivered_customer_date::TIMESTAMP - order_estimated_delivery_date::TIMESTAMP)) / (3600 * 24)), 2) AS avg_delay_days,
    COUNT(*) total_orders
FROM olist_orders_dataset
WHERE order_delivered_customer_date::TIMESTAMP IS NOT NULL
    AND order_estimated_delivery_date::TIMESTAMP IS NOT NULL
    AND order_delivered_customer_date::TIMESTAMP > order_estimated_delivery_date::TIMESTAMP
GROUP BY order_date
ORDER BY avg_delay_days DESC
LIMIT 5;
-- Which order had the longest delay from purchase to delivery?
SELECT
    *, 
    ROUND(EXTRACT(EPOCH FROM(order_delivered_customer_date::TIMESTAMP - order_purchase_timestamp::TIMESTAMP)) / (3600 * 24), 2) AS delay_days
FROM olist_orders_dataset
WHERE order_delivered_customer_date::TIMESTAMP IS NOT NULL
    AND order_estimated_delivery_date::TIMESTAMP IS NOT NULL
    AND order_purchase_timestamp::TIMESTAMP IS NOT NULL
ORDER BY delay_days DESC
LIMIT 1;
-- Find the average approval time for each order status.
SELECT
    order_status,
    ROUND(AVG(EXTRACT(EPOCH FROM (order_approved_at::TIMESTAMP - order_purchase_timestamp::TIMESTAMP)) / (3600 * 24)), 2) AS avg_approved_time_in_days
FROM olist_orders_dataset
WHERE order_approved_at::TIMESTAMP IS NOT NULL
    AND order_purchase_timestamp::TIMESTAMP IS NOT NULL
GROUP BY order_status;
-- Which statuses are more likely to result in delivery delays?
WITH delivery_delay_flags AS (
    SELECT
        order_status,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date THEN 1
            ELSE 0
        END AS is_delayed
    FROM olist_orders_dataset
    WHERE order_delivered_customer_date IS NOT NULL
        AND order_estimated_delivery_date IS NOT NULL
)
SELECT
    order_status,
    COUNT(*) AS total_delivered,
    SUM(is_delayed) AS delayed_deliveries,
    ROUND((100.0 * SUM(is_delayed) / COUNT(*)), 2) AS percentage_delay
FROM delivery_delay_flags
GROUP BY order_status;
-- How many orders were approved but never shipped?
SELECT
    COUNT(*)
FROM olist_orders_dataset
WHERE order_approved_at IS NOT NULL
    AND order_delivered_carrier_date IS NULL;
