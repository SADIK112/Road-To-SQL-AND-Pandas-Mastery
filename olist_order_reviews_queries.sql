-- Show all the data from review table
SELECT * FROM olist_order_reviews_dataset;
-- How many total reviews are there?
SELECT COUNT(*) FROM olist_order_reviews_dataset;
-- How many unique orders have reviews?
SELECT COUNT(DISTINCT order_id) AS total_unique_orders
FROM olist_order_reviews_dataset;
-- What is the average review score?
SELECT ROUND(AVG(review_score)::NUMERIC, 2) AS average_review
FROM olist_order_reviews_dataset;
-- What is the most common review score?
SELECT review_score, COUNT(review_score) AS review_count
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_count DESC
LIMIT 1;
-- How many reviews have no comment message?
SELECT COUNT(*) AS null_count
FROM olist_order_reviews_dataset
WHERE review_comment_message ISNULL; 
-- How many reviews have no title but have a message?
SELECT COUNT(*) AS reviews_with_message_but_no_title
FROM olist_order_reviews_dataset
WHERE review_comment_title ISNULL AND review_comment_message IS NOT NULL;
-- Count of reviews for each score (1 to 5)?
SELECT review_score, COUNT(*) AS score_count
FROM olist_order_reviews_dataset
GROUP BY review_score;
-- How many 5-star reviews are there?
SELECT review_score, COUNT(*) AS score_count
FROM olist_order_reviews_dataset
GROUP BY review_score
HAVING review_score = 5;
-- How many 1-star reviews are there?
SELECT review_score, COUNT(*) AS score_count
FROM olist_order_reviews_dataset
GROUP BY review_score
HAVING review_score = 1;
-- What is the earliest and latest review creation date?
SELECT 
    MIN(review_creation_date) AS oldest_review_date,
    MAX(review_creation_date) AS latest_review_date
FROM olist_order_reviews_dataset;
-- Average review score per day.
SELECT
    CAST(review_creation_date AS DATE) AS day_review,
    ROUND(AVG(review_score)::NUMERIC, 2) AS average_review
FROM olist_order_reviews_dataset
GROUP BY day_review
ORDER BY day_review ASC;
-- Which day had the most reviews?
SELECT
    CAST(review_creation_date AS DATE) AS day_review,
    COUNT(review_score) AS review_count
FROM olist_order_reviews_dataset
GROUP BY day_review
ORDER BY review_count DESC
LIMIT 1;
-- How many reviews were created each month?
-- BY YYYY-MM
SELECT
    TO_CHAR(review_creation_date, 'YYYY-MM') AS review_month,
    COUNT(review_score) AS review_count
FROM olist_order_reviews_dataset
GROUP BY review_month;
-- BY JUST DATE
SELECT
    CAST(DATE_TRUNC('month', review_creation_date) AS DATE) AS review_month,
    COUNT(review_score) AS review_count
FROM olist_order_reviews_dataset
GROUP BY review_month;
-- What is the average time taken to respond to a review? (review_answer_timestamp - review_creation_date)
SELECT
    ROUND(AVG(EXTRACT(EPOCH FROM (review_answer_timestamp::TIMESTAMP - review_creation_date::TIMESTAMP)) / (3600 * 24)), 2) AS avg_response_days
FROM olist_order_reviews_dataset
WHERE review_creation_date IS NOT NULL
  AND review_answer_timestamp IS NOT NULL
  AND review_answer_timestamp::TIMESTAMP > review_creation_date::TIMESTAMP;
-- Which review has the longest message?
SELECT
    review_id, 
    length(review_comment_message) AS review_length
FROM olist_order_reviews_dataset
WHERE review_comment_message IS NOT NULL
ORDER BY review_length DESC
LIMIT 1;
-- What percentage of reviews had a comment message?
WITH message_stats AS (
    SELECT 
        COUNT(*) FILTER (WHERE review_comment_message IS NOT NULL) AS review_message,
        COUNT(*) AS total_record
    FROM olist_order_reviews_dataset
)
SELECT ROUND((review_message::NUMERIC / total_record) * 100, 2) AS perc_review_msg
FROM message_stats;
-- What is the distribution of review scores over time (month/year)?
SELECT
    EXTRACT(YEAR FROM review_creation_date) AS year,
    EXTRACT(MONTH FROM review_creation_date) AS month,
    review_score,
    COUNT(*) AS total_reviews
FROM olist_order_reviews_dataset
GROUP BY year, month, review_score
ORDER BY year, month, review_score;
-- Which review score has the fastest average response time?
SELECT 
    review_score,
    ROUND(AVG((review_answer_timestamp::DATE - review_creation_date::DATE)), 2) AS average_response_days
    FROM olist_order_reviews_dataset
