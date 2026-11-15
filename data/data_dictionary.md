

This document outlines the database schema for the SaaS Subscription & Churn Analysis project. The database is built in MySQL and consists of six core tables.

## Table: `customers`
Stores demographic and acquisition information for each customer.

| Column Name | Data Type | Description | Constraints |
| :--- | :--- | :--- | :--- |
| `customer_id` | VARCHAR(50) | Unique identifier for the customer | **PRIMARY KEY** |
| `signup_date` | DATE | Date the customer signed up | **NOT NULL** |
| `acquisition_channel` | VARCHAR(30) | Marketing channel through which the customer was acquired (e.g., Social Media, Referral) | |
| `country` | VARCHAR(30) | Customer's country of residence | |
| `industry` | VARCHAR(30) | Customer's industry sector | |
| `company_size` | VARCHAR(20) | Categorical bucket for the customer's employee count | |

## Table: `subscriptions`
Stores the lifecycle and plan details of customer subscriptions.

| Column Name | Data Type | Description | Constraints |
| :--- | :--- | :--- | :--- |
| `subscription_id` | VARCHAR(50) | Unique identifier for the subscription | **PRIMARY KEY** |
| `customer_id` | VARCHAR(50) | Reference to the customer | **FOREIGN KEY** (`customers.customer_id`) |
| `start_date` | DATE | Subscription start date | **NOT NULL** |
| `end_date` | DATE | Subscription cancellation date (`NULL` if active) | |
| `subscription_status` | VARCHAR(30) | Current status (Active / Cancelled) | |
| `billing_cycle` | VARCHAR(20) | Billing frequency (Monthly / Annual) | |
| `plan` | VARCHAR(20) | Subscription tier (Basic / Pro / Enterprise) | |
| `monthly_price` | DECIMAL(12,2) | Normalized monthly price of the subscription | |
| `churn_type` | VARCHAR(30) | Classification of churn (Voluntary / Involuntary) | |
| `cancellation_reason` | VARCHAR(50) | The primary driver for cancellation (e.g., Poor Fit, Payment Failure) | |

## Table: `subscription_events`
Logs lifecycle changes and plan modifications over time.

| Column Name | Data Type | Description | Constraints |
| :--- | :--- | :--- | :--- |
| `event_id` | VARCHAR(50) | Unique identifier for the event | **PRIMARY KEY** |
| `subscription_id` | VARCHAR(50) | Reference to the subscription | **FOREIGN KEY** (`subscriptions.subscription_id`) |
| `event_date` | DATE | Date the event occurred | |
| `event_type` | VARCHAR(50) | Type of lifecycle event (e.g., Upgrade, Downgrade) | |
| `previous_plan` | VARCHAR(20) | Plan tier before the event | |
| `new_plan` | VARCHAR(20) | Plan tier after the event | |
| `previous_price` | DECIMAL(12,2) | Monthly price before the event | |
| `new_price` | DECIMAL(12,2) | Monthly price after the event | |

## Table: `usage_events`
Logs customer product engagement and feature usage.

| Column Name | Data Type | Description | Constraints |
| :--- | :--- | :--- | :--- |
| `event_id` | VARCHAR(50) | Unique identifier for the usage event | **PRIMARY KEY** |
| `customer_id` | VARCHAR(50) | Reference to the customer | **FOREIGN KEY** (`customers.customer_id`) |
| `event_timestamp` | DATETIME | Exact timestamp of the event | |
| `event_type` | VARCHAR(50) | Specific action taken (e.g., Report Generated, Data Exported) | |
| `feature_category` | VARCHAR(30) | Category of the feature used (e.g., Dashboard, Integrations) | |
| `session_duration` | DECIMAL(12,2)| Duration of the session in seconds | |

## Table: `invoices`
Financial records of billing and payment attempts.

| Column Name | Data Type | Description | Constraints |
| :--- | :--- | :--- | :--- |
| `invoice_id` | VARCHAR(50) | Unique identifier for the invoice | **PRIMARY KEY** |
| `subscription_id` | VARCHAR(50) | Reference to the subscription | **FOREIGN KEY** (`subscriptions.subscription_id`) |
| `invoice_date` | DATE | Date the invoice was generated | |
| `due_date` | DATE | Date the invoice is due | |
| `amount` | DECIMAL(12,2) | Total invoice amount | |
| `payment_status` | VARCHAR(30) | Current status (Paid / Pending / Failed) | |
| `payment_date` | DATE | Date payment was successfully processed | |
| `retry_count` | INT | Number of dunning retries attempted | |
| `failure_reason` | VARCHAR(50) | Reason for payment failure (if applicable) | |
| `recovered` | BOOLEAN | Flag indicating if a failed payment was eventually recovered | |
| `last_attempt_date` | DATE | Date of the final retry attempt | |

## Table: `support_tickets`
Customer support interactions and SLA performance metrics.

| Column Name | Data Type | Description | Constraints |
| :--- | :--- | :--- | :--- |
| `ticket_id` | VARCHAR(50) | Unique identifier for the support ticket | **PRIMARY KEY** |
| `customer_id` | VARCHAR(50) | Reference to the customer | **FOREIGN KEY** (`customers.customer_id`) |
| `created_at` | DATETIME | Timestamp the ticket was opened | |
| `resolved_at` | DATETIME | Timestamp the ticket was resolved (`NULL` if open) | |
| `issue_category` | VARCHAR(30) | Type of issue (e.g., Technical Issue, Billing) | |
| `priority` | VARCHAR(20) | Urgency level (Low / Medium / High / Critical) | |
| `ticket_status` | VARCHAR(30) | Current state (Resolved / Open / In Progress) | |
| `resolution_time_hours`| DECIMAL(12,2) | Total hours taken to resolve | |
| `sla_hours` | DECIMAL(12,2) | The target SLA window (in hours) based on priority & category | |
| `sla_breached` | BOOLEAN | Flag indicating if resolution time exceeded the SLA window | |
