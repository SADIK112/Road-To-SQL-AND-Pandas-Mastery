
-- 1. Count total records in the table
SELECT count(*) FROM olist_customers_dataset;

-- 2. Count unique customers
SELECT COUNT(DISTINCT customer_unique_id) AS unique_customer
FROM olist_customers_dataset;

-- 3. List all distinct states
SELECT DISTINCT customer_state
FROM olist_customers_dataset;

-- 4. Count customers in each state
SELECT customer_state, COUNT(*) AS customer_count
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY customer_count DESC;

-- 5. Cities with the most customers
SELECT customer_city, COUNT(customer_unique_id) AS customer_count
FROM olist_customers_dataset
GROUP BY customer_city
ORDER BY customer_count DESC;

-- 6. Count customers from Sao Paulo
SELECT customer_city, COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_city
HAVING customer_city LIKE 'sao paulo';

-- 7. Most common zip code prefix
SELECT customer_zip_code_prefix, count(*) as count_zip_prefix
FROM olist_customers_dataset
GROUP BY customer_zip_code_prefix
ORDER BY count_zip_prefix DESC
LIMIT 1;

-- 8. Top 10 cities by customer count
SELECT customer_city, COUNT(*) as customer_count
FROM olist_customers_dataset
GROUP BY customer_city
ORDER BY customer_count DESC
LIMIT 10;

-- 8.1. Second top 10 cities by customer count
SELECT customer_city, COUNT(*) as customer_count
FROM olist_customers_dataset
GROUP BY customer_city
ORDER BY customer_count DESC
LIMIT 10 OFFSET 10;

-- 9. Count unique cities in each state
SELECT customer_state, COUNT(DISTINCT customer_city) AS unique_city_count
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY unique_city_count DESC;

-- 10. Count customers in zip code prefix 9790
SELECT count(*)
FROM olist_customers_dataset
WHERE customer_zip_code_prefix = 9790;

-- 11. States with more than 1,000 customers
SELECT customer_state, COUNT(*) as customer_count
FROM olist_customers_dataset
GROUP BY customer_state
HAVING COUNT(*) > 1000
ORDER BY customer_count DESC;

-- 12. Zip code prefixes with more than 50 customers
SELECT customer_zip_code_prefix, COUNT(*) as customer_count
FROM olist_customers_dataset
GROUP BY customer_zip_code_prefix
HAVING COUNT(*) > 50
ORDER BY customer_count ASC;

-- 13. Customers in cities starting with "rio"
SELECT * FROM olist_customers_dataset
WHERE customer_city LIKE 'rio%';

-- 14. Top 5 states by unique customers
SELECT customer_state, COUNT(DISTINCT customer_unique_id) as unique_customer_count
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY unique_customer_count DESC
LIMIT 5;

-- 15. City with highest number of duplicate customers
SELECT customer_city, COUNT(*) AS duplicate_customer_count
FROM (
    SELECT customer_city, customer_unique_id
    FROM olist_customers_dataset
    GROUP BY customer_city, customer_unique_id
    HAVING COUNT(*) > 1
) AS duplicated_customers
GROUP BY customer_city
ORDER BY duplicate_customer_count DESC
LIMIT 1;

-- 16. Count customer_unique_ids appearing more than once
SELECT count(*) as duplicate_customer
FROM (
    SELECT customer_unique_id
    FROM olist_customers_dataset
    GROUP BY customer_unique_id
    HAVING COUNT(*) > 1
) AS repeated_ids;

-- 17. Cities with customers having multiple zip code prefixes
SELECT customer_city, COUNT(DISTINCT customer_zip_code_prefix) as unique_zip_counts
FROM olist_customers_dataset
GROUP BY customer_city
HAVING COUNT(DISTINCT customer_zip_code_prefix) > 1
ORDER BY unique_zip_counts DESC;

-- 18. Cities existing in multiple states
SELECT customer_city, COUNT(DISTINCT customer_state) as unique_states
FROM olist_customers_dataset
GROUP BY customer_city
HAVING COUNT(DISTINCT customer_state) > 1;

-- 19. Count customers in cities containing "paulo"
SELECT COUNT(*) FROM olist_customers_dataset
WHERE customer_city LIKE '%paulo%';

