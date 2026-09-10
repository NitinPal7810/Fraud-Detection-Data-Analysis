## Understanding the Data
### 1.1. Total Number of Transactions & Fraud Cases
##### Insight: This provides a fraud rate percentage, helping us see how common fraud is in this dataset.
select count(*) as total_transactions, sum(isFraud) as total_fraud_cases,(sum(isfraud)*100/count(*)) as fraud_precentage
from transactions
------------------------------------------------
### 1.2. Most Common Transaction Types
##### Insight: Helps identify the most frequently occurring transaction types.
select type, count(*) as transaction_count
from transactions
group by type
order by transaction_count desc;

### 1.3. Top 5 Customers with the Most Transactions
##### Insight: Identifies high-activity customers who could be flagged for deeper analysis.
SELECT nameOrig, COUNT(*) AS total_transactions, 
       SUM(amount) AS total_amount_spent
FROM transactions
GROUP BY nameOrig
having total_transactions > 10
ORDER BY total_transactions DESC
LIMIT 5;

------------------
## Finding Patterns and Anomalies
### 2.1. Fraud Rate Per Transaction Type
##### Insight: Detects which transaction types are most associated with fraud.
SELECT type, COUNT(*) AS total_transactions,
       SUM(isFraud) AS fraud_cases,
       (SUM(isFraud) * 100.0 / COUNT(*)) AS fraud_percentage
FROM transactions
GROUP BY type
ORDER BY fraud_percentage DESC;

### 2.2. Detecting Large Transactions (Potential Fraud Signals)
##### Insight: Transactions way above the average can be flagged as potential fraud cases.
SELECT * FROM transactions 
WHERE amount > (SELECT AVG(amount) + 3 * STDDEV(amount) FROM transactions)
ORDER BY amount DESC;

### 2.3. Identifying Customers Who Initiated Fraudulent Transactions
##### Insight: Lists customers who initiated the highest fraudulent transactions.
SELECT nameOrig, COUNT(*) AS fraud_attempts, 
       SUM(amount) AS total_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY nameOrig
ORDER BY total_fraud_amount DESC
LIMIT 5;

---------------------------
## Fraud Detection & Risk Analysis
### 3.1. Finding Transactions Where the Recipient's Balance is Unchanged (Possible Money Laundering)
##### Insight: Fraudsters might be moving money but not changing the destination balance, indicating potential money laundering.
SELECT * FROM transactions 
WHERE newbalanceDest = oldbalanceDest 
AND amount > 1000000 -- Filter high-value transactions
AND isFraud = 1;

### 3.2. Flagging Suspicious Customers Who Perform Both CASH-IN & CASH-OUT in Short Time
##### Insight: Fraudsters often use quick consecutive transactions to launder money.
SELECT nameOrig, COUNT(*) AS suspicious_transactions 
FROM transactions
WHERE type IN ('CASH-IN', 'CASH-OUT')
AND step BETWEEN 1 AND 3 -- Transactions occurring within 3 hours
GROUP BY nameOrig
HAVING COUNT(*) > 1;

### 3.3. Identifying Accounts with Rapidly Depleting Balances
#####  Insight: High depletion rates could indicate fraud or suspicious fund movements.
SELECT nameOrig, SUM(oldbalanceOrg - newbalanceOrig) AS total_depletion
FROM transactions
GROUP BY nameOrig
HAVING total_depletion > 50000
ORDER BY total_depletion DESC;