-- 1. Sellers & Orders
-- What is the total number of orders handled by each seller?
SELECT
    os.seller_id,
    COUNT(*) AS order_count
FROM olist_orders_dataset oo
JOIN olist_order_items_dataset ot
    ON oo.order_id = ot.order_id
JOIN olist_sellers_dataset os
    ON ot.seller_id = os.seller_id
GROUP BY os.seller_id;
-- Find sellers with zero orders.
SELECT
    DISTINCT os.seller_id AS seller
FROM olist_sellers_dataset os
LEFT JOIN olist_order_items_dataset ot
    ON os.seller_id = ot.seller_id
WHERE ot.order_id IS NULL;
-- Which state has the most sellers fulfilling orders?
SELECT
    os.seller_state,
    COUNT(DISTINCT ot.order_id) AS order_count
FROM olist_sellers_dataset os
JOIN olist_order_items_dataset ot
    ON os.seller_id = ot.seller_id
GROUP BY os.seller_state
ORDER BY order_count DESC;
-- 3. Orders & Customers
-- How many orders were placed by customers in each state?
SELECT
    c.customer_state,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist_customers_dataset c
JOIN olist_orders_dataset o
    ON c.customer_id = o.customer_id
GROUP BY customer_state
ORDER BY order_count DESC;
-- How many unique customers placed orders in each city?
SELECT
    c.customer_city,
    COUNT(DISTINCT c.customer_id) AS customer_count
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY customer_count DESC;
-- 4. Products & Orders
-- Top 10 product categories by number of orders.
SELECT 
    product_category_name,
    COUNT(DISTINCT o.order_id) AS order_count
FROM olist_orders_dataset o
JOIN olist_order_items_dataset t
    ON o.order_id = t.order_id
JOIN olist_products_dataset p
    ON t.product_id = p.product_id
GROUP BY p.product_category_name
ORDER BY order_count DESC
LIMIT 10;
-- How many sellers are associated with each product category?
SELECT
    p.product_category_name,
    COUNT(DISTINCT ot.seller_id) AS seller_count
FROM olist_products_dataset p
JOIN olist_order_items_dataset ot
    ON p.product_id = ot.product_id
GROUP BY p.product_category_name
ORDER BY seller_count DESC;
-- 5. Payments
-- What is the total revenue per seller?
SELECT
    ot.seller_id,
    ROUND(SUM(py.payment_value)::NUMERIC, 2) AS total_revenue
FROM olist_order_items_dataset ot
JOIN olist_order_payments_dataset py
    ON ot.order_id = py.order_id
GROUP BY ot.seller_id
ORDER BY total_revenue DESC;
-- Total revenue per product category.
WITH order_items AS (
    SELECT
        ot.order_id,
        ot.product_id,
        p.product_category_name,
        (ot.price + ot.freight_value) AS item_value
    FROM olist_order_items_dataset ot
    JOIN olist_products_dataset p
        ON ot.product_id = p.product_id
),
order_totals AS (
    SELECT
        order_id,
        SUM(item_value) AS total_order_value
    FROM order_items
    GROUP BY order_id
),
payment_totals AS (
    SELECT
        order_id,
        SUM(payment_value) AS total_payment_value
    FROM olist_order_payments_dataset
    GROUP BY order_id
)
SELECT
    oi.product_category_name,
    ROUND(SUM((oi.item_value / ott.total_order_value) * pt.total_payment_value)::NUMERIC, 2) AS total_revenue
FROM order_items oi
JOIN order_totals ott
    ON oi.order_id = ott.order_id
JOIN payment_totals pt
    ON oi.order_id = pt.order_id
GROUP BY oi.product_category_name
ORDER BY total_revenue DESC;

-- B. Medium Level (Multi-table JOINs & Window Functions)
-- 1. Seller & Revenue
-- Which sellers contribute to 80% of total revenue (Pareto principle)?
WITH seller_revenue AS (
    SELECT
        seller_id,
        SUM(price + freight_value) AS total_revenue
    FROM olist_order_items_dataset
    GROUP BY seller_id
),
ranked_sellers AS (
    SELECT
        seller_id,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS cum_revenue,
        SUM(total_revenue) OVER () AS total_revenue_sum
    FROM seller_revenue
)
SELECT
    seller_id,
    ROUND(total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND((100 * total_revenue / cum_revenue)::NUMERIC, 2) AS cum_percentage
FROM ranked_sellers
WHERE ROUND((100 * total_revenue / cum_revenue)::NUMERIC, 2) <= 80
ORDER BY total_revenue DESC;
-- Top 3 sellers by revenue in each state.
WITH seller_revenue AS (
    SELECT
        s.seller_id,
        s.seller_state,
        SUM(o.price + o.freight_value) AS total_revenue
    FROM olist_sellers_dataset s
    JOIN olist_order_items_dataset o
        ON s.seller_id = o.seller_id
    GROUP BY s.seller_id, s.seller_state
),
ranked_seller AS (
    SELECT
        seller_id,
        seller_state,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY seller_state
            ORDER BY total_revenue DESC
        ) AS revenue_rank
    FROM seller_revenue
)
SELECT
    seller_id,
    seller_state,
    ROUND(total_revenue::NUMERIC, 2),
    revenue_rank
