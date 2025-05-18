
-- This query analyzes website session behavior by identifying:

-- Where the session landed (e.g., homepage, specific landing pages).

-- What product or funnel pages were viewed during the session.

-- Summarizes how many sessions progressed through various stages of the funnel.




-- Flags each pageview with binary indicators (1 or 0) based on the pageview_url.
create view vw_full_conversion_funnel as 
WITH flagged AS (
   SELECT 
        wp.website_session_id AS session_id, 
        wp.website_pageview_id,
		wp.pageview_url,
		CASE WHEN wp.pageview_url = '/home' THEN 1 ELSE 0 END AS homepage,
		CASE WHEN wp.pageview_url = '/products' THEN 1 ELSE 0 END AS products_page,
		CASE WHEN wp.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mr_fuzzy_page, 
		CASE WHEN wp.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN wp.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN wp.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
		CASE WHEN wp.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page,
		CASE WHEN wp.pageview_url = '/lander-1' THEN 1 ELSE 0 END AS lander_1,
		CASE WHEN wp.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_2,
		CASE WHEN wp.pageview_url = '/the-forever-love-bear' THEN 1 ELSE 0 END AS forever_love_bear,
		CASE WHEN wp.pageview_url = '/lander-2' THEN 1 ELSE 0 END AS lander_2,
		CASE WHEN wp.pageview_url = '/lander-3' THEN 1 ELSE 0 END AS lander_3,
		CASE WHEN wp.pageview_url = '/the-birthday-sugar-panda' THEN 1 ELSE 0 END AS sugar_panda,
		CASE WHEN wp.pageview_url = '/lander-4' THEN 1 ELSE 0 END AS lander_4,
		CASE WHEN wp.pageview_url = '/lander-5' THEN 1 ELSE 0 END AS lander_5,
		CASE WHEN wp.pageview_url = '/the-hudson-river-mini-bear' THEN 1 ELSE 0 END AS hudson_river_bear
   FROM mavenfuzzyfactory.website_pageviews wp
),

-- Aggregate sessions into session level flages
session_level AS (
	select session_id, 
	MAX(homepage) AS saw_homepage,
    MAX(products_page) AS saw_products_page,
    MAX(mr_fuzzy_page) AS saw_mr_fuzzy_page,
    MAX(cart_page) AS saw_cart_page,
    MAX(shipping_page) AS saw_shipping_page,
    MAX(billing_page) AS saw_billing_page,
    MAX(thankyou_page) AS saw_thankyou_page,
    MAX(lander_1) AS saw_lander_1,
    MAX(billing_2) AS saw_billing_2,
    MAX(forever_love_bear) AS saw_forever_love_bear,
    MAX(lander_2) AS saw_lander_2,
    MAX(lander_3) AS saw_lander_3,
    MAX(sugar_panda) AS saw_sugar_panda,
    MAX(lander_4) AS saw_lander_4,
    MAX(lander_5) AS saw_lander_5,
    MAX(hudson_river_bear) AS saw_hudson_river_bear
    FROM flagged
	GROUP BY 1
),

landing_page AS (
	SELECT 
    	website_session_id,
    	MIN(website_pageview_id) AS landing_page_id
  	FROM mavenfuzzyfactory.website_pageviews
  	GROUP BY website_session_id
),


/*SELECT 
		s.*, 
		p.pageview_url AS landing_page
	FROM session_level s  -- attaches the landing_page_id to each session.
	LEFT JOIN landing_page l
	  ON s.session_id = l.website_session_id
	LEFT JOIN mavenfuzzyfactory.website_pageviews p
	  ON l.website_session_id = p.website_session_id 
	  AND l.landing_page_id = p.website_pageview_id*/


sort AS (
	SELECT 
		s.*, 
		p.pageview_url AS landing_page
	FROM session_level s  -- attaches the landing_page_id to each session.
	LEFT JOIN landing_page l
	  ON s.session_id = l.website_session_id
	LEFT JOIN mavenfuzzyfactory.website_pageviews p
	  ON l.website_session_id = p.website_session_id 
	  AND l.landing_page_id = p.website_pageview_id
)

