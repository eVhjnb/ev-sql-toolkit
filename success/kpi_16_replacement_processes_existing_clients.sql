-- success/kpi_16_replacement_processes_existing_clients.sql
-- KPI 16 – New Replacement Processes for Existing Clients (weekly).
-- Typical source: a normalized replacements table in the DWH.

SELECT
    COUNT(*)::INT AS replacements_existing_clients
FROM SCHEMA_NAME.REPLACEMENTS_TABLE     --real schema/table
WHERE year_week = :year_week            --format 'YYYY-WW'
  AND client_segment = 'EXISTING';      --adjust segmentation logic
