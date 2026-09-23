-- Disposable local PostgreSQL only. Run as its administrator.
CREATE ROLE dch_reader LOGIN;
CREATE SCHEMA dch_check;
GRANT USAGE ON SCHEMA dch_check TO dch_reader;
CREATE TABLE dch_check.invoices (
    id integer PRIMARY KEY,
    "Customer Name" text NOT NULL,
    amount numeric(12, 2),
    issued_at timestamptz
);
INSERT INTO dch_check.invoices VALUES
    (1, 'Example customer', 12.34, '2026-09-17T12:00:00Z');
CREATE VIEW dch_check.invoice_summary AS
    SELECT id, amount FROM dch_check.invoices;
GRANT SELECT ON dch_check.invoices, dch_check.invoice_summary TO dch_reader;
CREATE TABLE dch_check.write_only (id integer);
GRANT INSERT ON dch_check.write_only TO dch_reader;
