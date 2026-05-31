/*-------------------------------------------------------------------------------
								Monday Coffee
							Business Expansion Analysis
--------------------------------------------------------------------------------*/

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS city;

--Import tables

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

-- Question 1: Coffee Consumer Estimate
-- This query calculates the estimated number of coffee consumers by assuming 25% of each city’s population drinks coffee, converting the figure into millions, and ordering results from highest to lowest.  

SELECT
	city_name,
	ROUND((population * 0.25)/1000000.0, 2) AS coffee_cust_mil
FROM city
ORDER BY coffee_cust_mil DESC;

-- Question 2: Total Revenue per city for Q4 2023
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

-- Question 3: Sales Volume by Product
-- This query sums the total units sold for each coffee product and ranks products from best‑selling to least‑selling.  

SELECT
	products.product_name,
	COUNT(sales.product_id) AS total_units_sold
FROM sales
JOIN products
	ON sales.product_id = products.product_id
GROUP BY products.product_name
ORDER BY total_units_sold DESC;

-- Question 4: Average Sales per Customer by City
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

-- Question 5: Current Customers vs. Estimated Coffee Consumers
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

-- Question 6: Top 3 Products per City
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


-- Question 7: Unique Customers per City.
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
	
-- Question 8: Average Sale vs. Average Rent per Customer for evaluation of cost efficiency.
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

-- Question 9: Month-on-Month percentage change in Sales Growth
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

-- Question 10: Market Potential Summary per city.
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

-- Question 11: Top 20 customers with their city information
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


-- Question 12: Cities with the highest average number of orders per customer
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


-- Question 13: Which cities generated the highest revenue growth rate over the past year?
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

-- Question 14: Total Revenue per city for Q4 2023 vs 2024
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

