-- utils/filter_internal_test_accounts.sql
-- Reusable subquery to exclude internal / test accounts.

SELECT *
FROM   SCHEMA_NAME.AGREEMENTS_TABLE a   -- adjust schema/table
WHERE  a.client_type NOT IN ('INTERNAL', 'TEST');  -- adjust values
