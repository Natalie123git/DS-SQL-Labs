# Monday Coffee Expansion Analysis

## 1. Project Overview
Monday Coffee is a fictional coffee brand that has been selling its products online across multiple Indian cities since January 2023. The company is now looking to expand into physical store locations and wants to make data‑driven decisions about where to open.  

In this capstone project, I act as a **Data Analyst** for Monday Coffee. Using SQL, I analyzed sales, customer, product and city data to identify the **top three Indian cities best suited for new physical coffee shop locations**.

---

## 2. Problem Statement
The key business problem is:  
> *Cities that Monday Coffee should prioritize for its first physical store expansion, based on demand, customer behavior, profitability, and growth potential*

---
## 4. Project Objectives
- Estimate Market Potential
- Measure City‑Level Performance
- Assess Cost Efficiency
- Identify Growth Trends
- Build Comparative Scorecards
- Recommend Expansion Strategy 
---

## 4. Data Description
The data is divided into 4 tables which are in csv format.
- **Sales Table:** Transaction records (sale_id, sale_date, product_id, customer_id, total and rating).  
- **Customers Table:** Customer details (customer_id, customer_name, city_id).  
- **City Table:** City demographics and costs (city_id, city_name, population, estimated_rent, city_rank).  
- **Products Table:** Product catalog (product_id, product_name, price).

![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/ERD.png)

---

## 5. Methodology
Executed **14 SQL questions** to explore the dataset:
- **Demand Analysis:** Coffee consumer estimates, total revenue per city, product sales volumes.  
- **Customer Behavior:** Average sales per customer, unique customers per city, average orders per customer.  
- **Profitability:** Rent efficiency (avg sales vs. avg rent per customer).  
- **Growth Trends:** Month‑on‑month percentage change, YoY revenue comparison.  
- **Market Potential:** Combined scorecard of revenue, rent, customers, and consumer base.  

Each query was run in PostgreSQL, with outputs validated and screenshots captured.

---

## 6. Syntaxes and Results

### Drop existing tables

```sql
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;
```

### Create, Import and View tables

```sql
-- Create Products table
CREATE TABLE products (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(30),
    price TEXT
);

-- Create City table
CREATE TABLE city (
    city_id INT PRIMARY KEY,
    city_name VARCHAR(100),
	population INT,
	estimated_rent INT,
    city_rank INT
);

-- Create Customers table
CREATE TABLE customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    city_id INT REFERENCES city(city_id)
);

-- Create Sales table
CREATE TABLE sales (
    sale_id INT PRIMARY KEY,
    sale_date DATE,
	product_id INT REFERENCES products(product_id),
    customer_id INT REFERENCES customers(customer_id),
    total INT,
    rating INT
);

--View tables
SELECT * FROM products;
SELECT * FROM customers;
SELECT * FROM city;
SELECT * FROM sales;
```

### Questions

#### Question 1: Coffee Consumer Estimate
```sql
-- This query calculates the estimated number of coffee consumers by assuming 25% of each city’s population drinks coffee, converting the figure into millions, and ordering results from highest to lowest.  

SELECT
	city_name,
	ROUND((population * 0.25)/1000000.0, 2) AS coffee_cust_mil
FROM city
ORDER BY coffee_cust_mil DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_1_Coffee_Consumer_Estimate.png)
---

#### Question 2: Total Revenue per city for Q4 2023
```sql
-- This query computes the total coffee sales revenue per city during the last quarter of 2023 and sorts cities by revenue descending.  

SELECT 
    city.city_name,
    SUM(sales.total) AS total_revenue
FROM sales
JOIN customers 
    ON sales.customer_id = customers.customer_id
JOIN city 
    ON customers.city_id = city.city_id
WHERE sales.sale_date BETWEEN '2023-10-01' AND '2023-12-31'
GROUP BY city.city_name
ORDER BY total_revenue DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_2_Total_Revenue_per_city_Q4_2023.png)
---

#### Question 3: Sales Volume by Product
```sql
-- This query sums the total units sold for each coffee product and ranks products from best‑selling to least‑selling.  

SELECT
	products.product_name,
	COUNT(sales.product_id) AS total_units_sold
FROM sales
JOIN products
	ON sales.product_id = products.product_id
GROUP BY products.product_name
ORDER BY total_units_sold DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_3_Sales_Volume_by_Product.png)
---

#### Question 4: Average Sales per Customer by City
```sql
-- This query calculates average sales per customer by dividing total revenue by the number of unique customers in each city, while also showing total revenue and customer count.  

