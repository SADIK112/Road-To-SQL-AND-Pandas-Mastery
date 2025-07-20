-- Show all data
SELECT * FROM olist_sellers_dataset;
-- How many sellers are in the dataset?
SELECT COUNT(*) FROM olist_sellers_dataset;
-- How many sellers are there in each state?
SELECT seller_state, COUNT(*) AS seller_count
FROM olist_sellers_dataset
WHERE seller_state IS NOT NULL
GROUP BY seller_state
ORDER BY seller_count DESC;
-- Which state has the most sellers?
SELECT seller_state
FROM olist_sellers_dataset
WHERE seller_state IS NOT NULL
GROUP BY seller_state
ORDER BY COUNT(*) DESC
LIMIT 1;
-- Which city has the highest number of sellers?
SELECT seller_city
FROM olist_sellers_dataset
WHERE seller_city IS NOT NULL
GROUP BY seller_city
ORDER BY COUNT(*) DESC
LIMIT 1;
-- What is the average number of sellers per state?
SELECT ROUND(AVG(seller_count), 2) AS avg_seller_count
FROM (
    SELECT seller_state, COUNT(*) AS seller_count
    FROM olist_sellers_dataset
    WHERE seller_state IS NOT NULL
    GROUP BY seller_state
) sub;
-- Which states have more than 100 sellers?
SELECT seller_state
FROM olist_sellers_dataset
WHERE seller_state IS NOT NULL
GROUP BY seller_state
HAVING COUNT(*) > 100;
-- How many sellers are in the top 10 cities by seller count?
SELECT seller_city, COUNT(*) AS seller_count
FROM olist_sellers_dataset
WHERE seller_city IS NOT NULL
GROUP BY seller_city
ORDER BY seller_count DESC
LIMIT 10;
-- Which cities have only one seller?
SELECT seller_city, COUNT(*) AS seller_count
FROM olist_sellers_dataset
WHERE seller_city IS NOT NULL
GROUP BY seller_city
HAVING COUNT(*) = 1;
-- Rank cities by the number of sellers within each state.
SELECT 
    seller_city, 
    COUNT(*) AS seller_count,
    DENSE_RANK() OVER (
        PARTITION BY seller_state
        ORDER BY COUNT(*) DESC
    ) AS city_state_rank
FROM olist_sellers_dataset
GROUP BY seller_state, seller_city
ORDER BY seller_state, city_state_rank;
-- Find states where a single city accounts for more than 50% of sellers in that state.
WITH state_city_count AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS state_city_seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
),
state_count AS (
    SELECT seller_state, COUNT(*) AS state_seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state
)
SELECT
    sc.seller_state,
    sc.seller_city,
    ROUND((sc.state_city_seller_count::numeric / s.state_seller_count) * 100, 2) AS perc_state_city
FROM state_city_count sc
JOIN state_count s
    ON sc.seller_state = s.seller_state
WHERE (sc.state_city_seller_count::numeric / s.state_seller_count) > 0.5
ORDER BY perc_state_city DESC;
-- More efficient approach
WITH state_city_count AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS state_city_seller_count,
        SUM(COUNT(*)) OVER (PARTITION BY seller_state) AS state_seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
)
SELECT
    seller_state,
    seller_city,
    ROUND((state_city_seller_count::NUMERIC / state_seller_count) * 100, 2) AS perc_state_city
FROM state_city_count
WHERE (state_city_seller_count::NUMERIC / state_seller_count) > 0.5
ORDER BY perc_state_city DESC;
-- Which state has the highest concentration of sellers in its top 3 cities?
WITH state_city_rank AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS seller_count,
        ROW_NUMBER() OVER (
            PARTITION BY seller_state
            ORDER BY COUNT(*) DESC
        ) AS city_rank
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
    ORDER BY seller_state, city_rank
),
top3_city_state_totals AS (
    SELECT 
        seller_state,
        SUM(seller_count) AS top3_total
    FROM state_city_rank
    WHERE city_rank <= 3
    GROUP BY seller_state
),
state_total AS (
    SELECT
        seller_state,
        COUNT(*) AS state_seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state
)
SELECT
    t.seller_state,
    ROUND((t.top3_total::NUMERIC / s.state_seller_count) * 100, 2) AS top3_city_concentration
FROM top3_city_state_totals t
JOIN state_total s
    ON t.seller_state = s.seller_state
ORDER BY top3_city_concentration DESC;
-- Calculate the percentage of sellers in each state compared to the total number of sellers.
SELECT
    seller_state,
    COUNT(*) AS seller_count,
    ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS seller_percentage
FROM olist_sellers_dataset
GROUP BY seller_state
ORDER BY seller_percentage DESC;
-- Identify cities that belong to states with more than 500 sellers but themselves have fewer than 10 sellers.
WITH state_seller_stats AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS seller_city_count,
        SUM(COUNT(*)) OVER (PARTITION BY seller_state) AS seller_state_count
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
)
SELECT
    seller_state,
    seller_city,
    seller_city_count,
    seller_state_count
