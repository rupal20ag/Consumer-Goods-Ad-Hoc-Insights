select * from dim_customer
-- Provide the list of markets in which customer "Atliq Exclusive" operates its
-- business in the APAC region.
 select distinct market from dim_customer
 where customer='Atliq Exclusive' and region='APAC'
 
--  What is the percentage of unique product increase in 2021 vs. 2020? The
-- final output contains these fields,
-- unique_products_2020
-- unique_products_2021
-- percentage_chg
-- select * from dim_product
with cte as
(select count(distinct dp.product_code) as product_count,dp.product,fsm.fiscal_year
from dim_product dp
join fact_sales_monthly fsm
on dp.product_code=fsm.product_code
group by 2,3),
main as
(select cte.product,cte.product_count as product_2020,cte2.product_count as product_2021,
(cte2.product_count-cte.product_count)*100/cte.product_count as percentage_chg
from cte
join cte as cte2
on cte.product=cte2.product
where cte.fiscal_year=2020 and cte2.fiscal_year=2021)
select main.product,main.product_2020,main.product_2021,main.percentage_chg || '%' as pct_chg
from main
where percentage_chg<>0
order by pct_chg desc


-- Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains
-- 2 fields,
-- segment
-- product_count

select segment, count(distinct product) as total_Product
from dim_product
group by 1
order by 2 desc

-- Follow-up: Which segment had the most increase in unique products in
-- 2021 vs 2020? The final output contains these fields,
-- segment
-- product_count_2020
-- product_count_2021
-- difference
with cte as(
select segment, count(distinct product) as total_Product,fsm.fiscal_year 
from dim_product dp
join fact_sales_monthly fsm
on dp.product_code=fsm.product_code
group by 1,3)
select cte.segment,cte.total_Product as product_count_2020 ,
cte2.total_Product as product_count_2021,(cte2.total_Product-cte.total_Product) as difference
from cte
join cte cte2
on cte.segment=cte2.segment and cte.fiscal_year=2020 and cte2.fiscal_year=2021
order by difference desc

-- Get the products that have the highest and lowest manufacturing costs.
-- The final output should contain these fields,
-- product_code
-- product
-- manufacturing_cost
select * from fact_manufacturing_cost
with cte as(
select dp.product_code,dp.product,
fmc.manufacturing_cost
from dim_product dp
join fact_manufacturing_cost fmc
on dp.product_code=fmc.product_code)
select product_code,product,manufacturing_cost
from cte
where manufacturing_cost=(select max(manufacturing_cost) from cte)
or manufacturing_cost=(select min(manufacturing_cost) from cte)

--  Generate a report which contains the top 5 customers who received an
-- average high pre_invoice_discount_pct for the fiscal year 2021 and in the
-- Indian market. The final output contains these fields,
-- customer_code
-- customer
-- average_discount_percentage

select * from fact_pre_invoice_deductions

select dc.customer_code,dc.customer,round(cast(avg(pre_invoice_discount_pct)  as numeric),2)as avg_pid
from dim_customer dc
join fact_pre_invoice_deductions fpid
on dc.customer_code=fpid.customer_code
where market='India' and fiscal_year=2021
group by 1,2
order by 3 desc
limit 5

--  Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount
 
 with cte as(
 select to_char(date,'Mon') as month,
 round(cast(sum(gross_price * fsm.sold_quantity)/1000000 as numeric),2) || ' Mn' as Gross_sale_2020
 from fact_gross_price fgp
 join fact_sales_monthly fsm
 on fgp.product_code=fsm.product_code
 and fgp.fiscal_year=fsm.fiscal_year
 join dim_customer dc
 on dc.customer_code=fsm.customer_code
 where customer='Atliq Exclusive' and fgp.fiscal_year=2020
 group by 1
 ),
 cte2 as( select to_char(date,'Mon') as month,
 round(cast(sum(gross_price * fsm.sold_quantity)/1000000 as numeric),2) || ' Mn' as Gross_sale_2021
 from fact_gross_price fgp
 join fact_sales_monthly fsm
 on fgp.product_code=fsm.product_code
 and fgp.fiscal_year=fsm.fiscal_year
 join dim_customer dc
 on dc.customer_code=fsm.customer_code
 where customer='Atliq Exclusive' and fgp.fiscal_year=2021
 group by 1)
 select cte.month,cte.Gross_sale_2020,cte2.Gross_sale_2021
 from cte
 join cte2
 on cte.month=cte2.month
 order by case cte.month
             WHEN 'Jan' THEN 1
             WHEN 'Feb' THEN 2
             WHEN 'Mar' THEN 3
             WHEN 'Apr' THEN 4
             WHEN 'May' THEN 5
             WHEN 'Jun' THEN 6
             WHEN 'Jul' THEN 7
             WHEN 'Aug' THEN 8
             WHEN 'Sep' THEN 9
             WHEN 'Oct' THEN 10
             WHEN 'Nov' THEN 11
             WHEN 'Dec' THEN 12
          END
 
--  In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity
select 'Q'|| date_part('Quarter',date) as quarter,
sum(sold_quantity) as total_sold_quantity,
sum(sold_quantity)/100000 || ' L' as approx_total_sold_quantity
from fact_sales_monthly
where fiscal_year=2020
group by 1
order by 2 desc

-- . Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage
with cte as(
select dc.channel,round(cast(sum(fgp.gross_price * fsm.sold_quantity)as numeric)/1000000,2) as total_gross_sale
from fact_gross_price fgp
join fact_sales_monthly fsm
on fgp.product_code=fsm.product_code and fgp.fiscal_year=fsm.fiscal_year
join dim_customer dc
on dc.customer_code=fsm.customer_code
where fgp.fiscal_year=2021
group by 1
order by 2 desc),
cte2 as(
select sum(total_gross_sale) as total
from cte)
select channel,total_gross_sale || ' Mn' as gross_sale,
round(cast((total_gross_sale*100/total)as numeric),2) || '%' as pct_contribution
from cte
cross join
cte2

-- Get the Top 3 products in each division that have a high
-- total_sold_quantity in the fiscal_year 2021? The final output contains these
-- fields,
-- division
-- product_code
with cte as(
select division,product,sum(sold_quantity) as total_sold_quantity
from dim_product dp
join fact_sales_monthly fsm
on dp.product_code=fsm.product_code
group by 1,2),
cte2 as
(select division,product,total_sold_quantity,
 dense_rank() over(partition by division order by total_sold_quantity desc) as rank
from cte)
select division,product,total_sold_quantity
from cte2
where rank<=3