SELECT 
    city.city_name,
    SUM(sales.total) AS total_revenue,
    COUNT(DISTINCT customers.customer_id) AS customer_count,
    SUM(sales.total) / COUNT(DISTINCT customers.customer_id) AS avg_sales_per_customer
FROM sales
JOIN customers 
    ON sales.customer_id = customers.customer_id
JOIN city 
    ON customers.city_id = city.city_id
GROUP BY city.city_name
ORDER BY total_revenue DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_4_Average_Sales_per_Customer_by_City.png)
---

#### Question 5: Current Customers vs. Estimated Coffee Consumers
```sql
-- This query uses CTEs to compare the estimated coffee‑drinking population with the actual number of unique customers from sales data.  

WITH estimated_coffee_consumers AS (
    SELECT
		city.city_id,
		city_name,
		ROUND((population * 0.25)/1000000.0, 2) AS coffee_cust_mil
	FROM city
	ORDER BY coffee_cust_mil DESC
),
current_customers AS (
    SELECT 
        customers.city_id,
        COUNT(DISTINCT customers.customer_id) AS current_customers
    FROM sales
    JOIN customers 
        ON sales.customer_id = customers.customer_id
    GROUP BY customers.city_id
)
SELECT 
    e.city_name,
    e.coffee_cust_mil,
    cc.current_customers
FROM estimated_coffee_consumers e
LEFT JOIN current_customers cc 
    ON e.city_id = cc.city_id
ORDER BY e.coffee_cust_mil DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_5_Current_Customers_vs_Estimated_Coffee_Consumers.png)
---

#### Question 6: Top 3 Products per City
```sql
-- This query ranks coffee products within each city by number of orders using a window function and selects the top three products per city.  

SELECT 
	city_name, 
	product_name,
	total_orders
FROM (
	SELECT
		city.city_name,
		products.product_name,
		COUNT(sales.product_id) AS total_orders,
		RANK() OVER (
	            PARTITION BY city.city_name 
	            ORDER BY COUNT(sales.product_id) DESC
	        ) AS product_rank
	FROM sales
	JOIN products
		ON sales.product_id = products.product_id
	JOIN customers
		ON sales.customer_id = customers.customer_id
	JOIN city
		ON customers.city_id = city.city_id
	GROUP BY city.city_name, products.product_name
	)
WHERE product_rank <= 3
ORDER BY city_name, total_orders DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_6_Top_3_Products_per_City_1.png)
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_6_Top_3_Products_per_City_2.png)
---

#### Question 7: Unique Customers per City.
```sql
-- This query counts the distinct customers in each city who have made at least one coffee purchase and orders cities by customer count descending.  

SELECT
	city.city_name,
	COUNT(DISTINCT sales.customer_id) AS current_customers
FROM sales
JOIN customers
	ON sales.customer_id = customers.customer_id
JOIN city
	ON customers.city_id = city.city_id
GROUP BY city.city_name
ORDER BY current_customers DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_7_Unique_Customers_per_City.png)
---

#### Question 8: Average Sale vs. Average Rent per Customer for evaluation of cost efficiency.
```sql
-- This query compares the average sale amount per customer against the average rent cost per customer to evaluate cost efficiency across cities.  

SELECT 
    city.city_name,
    SUM(sales.total) / COUNT(DISTINCT customers.customer_id) AS avg_sale_per_cust,
    city.estimated_rent / COUNT(DISTINCT customers.customer_id) AS avg_rent_per_cust
FROM sales
JOIN customers 
    ON sales.customer_id = customers.customer_id
JOIN city 
    ON customers.city_id = city.city_id
GROUP BY city.city_name, city.estimated_rent
ORDER BY avg_sale_per_cust DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_8_Average_Sale_vs_Average_Rent_per_Customer.png)
---

#### Question 9: Month-on-Month percentage change in Sales Growth
```sql
-- This query calculates the month‑on‑month percentage change in total sales for each city by using the LAG() window function to compare each month’s sales with the previous month, excluding the first month where no prior data exists.  

SELECT 
    city_name,
    sale_month,
    total_sales,
    prev_month_sales,
    ROUND(((total_sales - prev_month_sales) * 100.0 / prev_month_sales), 2) AS pct_change
FROM (
    SELECT 
        city.city_name,
        DATE_TRUNC('month', sales.sale_date) AS sale_month,
        SUM(sales.total) AS total_sales,
        LAG(SUM(sales.total)) OVER (
            PARTITION BY city.city_name 
            ORDER BY DATE_TRUNC('month', sales.sale_date)
        ) AS prev_month_sales
    FROM sales
    JOIN customers
		ON sales.customer_id = customers.customer_id
    JOIN city
		ON customers.city_id = city.city_id
    GROUP BY city.city_name, DATE_TRUNC('month', sales.sale_date)
)
WHERE prev_month_sales IS NOT NULL
ORDER BY city_name, sale_month;
```
https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_9_Month-on-Month_percentage_change.csv

