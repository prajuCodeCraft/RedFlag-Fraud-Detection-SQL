-- =====================================================================
-- RedFlag - Fraud Detection Submission
-- Student: Praju | Batch: DA-DS-1
-- =====================================================================
USE redflag;

-- =====================================================================
-- PATTERN 1 - VELOCITY FRAUD
-- What I'm looking for: users with 30+ transactions on a single calendar day.
-- This flags unusually high daily transaction velocity that may indicate
-- automation, account takeover, or transaction churning.
-- Expected suspects: about 45-55 user-days.
-- =====================================================================
SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS daily_txn_count
FROM transactions
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY daily_txn_count DESC;

-- My findings: 50 suspect user-days flagged.
-- Example: user 14569 recorded 60 transactions on 2024-04-03.
-- Example: user 14556 recorded 60 transactions on 2024-05-28.

-- =====================================================================
-- PATTERN 2 - ROUND-AMOUNT CLUSTERING
-- What I'm looking for: users making 15+ transactions at exact round
-- amounts commonly associated with laundering or structured transfers.
-- Expected suspects: exactly 25.
-- =====================================================================
SELECT
    user_id,
    COUNT(*) AS round_amount_txn_count
FROM transactions
WHERE amount IN (100, 200, 500, 1000, 2000, 5000, 10000)
GROUP BY user_id
HAVING COUNT(*) >= 15
ORDER BY round_amount_txn_count DESC;

-- My findings: 25 suspect users flagged.
-- Example: user 14533 had 30 qualifying round-amount transactions.
-- Example: user 14535 had 30 qualifying round-amount transactions.

-- =====================================================================
-- PATTERN 3 - CARD TESTING
-- What I'm looking for: users making 30+ transactions below Rs 10
-- on a single day, a signature of automated card validation/testing.
-- Expected suspects: exactly 20.
-- =====================================================================
SELECT
    user_id,
    DATE(txn_time) AS attack_date,
    COUNT(*) AS tiny_txn_count
FROM transactions
WHERE amount < 10
GROUP BY user_id, DATE(txn_time)
HAVING COUNT(*) >= 30
ORDER BY tiny_txn_count DESC;

-- My findings: 20 suspect user-days flagged.
-- Example: user 14556 recorded 60 sub-Rs 10 transactions on 2024-05-28.
-- Example: user 14569 recorded 60 sub-Rs 10 transactions on 2024-04-03.

-- =====================================================================
-- PATTERN 4 - FAILED-THEN-SUCCEEDED
-- What I'm looking for: users with 20+ failed transactions that are
-- followed within 2 minutes by a successful transaction of the same amount.
-- This is the advanced Week 4 version of repeated payment/card retries.
-- Expected suspects: exactly 25.
-- =====================================================================
SELECT
    f.user_id,
    COUNT(*) AS failed_success_pairs
FROM transactions AS f
WHERE f.status = 'FAILED'
  AND EXISTS (
      SELECT 1
      FROM transactions AS s
      WHERE s.user_id = f.user_id
        AND s.amount = f.amount
        AND s.status = 'SUCCESS'
        AND s.txn_time > f.txn_time
        AND TIMESTAMPDIFF(SECOND, f.txn_time, s.txn_time) <= 120
  )
GROUP BY f.user_id
HAVING COUNT(*) >= 20
ORDER BY failed_success_pairs DESC;

-- My findings: 25 suspect users flagged.
-- Example: user 14595 produced 35 failed-then-success pairs.
-- Example: user 14593 produced 34 failed-then-success pairs.

-- =====================================================================
-- PATTERN 5 - ODD-HOUR CONCENTRATION
-- What I'm looking for: users with at least 30 total transactions where
-- 80% or more occur during hours 2, 3, or 4.
-- Expected suspects: exactly 20.
-- =====================================================================
SELECT
    user_id,
    COUNT(*) AS total_txn_count,
    SUM(CASE
        WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
        ELSE 0
    END) AS odd_hour_txn_count,
    ROUND(
        SUM(CASE
            WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
            ELSE 0
        END) / COUNT(*),
        4
    ) AS odd_hour_ratio
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 30
   AND SUM(CASE
       WHEN HOUR(txn_time) BETWEEN 2 AND 4 THEN 1
       ELSE 0
   END) / COUNT(*) >= 0.80
ORDER BY odd_hour_ratio DESC, total_txn_count DESC;

-- My findings: 20 suspect users flagged.
-- Example: user 14606 had 49 odd-hour transactions out of 52 total.
-- Example: user 14609 had 45 odd-hour transactions out of 48 total.

-- =====================================================================
-- PATTERN 6 - MULE ACCOUNTS
-- What I'm looking for: users with at least 5 instances where a CREDIT
-- is followed within 30 minutes by a DEBIT worth at least 70% of that
-- credit. This captures rapid movement of incoming funds.
-- Expected suspects: exactly 30.
-- =====================================================================
SELECT
    c.user_id,
    COUNT(*) AS credit_debit_instances
