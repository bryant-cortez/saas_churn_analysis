
USE churn_analytics;


-- Store customer profiles, signup dates, and acquisition information.
CREATE TABLE customers (
	customer_id VARCHAR(50) PRIMARY KEY, 
    signup_date DATE NOT NULL, 
    acquisition_channel VARCHAR(30), 
    country VARCHAR(30),
    industry VARCHAR(30), 
    company_size VARCHAR(20)
);


-- Track customer subscriptions, billing details, plan information, and churn outcomes.
CREATE TABLE subscriptions (
	subscription_id VARCHAR(50) PRIMARY KEY, 
    customer_id VARCHAR(50), 
    start_date DATE NOT NULL, 
    end_date DATE, 
    subscription_status VARCHAR(30),
    billing_cycle VARCHAR(20),
    plan VARCHAR(20),
    monthly_price DECIMAL(12,2),
    churn_type VARCHAR(30), 
    cancellation_reason VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- Record subscription plan changes, including upgrades, downgrades, and pricing changes.
CREATE TABLE subscription_events (
	event_id VARCHAR(50) PRIMARY KEY, 
    subscription_id VARCHAR(50), 
    event_date DATE, 
    event_type VARCHAR(50), 
    previous_plan VARCHAR(20), 
    new_plan VARCHAR(20), 
    previous_price DECIMAL(12,2), 
    new_price DECIMAL(12,2),
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);


-- Track customer product activity, feature usage, and session duration.
CREATE TABLE usage_events (
	event_id VARCHAR(50) PRIMARY KEY, 
    customer_id VARCHAR(50), 
    event_timestamp DATETIME, 
    event_type VARCHAR(50), 
    feature_category VARCHAR(30), 
    session_duration DECIMAL (12,2),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);


-- Store subscription invoices, payment outcomes, failed payment retries, and recoveries.
CREATE TABLE invoices (
	invoice_id VARCHAR(50) PRIMARY KEY, 
    subscription_id VARCHAR(50), 
    invoice_date DATE, 
    due_date DATE, 
    amount DECIMAL(12,2), 
    payment_status VARCHAR(30), 
    payment_date DATE, 
    retry_count INT, 
    failure_reason VARCHAR(50), 
    recovered BOOLEAN, 
    last_attempt_date DATE, 
    FOREIGN KEY (subscription_id) REFERENCES subscriptions(subscription_id)
);


-- Track customer support issues, resolution times, ticket priorities, and SLA compliance.
CREATE TABLE support_tickets (
	ticket_id VARCHAR(50) PRIMARY KEY, 
    customer_id VARCHAR(50), 
    created_at DATETIME, 
    resolved_at DATETIME, 
    issue_category VARCHAR(30), 
    priority VARCHAR(20), 
    ticket_status VARCHAR(30), 
    resolution_time_hours DECIMAL(12,2),
    sla_hours DECIMAL(12,2),
    sla_breached BOOLEAN,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);




    
    



    




    





    











































