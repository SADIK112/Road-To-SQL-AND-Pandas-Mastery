-- How many rows are there in total
SELECT *
FROM olist_order_items_dataset
SELECT COUNT(*)
FROM olist_order_items_dataset;
-- How many unique orders are there
SELECT COUNT(DISTINCT order_id) AS unique_orders
FROM olist_order_items_dataset;
-- How many products are sold in each order (on average)
SELECT ROUND(AVG(item_count), 2) AS avg_items_per_order
FROM (
        SELECT order_id, COUNT(*) AS item_count
        FROM olist_order_items_dataset
        GROUP BY
            order_id
    ) AS order_item_counts;
-- What’s the average item price
SELECT product_id, AVG(price) AS average_price
FROM olist_order_items_dataset
GROUP BY
    product_id
ORDER BY average_price DESC;
-- What’s the total freight value
SELECT ROUND(
        SUM(freight_value::numeric), 2
    ) AS total_freight_value
FROM olist_order_items_dataset;
-- What is the minimum and maximum price of any product
SELECT
    product_id,
    MIN(price) AS minimum_price,
    MAX(price) AS maximum_price
FROM olist_order_items_dataset
GROUP BY
    product_id;
-- How many unique sellers are in the dataset
SELECT COUNT(DISTINCT seller_id) AS unique_sellers
FROM olist_order_items_dataset;
-- What is the average number of items per seller
SELECT AVG(items_count) AS avg_items_per_seller
FROM (
        SELECT seller_id, COUNT(*) AS items_count
        FROM olist_order_items_dataset
        GROUP BY
            seller_id
    ) AS seller_items;
-- Medium Questions
-- What’s the total revenue (sum of price) per seller
SELECT seller_id, ROUND(SUM(price::numeric), 2) AS total_revenue
FROM olist_order_items_dataset
GROUP BY
    seller_id
ORDER BY total_revenue DESC;
-- Which seller has the most items sold (count)
-- which one has the most revenue
SELECT seller_id, COUNT(*) AS total_order_items
FROM olist_order_items_dataset
GROUP BY
    seller_id
ORDER BY total_order_items DESC
LIMIT 1;
-- Which order had the highest total price
SELECT order_id, ROUND(SUM(price::numeric), 2) AS total_price
FROM olist_order_items_dataset
GROUP BY
    order_id
ORDER BY total_price DESC
LIMIT 1;
-- Which order had the highest freight cost
SELECT order_id, ROUND(
        SUM(freight_value::numeric), 2
    ) AS total_freight
FROM olist_order_items_dataset
GROUP BY
    order_id
ORDER BY total_freight DESC
LIMIT 1;
-- What is the average shipping limit date difference per seller
-- Extract - find/convert the timestap in seconds, average it and "TO_TIMESTAMP" converts it back to timestamp
SELECT seller_id, TO_TIMESTAMP(
        AVG(
            EXTRACT(
                EPOCH
                FROM shipping_limit_date
            )
        )
    )::date AS average_date
FROM olist_order_items_dataset
GROUP BY
    seller_id;
-- Which seller has the highest average freight cost per item
SELECT
    seller_id,
    ROUND(
        AVG(freight_value::numeric),
        1
    ) AS average_freight_cost
FROM olist_order_items_dataset
GROUP BY
    seller_id
ORDER BY average_freight_cost DESC
LIMIT 1;
-- List all sellers with more than 1,000 items sold
SELECT seller_id, COUNT(*) AS order_items
FROM olist_order_items_dataset
GROUP BY
    seller_id
HAVING
    COUNT(*) > 1000
ORDER BY order_items DESC;
-- How many products were sold with price over 100
SELECT COUNT(*) FROM olist_order_items_dataset WHERE price > 100;
-- Hard/Advanced Questions
-- Which seller has the highest average revenue per order (with at least 10 orders)
WITH
    seller_order_revenue AS (
        SELECT
            seller_id,
            order_id,
            SUM(price) AS order_revenue
        FROM olist_order_items_dataset
        GROUP BY
            seller_id,
            order_id
    ),
    seller_avg_revenue AS (
        SELECT
            seller_id,
            COUNT(order_id) AS total_orders,
            AVG(order_revenue) AS average_order_revenue
        FROM seller_order_revenue
        GROUP BY
            seller_id
        HAVING
            COUNT(order_id) >= 10
    )
SELECT
    seller_id,
    ROUND(
        (
            average_order_revenue::numeric
        ),
        2
    ) AS avg_order_revenue,
    total_orders
FROM seller_avg_revenue
ORDER BY avg_order_revenue DESC;
-- Rank sellers by total revenue within each month (use shipping_limit_date)
SELECT
    seller_id,
    EXTRACT(
        MONTH
        FROM shipping_limit_date
    ) AS shipping_month,
    ROUND(SUM(price::numeric), 2) AS total_revenue,
    DENSE_RANK() OVER (
        PARTITION BY
            EXTRACT(
                MONTH
                FROM shipping_limit_date
            )
        ORDER BY ROUND(SUM(price::numeric), 2) DESC
    ) AS seller_rank
FROM olist_order_items_dataset
GROUP BY
    seller_id,
    EXTRACT(
        MONTH
        FROM shipping_limit_date
    )
ORDER BY shipping_month, seller_rank;
-- Which orders contain more than one seller
SELECT order_id, COUNT(DISTINCT seller_id) AS seller_count
FROM olist_order_items_dataset
GROUP BY
    order_id
HAVING
    COUNT(DISTINCT seller_id) > 1;
-- Find the top 3 most expensive items (price + freight) per seller
WITH
    expensive_item_rank AS (
        SELECT
            seller_id,
            (price + freight_value) AS total_price,
            ROW_NUMBER() OVER (
                PARTITION BY
                    seller_id
                ORDER BY (price + freight_value) DESC
            ) AS price_rank
        FROM olist_order_items_dataset
    )
SELECT seller_id, ROUND(total_price::numeric, 2), price_rank
FROM expensive_item_rank
WHERE
    price_rank <= 3
ORDER BY seller_id, price_rank;
-- Which products are sold by more than 1 seller
SELECT product_id, COUNT(DISTINCT seller_id) AS seller_count
FROM olist_order_items_dataset
GROUP BY
    product_id
HAVING
    COUNT(DISTINCT seller_id) > 1;
-- Compute price-to-freight ratio per item and find top 10 highest ratios
SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,
    price,
    freight_value,
    ROUND(
        (
            price / NULLIF(freight_value, 0)
        )::numeric,
        2
    ) AS price_freight_ratio
FROM olist_order_items_dataset
WHERE
    freight_value > 0
ORDER BY price_freight_ratio DESC
LIMIT 10;
-- Find the order-seller pairs where the freight cost is more than the item price
SELECT
    order_id,
    seller_id,
    price,
    freight_value
FROM olist_order_items_dataset
WHERE
    freight_value > price;
-- Calculate total sales and freight by day using shipping_limit_date (time series analysis).
SELECT
    shipping_limit_date::date AS shipping_date,
    ROUND(SUM(price)::numeric, 2) AS total_sale,
    ROUND(
        SUM(freight_value)::numeric,
        2
    ) AS total_freight_value
FROM olist_order_items_dataset
GROUP BY
    shipping_limit_date::date
ORDER BY shipping_date DESC
