-- How many rows are in the olist_geolocation_dataset?
SELECT COUNT(*) FROM olist_geolocation_dataset;
-- How many unique zip code prefixes are there?
SELECT DISTINCT
    geolocation_zip_code_prefix
FROM olist_geolocation_dataset;
-- How many unique cities are in the dataset?
SELECT DISTINCT geolocation_city FROM olist_geolocation_dataset;
-- What is the most common state?
SELECT geolocation_state
FROM olist_geolocation_dataset
GROUP BY
    geolocation_state
ORDER BY COUNT(geolocation_state) DESC
LIMIT 1;
-- What is the most common city in the dataset?
SELECT geolocation_city
FROM olist_geolocation_dataset
GROUP BY
    geolocation_city
ORDER BY COUNT(geolocation_city) DESC
LIMIT 1;
-- How many unique combinations of city and state exist?
SELECT
    COUNT(
        DISTINCT (
            geolocation_city,
            geolocation_state
        )
    ) AS unique_city_state_combination_count
FROM olist_geolocation_dataset;
-- Which city has the most zip code prefixes?
SELECT geolocation_city, COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) AS unique_zips
FROM olist_geolocation_dataset
GROUP BY
    geolocation_city
ORDER BY COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) DESC
LIMIT 1;
-- How many zip code prefixes are there per state?
SELECT
    geolocation_state,
    COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) AS zip_code_prefix_count
FROM olist_geolocation_dataset
GROUP BY
    geolocation_state
ORDER BY zip_code_prefix_count DESC;
-- What are the top 5 cities by number of entries?
SELECT geolocation_city, COUNT(*) AS entry_count
FROM olist_geolocation_dataset
GROUP BY
    geolocation_city
ORDER BY entry_count DESC
LIMIT 5;
-- What is the average latitude and longitude per state?
SELECT
    geolocation_state,
    AVG(geolocation_lat) AS average_latitide,
    AVG(geolocation_lng) AS average_longitude
FROM olist_geolocation_dataset
GROUP BY
    geolocation_state;
-- Which zip code prefix appears in more than one state?
SELECT
    geolocation_zip_code_prefix,
    COUNT(DISTINCT geolocation_state) AS unique_state
FROM olist_geolocation_dataset
GROUP BY
    geolocation_zip_code_prefix
HAVING
    COUNT(DISTINCT geolocation_state) > 1;
-- How many zip code prefixes are shared by more than one city?
SELECT COUNT(*)
FROM (
        SELECT geolocation_zip_code_prefix, COUNT(DISTINCT geolocation_city)
        FROM olist_geolocation_dataset
        GROUP BY
            geolocation_zip_code_prefix
        HAVING
            COUNT(DISTINCT geolocation_city) > 1
    ) AS repeated_zips
WITH
    zip_city_counts AS (
        SELECT
            geolocation_zip_code_prefix,
            COUNT(DISTINCT geolocation_city) as unique_city_count
        FROM olist_geolocation_dataset
        GROUP BY
            geolocation_zip_code_prefix
    )
SELECT COUNT(*)
FROM zip_city_counts
WHERE
    unique_city_count > 1;
-- Find all cities that span more than 5 zip code prefixes.
SELECT geolocation_city, COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) AS unique_zip
FROM olist_geolocation_dataset
GROUP BY
    geolocation_city
HAVING
    COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) > 5;
-- Identify states where a single city takes up more than 50% of the zip code prefixes.
-- Step 1: Get zip prefix count per city in each state
WITH
    state_city_zip_count AS (
        SELECT
            geolocation_state,
            geolocation_city,
            COUNT(
                DISTINCT geolocation_zip_code_prefix
            ) as city_zip_count
        FROM olist_geolocation_dataset
        GROUP BY
            geolocation_state,
            geolocation_city
    ),
    -- Step 2: Get total zip prefix count per state
    state_total_zip_count AS (
        SELECT
            geolocation_state,
            COUNT(
                DISTINCT geolocation_zip_code_prefix
            ) AS total_zip_count
        FROM olist_geolocation_dataset
        GROUP BY
            geolocation_state
    )
    -- Step 3: Join and filter cities where zip % > 50%
