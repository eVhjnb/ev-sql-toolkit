-- leadership/kpi_interview_activity_by_pod.sql
-- KPI – Weekly count of specific recruitment-related email activities, grouped by POD.
-- Parameters:
--   :year_week  → ISO year-week string (e.g. '2025-44')
-- adjust PODs list ('Arc','Bay') according to your leadership structure.

WITH t_interview00 AS (
    SELECT 
        id,
        hs_object_id,
        hs_activity_type,
        (hs_createdate::TIMESTAMP - INTERVAL '7 hour') AS creation_date,
        metadata->> 'from_email' AS agent_mail, 
        EXTRACT(year FROM ((hs_createdate::TIMESTAMP - INTERVAL '7 hour')::DATE))
            || '-' ||
        EXTRACT(week FROM ((hs_createdate::TIMESTAMP - INTERVAL '7 hour')::DATE)) AS activity_week
    FROM vl_analytics.engagements e
    WHERE e.metadata->>'subject'   ILIKE 'Virtual Latinos: Confirm Assistant Recruitment Details%'
      AND e.metadata->>'direction' = 'EMAIL'
),
t_results00 AS (
    SELECT
        t0.id,
        t0.hs_object_id,
        t0.hs_activity_type,
        t0.creation_date,
        t0.agent_mail,
        t0.activity_week,
        t1.pod
    FROM t_interview00 t0
    LEFT JOIN vl_analytics.podagent t1
           ON t0.agent_mail = t1.agent
    WHERE t1.pod IN ('Arc','Bay')
)
SELECT 
    COUNT(activity_week) AS count_activity_week
FROM t_results00
WHERE activity_week = :year_week;