![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_9_Month-on-Month_percentage_change.png)
---

#### Question 10: Market Potential Summary per city.
```sql
-- This query produces a comprehensive market potential table per city, showing total revenue, estimated rent, total customers, estimated coffee consumers, and average sales and rent per customer, ordered by revenue descending.  

SELECT 
    city.city_name,
    SUM(sales.total) AS total_revenue,
    city.estimated_rent,
    COUNT(DISTINCT customers.customer_id) AS total_customers,
    ROUND((city.population * 0.25) / 1000000.0, 2) AS coffee_cust_mil,
	ROUND(SUM(sales.total) * 1.0 / COUNT(DISTINCT customers.customer_id), 2) AS avg_sales_per_customer,
    ROUND(city.estimated_rent * 1.0 / COUNT(DISTINCT customers.customer_id), 2) AS avg_rent_per_customer
FROM sales
JOIN customers 
    ON sales.customer_id = customers.customer_id
JOIN city 
    ON customers.city_id = city.city_id
GROUP BY city.city_name, city.estimated_rent, city.population
ORDER BY total_revenue DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_10_Market_Potential_Summary_per_city.png)
---

#### Question 11: Top 20 customers with their city information
```sql
-- Who are the top 20 customers, based on their total spending across all purchases and number of orders?

SELECT 
    customers.customer_id,
    customers.customer_name,
    city.city_name,
    SUM(sales.total) AS total_cust_revenue,
    COUNT(sales.sale_id) AS customer_orders
FROM sales
JOIN customers
    ON sales.customer_id = customers.customer_id
JOIN city
    ON customers.city_id = city.city_id
GROUP BY customers.customer_id, customers.customer_name, city.city_name
ORDER BY total_cust_revenue DESC
LIMIT 20;
-- This query reveals the top 10 customers ranked by total spending, 
-- helping Monday Coffee recognize its most valuable clients and prioritize them for 
-- loyalty programs, personalized offers, or premium services.
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_11_Top_20_customers.png)
---

#### Question 12: Cities with the highest average number of orders per customer
```sql
-- Which cities have the highest average number of orders per customer?  

SELECT 
    city.city_name,
    ROUND(COUNT(sales.sale_id) * 1.0 / COUNT(DISTINCT customers.customer_id), 2) AS avg_orders_per_customer
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
GROUP BY city.city_name
ORDER BY avg_orders_per_customer DESC;
-- This query shows where customers buy most frequently, highlighting cities with stronger engagement and potential for steady foot traffic in physical stores.
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_12_Cities_with_highest_average_orders_per_customer.png)
---

#### Question 13: Which cities generated the highest revenue growth rate over the past year?
```sql
-- Year-over-year(yoy) revenue growth per city
SELECT 
    city.city_name,
    SUM(CASE WHEN EXTRACT(YEAR FROM sales.sale_date) = 2023 THEN sales.total END) AS revenue_2023,
    SUM(CASE WHEN EXTRACT(YEAR FROM sales.sale_date) = 2024 THEN sales.total END) AS revenue_2024,
    ROUND((SUM(CASE WHEN EXTRACT(YEAR FROM sales.sale_date) = 2024 THEN sales.total END) - 
           SUM(CASE WHEN EXTRACT(YEAR FROM sales.sale_date) = 2023 THEN sales.total END)) * 100.0 /
           SUM(CASE WHEN EXTRACT(YEAR FROM sales.sale_date) = 2023 THEN sales.total END), 2) AS yoy_growth_pct
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
GROUP BY city.city_name
ORDER BY yoy_growth_pct DESC;
-- This query highlights cities where sales are accelerating fastest, signaling strong momentum and future potential for physical store expansion.
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_13_Year-over-year_revenue_growth_per_city.png)
---

