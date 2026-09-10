# Fraud Detection with SQL — PaySim Dataset

An end-to-end SQL-based fraud detection analysis on the **PaySim** synthetic mobile money transaction dataset (~6.36M rows). This project covers exploratory data analysis, anomaly detection, and fraud risk scoring using purely SQL — no ML, no Python, just structured queries.

---

## Dataset

**PaySim** simulates real-world mobile money transactions based on a sample of real financial logs from a mobile money service in an African country. It is widely used for fraud detection benchmarking.

| Column | Description |
|---|---|
| `step` | Time unit (1 step = 1 hour) |
| `type` | Transaction type: CASH-IN, CASH-OUT, DEBIT, PAYMENT, TRANSFER |
| `amount` | Transaction amount |
| `nameOrig` | Sender customer ID |
| `oldbalanceOrg` | Sender's balance before transaction |
| `newbalanceOrig` | Sender's balance after transaction |
| `nameDest` | Recipient customer ID |
| `oldbalanceDest` | Recipient's balance before transaction |
| `newbalanceDest` | Recipient's balance after transaction |
| `isFraud` | Ground truth fraud label (1 = fraud, 0 = legit) |
| `isFlaggedFraud` | System-flagged fraud attempt |

> Dataset source: [Kaggle — Synthetic Financial Datasets For Fraud Detection](https://www.kaggle.com/datasets/ealaxi/paysim1)

---

## Objectives

- Understand the distribution and volume of transactions across types
- Calculate and contextualize the overall fraud rate
- Identify transaction types most associated with fraud
- Flag statistical outliers and high-risk behavioral patterns
- Surface potential money laundering signals via balance anomalies

---

## Project Structure

```
fraud-detection-sql/
│
├── queries/
│   ├── 1_understanding_data.sql       # Fraud rate, transaction types, top customers
│   ├── 2_patterns_and_anomalies.sql   # Fraud per type, large txns, fraud initiators
│   └── 3_risk_analysis.sql            # Money laundering, rapid depletion, mule accounts
│
└── README.md
```

---

## 📊 Analysis Overview

### Section 1 — Understanding the Data

**1.1 Total Transactions & Fraud Rate**

Computes the overall fraud percentage to establish a baseline. Fraud is rare (~0.1–0.13%) but highly consequential in dollar terms.

```sql
SELECT COUNT(*) AS total_transactions,
       SUM(isFraud) AS total_fraud_cases,
       (SUM(isFraud) * 100.0 / COUNT(*)) AS fraud_percentage
FROM transactions;
```

---

**1.2 Most Common Transaction Types**

Identifies which transaction types dominate volume — critical context before drilling into fraud rates per type.

```sql
SELECT type, COUNT(*) AS transaction_count
FROM transactions
GROUP BY type
ORDER BY transaction_count DESC;
```

---

**1.3 Top 5 High-Activity Customers**

Flags customers with disproportionately high transaction counts — potential candidates for deeper behavioral profiling.

```sql
SELECT nameOrig, COUNT(*) AS total_transactions,
       SUM(amount) AS total_amount_spent
FROM transactions
GROUP BY nameOrig
HAVING total_transactions > 10
ORDER BY total_transactions DESC
LIMIT 5;
```

---

### Section 2 — Patterns & Anomalies

**2.1 Fraud Rate Per Transaction Type**

In PaySim, fraud is concentrated in `TRANSFER` and `CASH-OUT` types. This query makes that visible.

```sql
SELECT type, COUNT(*) AS total_transactions,
       SUM(isFraud) AS fraud_cases,
       (SUM(isFraud) * 100.0 / COUNT(*)) AS fraud_percentage
FROM transactions
GROUP BY type
ORDER BY fraud_percentage DESC;
```

---

**2.2 Statistical Outlier Detection (3-Sigma Rule)**

Transactions more than 3 standard deviations above the mean amount are flagged as potential fraud signals.

```sql
SELECT * FROM transactions
WHERE amount > (SELECT AVG(amount) + 3 * STDDEV(amount) FROM transactions)
ORDER BY amount DESC;
```

---

**2.3 Top Fraud Initiators by Amount**

Identifies customers responsible for the highest cumulative fraudulent transaction amounts.

```sql
SELECT nameOrig, COUNT(*) AS fraud_attempts,
       SUM(amount) AS total_fraud_amount
FROM transactions
WHERE isFraud = 1
GROUP BY nameOrig
ORDER BY total_fraud_amount DESC
LIMIT 5;
```

---

### Section 3 — Fraud Detection & Risk Analysis

**3.1 Unchanged Recipient Balance (Money Laundering Signal)**

When large amounts are transferred but the recipient's balance doesn't change, it suggests funds are being routed through intermediary mule accounts.

```sql
SELECT * FROM transactions
WHERE newbalanceDest = oldbalanceDest
AND amount > 1000000
AND isFraud = 1;
```

---

**3.2 CASH-IN → CASH-OUT Cycling (Rapid Structuring)**

A classic money laundering pattern: funds are deposited and immediately withdrawn within a short time window to avoid detection.

```sql
SELECT nameOrig, COUNT(*) AS suspicious_transactions
FROM transactions
WHERE type IN ('CASH-IN', 'CASH-OUT')
AND step BETWEEN 1 AND 3
GROUP BY nameOrig
HAVING COUNT(*) > 1;
```

---

**3.3 Rapidly Depleting Account Balances**

Accounts that lose large cumulative balances across transactions may indicate unauthorized fund draining or coordinated fraud.

```sql
SELECT nameOrig,
       SUM(oldbalanceOrg - newbalanceOrig) AS total_depletion
FROM transactions
GROUP BY nameOrig
HAVING total_depletion > 50000
ORDER BY total_depletion DESC;
```

---

## Key Findings

- Fraud is concentrated exclusively in **TRANSFER** and **CASH-OUT** transaction types — all other types have zero fraud in the dataset
- Fraudulent transactions frequently show **zero recipient balance change**, even for amounts exceeding ₹1M — a strong money laundering indicator
- The **3-sigma outlier rule** effectively surfaces a small subset of transactions that are disproportionately high-value
- Customers who cycle between CASH-IN and CASH-OUT within 1–3 steps exhibit structuring behavior consistent with layering in the AML framework

---

## Tech Stack

- **Database**: MySQL / PostgreSQL compatible
- **Concepts used**: Aggregations, Subqueries, Window context via `HAVING`, `STDDEV()`, CTEs (extendable), Stored Procedures (extendable)

---

## Author

**Deepak** | [LinkedIn](www.linkedin.com/in/deepak1114) 

---

> *This project is based on synthetic data and is intended for educational and portfolio purposes only.*