FROM state_seller_stats
WHERE seller_city_count < 10 AND seller_state_count > 500
ORDER BY seller_state, seller_city_count;
-- Find the top 5 states that contribute to 80% of all sellers (Pareto principle).
WITH seller_stats AS (
    SELECT
        seller_state,
        COUNT(*) AS seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state
),
ranked_states AS (
    SELECT
        seller_state,
        seller_count,
        SUM(seller_count) OVER (ORDER BY seller_count DESC) AS cum_seller_count,
        SUM(seller_count) OVER () AS total_seller
    FROM seller_stats
),
final AS (
    SELECT
        seller_state,
        cum_seller_count,
        ROUND(100 * cum_seller_count / total_seller, 2) AS cum_percentage
    FROM ranked_states
)
SELECT *
FROM final
WHERE cum_percentage <= 80;
-- Which state has the lowest seller-to-city ratio (sellers per city)?
WITH state_seller_city_counts AS (
    SELECT
        seller_state,
        COUNT(*) AS total_sellers,
        COUNT(DISTINCT seller_city) AS total_cities
    FROM olist_sellers_dataset
    GROUP BY seller_state
)
SELECT
    seller_state,
    ROUND(total_sellers::numeric / total_cities, 2) AS seller_to_city_ratio
FROM state_seller_city_counts
ORDER BY seller_to_city_ratio ASC
LIMIT 1;
-- Identify the median number of sellers per city for each state and rank the states by this median.
WITH state_seller_stats AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
),
state_medians AS (
    SELECT
        seller_state,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY seller_count) AS median_sellers_per_city
    FROM state_seller_stats
    GROUP BY seller_state
)
SELECT
    seller_state,
    median_sellers_per_city,
    ROW_NUMBER() OVER (
        ORDER BY median_sellers_per_city DESC
    ) AS state_rank
FROM state_medians
ORDER BY state_rank;
-- Detect outliers: Which cities have unusually high numbers of sellers compared to others in the same state?
WITH city_seller_counts AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
),
stats AS (
    SELECT
        PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY seller_count) AS q1,
        PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY seller_count) AS q3
    FROM city_seller_counts
),
outlier_thresolds AS (
    SELECT q1, q3, (q3 - q1) * 1.5 AS iqr_multiplier
    FROM stats
)
SELECT
    s.seller_state,
    s.seller_city,
    s.seller_count
FROM city_seller_counts s, outlier_thresolds ot
    WHERE s.seller_count < (ot.q1 - ot.iqr_multiplier)
    OR s.seller_count > (ot.q3 + ot.iqr_multiplier)
ORDER BY s.seller_count DESC;
-- For each state, calculate the percentage contribution of its largest city to the total sellers in that state.
WITH state_city_rank_stats AS (
    SELECT
        seller_state,
        seller_city,
        COUNT(*) AS state_city_seller,
        SUM(COUNT(*)) OVER (PARTITION BY seller_state) AS state_seller,
        ROW_NUMBER() OVER (
            PARTITION BY seller_state
            ORDER BY COUNT(*) DESC
        ) AS city_rank
    FROM olist_sellers_dataset
    GROUP BY seller_state, seller_city
    ORDER BY seller_state, city_rank
)
SELECT
    seller_state,
    seller_city,
    state_city_seller,
    state_seller,
    city_rank,
    ROUND(100 * state_city_seller / state_seller, 2) AS perc_state_city
FROM state_city_rank_stats
WHERE city_rank = 1;
-- Create a cumulative distribution of sellers by state and find the state where cumulative percentage crosses 70%.
WITH state_seller_stats AS (
    SELECT
        seller_state,
        COUNT(*) AS seller_count
    FROM olist_sellers_dataset
    GROUP BY seller_state
),
cum_seller_stats AS (
    SELECT
        seller_state,
        SUM(seller_count) OVER (ORDER BY seller_count DESC) AS cum_seller_count,
        SUM(seller_count) OVER () AS total_seller
    FROM state_seller_stats
)
SELECT
    seller_state,
    cum_seller_count,
    ROUND(100.0 * cum_seller_count / total_seller, 2) AS perc_cum_seller
FROM cum_seller_stats
WHERE ROUND(100.0 * cum_seller_count / total_seller, 2) >= 70
ORDER BY cum_seller_count
LIMIT 1;
-- Which states have an equal number of sellers and unique cities?
SELECT
    seller_state,
    COUNT(*) AS seller_count,
    COUNT(DISTINCT seller_city) AS city_count
FROM olist_sellers_dataset
GROUP BY seller_state
HAVING COUNT(*) = COUNT(DISTINCT seller_city)
