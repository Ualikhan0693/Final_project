#Задание 1 список клиентов с непрерывной историей за год
SELECT id_client
FROM (
    SELECT id_client,
           SUBSTRING(date_new, 4, 7) AS ym
    FROM transactions
    WHERE date_new BETWEEN '01.06.2015' AND '31.05.2016'
    GROUP BY id_client, ym
) t
GROUP BY id_client
HAVING COUNT(DISTINCT ym) = 12;
#средний чек
SELECT id_client,
       AVG(sum_payment) AS avg_check
FROM transactions
WHERE date_new BETWEEN '01.06.2015' AND '31.05.2016'
GROUP BY id_client;
#средняя сумма покупок за месяц
WITH cm AS (
  SELECT id_client,
         SUBSTRING(date_new, 4, 7) AS ym,
         SUM(sum_payment) AS month_sum
  FROM transactions
  WHERE date_new BETWEEN '01.06.2015' AND '31.05.2016'
  GROUP BY id_client, ym
)
SELECT id_client,
       SUM(month_sum) / COUNT(*) AS avg_month_sum
FROM cm
GROUP BY id_client;
#количество всех операций по клиенту за период
SELECT id_client,
       COUNT(*) AS ops_count
FROM transactions
WHERE date_new BETWEEN '01.06.2015' AND '31.05.2016'
GROUP BY id_client;

#Задание 2 средняя сумма чека в месяц
SELECT
  DATE_FORMAT(date_new, '%m.%Y') AS month_year,
  AVG(sum_payment) AS avg_check
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month_year
ORDER BY MIN(date_new);
#среднее количество операций в месяц
SELECT
  DATE_FORMAT(date_new, '%Y-%m') AS month_year,   -- формат: ГГГГ-ММ
  COUNT(*) AS ops_count
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month_year
ORDER BY month_year;
SELECT
  AVG(ops_count) AS avg_ops_per_month
FROM 
(SELECT DATE_FORMAT(date_new, '%Y-%m') AS month_year,
	COUNT(*) AS ops_count
  FROM transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
  GROUP BY month_year) t;
#среднее количество клиентов, которые совершали операции
SELECT
  DATE_FORMAT(date_new, '%Y-%m') AS month_year,
  COUNT(DISTINCT id_client) AS client_count
FROM transactions
WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
GROUP BY month_year
ORDER BY month_year;
SELECT
  AVG(client_count) AS avg_clients_per_month
FROM 
(SELECT
    DATE_FORMAT(date_new, '%Y-%m') AS month_year,
    COUNT(DISTINCT id_client) AS client_count
  FROM transactions
  WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
  GROUP BY month_year) t;
#долю от общего количества операций за год и долю в месяц от общей суммы операций
WITH monthly AS (SELECT
	DATE_FORMAT(date_new, '%Y-%m') AS month_year,
	COUNT(*) AS ops_count,
	SUM(sum_payment) AS ops_sum
    FROM transactions
    WHERE date_new BETWEEN '2015-06-01' AND '2016-05-31'
    GROUP BY month_year),
totals AS (SELECT
	SUM(ops_count) AS total_ops,
	SUM(ops_sum)   AS total_sum
    FROM monthly)
SELECT
    m.month_year,
    m.ops_count,
    ROUND(m.ops_count / t.total_ops * 100, 2) AS ops_share_percent,
    m.ops_sum,
    ROUND(m.ops_sum / t.total_sum * 100, 2)   AS sum_share_percent
FROM monthly m
CROSS JOIN totals t
ORDER BY m.month_year;
SELECT
  month_year,
  gender,
  ops_count,
  ROUND(ops_count * 100.0 / SUM(ops_count) OVER (PARTITION BY month_year), 2) AS ops_share_percent,
  ops_sum,
  ROUND(ops_sum   * 100.0 / SUM(ops_sum)   OVER (PARTITION BY month_year), 2) AS spend_share_percent
FROM (
  SELECT
    DATE_FORMAT(t.date_new, '%Y-%m') AS month_year,
    COALESCE(NULLIF(UPPER(c.gender), ''), 'NA') AS gender,
    COUNT(*) AS ops_count,
    SUM(t.sum_payment) AS ops_sum
  FROM transactions t
  LEFT JOIN customers c ON c.id_client = t.id_client
  WHERE t.date_new BETWEEN '2015-06-01' AND '2016-05-31'
  GROUP BY month_year, gender) s
ORDER BY month_year, FIELD(gender, 'M','F','NA');
#3. возрастные группы клиентов с шагом 10 лет и отдельно клиентов
SELECT
  CASE
    WHEN c.age IS NULL THEN 'NA'
    ELSE CONCAT(FLOOR(c.age/10)*10, '-', FLOOR(c.age/10)*10+9)
  END AS age_group,
  COUNT(t.id_check)  AS ops_count,
  SUM(t.sum_payment) AS ops_sum
FROM customers c
LEFT JOIN transactions t ON c.id_client = t.id_client
GROUP BY age_group
ORDER BY age_group;
SELECT
    age_group,
    quarter,
    ops_count,
    ops_sum,
    avg_check,
    ROUND(ops_count * 100.0 / SUM(ops_count) OVER (PARTITION BY quarter), 2) AS ops_share_percent,
    ROUND(ops_sum   * 100.0 / SUM(ops_sum)   OVER (PARTITION BY quarter), 2) AS sum_share_percent
FROM (SELECT
	CASE
		WHEN c.age IS NULL THEN 'NA'
		ELSE CONCAT(FLOOR(c.age/10)*10, '-', FLOOR(c.age/10)*10+9)
        END AS age_group,
        CONCAT(YEAR(t.date_new), '-Q', QUARTER(t.date_new)) AS quarter,
        COUNT(*) AS ops_count,
        SUM(t.sum_payment) AS ops_sum,
        AVG(t.sum_payment) AS avg_check
    FROM customers c
    JOIN transactions t ON c.id_client = t.id_client
    GROUP BY age_group, quarter) sub
ORDER BY quarter, age_group;