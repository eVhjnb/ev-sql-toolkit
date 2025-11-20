-- core_patterns/date_windows.sql
-- Patrones de ventanas temporales para KPIs semanales/anuales

-- Últimos 52 weeks tomando como referencia una fecha de corte
-- :cutoff_date se sustituye por la fecha (YYYY-MM-DD)

WITH date_window AS (
    SELECT
        CAST(:cutoff_date AS DATE)            AS cutoff_date,
        CAST(:cutoff_date AS DATE)
            - INTERVAL '52 weeks'             AS window_start_date
)
SELECT *
FROM date_window;
