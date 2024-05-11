-- Create database
CREATE DATABASE IF NOT EXISTS amazonSalesData;

-- Using the database
USE amazonsalesdata;

-- Create table
CREATE TABLE IF NOT EXISTS sales(
	invoice_id VARCHAR(30) NOT NULL PRIMARY KEY,
    branch VARCHAR(5) NOT NULL,
    city VARCHAR(30) NOT NULL,
    customer_type VARCHAR(30) NOT NULL,
    gender VARCHAR(10) NOT NULL,
    product_line VARCHAR(100) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    quantity INT NOT NULL,
    VAT FLOAT(6,4) NOT NULL,
    total DECIMAL(10, 2) NOT NULL,
    date DATETIME NOT NULL,
    time TIME NOT NULL,
    payment_method VARCHAR(15) NOT NULL,
    cogs DECIMAL(10,2) NOT NULL,
    gross_margin_percentage FLOAT(11,9),
    gross_income DECIMAL(10, 2) NOT NULL,
    rating FLOAT(2, 1)
);

-- ********************************************************************************************
-- Feature Enginering

-- Add the time_of_day column
SELECT
	time,
	(CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END) AS time_of_day
FROM sales;

ALTER TABLE sales ADD COLUMN time_of_day VARCHAR(20);

UPDATE sales
SET time_of_day = (
	CASE
		WHEN `time` BETWEEN "00:00:00" AND "12:00:00" THEN "Morning"
        WHEN `time` BETWEEN "12:01:00" AND "16:00:00" THEN "Afternoon"
        ELSE "Evening"
    END
);

-- Add day_name column
SELECT
	date,
	DAYNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN day_name VARCHAR(10);

UPDATE sales
SET day_name = DAYNAME(date);


-- Add month_name column
SELECT
	date,
	MONTHNAME(date)
FROM sales;

ALTER TABLE sales ADD COLUMN month_name VARCHAR(10);

UPDATE sales 
SET 
    month_name = MONTHNAME(date);

-- ****************************************************************************************************
-- Exploratory Data Analysis

-- Question 1: What is the count of distinct cities in the dataset?

SELECT 
	DISTINCT city
FROM sales;

-- Question 2: For each branch, what is the corresponding city?

SELECT DISTINCT
    branch, city
FROM
    sales;

-- Question 3: What is the count of distinct product lines in the dataset?

SELECT
	DISTINCT product_line
FROM sales;

-- Question 4: Which payment method occurs most frequently?

SELECT 
    payment_method, COUNT(payment_method) as total_count
FROM
    sales
GROUP BY payment_method
ORDER BY total_count DESC;

-- Question 5: Which product line has the highest sales?

SELECT 
    product_line, SUM(total) AS total_sales
FROM
    sales
GROUP BY product_line
ORDER BY total_sales DESC;

-- Question 6: How much revenue is generated each month?

SELECT 
    month_name, SUM(total) AS total_revenue
FROM
    sales
GROUP BY month_name
ORDER BY total_revenue DESC;

-- Question 7: In which month did the cost of goods sold reach its peak?

SELECT 
    month_name, SUM(cogs) AS cost_of_goods_sold
FROM
    sales
GROUP BY month_name
ORDER BY cost_of_goods_sold DESC;

-- Question 8: Which product line generated the highest revenue?

SELECT 
    product_line, SUM(total) AS total_revenue
FROM
    sales
GROUP BY product_line
ORDER BY total_revenue DESC;

-- Question 9: In which city was the highest revenue recorded?

SELECT 
    city, SUM(total) AS total_revenue
FROM
    sales
GROUP BY city
ORDER BY total_revenue DESC;

-- Question 10: Which product line incurred the highest Value Added Tax?

SELECT 
    product_line, SUM(VAT) AS total_vat
FROM
    sales
GROUP BY product_line
ORDER BY total_vat DESC;

-- Question 11: For each product line, add a column indicating "Good" if its sales are above average, otherwise "Bad."

WITH CTE_Sub_Table AS (
SELECT ROUND(AVG(total),2) AS Avg_Total_Sales
FROM sales
)

SELECT product_line, ROUND(SUM(total),2) AS total_sales,ROUND(AVG(total),2) AS avg_sales, 
CASE
WHEN AVG(total) > (SELECT * FROM CTE_Sub_Table) THEN 'Good'
ELSE 'Bad'
END AS Status_of_Sales
FROM sales
GROUP BY product_line;


