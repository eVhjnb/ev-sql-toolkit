-- success/kpi_32_overall_churn_52_weeks.sql
-- KPI 32 – Overall churn [real churn] over the last 52 weeks.
-- Window: last 52 weeks from :cutoff_date.

WITH date_window AS (
    SELECT
        CAST(:cutoff_date AS DATE) AS cutoff_date,
        CAST(:cutoff_date AS DATE) - INTERVAL '52 weeks' AS window_start_date
),
base_agreements AS (
    SELECT
        a.agreement_id,
        a.client_type,
        a.agreement_status,
        a.start_date,
        a.end_date
    FROM SCHEMA_NAME.AGREEMENTS_TABLE a   --adjust schema/table
    WHERE a.start_date IS NOT NULL
),
filtered_agreements AS (
    SELECT *
    FROM base_agreements
    WHERE client_type NOT IN ('INTERNAL', 'TEST')  --adjust values
),
churned_in_window AS (
    SELECT
        COUNT(DISTINCT agreement_id) AS churned_count
    FROM filtered_agreements fa
    CROSS JOIN date_window dw
    WHERE fa.end_date IS NOT NULL
      AND fa.agreement_status IN ('TERM_CLIENT', 'TERM_OTHER')  --churn statuses
      AND fa.end_date >= dw.window_start_date
      AND fa.end_date <= dw.cutoff_date
),
exposed_in_window AS (
    -- Agreements that were “exposed” (active or ended) at any point in the window
    SELECT
        COUNT(DISTINCT agreement_id) AS exposed_count
    FROM filtered_agreements fa
    CROSS JOIN date_window dw
    WHERE fa.start_date <= dw.cutoff_date
      AND (fa.end_date IS NULL OR fa.end_date >= dw.window_start_date)
)
SELECT
    CASE
        WHEN e.exposed_count = 0 THEN 0::NUMERIC
        ELSE c.churned_count::NUMERIC / e.exposed_count::NUMERIC
    END AS overall_churn_52w
FROM churned_in_window c, exposed_in_window e;
