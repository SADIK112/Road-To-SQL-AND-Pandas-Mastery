-- Show all products
SELECT * FROM olist_products_dataset;
-- Count the total number of products.
SELECT COUNT(*) FROM olist_products_dataset;
-- How many unique product categories exist?
SELECT COUNT(DISTINCT product_category_name) 
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL;
-- List all distinct product categories.
SELECT DISTINCT product_category_name 
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL;
-- How many products have missing category names?
SELECT COUNT(*) 
FROM olist_products_dataset
WHERE product_category_name IS NULL OR product_category_name = '';
-- Find the average product_weight_g across all products.
SELECT ROUND(AVG(product_weight_g), 2) AS avg_product_weight
FROM olist_products_dataset;
-- What is the maximum and minimum product_length and height?
SELECT 
    MAX(product_length_cm) AS max_length,
    MIN(product_length_cm) AS min_length,
    MAX(product_height_cm) AS max_height,
    MIN(product_height_cm) AS min_height
FROM olist_products_dataset;
-- Which product has the longest category?
SELECT 
    product_category_name,
    length(product_category_name) AS category_name_length
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL OR product_category_name = ''
ORDER BY category_name_length DESC
LIMIT 1;
-- How many products have weight greater than 5000 grams?
SELECT 
    COUNT(*)
FROM olist_products_dataset
WHERE product_weight_g > 1000;
-- Find the top 5 product categories by number of products.
SELECT
    product_category_name,
    COUNT(*) AS products_count
FROM olist_products_dataset
GROUP BY product_category_name
ORDER BY products_count DESC
LIMIT 5;
-- Which product category has the heaviest average weight?
SELECT
    product_category_name,
    ROUND(AVG(product_weight_g), 2) AS average_weight
FROM olist_products_dataset
GROUP BY product_category_name
ORDER BY average_weight DESC
LIMIT 1;
-- Rank categories by average product weight.
SELECT
    product_category_name,
    ROUND(AVG(product_weight_g), 2) AS avg_weight,
    RANK() OVER (
        ORDER BY ROUND(AVG(product_weight_g), 2) DESC
    ) AS category_rank
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL AND product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY category_rank;
-- How many products have all dimensions (length, height, width) greater than 100 cm?
SELECT COUNT(*) FROM olist_products_dataset
WHERE product_length_cm > 100
    AND product_height_cm > 100
    AND product_width_cm > 100;
-- Which category has the smallest average dimensions (L × W × H)?
SELECT
    product_category_name,
    (product_length_cm * product_height_cm * product_width_cm) AS dimension
FROM olist_products_dataset
WHERE product_length_cm IS NOT NULL
    AND product_height_cm IS NOT NULL
    AND product_width_cm IS NOT NULL
ORDER BY dimension ASC
LIMIT 1;
-- Which category has the largest average product volume (L × W × H in cm³)?
SELECT
    product_category_name,
    ROUND(AVG(product_length_cm * product_height_cm * product_width_cm), 2) AS volume
FROM olist_products_dataset
WHERE product_length_cm IS NOT NULL
    AND product_height_cm IS NOT NULL
    AND product_width_cm IS NOT NULL
GROUP BY product_category_name
ORDER BY volume ASC
LIMIT 1;
-- Find the standard deviation of product weights by category.
SELECT
    product_category_name,
    ROUND(STDDEV(product_weight_g), 2) AS std_weight
FROM olist_products_dataset
WHERE product_weight_g IS NOT NULL
    AND product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY std_weight DESC;
-- Which products have extreme dimensions (outliers) based on volume?
-- IQR = Q3 - Q1; outlier rule → outside [Q1 - 1.5×IQR, Q3 + 1.5×IQR].
WITH products_volume AS (
    SELECT
        product_id,
        product_category_name,
        ROUND(product_length_cm * product_height_cm * product_width_cm, 2) AS volume
    FROM olist_products_dataset
    WHERE product_length_cm IS NOT NULL
        AND product_height_cm IS NOT NULL
        AND product_width_cm IS NOT NULL
),
stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY volume) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY volume) AS q3
    FROM products_volume
),
outlier_thresolds AS (
    SELECT q1, q3, (q3 - q1) * 1.5 AS iqr_multiplier
    FROM stats
)
SELECT
    pv.product_id,
    pv.product_category_name,
    pv.volume
