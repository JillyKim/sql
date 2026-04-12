/* ASSIGNMENT 2 */
--Please write responses between the QUERY # and END QUERY blocks
/* SECTION 2 */

-- COALESCE
/* 1. Our favourite manager wants a detailed long list of products, but is afraid of tables! 
We tell them, no problem! We can produce a list with all of the appropriate details. 

Using the following syntax you create our super cool and not at all needy manager a list:

SELECT 
product_name || ', ' || product_size|| ' (' || product_qty_type || ')'
FROM product

But wait! The product table has some bad data (a few NULL values). 
Find the NULLs and then using COALESCE, replace the NULL with a blank for the first column with
nulls, and 'unit' for the second column with nulls. 

**HINT**: keep the syntax the same, but edited the correct components with the string. 
The `||` values concatenate the columns into strings. 
Edit the appropriate columns -- you're making two edits -- and the NULL rows will be fixed. 
All the other rows will remain the same. */
--QUERY 1

SELECT
product_name || ', ' || 
coalesce(product_size,'')||' (' ||
coalesce(product_qty_type, "unit" )|| ')' as list_of_products
FROM product;

--END QUERY


--Windowed Functions
/* 1. Write a query that selects from the customer_purchases table and numbers each customer’s  
visits to the farmer’s market (labeling each market date with a different number). 
Each customer’s first visit is labeled 1, second visit is labeled 2, etc. 

You can either display all rows in the customer_purchases table, with the counter changing on
each new market date for each customer, or select only the unique market dates per customer 
(without purchase details) and number those visits. 
HINT: One of these approaches uses ROW_NUMBER() and one uses DENSE_RANK(). 
Filter the visits to dates before April 29, 2022. */
--QUERY 2
SELECT DISTINCT customer_id, market_date,
dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date ASC) as customer_visit
FROM customer_purchases
WHERE market_date < '2022-04-29';

--END QUERY


/* 2. Reverse the numbering of the query so each customer’s most recent visit is labeled 1, 
then write another query that uses this one as a subquery (or temp table) and filters the results to 
only the customer’s most recent visit.
HINT: Do not use the previous visit dates filter. */
--QUERY 3

SELECT DISTINCT customer_id, market_date, customer_visit
FROM
	(SELECT  customer_id, market_date,
	dense_rank() OVER (PARTITION BY customer_id ORDER BY market_date DESC) as customer_visit
	FROM customer_purchases
)
WHERE customer_visit = 1;
--END QUERY


/* 3. Using a COUNT() window function, include a value along with each row of the 
customer_purchases table that indicates how many different times that customer has purchased that product_id. 

You can make this a running count by including an ORDER BY within the PARTITION BY if desired.
Filter the visits to dates before April 29, 2022. */
--QUERY 4

SELECT customer_id, product_id, 
count () OVER (PARTITION BY customer_id, product_id ORDER BY market_date, transaction_time ASC) as num_of_purchases
FROM customer_purchases
WHERE market_date < '2022-04-29';

--END QUERY

-- String manipulations
/* 1. Some product names in the product table have descriptions like "Jar" or "Organic". 
These are separated from the product name with a hyphen. 
Create a column using SUBSTR (and a couple of other commands) that captures these, but is otherwise NULL. 
Remove any trailing or leading whitespaces. Don't just use a case statement for each product! 

| product_name               | description |
|----------------------------|-------------|
| Habanero Peppers - Organic | Organic     |

Hint: you might need to use INSTR(product_name,'-') to find the hyphens. INSTR will help split the column. */
--QUERY 5
SELECT product_name,
CASE WHEN instr(product_name, '- J') >0 THEN substr(product_name, -3)
		WHEN instr(product_name, '- O') >0 THEN substr(product_name, -7)
END as description
FROM product;

--END QUERY


/* 2. Filter the query to show any product_size value that contain a number with REGEXP. */
--QUERY 6
SELECT *
FROM product
WHERE product_size REGEXP '[0-9]';


--END QUERY


-- UNION
/* 1. Using a UNION, write a query that displays the market dates with the highest and lowest total sales.

HINT: There are a possibly a few ways to do this query, but if you're struggling, try the following: 
1) Create a CTE/Temp Table to find sales values grouped dates; 
2) Create another CTE/Temp table with a rank windowed function on the previous query to create 
"best day" and "worst day"; 
3) Query the second temp table twice, once for the best day, once for the worst day, 
with a UNION binding them. */
--QUERY 7

--(1)find the market dates with the highest total sales
SELECT market_date, total_sales, highest_sales as [row_number]
FROM (
	SELECT market_date,
			SUM(quantity*cost_to_customer_per_qty) AS total_sales,
			row_number() OVER(ORDER BY (SUM(quantity*cost_to_customer_per_qty)) DESC) as highest_sales
	FROM customer_purchases
	GROUP BY market_date
		)