SELECT 
	CASE 
		when saw_homepage = 1 then 'saw_homepage'
		when saw_lander_1 = 1 then 'saw_lander_1'
		when saw_lander_2 = 1 then 'saw_lander_2'
		when saw_lander_3 = 1 then 'saw_lander_3'
		when saw_lander_4 = 1 then 'saw_lander_4'
		when saw_lander_5 = 1 then 'saw_lander_5'
		ELSE 'other'
	END AS landing_segment,

	COUNT(DISTINCT session_id) AS total_sessions,

	-- Product-related
	COUNT(DISTINCT CASE WHEN saw_products_page = 1 THEN session_id END) AS sessions_saw_products,
	COUNT(DISTINCT CASE WHEN saw_mr_fuzzy_page = 1 THEN session_id END) AS sessions_saw_mr_fuzzy,
	COUNT(DISTINCT CASE WHEN saw_forever_love_bear = 1 THEN session_id END) AS sessions_saw_forever_love_bear,
	COUNT(DISTINCT CASE WHEN saw_sugar_panda = 1 THEN session_id END) AS sessions_saw_sugar_panda,
	COUNT(DISTINCT CASE WHEN saw_hudson_river_bear = 1 THEN session_id END) AS sessions_saw_hudson_river_bear,

	-- Funnel
	COUNT(DISTINCT CASE WHEN saw_cart_page = 1 THEN session_id END) AS sessions_saw_cart,
	COUNT(DISTINCT CASE WHEN saw_shipping_page = 1 THEN session_id END) AS sessions_saw_shipping,
	COUNT(DISTINCT CASE WHEN saw_billing_page = 1 THEN session_id END) AS sessions_easypesa,
	COUNT(DISTINCT CASE WHEN saw_billing_2 = 1 THEN session_id END) AS sessions_saw_jazzcash,
	COUNT(DISTINCT CASE WHEN saw_thankyou_page = 1 THEN session_id END) AS sessions_saw_thankyou,

	-- Conversion rate
	ROUND(100.0 * COUNT(DISTINCT CASE WHEN saw_thankyou_page = 1 THEN session_id END) / COUNT(DISTINCT session_id), 2) AS conversion_rate_percent,

	-- Bounce rate
	COUNT(DISTINCT CASE WHEN 
		(saw_products_page + saw_mr_fuzzy_page + saw_forever_love_bear + saw_sugar_panda + saw_hudson_river_bear +
		 saw_cart_page + saw_shipping_page + saw_billing_page + saw_billing_2 + saw_thankyou_page) = 0 THEN session_id END) AS bounced_sessions,

	ROUND(100.0 * COUNT(DISTINCT CASE WHEN 
		(saw_products_page + saw_mr_fuzzy_page + saw_forever_love_bear + saw_sugar_panda + saw_hudson_river_bear +
		 saw_cart_page + saw_shipping_page + saw_billing_page + saw_billing_2 + saw_thankyou_page) = 0 THEN session_id END) / COUNT(DISTINCT session_id), 2) AS bounce_rate_percent

FROM sort
GROUP BY 1
ORDER BY total_sessions DESC;



 -- AVERAGE_SESSION_DURATION
create view VW_AVERAGE_SESSION_DURATION AS
SELECT 
	website_session_id,
	
    TIMESTAMPDIFF(SECOND, MIN(created_at), MAX(created_at)) / 60 AS session_duration
FROM website_pageviews
group by website_session_id 


-- average pages per session
create view VW_average_pages_per_session AS
select 
	*,
	rank() over(partition by website_session_id order by website_pageview_id) as Ranks
	from website_pageviews wp 




-- BOUNCE RATE 
	
create view vw_bounce_rate as 
WITH a AS (
  SELECT 
    website_session_id,
    RANK() OVER(PARTITION BY website_session_id ORDER BY website_pageview_id) AS Ranks
  FROM website_pageviews wp
),
b AS (
  SELECT website_session_id, COUNT(*) AS pageview_count
  FROM a
  GROUP BY website_session_id
)
SELECT 
  ROUND(100.0 * SUM(CASE WHEN pageview_count = 1 THEN 1 ELSE 0 END) / COUNT(*), 2) AS bounce_rate
FROM b;