FROM ranked_seller
WHERE revenue_rank <= 3;
-- Rank all sellers globally by total revenue.
WITH seller_revenue AS (
    SELECT
        s.seller_id,
        SUM(o.price + o.freight_value) AS total_revenue
    FROM olist_sellers_dataset s
    JOIN olist_order_items_dataset o
        ON s.seller_id = o.seller_id
    GROUP BY s.seller_id
)
SELECT
    seller_id,
    ROUND(total_revenue::NUMERIC, 2),
    ROW_NUMBER() OVER (
        ORDER BY total_revenue DESC
    ) AS rank_seller
FROM seller_revenue;
-- What is the revenue share of each product category?
WITH category_revenue AS (
    SELECT
        p.product_category_name,
        SUM(o.price + o.freight_value) AS total_revenue
    FROM olist_order_items_dataset o
    JOIN olist_products_dataset p
        ON o.product_id = p.product_id
    GROUP BY p.product_category_name
),
total_revenue AS (
    SELECT
        SUM(total_revenue) AS overall_revenue
    FROM category_revenue
)
SELECT
    c.product_category_name,
    ROUND(c.total_revenue::NUMERIC, 2) AS total_revenue,
    ROUND((100 * c.total_revenue / t.overall_revenue)::NUMERIC, 2) AS revenue_share
FROM category_revenue c, total_revenue t
ORDER BY revenue_share DESC;
-- 2. Delivery & Logistics
-- Which product categories have the longest average delivery time?
SELECT
    p.product_category_name,
    ROUND(AVG(o.order_delivered_customer_date::DATE - o.order_purchase_timestamp::DATE), 2) AS avg_delivery_time
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
JOIN olist_products_dataset p
    ON p.product_id = oi.product_id
WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_purchase_timestamp IS NOT NULL
GROUP BY p.product_category_name
ORDER BY avg_delivery_time DESC;
-- Which states have the highest percentage of late deliveries?
WITH state_delivery_stats AS (
    SELECT
        c.customer_state,
        COUNT(*) AS total_orders,
        SUM(
            CASE 
                WHEN o.order_delivered_customer_date > o.order_estimated_delivery_date THEN 1
                ELSE 0
            END
        ) AS late_orders
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    WHERE o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY c.customer_state
)
SELECT
    customer_state,
    ROUND((100 * late_orders / total_orders)::NUMERIC, 2) AS perc_late_orders
FROM state_delivery_stats
ORDER BY perc_late_orders DESC;
-- 3. Reviews
-- Rank sellers by average review score.
SELECT
    o.seller_id,
    ROUND(AVG(r.review_score), 2) AS avg_review_score,
    ROW_NUMBER() OVER (
        ORDER BY AVG(r.review_score) DESC
    ) AS review_rank
FROM olist_order_reviews_dataset r
JOIN olist_order_items_dataset o
    ON r.order_id = o.order_id
GROUP BY o.seller_id
ORDER BY avg_review_score DESC;
-- Which product categories have the best average review scores?
SELECT
    p.product_category_name,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM olist_order_reviews_dataset r
JOIN olist_order_items_dataset ot
    ON r.order_id = ot.order_id
JOIN olist_products_dataset p
    ON p.product_id = ot.product_id
GROUP BY p.product_category_name
ORDER BY avg_review_score DESC;
-- How many orders per seller received reviews below 3?
SELECT
    o.seller_id,
    COUNT(*) AS orders_count
FROM olist_order_items_dataset o
JOIN olist_order_reviews_dataset r
    ON o.order_id = r.order_id
WHERE r.review_score < 3
GROUP BY o.seller_id
ORDER BY orders_count DESC;
-- 4. Customers & Revenue
-- Which cities generate the most revenue?
SELECT
    c.customer_city,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_city
