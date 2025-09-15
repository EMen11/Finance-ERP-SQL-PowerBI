-- 04_queries.sql — Analytical examples

-- Quick sanity checks
SELECT COUNT(*) AS invoice_count FROM public.invoices;
SELECT * FROM public.v_invoice_totals LIMIT 5;
SELECT * FROM public.v_invoice_open_balance LIMIT 5;

-- A) Paid vs unpaid (by month)
WITH inv AS (
  SELECT invoice_id,
         date_trunc('month', invoice_date)::date AS month_start,
         total_incl_tax,
         (total_incl_tax - total_paid) AS open_balance
  FROM public.v_invoice_open_balance
  WHERE status = 'posted'
)
SELECT
  month_start,
  COUNT(*)                                           AS invoices_total,
  COUNT(*) FILTER (WHERE open_balance = 0)           AS invoices_paid,
  COUNT(*) FILTER (WHERE open_balance > 0)           AS invoices_unpaid,
  SUM(total_incl_tax)                                AS amount_total,
  SUM(total_incl_tax) FILTER (WHERE open_balance=0)  AS amount_paid,
  SUM(open_balance)                                  AS amount_open
FROM inv
GROUP BY month_start
ORDER BY month_start;

-- B) Revenue by customer
SELECT
  c.customer_code,
  c.customer_name,
  SUM(v.total_incl_tax)                              AS billed_amount,
  SUM(v.total_incl_tax - v.open_balance)             AS collected_amount,
  SUM(v.open_balance)                                AS open_balance
FROM public.v_invoice_open_balance v
JOIN public.customers c ON c.customer_id = v.customer_id
GROUP BY c.customer_code, c.customer_name
ORDER BY billed_amount DESC;