WHERE highest_sales = 1
--(3) Use a UNION to display the two values
UNION
--(2) find the market dates with the lowest total sales
SELECT market_date, total_sales, lowest_sales
FROM (
	SELECT market_date,
			SUM(quantity*cost_to_customer_per_qty) AS total_sales,
			row_number() OVER(ORDER BY (SUM(quantity*cost_to_customer_per_qty)) ASC) as lowest_sales 
FROM customer_purchases
GROUP BY market_date
	)
WHERE lowest_sales = 1;

--END QUERY



/* SECTION 3 */

-- Cross Join
/*1. Suppose every vendor in the `vendor_inventory` table had 5 of each of their products to sell to **every** 
customer on record. How much money would each vendor make per product? 
Show this by vendor_name and product name, rather than using the IDs.

HINT: Be sure you select only relevant columns and rows. 
Remember, CROSS JOIN will explode your table rows, so CROSS JOIN should likely be a subquery. 
Think a bit about the row counts: how many distinct vendors, product names are there (x)?
How many customers are there (y). 
Before your final group by you should have the product of those two queries (x*y).  */
--QUERY 8

--(1) Create a Temp table with vendor name, product name, and original price
DROP TABLE IF EXISTS temp.new_inventory;
CREATE TABLE temp.new_inventory AS
SELECT DISTINCT
v.vendor_name,
v.vendor_id,
p.product_id, 
product_name,
original_price
FROM vendor_inventory AS vi
INNER JOIN vendor AS v
		ON v.vendor_id = vi.vendor_id
INNER JOIN product AS p
		ON p.product_id = vi.product_id;
--(2) Cross join the number of customers to calculate profit that each vendor make per product 
SELECT vendor_name, product_name, original_price, 
cp.n_of_customers, 
5*cp.n_of_customers*original_price AS profit_per_product
FROM new_inventory
		CROSS JOIN (SELECT COUNT (DISTINCT customer_id) AS n_of_customers
		FROM customer_purchases
		) AS cp;
	
--END QUERY


-- INSERT
/*1.  Create a new table "product_units". 
This table will contain only products where the `product_qty_type = 'unit'`. 
It should use all of the columns from the product table, as well as a new column for the `CURRENT_TIMESTAMP`.  
Name the timestamp column `snapshot_timestamp`. */
--QUERY 9

--(1) add new column for the CURRENT_TIMESTAMP using Insert into
DROP TABLE IF EXISTS temp.time_stamp;
CREATE TEMP TABLE time_stamp (snapshot_timestamp TEXT);

INSERT INTO TEMP.time_stamp
VALUES (CURRENT_TIMESTAMP);
--(2) create a table 'product units', joining with time_Stamp
DROP TABLE IF EXISTS temp.product_units;
CREATE TEMP TABLE product_units AS
SELECT *
FROM product
CROSS JOIN time_stamp
WHERE product_qty_type = 'unit';
--(3) verify the result
SELECT*
FROM product_units;

--END QUERY


/*2. Using `INSERT`, add a new row to the product_units table (with an updated timestamp). 
This can be any product you desire (e.g. add another record for Apple Pie). */
--QUERY 10
INSERT INTO product_units
VALUES (11, 'Eggs - Organic' , '1dozen', 6, 'unit', CURRENT_TIMESTAMP);

UPDATE product_units
SET snapshot_timestamp = CURRENT_TIMESTAMP
WHERE product_id = 11;

--END QUERY

-- DELETE
/* 1. Delete the older record for the whatever product you added. 

HINT: If you don't specify a WHERE clause, you are going to have a bad time.*/
--QUERY 11
DELETE FROM product_units
WHERE product_id = 10;

--END QUERY


-- UPDATE
/* 1.We want to add the current_quantity to the product_units table. 
First, add a new column, current_quantity to the table using the following syntax.

ALTER TABLE product_units
ADD current_quantity INT

Then, using UPDATE, change the current_quantity equal to the last quantity value from the vendor_inventory details.

HINT: This one is pretty hard. 
First, determine how to get the "last" quantity per product. 
Second, coalesce null values to 0 (if you don't have null values, figure out how to rearrange your query so you do.) 
Third, SET current_quantity = (...your select statement...), remembering that WHERE can only accommodate one column. 
Finally, make sure you have a WHERE statement to update the right row, 
	you'll need to use product_units.product_id to refer to the correct row within the product_units table. 
When you have all of these components, you can run the update statement. */
--QUERY 12
ALTER TABLE product_units
ADD current_quantity INT;

--(1) get the last quantity per product using CTE
UPDATE product_units
SET current_quantity = coalesce(current_quantity,0);

WITH last_quantity AS (
SELECT market_date,
vendor_id,
product_id,
quantity,
latest_day
FROM (
	SELECT market_date, vendor_id, product_id, quantity, 
		RANK()OVER(PARTITION BY vendor_id, product_id ORDER BY market_date DESC) AS latest_day
	FROM vendor_inventory
		)
	WHERE latest_day = 1
	)
UPDATE product_units
SET current_quantity = last_quantity.quantity
FROM last_quantity
WHERE product_units.product_id = last_quantity.product_id;

--END QUERY