SELECT c.geolocation_state, c.geolocation_city, c.city_zip_count, s.total_zip_count, ROUND(
        1.0 * c.city_zip_count / s.total_zip_count, 2
    ) AS zip_percentage
FROM
    state_city_zip_count c
    JOIN state_total_zip_count s ON c.geolocation_state = s.geolocation_state
WHERE
    1.0 * c.city_zip_count / s.total_zip_count > 0.5
ORDER BY zip_percentage DESC;
-- Find the top 3 cities per state by number of distinct zip code prefixes.
WITH
    state_city_zip_count AS (
        SELECT
            geolocation_state,
            geolocation_city,
            COUNT(
                DISTINCT geolocation_zip_code_prefix
            ) AS city_zip_count
        FROM olist_geolocation_dataset
        GROUP BY
            geolocation_state,
            geolocation_city
        ORDER BY city_zip_count DESC
    ),
    ranked_cities AS (
        SELECT *, ROW_NUMBER() OVER (
                PARTITION BY
                    geolocation_state
                ORDER BY city_zip_count DESC
            ) AS rank_within_state
        FROM state_city_zip_count
    )
SELECT
    geolocation_state,
    geolocation_city,
    city_zip_count
FROM ranked_cities
WHERE
    rank_within_state <= 3
ORDER BY
    geolocation_state,
    rank_within_state

SELECT ranked.geolocation_state, ranked.geolocation_city, ranked.city_zip_count
FROM (
        SELECT
            geolocation_state, geolocation_city, COUNT(
                DISTINCT geolocation_zip_code_prefix
            ) AS city_zip_count, ROW_NUMBER() OVER (
                PARTITION BY
                    geolocation_state
                ORDER BY COUNT(
                        DISTINCT geolocation_zip_code_prefix
                    ) DESC
            ) AS rank_within_state
        FROM olist_geolocation_dataset
        GROUP BY
        GROUP BY
            geolocation_state, geolocation_city
    ) AS ranked
WHERE
    rank_within_state <= 3
ORDER BY
    geolocation_state,
    rank_within_state;
-- Are there zip code prefixes used in more than one city and state? List them.
WITH
    zip_more_than_one_city AS (
        SELECT
            geolocation_zip_code_prefix,
            COUNT(DISTINCT geolocation_city) AS unique_city_count,
            COUNT(DISTINCT geolocation_state) AS unique_state_count
        FROM olist_geolocation_dataset
        GROUP BY
            geolocation_zip_code_prefix
    )
SELECT
    geolocation_zip_code_prefix,
    unique_city_count,
    unique_state_count
FROM zip_more_than_one_city
WHERE
    unique_city_count > 1
    AND unique_state_count > 1
ORDER BY
    unique_city_count,
    unique_state_count
SELECT
    geolocation_zip_code_prefix,
    COUNT(DISTINCT geolocation_city) AS city_count,
    COUNT(DISTINCT geolocation_state) AS state_count
FROM olist_geolocation_dataset
GROUP BY
    geolocation_zip_code_prefix
HAVING
    COUNT(DISTINCT geolocation_city) > 1
    AND COUNT(DISTINCT geolocation_state) > 1
ORDER BY city_count, state_count DESC;
-- Find the geographic center (avg lat/lng) of each state.
SELECT
    geolocation_state,
    AVG(geolocation_lat) AS avg_latitude,
    AVG(geolocation_lng) AS avg_longitude
FROM olist_geolocation_dataset
GROUP BY
    geolocation_state;
-- Cluster zip codes (prefixes) by proximity using lat/lng rounding (e.g., round to 1 decimal place).
SELECT
    ROUND(geolocation_lat::numeric, 1) AS lat_cluster,
    ROUND(geolocation_lng::numeric, 1) AS lng_cluster,
    COUNT(
        DISTINCT geolocation_zip_code_prefix
    ) AS zip_prefix_count,
    COUNT(*) AS total_points
FROM olist_geolocation_dataset
GROUP BY
    ROUND(geolocation_lat::numeric, 1),
    ROUND(geolocation_lng::numeric, 1)
ORDER BY zip_prefix_count DESC;
