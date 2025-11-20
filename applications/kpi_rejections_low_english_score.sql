-- applications/kpi_rejections_low_english_score.sql
-- KPI – Applicants rejected due to low English EF test score (< 61)
-- Parameters:
--   :week_main  → ISO year-week of the main week (e.g. '2025-44')
--   :week_next  → ISO year-week of the following week (e.g. '2025-45')

WITH t_contacts AS (
    SELECT 
        id,
        properties_contact_type,
        properties_email,
        properties_application_stage_vl,
        properties_vldirectoryrejected_date,
        TO_CHAR(properties_vldirectoryrejected_date, 'IYYY-IW') AS reject_week
    FROM hubspot_staging.contacts
    WHERE properties_contact_type IN ('Applicant','Candidate','VA, Candidate')
      AND properties_email IS NOT NULL
),
t_details AS (
    SELECT 
        contact_hs_id,
        how_they_found_us,
        hubspot_test,
        VLdirectoryincomplete_date,
        vldirectoryinvite_date,
        vldirectoryready_date,
        rejection_reason,
        TO_CHAR(vldirectoryinvite_date, 'IYYY-IW') AS invite_week,
        TO_CHAR(VLdirectoryincomplete_date, 'IYYY-IW') AS incomplete_week,
        TO_CHAR(vldirectoryready_date, 'IYYY-IW') AS ready_week
    FROM vl_analytics.contacts_details
),
t_mixcontact AS (
    SELECT 
        t1.id,
        t1.properties_contact_type,
        t1.properties_email,
        t1.properties_application_stage_vl,
        t1.properties_vldirectoryrejected_date,
        t2.vldirectoryinvite_date,
        t2.how_they_found_us,
        t2.hubspot_test,
        t2.VLdirectoryincomplete_date,
        t2.vldirectoryready_date,
        t2.rejection_reason,
        t1.reject_week,
        t2.invite_week,
        t2.incomplete_week,
        t2.ready_week
    FROM t_contacts t1
    LEFT JOIN t_details t2
           ON t1.id = t2.contact_hs_id
    WHERE COALESCE(t2.hubspot_test, 'empty') NOT IN ('Yes','true')
      AND COALESCE(LOWER(t2.how_they_found_us), 'empty') <> 'rtspecialprocess'
      AND t2.rejection_reason = 'Low EF SET test score'
),
t_vldirectoryrejected_uno AS (
    SELECT * 
    FROM t_mixcontact
    WHERE properties_application_stage_vl = 'VLdirectoryrejected'
      AND reject_week = :week_main
      AND VLdirectoryincomplete_date IS NULL
),
t_vldirectoryrejected_buno AS (
    SELECT 
        COUNT(reject_week) AS reject_a
    FROM t_vldirectoryrejected_uno
),
t_vldirectoryrejected_dos AS (
    SELECT * 
    FROM t_mixcontact
    WHERE properties_application_stage_vl = 'VLdirectoryrejected'
      AND reject_week = :week_main
      AND incomplete_week = :week_main
),
t_vldirectoryrejected_bdos AS (
    SELECT 
        COUNT(reject_week) AS reject_b
    FROM t_vldirectoryrejected_dos
), 
t_vldirectoryrejected_tres AS (
    SELECT * 
    FROM t_mixcontact
    WHERE properties_application_stage_vl = 'VLdirectoryrejected'
      AND reject_week = :week_next
      AND incomplete_week = :week_main
),
t_vldirectoryrejected_btres AS (
    SELECT 
        COUNT(reject_week) AS reject_c
    FROM t_vldirectoryrejected_tres
)
SELECT
    (reject_a + reject_b + reject_c) AS sum_all
FROM t_vldirectoryrejected_buno,
     t_vldirectoryrejected_bdos,
     t_vldirectoryrejected_btres;