-- Question 12: Identify the branch that exceeded the average number of products sold.

SELECT 
    branch, SUM(quantity) AS qnty
FROM
    sales
GROUP BY branch
HAVING SUM(quantity) > (SELECT 
        AVG(quantity)
    FROM
        sales);

-- Question 13: Which product line is most frequently associated with each gender?

WITH gender_product_count as (
SELECT gender, product_line, COUNT(*) AS gender_count,
ROW_NUMBER() OVER(PARTITION BY gender ORDER BY count(*) DESC) as rn
FROM sales
GROUP BY gender, product_line
)
SELECT gender, product_line, gender_count
FROM gender_product_count
WHERE rn=1;

-- Question 14: Calculate the average rating for each product line.

SELECT 
    product_line, ROUND(AVG(rating), 2) AS avg_rating
FROM
    sales
GROUP BY product_line
ORDER BY avg_rating DESC;

-- Question 15: Count the sales occurrences for each time of day on every weekday.

 SELECT 
    day_name,time_of_day,
    COUNT(*) AS sales_occurrences
FROM 
    sales
GROUP BY 
   day_name, time_of_day
ORDER BY 
    day_name, time_of_day;

-- Question 16: Identify the customer type contributing the highest revenue.

SELECT 
    customer_type, SUM(total) AS total_revenue
FROM
    sales
GROUP BY customer_type
ORDER BY total_revenue DESC;

-- Question 17: Determine the city with the highest VAT percentage.

SELECT 
    city, ROUND(AVG(VAT), 2) AS vat
FROM
    sales
GROUP BY city
ORDER BY vat DESC;

-- Question 18: Identify the customer type with the highest VAT payments.

SELECT 
    customer_type, SUM(VAT) AS total_tax
FROM
    sales
GROUP BY customer_type
ORDER BY total_tax DESC;

-- Question 19: What is the count of distinct customer types in the dataset?

SELECT
	DISTINCT customer_type
FROM sales;

-- Question 20: What is the count of distinct payment methods in the dataset?

SELECT
	DISTINCT payment_method
FROM sales;

-- Question 21: Which customer type occurs most frequently?

SELECT 
    customer_type, COUNT(*) AS count
FROM
    sales
GROUP BY customer_type
ORDER BY count DESC;

-- Question 22: Identify the customer type with the highest purchase frequency.

SELECT 
    customer_type, COUNT(*) as customer_freq
FROM
    sales
GROUP BY customer_type
ORDER BY customer_freq DESC;

-- Question 23: Determine the predominant gender among customers

SELECT 
    gender, COUNT(*) AS gender_cnt
FROM
    sales
GROUP BY gender
ORDER BY gender_cnt DESC;

-- Question 24: Examine the distribution of genders within each branch.

SELECT branch, gender, COUNT(gender) AS gender_cnt
FROM sales
GROUP BY branch, gender
ORDER BY branch, gender;

-- Question 25: Identify the time of day when customers provide the most ratings.

SELECT 
    time_of_day, AVG(rating) AS avg_rating
FROM
    sales
GROUP BY time_of_day
ORDER BY avg_rating DESC;

-- Question 26: Determine the time of day with the highest customer ratings for each branch.

WITH cte AS
(
SELECT branch, time_of_day, AVG(rating) AS max_rating ,
RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) AS rn
FROM sales
GROUP BY branch, time_of_day
)
SELECT branch, time_of_day, max_rating
FROM cte
WHERE rn=1;

-- Question 27: Identify the day of the week with the highest average ratings.

SELECT 
    day_name, ROUND(AVG(rating),2) AS avg_rating
FROM
    sales
GROUP BY day_name
ORDER BY avg_rating DESC;

-- Question 28: Determine the day of the week with the highest average ratings for each branch.

WITH branch_weekday_ratings as(
SELECT branch, day_name, AVG(rating) AS avg_rating
FROM sales
GROUP BY branch, day_name
),
ranked_branch_weekday_ratings AS (
SELECT branch, day_name,avg_rating,
RANK() OVER(PARTITION BY branch ORDER BY avg_rating DESC) AS  rating_rank
FROM branch_weekday_ratings
)
SELECT 
    branch,
    day_name,
    avg_rating
FROM 
    ranked_branch_weekday_ratings
WHERE 
    rating_rank = 1;
