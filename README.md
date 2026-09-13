# 🚨 RedFlag – The Fraud Files

### SQL-Powered Fraud Detection Engine | MySQL | Data Analytics

> **Build a fraud detection engine using pure SQL. No ML. No Python. No excuses.**

RedFlag is an industry-style fraud detection project built around a large transactional dataset from **PayFast**, a fictional Indian payment aggregator.

The goal is simple:

**Find suspicious users, transactions, and merchants hidden inside 200K+ payment transactions — using SQL.**

---

## 🧩 The Challenge

Payment platforms process huge numbers of transactions every day.

Among thousands of legitimate transactions, fraudulent behavior can hide in patterns such as:

* unusually high transaction frequency
* repeated small-value payments
* suspicious refund activity
* unusual transaction hours
* rapid movement of money
* sudden activity after long periods of inactivity
* suspicious merchant-user relationships
* geographically impossible transactions

The challenge was to detect these behaviors using **SQL logic alone**.

No machine learning.

No Python.

No external fraud-detection libraries.

Just SQL. 🧠

---

## 📊 Dataset

The project uses the provided **RedFlag transaction dataset** for the fictional PayFast payment aggregator.

### Dataset characteristics

| Attribute         | Details                       |
| ----------------- | ----------------------------- |
| Transactions      | 200K+                         |
| Users             | 14K+                          |
| Merchants         | 800                           |
| Period            | Jan–Jun 2024                  |
| Payment Modes     | UPI, CARD, NETBANKING, WALLET |
| Transaction Types | DEBIT, CREDIT, REFUND         |
| Status            | SUCCESS, FAILED               |
| Geography         | Multiple Indian cities        |

### Transaction Schema

```text
txn_id
user_id
merchant_id
amount
txn_time
status
payment_mode
city
txn_type
```

The dataset contains indexed fields for efficient analysis of users, transaction time, and merchants.

---

# 🔍 12 Fraud Detection Patterns

## 01 — Velocity Fraud ⚡

### Idea

A user suddenly performs a very large number of transactions within a single day.

### Detection

Flag user-days containing **30 or more transactions**.

### Why it matters

Fraudsters often automate or rapidly execute transactions after gaining access to an account.

---

## 02 — Round-Amount Clustering 💰

### Idea

Repeated transactions using suspiciously round amounts.

### Detection

Look for users with **15+ transactions** involving amounts such as:

```text
₹100
₹200
₹500
₹1,000
₹2,000
₹5,000
₹10,000
```

### Why it matters

Repeated round-value transactions can indicate automated transfers or structured activity.

---

## 03 — Card Testing 💳

### Idea

Attackers may test stolen card/payment credentials using many tiny transactions.

### Detection

Find users making **30+ transactions below ₹10 within one day**.

### Why it matters

Small-value authorization attempts can be used to test whether compromised payment credentials work.

---

## 04 — Failed → Successful Transactions 🔄

### Idea

Repeated failed payments followed shortly by successful payments of the same amount.

### Detection

Identify transaction pairs where:

```text
FAILED
   ↓
within 2 minutes
   ↓
SUCCESS
```

with the same user and amount.

### Why it matters

Repeated attempts can indicate credential testing or payment manipulation.

---

## 05 — Odd-Hour Concentration 🌙

### Idea

Some suspicious accounts may operate heavily during unusual hours.

### Detection

Flag users who:

* have 30+ total transactions
* perform at least 80% of them during hours:

```text
02:00
03:00
04:00
```

### Why it matters

Extreme concentration during unusual hours can be a useful behavioral signal.

---

## 06 — Mule Accounts 🐴

### Idea

A money mule receives funds and quickly moves them elsewhere.

### Detection

Look for users showing repeated:

```text
CREDIT
   ↓
within 30 minutes
   ↓
DEBIT
```

where the debit represents at least 70% of the credit amount.

### Why it matters

Rapid incoming/outgoing money movement is a classic suspicious behavior.

---

## 07 — Refund Abuse 🔁

### Idea

A user generates an unusually high proportion of refund transactions.

### Detection

Flag users with:

* 20+ transactions
* refund ratio greater than 40%

### Why it matters

Excessive refunds can indicate abuse of a merchant's refund process.

---

## 08 — Merchant Collusion 🤝

### Idea

A small group of users dominates a merchant's transaction value.

### Detection

Identify merchants where the **top 5 users account for more than 60% of total transaction value**.

### Why it matters

Highly concentrated transaction activity may indicate coordinated behavior.

---

## 09 — Just-Under-Threshold Transactions 🎯

### Idea

Fraudsters may deliberately keep transactions just below a monitoring or approval threshold.

### Detection

Find users with **10+ transactions exactly at ₹9,999**.

### Why it matters

Repeated threshold-adjacent transactions can indicate deliberate structuring.

---

## 10 — Dormant → Active Accounts 💤➡️⚡

### Idea

An account remains inactive for a long period and suddenly becomes highly active.

### Detection

Identify users with:

* a transaction gap of at least 90 days
* followed by 15+ transactions

### Why it matters

A dormant account becoming suddenly active can be a strong anomaly signal.

---

## 11 — Velocity Spike 📈