-- 20. Percentage of customers from SP
SELECT ROUND(
    100 * COUNT(*) FILTER(WHERE customer_state = 'SP') / COUNT(*)
) as percentage_from_SP
FROM olist_customers_dataset;

-- 20.1. Percentage of distinct customers from SP
SELECT ROUND(
    100 * COUNT(DISTINCT customer_unique_id) FILTER(WHERE customer_state = 'SP') / COUNT(*)
) as percentage_from_SP
FROM olist_customers_dataset;

-- 22. City with highest number of repeated customers
SELECT customer_city, COUNT(*) AS repeated_customer_count
FROM (
    SELECT customer_city, customer_unique_id
    FROM olist_customers_dataset
    GROUP BY customer_city, customer_unique_id
    HAVING COUNT(*) > 1
) AS repeated_customers
GROUP BY customer_city
ORDER BY repeated_customer_count DESC;

-- 23. Rank cities within each state by customer count
SELECT customer_city, customer_state,
COUNT(DISTINCT customer_unique_id) AS customer_count,
DENSE_RANK() OVER (
    PARTITION BY customer_state
    ORDER BY COUNT(DISTINCT customer_unique_id) DESC) as city_rank
FROM olist_customers_dataset
GROUP BY customer_city, customer_state
ORDER BY customer_state, city_rank;

-- 24. Assign row number to each customer_unique_id by zip code
SELECT 
  customer_unique_id,
  customer_zip_code_prefix,
  ROW_NUMBER() OVER (
    PARTITION BY customer_unique_id 
    ORDER BY customer_zip_code_prefix
  ) AS row_num
FROM olist_customers_dataset;

-- 25. Customers appearing in multiple cities
SELECT customer_unique_id, STRING_AGG(DISTINCT customer_city, ', ') AS cities
FROM olist_customers_dataset
GROUP BY customer_unique_id
HAVING COUNT(DISTINCT customer_city) > 1;

-- 26. Summary table: state, total customers, unique cities, average zip code
SELECT customer_state,
COUNT(DISTINCT customer_unique_id) AS customer_count,
COUNT(DISTINCT customer_city) AS city_count,
ROUND(AVG(customer_zip_code_prefix), 2) AS average_zip_code
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY customer_count DESC;

-- 27. Top 3 zip code prefixes per state by customer count
SELECT * FROM (
    SELECT customer_state, customer_zip_code_prefix,
    COUNT(DISTINCT customer_unique_id) AS customer_count,
    DENSE_RANK() OVER (
        PARTITION BY customer_state
        ORDER BY COUNT(DISTINCT customer_unique_id) DESC
    ) AS zip_rank
    FROM olist_customers_dataset
    GROUP BY customer_state, customer_zip_code_prefix
) AS ranked_zips
WHERE zip_rank <= 3
ORDER BY customer_state, zip_rank;

-- 28. Average number of customers per city within each state
SELECT 
    customer_state, 
    ROUND(AVG(customer_per_city), 2) AS avg_customer_per_city
FROM (
    SELECT customer_state, customer_city, 
    COUNT(DISTINCT customer_unique_id) AS customer_per_city
    FROM olist_customers_dataset
    GROUP BY customer_state, customer_city
)
GROUP BY customer_state
ORDER BY avg_customer_per_city DESC;

-- 29. Cities with customers from more than 3 different zip codes
WITH zip_per_city AS (
    SELECT customer_city,
    COUNT(DISTINCT customer_zip_code_prefix) AS zip_count
    FROM olist_customers_dataset
    GROUP BY customer_city
)
SELECT customer_city
FROM zip_per_city
WHERE zip_count > 3;

-- 30. Customers with zip code prefixes shared across states
WITH shared_zip_codes AS (
    SELECT customer_zip_code_prefix
    FROM olist_customers_dataset
    GROUP BY customer_zip_code_prefix
    HAVING COUNT(DISTINCT customer_state) > 1
)
SELECT customer_unique_id
FROM olist_customers_dataset
WHERE customer_zip_code_prefix IN (
    SELECT customer_zip_code_prefix FROM shared_zip_codes
);
