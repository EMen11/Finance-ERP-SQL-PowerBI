-- 02_seed.sql — Seed data for ERP demo
-- Customers
INSERT INTO public.customers (customer_code, customer_name, country, city, segment) VALUES
('CUST-001','Acme SA','Switzerland','Geneva','Enterprise'),
('CUST-002','Helvetic GmbH','Switzerland','Zurich','SMB'),
('CUST-003','Iberia SL','Spain','Madrid','SMB');

-- Products
INSERT INTO public.products (sku, product_name, category, unit_price) VALUES
('SKU-100','Licences Suite A','Software', 1200),
('SKU-200','Support Premium','Services', 300),
('SKU-300','Formation 1j','Services', 900);

-- Employees
INSERT INTO public.employees (employee_code, full_name, role) VALUES
('E-001','Claudia Perez','Account Manager'),
('E-002','Felix Martin','Sales Rep');

-- Invoices
INSERT INTO public.invoices (invoice_number, customer_id, salesperson_id, status, invoice_date, due_date, currency, terms_days) VALUES
('INV-2025-0001', 1, 1, 'posted', DATE '2025-07-10', DATE '2025-08-09', 'CHF', 30),
('INV-2025-0002', 1, 2, 'posted', DATE '2025-08-15', DATE '2025-09-14', 'CHF', 30),
('INV-2025-0003', 2, 2, 'posted', DATE '2025-08-28', DATE '2025-09-27', 'CHF', 30),
('INV-2025-0004', 3, 1, 'posted', DATE '2025-09-02', DATE '2025-10-02', 'EUR', 30);

-- Invoice lines (with unit prices + tax)
INSERT INTO public.invoice_lines (invoice_id, product_id, quantity, unit_price, tax_rate_pct) VALUES
(1, 1, 2, 1200, 7.7),
(1, 2, 4,  300, 7.7),
(2, 3, 1,  900, 7.7),
(3, 1, 1, 1200, 7.7),
(3, 2, 2,  300, 7.7),
(4, 1, 1, 1200, 20.0);

-- Payments
INSERT INTO public.payments (customer_id, received_date, amount_received, method, currency) VALUES
(1, DATE '2025-08-05', 3000, 'bank_transfer', 'CHF'),
(1, DATE '2025-09-05',  900, 'bank_transfer', 'CHF'),
(2, DATE '2025-09-03', 1500, 'card', 'CHF');

-- Payment allocations
INSERT INTO public.payment_allocations (payment_id, invoice_id, amount_applied) VALUES
(1, 1, 3000),
(2, 2,  900),
(3, 3, 1500);