#### Question 14: Total Revenue per city for Q4 2023 vs 2024
```sql
-- This query computes the total coffee sales revenue per city during the last quarter of 2023 and sorts cities by revenue descending.  

-- Total Revenue per City for Q4 2023 vs Q4 2024
SELECT 
    city.city_name,
    SUM(CASE 
            WHEN sales.sale_date BETWEEN '2023-10-01' AND '2023-12-31' 
            THEN sales.total 
            ELSE 0 
        END) AS revenue_q4_2023,
    SUM(CASE 
            WHEN sales.sale_date BETWEEN '2024-10-01' AND '2024-12-31' 
            THEN sales.total 
            ELSE 0 
        END) AS revenue_q4_2024
FROM sales
JOIN customers ON sales.customer_id = customers.customer_id
JOIN city ON customers.city_id = city.city_id
GROUP BY city.city_name
ORDER BY revenue_q4_2024 DESC;
```
![Result1](https://github.com/Natalie123git/DS-SQL-Labs/blob/main/Question_14_Total_Revenue_per_City%20_Q4_2023_vs_Q4_2024.png)

---

## 7. SQL Concepts Used
- **Aggregations:** `SUM()`, `COUNT()`, `AVG()`  
- **Grouping:** `GROUP BY` with multiple columns  
- **Conditional Logic:** `CASE WHEN` for filtering by quarter/year  
- **Joins:** `INNER JOIN` across sales, customers, city, products  
- **Window Functions:** `LAG()` for month‑on‑month growth, `RANK()` for top products per city  
- **CTEs:** Used for intermediate calculations (e.g., consumer estimates vs. current customers)

---

## 8. Key Insights & Recommendations
| City | Combined Total Revenue | Customers | Coffee Consumers (M) | Avg Orders/Customer | Avg Sales/Customer | Avg Rent/Customer | YoY Growth (%) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **Pune** | ₹1,258,290 | 52 | 1.88 | 41.06 | ₹24,197 | ₹294 | -52.48% |
| **Chennai** | ₹944,120 | 42 | 2.78 | 38.12 | ₹22,479 | ₹407 | -54.37% |
| **Bangalore** | ₹860,110 | 39 | 3.08 | 37.54 | ₹22,054 | ₹761 | -55.08% |
| **Jaipur** | ₹803,450 | 69 | 1.00 | 19.96 | ₹11,644 | ₹156 | -42.55% |
| **Delhi** | ₹750,420 | 68 | 7.75 | 19.19 | ₹11,035 | ₹330 | -34.19% |
| **Mumbai** | ₹235,000 | 27 | 5.10 | 15.67 | ₹8,703 | ₹1,167 | -34.45% |
| **Kanpur** | ₹213,550 | 35 | 0.78 | 10.63 | ₹6,101 | ₹231 | -19.68% |
| **Surat** | ₹176,540 | 27 | 1.80 | 11.00 | ₹6,538 | ₹500 | -23.79% |
| **Kolkata** | ₹171,460 | 28 | 3.73 | 10.21 | ₹6,123 | ₹579 | -23.27% |
| **Nagpur** | ₹140,050 | 24 | 0.73 | 10.54 | ₹5,835 | ₹300 | -34.94% |
| **Indore** | ₹138,590 | 21 | 0.83 | 11.00 | ₹6,600 | ₹300 | -46.45% |
| **Ahmedabad** | ₹137,690 | 23 | 2.08 | 9.78 | ₹5,987 | ₹626 | -26.37% |
| **Hyderabad** | ₹131,520 | 21 | 2.50 | 10.52 | ₹6,263 | ₹1,071 | -44.12% |
| **Lucknow** | ₹109,400 | 21 | 0.95 | 9.43 | ₹5,210 | ₹429 | -34.97% |

- **Pune:** Highest revenue (₹1.25M), strong loyalty (avg orders per customer = 41.06), excellent rent efficiency (₹24,197 sales vs. ₹294 rent per customer).  
- **Chennai:** Second highest revenue (₹944,120). Large customer base (42), high avg orders (38.12), strong seasonal growth in Sept 2023.  
- **Bangalore:** Third highest revenue (₹860,110), high avg orders (37.54), Average sales per customer (₹22,054) compared to rent per customer (₹761) still shows profitability, strong demand spikes in Sept 2023.  
- **YoY Decline in 2024:** Online sales dropped across all cities, signaling maybe saturation. Physical stores can stabilize demand and capture untapped consumer potential.
- Top 20 customers are from the above cities, with the highest average sales per customer and highest total revenue

**Recommendation:** Open first physical stores in **Pune, Chennai, and Bangalore** to balance profitability, loyalty, and growth momentum.

---

## 9. Limitations & Future Work
- **Data Limitations:** Dataset may not fully capture one‑time buyers (repeat rate anomaly). 
- **Timeframe:** Analysis limited to 2023–2024. Data for 2024 seemed to be quite low and so analysis results were mainly based on data from 2023, longer historical data would improve forecasting.  
- **External Factors:** Rent estimates are static; real estate market fluctuations not modeled.  
- **Future Work:**  
  - Incorporate marketing campaign data to explain seasonal spikes.  
  - Use predictive modeling (ARIMA, regression) for demand forecasting.  
  - Add competitor benchmarking for store placement strategy.

---