FROM products_volume pv, outlier_thresolds ot
    WHERE pv.volume < (ot.q1 - ot.iqr_multiplier)
    OR pv.volume > (ot.q3 + ot.iqr_multiplier)
ORDER BY pv.volume DESC; 
-- Top 5 categories with the highest variation in product_weight_g.
-- here variation hints to find standard deviation
SELECT
    product_category_name,
    ROUND(STDDEV(product_weight_g), 2) AS std_weight
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
    AND product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY std_weight DESC
LIMIT 5;
-- Find the correlation between product weight and volume.
-- close to +1 means positive corr
-- close to 0 means no corr
-- close to -1 means negative corr
SELECT
    ROUND(CORR(product_weight_g, (product_length_cm * product_height_cm * product_width_cm))::NUMERIC, 2) AS weight_volume_corr
FROM olist_products_dataset
WHERE product_weight_g IS NOT NULL
    AND product_length_cm IS NOT NULL
    AND product_height_cm IS NOT NULL
    AND product_width_cm IS NOT NULL;
-- Which category has the largest difference between max and min product weights?
SELECT
    product_category_name,
    (MAX(product_weight_g) - MIN(product_weight_g)) AS min_max_diff
FROM olist_products_dataset
WHERE product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY min_max_diff DESC;
-- Which product category contributes the highest percentage to total product volume?
WITH categorywise_volume AS (
    SELECT
        product_category_name,
        SUM(product_length_cm * product_height_cm * product_width_cm)::NUMERIC AS ctg_volume
    FROM olist_products_dataset
    WHERE product_category_name IS NOT NULL
      AND product_length_cm IS NOT NULL
      AND product_height_cm IS NOT NULL
      AND product_width_cm IS NOT NULL
    GROUP BY product_category_name
),
total_volume AS (
    SELECT
        SUM(product_length_cm * product_height_cm * product_width_cm)::NUMERIC AS volume
    FROM olist_products_dataset
    WHERE product_length_cm IS NOT NULL
      AND product_height_cm IS NOT NULL
      AND product_width_cm IS NOT NULL
)
SELECT
    product_category_name,
    ROUND((ct.ctg_volume / t.volume) * 100, 2) AS perc_volume_ctg
FROM categorywise_volume ct
CROSS JOIN total_volume t
ORDER BY perc_volume_ctg DESC;
-- better approach
SELECT
    product_category_name,
    ROUND(SUM(product_length_cm * product_height_cm * product_width_cm)::NUMERIC /
          SUM(SUM(product_length_cm * product_height_cm * product_width_cm)) OVER () * 100, 2) AS perc_volume_ctg
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
    AND product_length_cm IS NOT NULL
    AND product_height_cm IS NOT NULL
    AND product_width_cm IS NOT NULL
GROUP BY product_category_name
ORDER BY perc_volume_ctg DESC;
-- Compute category-wise median/2nd quatile weight.
SELECT
    product_category_name,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY product_weight_g) AS median_weight
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
    AND product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY median_weight DESC;
-- Compute category-wise 1st quartile weight.
SELECT
    product_category_name,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY product_weight_g) AS first_quartile_weigth
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
    AND product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY first_quartile_weigth DESC;
-- Compute category-wise 3rd quartile weight.
SELECT
    product_category_name,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY product_weight_g) AS third_quartile_weigth
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
    AND product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY third_quartile_weigth DESC;
-- Which categories have the most variation in product size (standard deviation of weight)?
SELECT
    product_category_name,
    ROUND(STDDEV(product_weight_g)::NUMERIC, 2) AS weight_variation
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
    AND product_weight_g IS NOT NULL
GROUP BY product_category_name
ORDER BY weight_variation DESC;
