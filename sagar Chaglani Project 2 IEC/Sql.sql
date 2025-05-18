-- Project: Maven Fuzzy Factory
-- by: Sagar chaglani
-- Institute of Emerging careers
-- 5/17/2025





-- where the bulk of our website sessions and Orders coming from? 
-- breakdown by UTM source, campaign and referring domain
-- Where are the bulk of our website sessions and orders coming from?

select 
	ws.utm_source utm_,
	ws.utm_campaign ,
	ws.http_referer ,
	count(ws.website_session_id) as sessions,
	count(distinct o.order_id ) as orders
from website_sessions ws left join orders o on ws.website_session_id = o.website_session_id 
group by 1,2,3 
order by sessions desc 


-- yearly and quaterly sessions to order conversion rate
-- To see the trend of sessions across all the years by which we can know how over buisness is performing overall
select 
	year (ws.created_at) as years,
	quarter(ws.created_at) as quaterly,
	count(distinct ws.website_session_id) as total_sessions,
    count(distinct o.order_id) as total_orders,
    count(distinct o.order_id) * 100/ count(distinct ws.website_session_id) as conversion_rate_percentage
from website_sessions ws
left join orders o on ws.website_session_id = o.website_session_id
group by years, quaterly


-- quaterly increase in sessions to order conversion rate (CVR), revenue per session, revenue per order
-- To see which quater is performing the best and which are not 
with cte_quarterly as (
  select 
    year(ws.created_at) as years,
    quarter(ws.created_at) as quarterly,
    count(distinct ws.website_session_id) as total_sessions,
    count(distinct o.order_id) as total_orders,
    round(count(distinct o.order_id) * 1.0 / count(distinct ws.website_session_id),4)as conversion_rate,
    -- Revenue per Order = Revenue / Orders
    ROUND(SUM(o.price_usd) * 1.0 / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS revenue_per_order,

    -- Revenue per Session = Revenue / Sessions
    ROUND(SUM(o.price_usd) * 1.0 / NULLIF(COUNT(DISTINCT ws.website_session_id), 0), 2) AS revenue_per_session
    from website_sessions ws
  left join orders o on ws.website_session_id = o.website_session_id
  group by years, quarterly
)

select 
  years,
  quarterly,
  total_sessions,
  total_orders,
  conversion_rate,
  revenue_per_order,
  revenue_per_session,
  lag(conversion_rate) over (order by years, quarterly) as prev,
  round(
    (conversion_rate - lag(conversion_rate) over (order by years, quarterly)) 
    / nullif(lag(conversion_rate) over (order by years, quarterly), 0) * 100,
    2
  ) as quarterly_cvr_change_percentage
from cte_quarterly
order by years, quarterly;





-- monthly and yearly session to order CVR 
create view vw_monthly_trend as
with cte_monthly as (
  select
    year(ws.created_at) as years,
    month(ws.created_at) as month,
    count(distinct ws.website_session_id) as total_sessions,
    count(distinct o.order_id) as total_orders,
    round(count(distinct o.order_id) * 100 / count(distinct ws.website_session_id), 4) as conversion_rate,

    -- Revenue per Order = Revenue / Orders
    round(sum(o.price_usd) * 1.0 / nullif(count(distinct o.order_id), 0), 2) as revenue_per_order,

    -- Revenue per Session = Revenue / Sessions
    round(sum(o.price_usd) * 1.0 / nullif(count(distinct ws.website_session_id), 0), 2) as revenue_per_session

  from website_sessions ws
  left join orders o on ws.website_session_id = o.website_session_id
  group by years, month
)

select 
  years,
  month,
  total_sessions,
  total_orders,
  conversion_rate,
  revenue_per_order,
  revenue_per_session,
  lag(conversion_rate) over (order by years, month) as prev,
  round(
    (conversion_rate - lag(conversion_rate) over (order by years, month)) 
    / nullif(lag(conversion_rate) over (order by years, month), 0) * 100,
    2
  ) as monthly_cvr_change_percentage
from cte_monthly
order by years, month;





-- What are the top-performing traffic sources each month, based on sessions and orders?
with Highest as (
select 
	year (ws.created_at) as years,
	month(ws.created_at) as month_no,
	monthname(ws.created_at) as month_name, 
	ws.utm_source,
	ws.utm_campaign ,
	ws.http_referer ,
	count(ws.website_session_id) as sessions,
	count(distinct o.order_id ) as orders
from website_sessions ws left join orders o on ws.website_session_id = o.website_session_id  
group by 1,2,3,4,5,6
order by 1,2,sessions desc 
),
top_source as (
select *,
	rank() over(partition by years,month_no order by sessions desc,orders desc) as ranks
	from highest
)
select *
from top_source 
where ranks = 1


-- bsearch and gsearching finding if the orders made are brand, nonbrand, organic or direct
create view channel_growth as 
SELECT 
	YEAR(website_sessions.created_at) AS yr,
	QUARTER(website_sessions.created_at) AS qtr,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS brand_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS organic_search_orders,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS direct_type_in_orders
    
FROM website_sessions 
	LEFT JOIN orders
		ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2



		### SALES ANALYSIS ###
#no. of sales, total revenue & total margin generated
SELECT 
	   YEAR(created_at) AS year,
	   MONTH(created_at) AS month,
       COUNT(DISTINCT order_id) AS numberOfSales,
       SUM(price_usd) AS totalRevenue,
       SUM(price_usd - cogs_usd) AS total_profit
FROM order_items
GROUP BY 1,2;



-- Total_revenue, orders, profit_margin, average_order_value|
create view product as 
SELECT 
    oi.created_at,
    COUNT(DISTINCT oi.order_id) AS orders, 
    SUM(oi.price_usd) AS total_revenue,  
    SUM(oi.price_usd - oi.cogs_usd) AS profit,
    AVG(oi.price_usd) AS average_order_value,
    ROUND((SUM(oi.price_usd - oi.cogs_usd) / SUM(oi.price_usd)) * 100, 2) AS avg_profit_margin_percent
FROM order_items oi 
GROUP BY 1



-- average refund rate percentage 

create view refund as 
SELECT 
	o.created_at,
	sum(o.price_usd),
  COUNT(DISTINCT r.order_id) * 100.0 / COUNT(DISTINCT o.order_id) AS avg_refund_rate_percent
FROM orders o
LEFT JOIN order_item_refunds r ON o.order_id = r.order_id
group by 1



-- yearly and monthly sales of products
create view test as 
select 

	oi.created_at,
	p2.product_name,
	sum(oi.price_usd) as revenue 
	
from products p2 left join order_items oi on p2.product_id = oi.product_id 
group by 1,2
order by 1



  




