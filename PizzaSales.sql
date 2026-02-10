Select SUM(total_price) as TotalRevenue from PizzaSales

Select SUM(total_price)/COUNT(DISTINCT order_id) as AvgOrderValue from PizzaSales

Select SUM(quantity) as TotalPizzaSold from PizzaSales

Select COUNT(DISTINCT order_id) as TotalOrders from PizzaSales

-- For each and every order almost more than 2 pizzas are sold
Select CAST(CAST(SUM(quantity) as decimal(10,2)) / CAST(COUNT(DISTINCT order_id) as decimal(10,2)) as decimal(10,2)) as AvgPizzaPerOrder from PizzaSales

-- Daily Trends for Total Order
Select DATENAME(DW, order_date) as OrderDay, COUNT(DISTINCT order_id) as TotalOrders from PizzaSales
GROUP BY DATENAME(DW, order_date)

-- Monthly trend for Total Order
Select DATENAME(MONTH, order_date) as Month, COUNT(DISTINCT order_id) as TotalOrders from PizzaSales
GROUP BY DATENAME(MONTH, order_date)
ORDER BY TotalOrders DESC

Select pizza_category, sum(total_price) as TotalSales, 
SUM(total_price) * 100 / (Select SUM(total_price) from PizzaSales)  as PercentageSales
from PizzaSales
GROUP BY pizza_category

-- If want to filter by month, add WHERE MOTH(order_date) = 1 for Jan, 2 for Feb, etc before GROUP BY
-- WHERE DATEPART(QUARTER, order_date) = 1 for quarter 1

Select pizza_size, CAST(sum(total_price) AS decimal (10,2)) TotalSales, 
CAST(SUM(total_price) * 100 / (Select SUM(total_price) from PizzaSales WHERE DATEPART(QUARTER, order_date) = 1) AS decimal (10,2))  as PercentageSales
from PizzaSales
WHERE DATEPART(QUARTER, order_date) = 1
GROUP BY pizza_size
ORDER BY PercentageSales Desc

-- Top 5 best sellers with respect to total sales
Select TOP 5 pizza_name, SUM(total_price) as TotalSales from PizzaSales
GROUP BY pizza_name
ORDER BY TotalSales Desc

-- Top 5 worst sellers with respect to total quantity sold
Select TOP 5 pizza_name, SUM(quantity) as TotalQuantity from PizzaSales
GROUP BY pizza_name
ORDER BY TotalQuantity Asc

-- Top 5 best sellers with respect to total order
Select TOP 5 pizza_name, COUNT(DISTINCT order_id) as TotalOrder from PizzaSales
GROUP BY pizza_name
ORDER BY TotalOrder Desc