WHERE review_answer_timestamp IS NOT NULL AND review_creation_date IS NOT NULL
GROUP BY review_score
ORDER BY average_response_days ASC
LIMIT 1;
-- Find top 5 days with the most 5-star reviews.
SELECT
    review_score,
    CAST(review_creation_date AS DATE) AS review_days,
    COUNT(*) AS review_count
FROM olist_order_reviews_dataset
WHERE review_creation_date IS NOT NULL
GROUP BY review_score, review_days
HAVING review_score = 5
ORDER BY review_count DESC
LIMIT 5;
-- Count of reviews by presence of title and/or message.
SELECT
    CASE
        WHEN review_comment_title IS NOT NULL AND review_comment_message IS NOT NULL THEN 'Both message & title'
        WHEN review_comment_title IS NOT NULL AND review_comment_message IS NULL THEN 'Only title'
        WHEN review_comment_title IS NULL AND review_comment_message IS NOT NULL THEN 'Only message'
        ELSE 'Neither'
    END AS review_type,
    COUNT(*) AS review_count
FROM olist_order_reviews_dataset
GROUP BY review_type;
-- Which orders have multiple reviews?
SELECT
    order_id,
    ARRAY_AGG(review_id) AS review_ids,
    COUNT(DISTINCT review_id) AS review_count
FROM olist_order_reviews_dataset
GROUP BY order_id
HAVING COUNT(DISTINCT review_id) > 1;
-- Which review scores have the most detailed feedback (longest messages)?
SELECT
    review_score,
    ROUND(AVG(length(review_comment_message)), 2) AS avg_message_length,
    COUNT(*) AS review_count
FROM olist_order_reviews_dataset
WHERE review_comment_message IS NOT NULL
GROUP BY review_score
ORDER BY avg_message_length DESC;
-- Monthly average review score and trend (increasing/decreasing)?
SELECT
    CAST(DATE_TRUNC('month', review_creation_date) AS DATE) AS review_month,
    ROUND(AVG(review_score), 2) AS average_review
FROM olist_order_reviews_dataset
WHERE review_creation_date IS NOT NULL
GROUP BY review_month
ORDER BY review_month; 
-- Detect sentiment pattern: Are longer messages more likely to be low scores?
SELECT
    review_score,
    COUNT(*) review_count,
    ROUND(AVG(length(review_comment_message)), 2) AS average_message_length
FROM olist_order_reviews_dataset
WHERE review_comment_message IS NOT NULL
GROUP BY review_score
ORDER BY average_message_length DESC;
-- Create a summary table: score, total reviews, avg response time, % with message
SELECT
    review_score,
    COUNT(*) AS total_reviews,
    ROUND(AVG(review_answer_timestamp::DATE - review_creation_date::DATE), 2) AS average_response_days,
    ROUND(100 * COUNT(review_comment_message) / COUNT(*), 2) AS perc_with_message
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score;
-- Find the average delay (in hours) between review creation and answer by day
SELECT ROUND(AVG(EXTRACT(EPOCH FROM (review_answer_timestamp::TIMESTAMP - review_creation_date::TIMESTAMP)) / 3600.0), 2) AS average_delay_in_hours
FROM olist_order_reviews_dataset
WHERE review_answer_timestamp IS NOT NULL AND review_creation_date IS NOT NULL;
-- Find reviews that were responded to more than 7 days after creation
SELECT *,
       (review_answer_timestamp::DATE - review_creation_date::DATE) AS response_delay_days
FROM olist_order_reviews_dataset
WHERE 
  review_answer_timestamp IS NOT NULL 
  AND review_creation_date IS NOT NULL
  AND (review_answer_timestamp::DATE - review_creation_date::DATE) > 7;
-- What is the standard deviation of review scores per month?
SELECT
    CAST(DATE_TRUNC('month', review_creation_date) AS DATE) AS review_month,
    ROUND(STDDEV(review_score), 2) AS standard_review_score
FROM olist_order_reviews_dataset
WHERE review_creation_date IS NOT NULL
GROUP BY review_month
ORDER BY review_month ASC;
-- Find reviews created and answered on the same day
SELECT *
FROM olist_order_reviews_dataset
WHERE 
    review_creation_date IS NOT NULL AND review_answer_timestamp IS NOT NULL AND
    (review_answer_timestamp::DATE - review_creation_date::DATE) = 0;
-- What is the average review score per weekday (e.g., Monday, Tuesday)?
SELECT
    TO_CHAR(review_creation_date, 'day') AS weekday,
    ROUND(AVG(review_score), 2) AS avg_review_score
FROM olist_order_reviews_dataset
WHERE review_creation_date IS NOT NULL
GROUP BY TO_CHAR(review_creation_date, 'day');