ORDER BY total_revenue DESC;
-- Which states contribute to 70% of total revenue?
WITH states_revenue_stats AS (
    SELECT
        c.customer_state,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
    FROM olist_order_items_dataset oi
    JOIN olist_orders_dataset o
        ON oi.order_id = o.order_id
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_state
    ORDER BY total_revenue DESC
),
stats_cum_revenue AS (
    SELECT
        customer_state,
        total_revenue,
        SUM(total_revenue) OVER (ORDER BY total_revenue DESC) AS cum_revenue,
        SUM(total_revenue) OVER () AS overall_revenue
    FROM states_revenue_stats
)
SELECT
    customer_state,
    total_revenue,
    cum_revenue,
    ROUND((100 * cum_revenue / overall_revenue)::NUMERIC, 2) AS perc_revenue
FROM stats_cum_revenue
WHERE (100 * cum_revenue / overall_revenue) <= 70;
-- Find customers with the highest total spending.
SELECT
    c.customer_id,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_spending
FROM olist_order_items_dataset oi
JOIN olist_orders_dataset o
    ON oi.order_id = o.order_id
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spending DESC;
-- C. Hard Level (Advanced CTEs, Analytics, Outlier Detection)
-- 1. Advanced Seller Analytics
-- Top 3 sellers in each state based on revenue (RANK per state).
WITH stats_seller_rank AS (
    SELECT
        s.seller_id,
        s.seller_state,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY s.seller_state
            ORDER BY SUM(oi.price + oi.freight_value) DESC
        ) AS state_rank
    FROM olist_order_items_dataset oi
    JOIN olist_sellers_dataset s
        ON oi.seller_id = s.seller_id
    GROUP BY s.seller_id, s.seller_state
)
SELECT
    seller_id,
    seller_state,
    total_revenue,
    state_rank
FROM stats_seller_rank
WHERE state_rank <= 3
ORDER BY seller_state, state_rank;
-- Identify sellers with unusually high cancellation rates (outlier detection).
WITH seller_order_stats AS (
    SELECT
        oi.seller_id,
        COUNT(*) AS cancelled_order_count
    FROM olist_orders_dataset o
    JOIN olist_order_items_dataset oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'canceled'
    GROUP BY oi.seller_id
),
percentile_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY cancelled_order_count) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY cancelled_order_count) AS q3
    FROM seller_order_stats
),
outlier_threshold AS (
    SELECT
        q1,
        q3,
        (q3 - q1) * 1.5 AS iqr_multiplier
    FROM percentile_stats
)
SELECT
    s.seller_id,
    s.cancelled_order_count
FROM seller_order_stats s, outlier_threshold o
    WHERE s.cancelled_order_count < (o.q1 - o.iqr_multiplier)
    OR s.cancelled_order_count > (o.q3 + o.iqr_multiplier)
ORDER BY s.cancelled_order_count DESC;

-- 2. Customer Behavior
-- Which customers ordered from the same seller more than 3 times?
SELECT
    o.customer_id,
    oi.seller_id,
    COUNT(*) AS order_count
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
GROUP BY o.customer_id, oi.seller_id
HAVING COUNT(*) > 3
ORDER BY order_count DESC;
-- Which states have the highest repeat customer rate?
WITH customer_order_counts AS (
    SELECT
        c.customer_id,
        c.customer_state,
        COUNT(o.order_id) AS order_count
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    GROUP BY c.customer_id, c.customer_state
)
SELECT
    customer_state,
    COUNT(*) AS total_customers,
    COUNT(*) FILTER (WHERE order_count > 1) AS repeat_customers
FROM customer_order_counts
GROUP BY customer_state;
-- Identify top 10 customers by lifetime value (total spend).
SELECT
    c.customer_id,
    ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_spend
FROM olist_orders_dataset o
JOIN olist_order_items_dataset oi
    ON o.order_id = oi.order_id
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_id
ORDER BY total_spend DESC
LIMIT 10;
-- 3. Product Insights
-- Which product categories have the highest revenue-to-weight ratio?
WITH product_stats AS (
    SELECT
        p.product_category_name,
        SUM(p.product_weight_g) AS total_weight,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS total_revenue
    FROM olist_products_dataset p
    JOIN olist_order_items_dataset oi
        ON p.product_id = oi.product_id
    WHERE p.product_weight_g IS NOT NULL
    GROUP BY p.product_category_name
)
SELECT
    product_category_name,
    ROUND((total_revenue / NULLIF(total_weight, 0))::NUMERIC, 2) AS revenue_to_weight_ratio
