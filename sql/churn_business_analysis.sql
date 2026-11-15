
USE churn_analytics; 

-- Count eligible customers and early cancellations within 90 days of subscription start by acquisition channel.
WITH channel_info AS (
	SELECT C.acquisition_channel, 
			COUNT(CASE WHEN S.start_date <= '2026-05-03'
            OR (
				S.subscription_status = 'Cancelled' 
				AND DATEDIFF(S.end_date, S.start_date) <= 90
                AND S.end_date <= '2026-08-01'
            ) THEN 1 END) 
            AS eligible_customers,
			COUNT(CASE WHEN S.subscription_status = 'Cancelled' 
            AND DATEDIFF(S.end_date, S.start_date) <= 90 
            AND S.end_date <= '2026-08-01' THEN 1 END) 
			AS early_churned_customers
	FROM customers AS C
	INNER JOIN subscriptions AS S ON C.customer_id = S.customer_id
    GROUP BY C.acquisition_channel
), 


-- Calculate each acquisition channel's 90-day churn rate using its eligible customer population.
channel_early_churn AS (
	SELECT *, 
	ROUND(early_churned_customers / NULLIF(eligible_customers, 0) * 100.0, 2) 
	AS early_churn_rate
	FROM channel_info
	ORDER BY early_churn_rate DESC
), 


-- Calculate churn-related MRR and average MRR per early cancellation for each acquisition channel.
mrr_by_channel AS (
	SELECT C.acquisition_channel, 
			COUNT(*) AS early_churned_customers, 
			ROUND(SUM(S.monthly_price), 2) AS lost_mrr, 
			ROUND(SUM(S.monthly_price) / NULLIF(COUNT(*), 0), 2) AS avg_lost_mrr_per_customer
	FROM customers AS C 
	INNER JOIN subscriptions AS S ON C.customer_id = S.customer_id
	WHERE S.subscription_status = 'Cancelled' 
			AND DATEDIFF(S.end_date, S.start_date) <= 90 
			AND S.end_date <= '2026-08-01'
	GROUP BY C.acquisition_channel
	ORDER BY lost_mrr DESC
),


-- Identify consecutive SLA breaches for each customer using the next breach date.
breach_pairs AS (
	SELECT customer_id, created_at AS first_breach_date, 
			LEAD(created_at) OVER(PARTITION BY customer_id
			ORDER BY created_at ASC) AS second_breach_date 
	FROM support_tickets
	WHERE sla_breached = TRUE
),


-- Identify customers with at least two SLA breaches within 90 days, retaining one qualifying pair per customer.
unique_breach_pairs AS (
	SELECT customer_id, MIN(first_breach_date) AS first_breach_date, 
	MIN(second_breach_date) AS second_breach_date
	FROM breach_pairs
	WHERE second_breach_date IS NOT NULL
	AND TIMESTAMPDIFF(DAY, first_breach_date, second_breach_date) <= 90
	GROUP BY customer_id
), 


-- Compare overall subscription churn rates between customers with and without repeated SLA breaches.
breach_churn_rates AS (
	SELECT (CASE 
				WHEN B.customer_id IS NOT NULL THEN 'Repeated SLA Breaches'
				ELSE 'No Repeated SLA Breaches'
				END) AS breach_group, 
				COUNT(*) AS total_subscriptions, 
				COUNT(CASE WHEN S.subscription_status = 'Cancelled'
				THEN 1 END) AS cancelled_subscriptions, 
				ROUND(COUNT(CASE WHEN S.subscription_status = 'Cancelled'
				THEN 1 END) / NULLIF(COUNT(*), 0) * 100.0, 2) AS churn_rate_pct
	FROM subscriptions AS S
	LEFT JOIN unique_breach_pairs AS B ON S.customer_id = B.customer_id
	GROUP BY breach_group
), 


