-- utils/normalize_clients.sql
-- Example client normalization for names and IDs.

SELECT
    LOWER(TRIM(client_name)) AS client_name_norm,
    REGEXP_REPLACE(client_id, '[^0-9A-Za-z]', '', 'g') AS client_id_norm,
    *
FROM RAW_SCHEMA.CLIENTS_RAW;   -- adjust source schema/table
