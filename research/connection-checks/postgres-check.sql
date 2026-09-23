-- Run both discovery and reads in one libpq session as dch_reader.
SELECT current_user AS connection_identity;
SELECT table_name, table_type
FROM information_schema.tables
WHERE table_schema = 'dch_check'
ORDER BY table_name;
SELECT table_name, column_name, ordinal_position, data_type,
       numeric_precision, numeric_scale, is_nullable
FROM information_schema.columns
WHERE table_schema = 'dch_check'
ORDER BY table_name, ordinal_position;

DO $$
BEGIN
    IF current_user <> 'dch_reader' THEN
        RAISE EXCEPTION 'Wrong test identity';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'dch_check' AND table_name = 'invoices'
          AND column_name = 'Customer Name' AND is_nullable = 'NO'
    ) THEN
        RAISE EXCEPTION 'Quoted column metadata missing';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'dch_check' AND table_name = 'invoices'
          AND column_name = 'amount'
          AND numeric_precision = 12 AND numeric_scale = 2
    ) THEN
        RAISE EXCEPTION 'Decimal precision/scale missing';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM dch_check.invoice_summary WHERE id = 1 AND amount = 12.34
    ) THEN
        RAISE EXCEPTION 'View read failed';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'dch_check' AND table_name = 'write_only'
    ) THEN
        RAISE EXCEPTION 'Expected INSERT-only table to be discoverable';
    END IF;
    BEGIN
        PERFORM * FROM dch_check.write_only;
        RAISE EXCEPTION 'Unexpected read access on INSERT-only table';
    EXCEPTION WHEN insufficient_privilege THEN
        RAISE NOTICE 'PASS: discovery visibility does not grant SELECT';
    END;
    RAISE NOTICE 'PASS: one connection identity performed discovery and authorized reads';
END;
$$;