-- Measure churn-related MRR and average MRR per cancelled subscription by SLA breach group.
mrr_lost_by_breaches AS (
	SELECT (CASE 
				WHEN B.customer_id IS NOT NULL THEN 'Repeated SLA Breaches'
				ELSE 'No Repeated SLA Breaches'
				END) AS breach_group, 
			COUNT(*) AS cancelled_subscriptions, 
			SUM(S.monthly_price) AS lost_mrr, 
            AVG(S.monthly_price) AS avg_lost_mrr_per_cancelled_customer
	FROM subscriptions AS S
    LEFT JOIN unique_breach_pairs AS B ON S.customer_id = B.customer_id
    WHERE S.subscription_status = 'Cancelled'
    GROUP BY breach_group
),


-- Check whether the second qualifying SLA breach occurred before subscription cancellation.
breaches_before_cancellation AS (
	SELECT
		COUNT(*) AS cancelled_customers,
		COUNT(CASE WHEN DATE(B.second_breach_date) < S.end_date THEN 1 END) AS breaches_before_cancellation,
		ROUND(COUNT(CASE WHEN DATE(B.second_breach_date) < S.end_date THEN 1 END) / NULLIF(COUNT(*), 0) * 100.0, 2) AS pct_before_cancellation
	FROM subscriptions AS S
	INNER JOIN unique_breach_pairs AS B
		ON S.customer_id = B.customer_id
	WHERE S.subscription_status = 'Cancelled'
), 


-- Compare average customer MRR and total subscription MRR across SLA breach groups.
breach_group_mrr AS (
	SELECT
		(CASE
			WHEN B.customer_id IS NOT NULL
				THEN 'Repeated SLA Breaches'
			ELSE 'No Repeated SLA Breaches'
		END) AS breach_group,
		COUNT(*) AS total_subscriptions,
		ROUND(AVG(S.monthly_price), 2) AS avg_mrr_per_customer,
		ROUND(SUM(S.monthly_price), 2) AS total_subscription_mrr
	FROM subscriptions AS S
	LEFT JOIN unique_breach_pairs AS B
		ON S.customer_id = B.customer_id
	GROUP BY breach_group
), 


-- Calculate churn rates for each subscription plan, segmented by repeated SLA breach status.
churn_rate_by_plan_and_group AS (
	SELECT S.plan, 
		(CASE
			WHEN B.customer_id IS NOT NULL
				THEN 'Repeated SLA Breaches'
			ELSE 'No Repeated SLA Breaches'
		END) AS breach_group, 
        COUNT(*) AS total_customers, 
        COUNT(CASE WHEN S.subscription_status = 'Cancelled' THEN 1 END) 
        AS cancelled_customers, 
        ROUND(COUNT(CASE WHEN S.subscription_status = 'Cancelled' THEN 1 END)  / COUNT(*) * 100.0, 2) 
        AS churn_rate
	FROM subscriptions AS S
	LEFT JOIN unique_breach_pairs AS B ON S.customer_id = B.customer_id
	GROUP BY S.plan, (CASE
				WHEN B.customer_id IS NOT NULL
					THEN 'Repeated SLA Breaches'
				ELSE 'No Repeated SLA Breaches'
			END)
), 


-- Calculate churn-related MRR and average MRR per cancellation by plan and SLA breach group.
mrr_by_plan_and_group AS (
	SELECT S.plan, (CASE
			WHEN B.customer_id IS NOT NULL
				THEN 'Repeated SLA Breaches'
			ELSE 'No Repeated SLA Breaches'
		END) AS breach_group, 
        COUNT(*) AS cancelled_customers, 
        ROUND(SUM(S.monthly_price), 2) AS lost_mrr, 
        ROUND(AVG(S.monthly_price), 2) AS avg_lost_mrr
	FROM subscriptions AS S
	LEFT JOIN unique_breach_pairs AS B ON S.customer_id = B.customer_id
	WHERE S.subscription_status = 'Cancelled'
	GROUP BY S.plan, (CASE
				WHEN B.customer_id IS NOT NULL
					THEN 'Repeated SLA Breaches'
				ELSE 'No Repeated SLA Breaches'
			END)
)

SELECT * FROM mrr_by_plan_and_group;
        


    