### Idea

Instead of looking only at total transaction volume, compare a user's monthly activity against their own historical behavior.

### Detection

Flag users where:

```text
Peak monthly transactions >= 20
AND
Peak month >= 5 × average monthly activity
```

### Why it matters

A sudden behavioral change can be more informative than simply having a high transaction count.

---

## 12 — Geographic Impossibility 🌍

### Idea

A user appears to make transactions from different cities within an unrealistically short period.

### Detection

Compare consecutive transactions for each user and flag cases where:

```text
Different city
+
Time difference <= 60 minutes
```

### Why it matters

The pattern can indicate account sharing, compromised credentials, or impossible travel.

---

# 🛠️ SQL Concepts Used

This project goes beyond basic SQL.

### Core SQL

* `SELECT`
* `WHERE`
* `GROUP BY`
* `HAVING`
* `ORDER BY`
* `COUNT()`
* `SUM()`
* `AVG()`
* `CASE WHEN`
* `DISTINCT`

### Intermediate SQL

* Subqueries
* Correlated subqueries
* `EXISTS`
* Self-joins
* Conditional aggregation
* Date/time functions
* `DATE()`
* `HOUR()`
* `DATE_FORMAT()`
* `TIMESTAMPDIFF()`

### Advanced SQL

* Window functions
* `LAG()`
* `ROW_NUMBER()`
* `PARTITION BY`
* Behavioral baselines
* Sequential transaction analysis

---

# 📈 Detection Results

The completed analysis produced the following suspect counts:

| Pattern                        | Detected |
| ------------------------------ | -------: |
| P1 — Velocity Fraud            |   **50** |
| P2 — Round-Amount Clustering   |   **25** |
| P3 — Card Testing              |   **20** |
| P4 — Failed → Successful       |   **25** |
| P5 — Odd-Hour Concentration    |   **20** |
| P6 — Mule Accounts             |   **30** |
| P7 — Refund Abuse              |   **24** |
| P8 — Merchant Collusion        |   **15** |
| P9 — Just-Under-Threshold      |   **20** |
| P10 — Dormant → Active         |   **26** |
| P11 — Velocity Spike           |   **45** |
| P12 — Geographic Impossibility |   **15** |

These results align with the expected ranges/counts specified in the project brief.

---

# 📁 Repository Structure

```text
RedFlag-Fraud-Detection/
│
├── README.md
│
├── RedFlag_Praju.sql
│
└── dataset/
    └── redflag_transactions.sql
```

> The large transaction dataset may be kept separately depending on GitHub repository/file-size constraints.

---

# 🚀 How to Run

## 1. Install MySQL

Use:

* MySQL Server
* MySQL Workbench

## 2. Import the Dataset

Open:

```text
redflag_transactions.sql
```

in MySQL Workbench.

Execute the dataset script.

Then verify:

```sql
SELECT COUNT(*)
FROM redflag.transactions;
```

---

## 3. Run the Fraud Detection Queries

Open:

```text
RedFlag_Praju.sql
```

Make sure the database is selected:

```sql
USE redflag;
```

Run the 12 detection sections individually or together.

---

# 🎯 Project Objectives

This project was designed to demonstrate the ability to:

* analyze large transactional datasets
* translate fraud scenarios into SQL logic
* identify behavioral anomalies
* work with date/time data
* use aggregation effectively
* write multi-step SQL analysis
* apply window functions
* reason about real-world fraud patterns
* communicate analytical findings

---

# 💡 Key Takeaways

### 1. SQL can be surprisingly powerful.

Fraud detection doesn't always require machine learning.

Well-designed SQL can identify:

```text
velocity
behavioral changes
transaction sequences
financial patterns
geographic anomalies
merchant concentration
```

---

### 2. Context matters.

A transaction isn't necessarily suspicious because of its amount alone.

The surrounding behavior matters:

> Who made it?
> When?
> How frequently?
> Where?
> What happened immediately before it?

---

### 3. Behavioral baselines are powerful.

Comparing a user against their own historical activity can reveal anomalies that simple thresholds miss.

---

# 🧠 What I Learned

Working on RedFlag helped strengthen my understanding of:

**SQL → Data Analysis → Fraud Detection → Behavioral Analytics**

The biggest lesson was learning to translate a real-world problem statement into precise, testable SQL rules.

---

# 🔮 Future Improvements

Possible next steps:

* Build a dashboard using Power BI/Tableau
* Add a fraud-risk scoring system
* Track suspicious users across multiple patterns
* Create a combined fraud score
* Visualize transaction networks
* Add merchant-level behavioral monitoring
* Compare SQL-based detection with ML approaches

---

# 👨‍💻 Author

**Praju**

Computer Science Engineering Student

Interested in:

```text
Data Analytics
SQL
Data Science
Fraud Detection
Machine Learning
Software Development
```

---

## ⭐ If you find this project interesting

Feel free to explore the SQL queries, experiment with the thresholds, and build your own fraud-detection rules.

**Star ⭐ the repository if you found it useful!**

---

### Project

**RedFlag – The Fraud Files**

> Turning transaction data into fraud signals — one SQL query at a time. 🚨
