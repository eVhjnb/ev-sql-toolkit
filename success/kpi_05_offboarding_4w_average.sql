-- success/kpi_05_offboarding_4w_average.sql
-- KPI 5 – 4 Week Average of Offboarding Forms Completed (derived KPI).
-- Uses the scorecard table where the base KPI is already stored.

WITH date_window AS (
    SELECT
        CAST(:cutoff_date AS DATE) AS cutoff_date,
        CAST(:cutoff_date AS DATE) - INTERVAL '28 day' AS window_start
),
base_values AS (
    SELECT
        s.last_sunday,
        s.field_value
    FROM vl_analytics.scorecard_vl02 s              --adjust table if needed
    CROSS JOIN date_window dw
    WHERE s.sc_name = 'Success'                     --adjust scorecard name
      AND s.kpi_number = '06'                       --base KPI (offboarding forms)
      AND s.range_type = 'weekly'
      AND s.last_sunday >= dw.window_start
      AND s.last_sunday <= dw.cutoff_date
)
SELECT
    COALESCE(AVG(field_value), 0)::NUMERIC AS offboarding_4w_average
FROM base_values;