FROM transactions AS c
WHERE c.txn_type = 'CREDIT'
  AND EXISTS (
      SELECT 1
      FROM transactions AS d
      WHERE d.user_id = c.user_id
        AND d.txn_type = 'DEBIT'
        AND d.txn_time > c.txn_time
        AND TIMESTAMPDIFF(MINUTE, c.txn_time, d.txn_time) <= 30
        AND d.amount >= 0.70 * c.amount
  )
GROUP BY c.user_id
HAVING COUNT(*) >= 5
ORDER BY credit_debit_instances DESC;

-- My findings: 30 suspect users flagged.
-- Example: user 14630 had 15 qualifying credit-to-debit instances.
-- Example: user 14637 had 15 qualifying credit-to-debit instances.

-- =====================================================================
-- PATTERN 7 - REFUND ABUSE
-- What I'm looking for: users with at least 20 transactions and more
-- than 40% of their transactions recorded as REFUND.
-- Expected suspects: 24-25.
-- =====================================================================
SELECT
    user_id,
    COUNT(*) AS total_txn_count,
    SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) AS refund_count,
    ROUND(
        SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) / COUNT(*),
        4
    ) AS refund_ratio
FROM transactions
GROUP BY user_id
HAVING COUNT(*) >= 20
   AND SUM(CASE WHEN txn_type = 'REFUND' THEN 1 ELSE 0 END) / COUNT(*) > 0.40
ORDER BY refund_ratio DESC, refund_count DESC;

-- My findings: 24 suspect users flagged.
-- Example: user 14662 had 25 refunds out of 39 transactions.
-- Example: user 14670 had 32 refunds out of 50 transactions.

-- =====================================================================
-- PATTERN 8 - MERCHANT COLLUSION
-- What I'm looking for: merchants where the top 5 users by transaction
-- value contribute more than 60% of the merchant's total transaction value.
-- Expected suspects: exactly 15 merchants.
-- =====================================================================
WITH user_merchant_value AS (
    SELECT
        merchant_id,
        user_id,
        SUM(amount) AS user_txn_value
    FROM transactions
    GROUP BY merchant_id, user_id
), ranked_users AS (
    SELECT
        merchant_id,
        user_id,
        user_txn_value,
        ROW_NUMBER() OVER (
            PARTITION BY merchant_id
            ORDER BY user_txn_value DESC
        ) AS user_rank
    FROM user_merchant_value
), merchant_totals AS (
    SELECT
        merchant_id,
        SUM(amount) AS merchant_total_value
    FROM transactions
    GROUP BY merchant_id
), top_five AS (
    SELECT
        merchant_id,
        SUM(user_txn_value) AS top_five_value
    FROM ranked_users
    WHERE user_rank <= 5
    GROUP BY merchant_id
)
SELECT
    t.merchant_id,
    t.top_five_value,
    m.merchant_total_value,
    ROUND(t.top_five_value / m.merchant_total_value, 4) AS top_five_ratio
FROM top_five AS t
JOIN merchant_totals AS m
    ON m.merchant_id = t.merchant_id
WHERE t.top_five_value / m.merchant_total_value > 0.60
ORDER BY top_five_ratio DESC;

-- My findings: 15 suspect merchants flagged.
-- The flagged merchant IDs are 1 through 15, matching the seeded pattern.

-- =====================================================================
-- PATTERN 9 - JUST-UNDER-THRESHOLD (STRUCTURING)
-- What I'm looking for: users with 10+ transactions at exactly Rs 9,999,
-- a classic structuring pattern designed to stay below the stated KYC
-- threshold.
-- Expected suspects: exactly 20.
-- =====================================================================
SELECT
    user_id,
    COUNT(*) AS threshold_avoidance_count
FROM transactions
WHERE amount = 9999.00
GROUP BY user_id
HAVING COUNT(*) >= 10
ORDER BY threshold_avoidance_count DESC;

-- My findings: 20 suspect users flagged.
-- Example: user 14690 had 25 transactions at exactly Rs 9,999.
-- Example: user 14680 had 25 transactions at exactly Rs 9,999.

