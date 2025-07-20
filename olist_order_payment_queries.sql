-- Show Full dataset
SELECT * FROM olist_order_payments_dataset;
-- Alter all rows name where payment type = not_defined to cash
UPDATE olist_order_payments_dataset
SET payment_type = 'cash'
WHERE payment_type = 'not_defined';
-- How many payment records are there in total?
SELECT COUNT(*) FROM olist_order_payments_dataset;
-- What are the different types of payment methods used in the dataset?
SELECT DISTINCT payment_type FROM olist_order_payments_dataset;
-- Which payment type appears most frequently?
SELECT payment_type, COUNT(*) AS payments FROM olist_order_payments_dataset
GROUP BY("payment_type")
ORDER BY payments DESC
LIMIT 1;
-- What is the total amount paid across all orders?
SELECT ROUND(SUM(payment_value)::NUMERIC, 2) FROM olist_order_payments_dataset;
-- How many payments were made in a single installment?
SELECT COUNT(payment_installments) AS installment_count FROM olist_order_payments_dataset
WHERE  payment_installments = 1;
-- What is the average payment value for each payment type?
SELECT payment_type, ROUND(AVG(payment_value)::NUMERIC, 2) AS average_payment_amount
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY average_payment_amount DESC;
-- How many times does each number of installments occur?
SELECT payment_installments, COUNT(*) AS installment_count
FROM olist_order_payments_dataset
GROUP BY payment_installments
ORDER BY installment_count DESC;
-- What is the total payment value per payment type?
SELECT payment_type, ROUND(SUM(payment_value)::NUMERIC, 2) AS total_payment_amount
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_payment_amount DESC;
-- What is the highest and lowest payment value in the dataset?
SELECT min(payment_value), max(payment_value) FROM olist_order_payments_dataset;
-- How many unique orders used more than one payment (look for repeated order_ids)?
WITH unique_orders_payment AS (
    SELECT order_id, COUNT(DISTINCT payment_type) AS payment_method_count
    FROM olist_order_payments_dataset
    GROUP BY order_id
    HAVING COUNT(DISTINCT payment_type) > 1
)
SELECT COUNT(*) FROM unique_orders_payment;
-- Which orders had the most number of installments? List top 10.
SELECT order_id, SUM(payment_installments) AS total_installment
FROM olist_order_payments_dataset
GROUP BY order_id
ORDER BY total_installment DESC
LIMIT 10;
-- What’s the average number of installments for each payment 
SELECT 
  payment_type,
  ROUND(AVG(payment_installments)::NUMERIC, 2) AS avg_installments
FROM olist_order_payments_dataset
GROUP BY payment_type;
-- Identify the top 5 orders with the highest total payment value, considering that an order may have multiple payment rows.
SELECT order_id, ROUND(SUM(payment_value)::NUMERIC, 2) AS total_payment_value
FROM olist_order_payments_dataset
GROUP BY order_id
ORDER BY total_payment_value DESC;
-- Which payment type has the highest average number of installments?
SELECT payment_type,
ROUND(AVG(payment_installments)::NUMERIC, 2) AS avg_installments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY avg_installments DESC
LIMIT 1;
-- What percentage of total payments was made using credit card vs boleto?
SELECT 
  ROUND(100.0 * SUM(CASE WHEN payment_type = 'credit_card' THEN 1 ELSE 0 END) / COUNT(*), 2) AS credit_card_percentage,
  ROUND(100.0 * SUM(CASE WHEN payment_type = 'boleto' THEN 1 ELSE 0 END) / COUNT(*), 2) AS boleto_percentage
FROM olist_order_payments_dataset;
