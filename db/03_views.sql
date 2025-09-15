-- 03_views.sql — Reporting views
DROP VIEW IF EXISTS public.v_invoice_open_balance;
DROP VIEW IF EXISTS public.v_invoice_totals;

CREATE VIEW public.v_invoice_totals AS
SELECT
  i.invoice_id,
  i.invoice_number,
  i.customer_id,
  i.invoice_date,
  i.due_date,
  i.status,
  SUM(il.line_amount_excl) AS total_excl_tax,
  SUM(il.line_tax_amount)  AS total_tax,
  SUM(il.line_amount_incl) AS total_incl_tax
FROM public.invoices i
JOIN public.invoice_lines il ON il.invoice_id = i.invoice_id
GROUP BY i.invoice_id;

CREATE VIEW public.v_invoice_open_balance AS
SELECT
  v.invoice_id,
  v.invoice_number,
  v.customer_id,
  v.invoice_date,
  v.due_date,
  v.status,
  v.total_incl_tax,
  COALESCE((
    SELECT SUM(pa.amount_applied)
    FROM public.payment_allocations pa
    WHERE pa.invoice_id = v.invoice_id
  ), 0) AS total_paid,
  (v.total_incl_tax - COALESCE((
    SELECT SUM(pa.amount_applied)
    FROM public.payment_allocations pa WHERE pa.invoice_id = v.invoice_id
  ), 0)) AS open_balance
FROM public.v_invoice_totals v;
