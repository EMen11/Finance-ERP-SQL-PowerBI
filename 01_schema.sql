-- 01_schema.sql — Core schema for ERP demo
-- Safe drops
DROP TABLE IF EXISTS public.payment_allocations CASCADE;
DROP TABLE IF EXISTS public.invoice_lines CASCADE;
DROP TABLE IF EXISTS public.invoices CASCADE;
DROP TABLE IF EXISTS public.payments CASCADE;
DROP TABLE IF EXISTS public.employees CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.customers CASCADE;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'invoice_status') THEN
    DROP TYPE invoice_status;
  END IF;
END$$;

-- Enum for invoice status
CREATE TYPE invoice_status AS ENUM ('draft','posted','void');

-- Dimensions
CREATE TABLE public.customers (
  customer_id      SERIAL PRIMARY KEY,
  customer_code    TEXT UNIQUE NOT NULL,
  customer_name    TEXT NOT NULL,
  country          TEXT,
  city             TEXT,
  segment          TEXT,
  created_at       TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE public.products (
  product_id       SERIAL PRIMARY KEY,
  sku              TEXT UNIQUE NOT NULL,
  product_name     TEXT NOT NULL,
  category         TEXT,
  unit_price       NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  is_active        BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE public.employees (
  employee_id      SERIAL PRIMARY KEY,
  employee_code    TEXT UNIQUE NOT NULL,
  full_name        TEXT NOT NULL,
  role             TEXT,
  manager_id       INT REFERENCES public.employees(employee_id)
);

-- Billing
CREATE TABLE public.invoices (
  invoice_id       SERIAL PRIMARY KEY,
  invoice_number   TEXT UNIQUE NOT NULL,
  customer_id      INT NOT NULL REFERENCES public.customers(customer_id),
  salesperson_id   INT REFERENCES public.employees(employee_id),
  status           invoice_status NOT NULL DEFAULT 'posted',
  invoice_date     DATE NOT NULL,
  due_date         DATE NOT NULL,
  currency         TEXT NOT NULL DEFAULT 'EUR',
  terms_days       INT NOT NULL DEFAULT 30,
  created_at       TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE public.invoice_lines (
  invoice_line_id  SERIAL PRIMARY KEY,
  invoice_id       INT NOT NULL REFERENCES public.invoices(invoice_id) ON DELETE CASCADE,
  product_id       INT NOT NULL REFERENCES public.products(product_id),
  quantity         NUMERIC(12,2) NOT NULL CHECK (quantity > 0),
  unit_price       NUMERIC(12,2) NOT NULL CHECK (unit_price >= 0),
  tax_rate_pct     NUMERIC(5,2) NOT NULL DEFAULT 0,
  line_amount_excl NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_price) STORED,
  line_tax_amount  NUMERIC(14,2) GENERATED ALWAYS AS ((quantity * unit_price) * tax_rate_pct / 100.0) STORED,
  line_amount_incl NUMERIC(14,2) GENERATED ALWAYS AS ((quantity * unit_price) * (1 + tax_rate_pct / 100.0)) STORED
);

-- Collections
CREATE TABLE public.payments (
  payment_id       SERIAL PRIMARY KEY,
  customer_id      INT NOT NULL REFERENCES public.customers(customer_id),
  received_date    DATE NOT NULL,
  amount_received  NUMERIC(14,2) NOT NULL CHECK (amount_received >= 0),
  method           TEXT,
  currency         TEXT NOT NULL DEFAULT 'EUR',
  notes            TEXT
);

CREATE TABLE public.payment_allocations (
  allocation_id    SERIAL PRIMARY KEY,
  payment_id       INT NOT NULL REFERENCES public.payments(payment_id) ON DELETE CASCADE,
  invoice_id       INT NOT NULL REFERENCES public.invoices(invoice_id) ON DELETE CASCADE,
  amount_applied   NUMERIC(14,2) NOT NULL CHECK (amount_applied >= 0),
  applied_at       TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (payment_id, invoice_id)
);

-- Indexes
CREATE INDEX idx_inv_customer_date ON public.invoices(customer_id, invoice_date);
CREATE INDEX idx_alloc_invoice    ON public.payment_allocations(invoice_id);
CREATE INDEX idx_alloc_payment    ON public.payment_allocations(payment_id);
