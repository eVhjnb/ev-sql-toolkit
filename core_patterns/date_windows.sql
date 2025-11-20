-- core_patterns/date_windows.sql
-- Time window patterns for weekly / yearly KPIs.
-- :cutoff_date should be replaced with a date literal (YYYY-MM-DD).

WITH date_window AS (
    SELECT
        CAST(:cutoff_date AS DATE) AS cutoff_date,
        CAST(:cutoff_date AS DATE) - INTERVAL '52 weeks' AS window_start_date
)
SELECT *
FROM date_window;
