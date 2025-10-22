# Finance-ERP-SQL-PowerBI

# ERP Demo – SQL + Power BI Project

This project is a **mini ERP system** built in PostgreSQL with a connected **Power BI dashboard**.  

It simulates the core components of an ERP by modeling key business entities:  
- **Customers, Products, Employees** → the master data.  
- **Invoices, Payments, Allocations** → the transactional flows.  
- **Views & Queries** → the reporting layer.  

The workflow mimics a real ERP:  
1. Create invoices and invoice lines for customers.  
2. Record payments (full or partial) and allocate them to invoices.  
3. Compute balances and overdue amounts through SQL views.  
4. Expose these datasets to Power BI for interactive dashboards.  

This demonstrates end-to-end skills:  
- **SQL data modeling** (tables, enums, constraints, indexes).  
- **Data generation** (synthetic monthly invoices via PL/pgSQL).  
- **Analytical queries & views** (totals, open balances, paid vs unpaid).  
- **Business Intelligence reporting** (KPI cards, risk/aging analysis, data quality checks).  

The approach is designed to resemble a simplified ERP → not production-ready, but close enough to illustrate real-world finance & operations workflows.


---

## 1. Database Schema

The schema includes customers, products, employees, invoices, invoice lines, payments, and payment allocations.  
Invoice status is managed via a PostgreSQL enum.

File: [`db/01_schema.sql`](db/01_schema.sql)

Main objects:
- `customers`, `products`, `employees`
- `invoices`, `invoice_lines`
- `payments`, `payment_allocations`
- Enum `invoice_status`
- Indexes for performance

**Example (excerpt):**
```sql
-- Invoice status enum
CREATE TYPE invoice_status AS ENUM ('draft', 'posted', 'void');

-- Customers table
CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    country     VARCHAR(50),
    created_at  TIMESTAMP DEFAULT now()

```

---

## 2. Seed Data

Initial dataset for customers, products, employees, invoices, lines, and payments.  
Used to quickly test the schema and build the first dashboards.

File: [`db/02_seed.sql`](db/02_seed.sql)

```sql
-- Insert sample customers
INSERT INTO customers (name, country) VALUES
  ('Acme SA', 'Switzerland'),
  ('Helvetic GmbH', 'Germany'),
  ('Iberia SL', 'Spain');

-- Insert sample products
INSERT INTO products (sku, name, unit_price) VALUES
  ('SKU-001', 'Licenses Suite A', 4800),
  ('SKU-002', 'Support Premium', 2200),
  ('SKU-003', 'Training 1d',  950);
```




---

## 3. Views

Analytical views for reporting in Power BI.

File: [`db/03_views.sql`](db/03_views.sql)

- **`v_invoice_totals`** → totals excl. tax, tax, incl. tax per invoice  
- **`v_invoice_open_balance`** → billed, collected, open balance per invoice 

```sql
CREATE VIEW v_invoice_totals AS
SELECT i.invoice_id,
       SUM(il.quantity * il.unit_price)      AS total_excl_tax,
       SUM(il.quantity * il.unit_price * 0.1) AS tax,
       SUM(il.quantity * il.unit_price * 1.1) AS total_incl_tax
FROM invoices i
JOIN invoice_lines il ON i.invoice_id = il.invoice_id
GROUP BY i.invoice_id; 
```

---

## 4. Analytical Queries

Example SQL queries used directly for KPIs and checks.

File: [`db/04_queries.sql`](db/04_queries.sql)

- Paid vs unpaid invoices by month  
- Revenue per customer (billed / collected / balance)  
```sql
-- Paid vs unpaid invoices by month
SELECT DATE_TRUNC('month', i.invoice_date) AS month,
       COUNT(*) FILTER (WHERE i.status = 'paid')   AS paid_invoices,
       COUNT(*) FILTER (WHERE i.status <> 'paid') AS unpaid_invoices
FROM invoices i
GROUP BY 1
ORDER BY 1;
```

---

## 5. Synthetic Data Generation

PL/pgSQL script to generate synthetic invoices and lines month by month.  
Allows extension of the dataset to simulate real operations (e.g. 12 months of activity).

File: [`db/05_generation.sql`](db/05_generation.sql)

```sql
DO $$
DECLARE
    v_month DATE := DATE '2025-01-01';
BEGIN
    FOR i IN 1..12 LOOP
        INSERT INTO invoices (customer_id, invoice_date, due_date, status, invoice_number)
        VALUES ( (1 + random() * 3)::INT,
                 v_month,
                 v_month + INTERVAL '30 days',
                 'posted',
                 'INV-' || TO_CHAR(v_month, 'YYYYMM') || '-' || LPAD(i::TEXT, 3, '0'));

        v_month := v_month + INTERVAL '1 month';
    END LOOP;
END $$;
```
---

## 6. Power BI Report

File: [ERP Demo - SQL Project.pbix](powerbi/ERP%20Demo%20-%20SQL%20Project.pbix)

PDF Export: [ERP Demo - SQL Project.pdf](docs/ERP%20Demo%20-%20SQL%20Project.pdf)


### Page 1 – Financial Overview
- KPIs: Total Billed, Total Collected, Open Balance, % Collected  
- Paid vs Unpaid invoices (monthly trend)  
- Revenue by Customer  
- Revenue by Product  

![Dashboard Page 1](docs/dashboard_page1.png)

### Page 2 – Risk & Data Quality
- Risk KPIs: Avg Days Past Due, % Invoices Overdue, % Amount Overdue, Max Days Past Due  
- Aging Report: overdue amounts by customer and aging bucket  
- Scenario (What-If) block with Payment Delay parameter  
- Data Quality checks: % Clean Invoices, Duplicate numbers, anomalies 

![Dashboard Page 2](docs/dashboard_page2.png)  

## 7. Conclusion  

This project shows how a PostgreSQL database can power a realistic **ERP-style dataset** and how SQL + Power BI can be combined to produce actionable insights.  

- Page 1 focuses on **Finance & Collections KPIs** (billed vs collected, AR balance, client/product contribution).  
- Page 2 extends to **Risk & Data Quality**, with overdue analysis, scenario testing, and audit-style controls.  

Because the dataset is intentionally **small and synthetic**, most Data Quality checks return “clean.”  
In a larger dataset, more anomalies would naturally appear, making the DQ section more populated.  

Still, this setup is enough to demonstrate:  
- SQL proficiency (schema, views, PL/pgSQL generation).  
- BI reporting skills (DAX measures, interactive visuals).  
- Awareness of audit/risk practices (aging reports, overdue KPIs, DQ checks).  

This makes the project a strong **portfolio piece** for roles at the intersection of **Finance, Risk, and Data Analytics**.



