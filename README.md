# 🟩 Query: Ecommerce Data Query Exploration

## 📌 Description
The **Brazilian E-Commerce dataset** by Olist is a comprehensive collection of real sales data from a multi-vendor marketplace operating in Brazil. It covers detailed interactions between customers and sellers, including order information, delivery times, product details, payment transactions, and customer reviews.

### 📦 What's Included
- **Customers**: Unique customers with location details
- **Orders**: Order status, timestamps (purchase, delivery, etc.)
- **Order Items**: Products within orders, prices, and shipping costs
- **Products**: Product categories and metadata
- **Sellers**: Information about vendors and their locations
- **Payments**: Payment methods and transaction values
- **Reviews**: Customer review scores and comments
- **Geolocation**: Zip-code level coordinates for mapping

### 📊 Total Records
- ~100k orders
- ~75k customers
- ~3k sellers
- Covers a period between **2016 and 2018**

### 🧩 Source
- Originally published on [Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- Released by Olist, a Brazilian marketplace platform

This project focuses on performing **data analysis on the Olist E-commerce dataset** using both **SQL** and **Python (Pandas)**.  
The goal is to answer business questions related to sellers, cities, states, product dimensions, and categories by combining the power of **SQL queries** and **Python-based analysis**.
First initally we explore each type of data one by one in both sql and python and answering the same question in both places. This will make sure we master the query in both domain and
learn how to do complex queries.

---

## **Objective**
The primary goal is to analyze the Olist dataset to uncover trends, patterns, and outliers across different dimensions, including:
- **Sellers:** Distribution across states and cities, city dominance, top 3 city concentration, Pareto principle.
- **Products:** Volume, weight analysis, correlation, and category contributions.
- **States & Cities:** Median sellers per city, seller-to-city ratio, and outliers.

---

## **Our Approach**
1. **Analyze Each Table Separately:**  
   We start with a **single table at a time** (e.g., `olist_sellers_dataset`) and write SQL queries to answer questions like:
   - What is the average number of sellers per state?
   - Which states have the highest concentration of sellers in the top 3 cities?
   - Which states have a single city accounting for more than 50% of sellers?

2. **Outlier Detection & Statistical Analysis:**  
   For tables like `olist_products_dataset`, we calculate product volumes, detect outliers (IQR method), and check correlations (e.g., between product weight and volume).

3. **Pandas Implementation:**  
   Once we verify logic in SQL, we replicate and expand the analysis using **Pandas** to build cumulative distributions, rankings, and Pareto analysis.

---

## **Key Analytical Questions**
### Sellers:
- **Distribution:** How many sellers are there per state and per city?
- **Ranking:** How do cities rank by seller count within each state?
- **Dominance:** Are there states where a single city contributes more than 50% of sellers?
- **Concentration:** Which state has the highest concentration of sellers in its top 3 cities?
- **Pareto Principle:** Which states make up 70% or 80% of all sellers cumulatively?

### Products:
- Which products have **extreme dimensions** (outliers) based on volume?
- What is the **correlation between product weight and volume**?
- Which **category** has the largest difference between max and min product weights?
- Which product category contributes the **highest percentage to total product volume**?

### City-State Insights:
- Identify cities that belong to states with **more than 500 sellers but have fewer than 10 sellers**.
- Find **states with an equal number of sellers and unique cities**.
- Calculate the **median number of sellers per city for each state** and rank states by this median.

---

## **Tools & Technologies**
- **SQL (PostgreSQL/MySQL)** for initial analysis:
  - Window functions: `RANK()`, `ROW_NUMBER()`, `PERCENTILE_CONT()`.
  - CTEs and aggregate functions: `SUM()`, `COUNT()`, `AVG()`, `MAX()`, `MIN()`.
  - Outlier detection using IQR.

- **Python (Pandas, NumPy):**
  - `groupby`, `size`, `rank`, `quantile`, and `merge` for replication of SQL logic.
  - Cumulative distribution and Pareto calculations (`cumsum`).
  - Outlier detection and advanced category-level metrics.

---

## **Workflow**
1. Load datasets into SQL (or query CSV files directly with Pandas).
2. Write **SQL queries for each table individually** to answer the questions.
3. Replicate and extend queries in **Python (Pandas)** to cross-verify results.
4. (Optional) Build visualizations using **Matplotlib/Seaborn**.

---

## **Next Steps**
- Create **visual Pareto charts** to show cumulative seller distribution by state.
- Automate comparison of SQL and Pandas results for validation.
- Build an interactive dashboard with **Streamlit** or **Plotly Dash**.

---

## **Dataset**
We use the [Olist E-commerce Dataset](https://www.kaggle.com/olistbr/olist-dataset) which includes:
- `olist_sellers_dataset`
- `olist_products_dataset`
- Other related tables (orders, payments, etc., planned for later stages).