FROM product_stats
ORDER BY revenue_to_weight_ratio DESC;
-- Which categories contribute 80% of total order value (Pareto)?
WITH category_order_value_stats AS (
    SELECT
        p.product_category_name,
        ROUND(SUM(oi.price + oi.freight_value)::NUMERIC, 2) AS order_value
    FROM olist_products_dataset p
    JOIN olist_order_items_dataset oi
        ON p.product_id = oi.product_id
    GROUP BY p.product_category_name
    ORDER BY order_value DESC
),
category_cum_revenue AS (
    SELECT
        product_category_name,
        order_value,
        SUM(order_value) OVER (ORDER BY order_value DESC) AS cum_order_value,
        SUM(order_value) OVER () AS overall_order_value
    FROM category_order_value_stats
)
SELECT
    product_category_name,
    order_value,
    cum_order_value,
    ROUND((100 * cum_order_value / overall_order_value)::NUMERIC, 2) AS perc_order_value
FROM category_cum_revenue
WHERE (100 * cum_order_value / overall_order_value) <= 80;
-- 4. Review & Performance
-- Weighted average review score per seller (weighted by revenue).
WITH review_data AS (
    SELECT
        s.seller_id,
        r.review_score,
        (oi.price + oi.freight_value) AS revenue
    FROM olist_order_items_dataset oi
    JOIN olist_sellers_dataset s
        ON oi.seller_id = s.seller_id
    JOIN olist_order_reviews_dataset r
        ON oi.order_id = r.order_id
    WHERE r.review_score IS NOT NULL
)
SELECT
    seller_id,
    ROUND((SUM(review_score * revenue) / NULLIF(SUM(revenue), 0))::NUMERIC, 2) AS weighted_avg_review_score
FROM review_data
GROUP BY seller_id
ORDER BY weighted_avg_review_score DESC;
-- Which sellers have the highest proportion of 1-star reviews?
WITH review_order AS (
    SELECT
        oi.seller_id,
        r.review_score
    FROM olist_order_items_dataset oi
    JOIN olist_order_reviews_dataset r
        ON oi.order_id = r.order_id
)
SELECT
    seller_id,
    COUNT(*) FILTER (WHERE review_score = 1) AS one_star_count,
    COUNT(*) AS total_reviews,
    ROUND((100 * COUNT(*) FILTER (WHERE review_score = 1) / COUNT(*))::NUMERIC, 2) AS one_star_proportion
FROM review_order
GROUP BY seller_id;

-- 5. Delivery Performance
-- Which states have the worst average delivery delays?
SELECT
    c.customer_state,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_delivered_customer_date::TIMESTAMP - o.order_estimated_delivery_date::TIMESTAMP)) / (3600 * 24)), 2) AS avg_delivery_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date > o.order_estimated_delivery_date
GROUP BY c.customer_state
ORDER BY avg_delivery_days DESC;
-- Which states have the best avg delivery on time?
SELECT
    c.customer_state,
    ROUND(AVG(EXTRACT(EPOCH FROM (o.order_estimated_delivery_date::TIMESTAMP - o.order_delivered_customer_date::TIMESTAMP)) / (3600 * 24)), 2) AS avg_delivery_days
FROM olist_orders_dataset o
JOIN olist_customers_dataset c
    ON o.customer_id = c.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
  AND o.order_estimated_delivery_date IS NOT NULL
  AND o.order_delivered_customer_date < o.order_estimated_delivery_date
GROUP BY c.customer_state
ORDER BY avg_delivery_days ASC;
-- Detect cities with unusually high delivery delays (outliers).
WITH delivery_delay_stats AS (
    SELECT
        c.customer_city,
        ROUND(SUM(EXTRACT(EPOCH FROM (o.order_delivered_customer_date::TIMESTAMP - o.order_estimated_delivery_date::TIMESTAMP)) / (3600 * 24)), 2) AS delay_days
    FROM olist_orders_dataset o
    JOIN olist_customers_dataset c
        ON o.customer_id = c.customer_id
    WHERE o.order_delivered_customer_date IS NOT NULL
    AND o.order_estimated_delivery_date IS NOT NULL
    AND o.order_delivered_customer_date > o.order_estimated_delivery_date
    GROUP BY c.customer_city
),
percentile_stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY delay_days) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY delay_days) AS q3
    FROM delivery_delay_stats
),
outliers AS (
    SELECT
        q1,
        q3,
        (q3 - q1) * 1.5 AS iqr_multiplier
    FROM percentile_stats
)
SELECT
    d.customer_city,
    d.delay_days
FROM delivery_delay_stats d, outliers o
WHERE d.delay_days < (o.q1 - o.iqr_multiplier)
    OR d.delay_days > (o.q3 + o.iqr_multiplier)