-- =====================================================================
-- PATTERN 10 - DORMANT-THEN-ACTIVE
-- What I'm looking for: users with a 90+ day gap between consecutive
-- transactions followed by at least 15 transactions after the gap.
-- This is a signature of a dormant account being taken over and monetised.
-- Expected suspects: 25-27.
-- =====================================================================
WITH ordered_txns AS (
    SELECT
        txn_id,
        user_id,
        txn_time,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time, txn_id
        ) AS previous_txn_time
    FROM transactions
), dormant_gaps AS (
    SELECT
        user_id,
        txn_time AS gap_end_time,
        previous_txn_time,
        TIMESTAMPDIFF(DAY, previous_txn_time, txn_time) AS gap_days
    FROM ordered_txns
    WHERE previous_txn_time IS NOT NULL
      AND TIMESTAMPDIFF(DAY, previous_txn_time, txn_time) >= 90
), post_gap_activity AS (
    SELECT
        g.user_id,
        g.gap_end_time,
        g.previous_txn_time,
        g.gap_days,
        COUNT(t.txn_id) AS post_gap_txn_count
    FROM dormant_gaps AS g
    JOIN transactions AS t
        ON t.user_id = g.user_id
       AND t.txn_time > g.gap_end_time
    GROUP BY g.user_id, g.gap_end_time, g.previous_txn_time, g.gap_days
)
SELECT
    user_id,
    previous_txn_time,
    gap_end_time,
    gap_days,
    post_gap_txn_count
FROM post_gap_activity
WHERE post_gap_txn_count >= 15
ORDER BY post_gap_txn_count DESC, gap_days DESC;

-- My findings: 26 suspect users flagged.
-- Example: user 14526 had a qualifying dormant gap followed by 54 transactions.
-- Example: user 14701 had a qualifying dormant gap followed by 27 transactions.

-- =====================================================================
-- PATTERN 11 - VELOCITY SPIKE
-- What I'm looking for: users whose peak monthly transaction count is at
-- least 5x their historical monthly rate, with a peak of at least 20.
-- A minimum four-month observed history is used so the historical average
-- is meaningful rather than being based on only one or two active months.
-- Expected suspects: 35-45; seeded spike users should appear.
-- =====================================================================
WITH monthly_counts AS (
    SELECT
        user_id,
        DATE_FORMAT(txn_time, '%Y-%m') AS txn_month,
        COUNT(*) AS monthly_txn_count
    FROM transactions
    GROUP BY user_id, DATE_FORMAT(txn_time, '%Y-%m')
), user_month_stats AS (
    SELECT
        user_id,
        COUNT(*) AS observed_months,
        AVG(monthly_txn_count) AS average_monthly_txn_count,
        MAX(monthly_txn_count) AS peak_monthly_txn_count
    FROM monthly_counts
    GROUP BY user_id
)
SELECT
    user_id,
    observed_months,
    ROUND(average_monthly_txn_count, 2) AS average_monthly_txn_count,
    peak_monthly_txn_count,
    ROUND(
        peak_monthly_txn_count / average_monthly_txn_count,
        2
    ) AS peak_to_average_ratio
FROM user_month_stats
WHERE observed_months >= 4
  AND peak_monthly_txn_count >= 20
  AND peak_monthly_txn_count / average_monthly_txn_count >= 5
ORDER BY peak_to_average_ratio DESC, peak_monthly_txn_count DESC;

-- My findings: the dataset analysis produces 45 qualifying users with this
-- validated historical-baseline interpretation. The seeded spike group is
-- represented in the results.

-- =====================================================================
-- PATTERN 12 - GEOGRAPHIC IMPOSSIBILITY
-- What I'm looking for: consecutive transactions by the same user in
-- different cities within 60 minutes, which is physically implausible.
-- Expected suspects: exactly 15.
-- =====================================================================
WITH ordered_txns AS (
    SELECT
        txn_id,
        user_id,
        txn_time,
        city,
        LAG(txn_time) OVER (
            PARTITION BY user_id
            ORDER BY txn_time, txn_id
        ) AS previous_txn_time,
        LAG(city) OVER (
            PARTITION BY user_id
            ORDER BY txn_time, txn_id
        ) AS previous_city
    FROM transactions
), impossible_pairs AS (
    SELECT
        user_id,
        previous_city,
        city AS current_city,
        previous_txn_time,
        txn_time AS current_txn_time,
        TIMESTAMPDIFF(MINUTE, previous_txn_time, txn_time) AS minutes_between,
        ROW_NUMBER() OVER (
            PARTITION BY user_id
            ORDER BY txn_time, txn_id
        ) AS pair_rank
    FROM ordered_txns
    WHERE previous_city IS NOT NULL
      AND city <> previous_city
      AND TIMESTAMPDIFF(MINUTE, previous_txn_time, txn_time) <= 60
)
SELECT
    user_id,
    previous_city,
    current_city,
    previous_txn_time,
    current_txn_time,
    minutes_between
FROM impossible_pairs
WHERE pair_rank = 1
ORDER BY minutes_between ASC, user_id;

-- My findings: 15 suspect users flagged.
-- Example: user 14741 moved from Vadodara to Thiruvananthapuram in 30 minutes.
-- Example: user 14742 moved from Vadodara to Thiruvananthapuram in 44 minutes.

-- =====================================================================
-- END OF REDFLAG SUBMISSION
-- =====================================================================
