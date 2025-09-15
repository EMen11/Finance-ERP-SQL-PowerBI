-- 05_generation.sql — Synthetic data generation (Jan–Mar 2025)

-- Extra master data (idempotent inserts)
INSERT INTO public.customers (customer_code, customer_name)
SELECT v.code, v.name
FROM (VALUES
  ('CUST-004','Globex AG'),
  ('CUST-005','Initech SARL'),
  ('CUST-006','Wayne Ltd')
) AS v(code, name)
WHERE NOT EXISTS (
  SELECT 1 FROM public.customers c WHERE c.customer_code = v.code
);

INSERT INTO public.products (sku, product_name, unit_price, category, is_active)
SELECT v.sku, v.name, v.price, v.cat, TRUE
FROM (VALUES
  ('SKU-004','Workshop 2d',     1800, 'Training'),
  ('SKU-005','Consulting Pack', 2500, 'Service'),
  ('SKU-006','Cloud Add-on',     900, 'SaaS')
) AS v(sku, name, price, cat)
WHERE NOT EXISTS (
  SELECT 1 FROM public.products p WHERE p.sku = v.sku
);

-- Generator: invoices + lines (unit_price included), status 'posted'
DO $$
DECLARE
  d date;
  i int;
  inv_date date;
  due_date date;
  inv_id int;
  cust_id int;
  n_invoices int;
  n_lines int;
  prod record;
BEGIN
  FOR d IN SELECT generate_series(date '2025-01-01', date '2025-03-01', interval '1 month')::date LOOP
    n_invoices := 6 + floor(random()*4);
    FOR i IN 1..n_invoices LOOP
      inv_date := d + (1 + floor(random()*27))::int;
      due_date := inv_date + 30;

      SELECT c.customer_id INTO cust_id
      FROM public.customers c
      ORDER BY random() LIMIT 1;

      INSERT INTO public.invoices (customer_id, invoice_date, due_date, status, invoice_number)
      VALUES (
        cust_id, inv_date, due_date, 'posted',
        'INV-' || to_char(inv_date,'YYYYMM') || '-' || lpad(i::text,3,'0')
      )
      RETURNING invoice_id INTO inv_id;

      n_lines := 1 + floor(random()*3);
      FOR prod IN
        SELECT p.product_id, p.unit_price
        FROM public.products p
        ORDER BY random()
        LIMIT n_lines
      LOOP
        INSERT INTO public.invoice_lines (invoice_id, product_id, quantity, unit_price)
        VALUES (inv_id, prod.product_id, (1 + floor(random()*4))::int, prod.unit_price);
      END LOOP;
    END LOOP;
  END LOOP;
END $$;

-- Quick check
SELECT to_char(invoice_date,'YYYY-MM') AS yyyymm, COUNT(*) AS invoices_count
FROM public.invoices
WHERE invoice_date BETWEEN date '2025-01-01' AND date '2025-03-31'
GROUP BY 1
ORDER BY 1;
