-- recruitment/kpi_existing_clients_agreements_signed.sql
-- KPI – Agreements signed for (classified) existing clients, by week and POD.
-- Parameters:
--   :last_sunday  → last Sunday date used as boundary (DATE, 'YYYY-MM-DD')
--   :year_week    → ISO year-week string (e.g. '2025-44')

WITH t_dealA00 AS (
    SELECT
        id,
        properties_createdate::DATE AS create_date,
        "companies",
        JSONB_ARRAY_ELEMENTS_TEXT("companies"::jsonb)::varchar AS company_id,
        properties_main_contact_email,
        properties_total_deposit_amount,
        properties_pod,
        properties_agent_1,
        properties_agent_2,
        properties_manager,
        properties_associates,
        properties_consultant
    FROM hubspot_staging.deals
),
t_companyA00 AS (
    SELECT
        "id",
        properties_name AS company_name
    FROM hubspot_staging.companies
),
t_podgentA00 AS (
    SELECT agent, pod
    FROM vl_analytics.podagent
    WHERE status = 'Active'
),
t_dealidA00 AS (
    SELECT 
        "id",
        JSONB_ARRAY_ELEMENTS_TEXT("contacts"::jsonb)::varchar AS id_contacts
    FROM hubspot_staging.deals 
),
t_leadclientA00 AS (
    SELECT
        "id",
        properties_contact_type,
        properties_email,
        properties_company
    FROM hubspot_staging.contacts
    WHERE properties_contact_type IN (
              '',
              'Customer',
              'Lead Customer',
              'Vendor',
              'Email contact',
              'Other',
              'Partner',
              'Warm Leads'
          )
       OR properties_contact_type IS NULL
),
t_dealcompany AS (
    SELECT
        t0."id",
        t1."id" AS id_contacts,
        t1.properties_company AS name_of_company
    FROM t_dealidA00 t0
    LEFT JOIN t_leadclientA00 t1
           ON t0.id_contacts = t1."id"
    WHERE t1."id" IS NOT NULL
),
t_namescompaniesA00 AS (
    SELECT mail1, company_name
    FROM vl_analytics._companyname
),
t_previo00 AS (
    SELECT 
        t0."id",
        t0.create_date,
        CASE    
            WHEN t8.name_of_company IS NULL AND t1.company_name IS NULL THEN t7.company_name
            WHEN t8.name_of_company IS NULL THEN t1.company_name
            ELSE t8.name_of_company
        END AS company_name,
        t0.properties_total_deposit_amount AS deposit_amount,
        CASE
            WHEN (t0.properties_pod IS NULL OR t0.properties_pod = 'ECO')
             AND t2.pod IS NULL AND t3.pod IS NULL AND t4.pod IS NULL AND t5.pod IS NULL
                THEN t6.pod
            WHEN (t0.properties_pod IS NULL OR t0.properties_pod = 'ECO')
             AND t2.pod IS NULL AND t3.pod IS NULL AND t4.pod IS NULL
                THEN t5.pod
            WHEN (t0.properties_pod IS NULL OR t0.properties_pod = 'ECO')
             AND t2.pod IS NULL AND t3.pod IS NULL
                THEN t4.pod
            WHEN (t0.properties_pod IS NULL OR t0.properties_pod = 'ECO')
             AND t2.pod IS NULL
                THEN t3.pod
            WHEN (t0.properties_pod IS NULL OR t0.properties_pod = 'ECO')
                THEN t2.pod
            ELSE INITCAP(t0.properties_pod)
        END AS base_pod
    FROM t_dealA00 t0
    LEFT JOIN t_companyA00 t1 ON t0.company_id = t1."id"
    LEFT JOIN t_podgentA00  t2 ON t0.properties_agent_1 = t2.agent
    LEFT JOIN t_podgentA00 t3 ON t0.properties_agent_2 = t3.agent
    LEFT JOIN t_podgentA00 t4 ON t0.properties_manager = t4.agent
    LEFT JOIN t_podgentA00 t5 ON t0.properties_associates = t5.agent
    LEFT JOIN t_podgentA00 t6 ON t0.properties_consultant = t6.agent
    LEFT JOIN t_namescompaniesA00 t7 ON t0.properties_main_contact_email = t7.mail1
    LEFT JOIN t_dealcompany t8 ON t0."id" = t8."id"
),
t_previo01 AS (
    SELECT
        "id",
        create_date,
        company_name,
        deposit_amount,
        base_pod
    FROM t_previo00
    ORDER BY company_name ASC
),
t_namescompaniesB00 AS (
    SELECT company_name, fixed_company_name
    FROM vl_analytics._companyname
),
t_dealcompanies00 AS (
    SELECT DISTINCT ON (t0."id")
        t0."id",
        t0.create_date,
        CASE
            WHEN t1.fixed_company_name IS NULL THEN t0.company_name
            ELSE t1.fixed_company_name
        END AS company_name,
        deposit_amount,
        base_pod
    FROM t_previo01 t0
    LEFT JOIN t_namescompaniesB00 t1
           ON t0.company_name = t1.company_name
),
tablaA00 AS (
    SELECT
        id,
        properties_status AS status,
        properties_customer_company AS customer_company,
        CASE
            WHEN CAST(SUBSTRING(properties_agreement_number FROM 6 FOR 2) AS INTEGER) <= 12
             AND CAST(SUBSTRING(properties_agreement_number FROM 9 FOR 2) AS INTEGER) <= 31
                THEN TO_DATE(LEFT(properties_agreement_number, 10), 'YYYY-MM-DD')
            ELSE NULL
        END AS creation_date,
        (properties_official_start_date::TIMESTAMP + INTERVAL '1 day')::DATE        AS official_start_date,
        (properties_date_client_signed_agreement::TIMESTAMP + INTERVAL '1 day')::DATE AS date_client_signed,
        (properties_last_day_of_work::TIMESTAMP + INTERVAL '1 day')::DATE           AS last_day_of_work,
        CASE
            WHEN properties_date_client_signed_agreement IS NULL
                THEN (properties_official_start_date::TIMESTAMP + INTERVAL '1 day')::DATE
            WHEN properties_official_start_date IS NULL 
                THEN properties_hs_createdate::DATE
            ELSE (properties_date_client_signed_agreement::TIMESTAMP + INTERVAL '1 day')::DATE
        END AS last_admon_date
    FROM hubspot_staging.agreements
    WHERE COALESCE(properties_customer_company, 'Empty') NOT IN (
        'Bloominari dba Virtual Latinos',
        'Virtual Latinos',
        'Virtualito LLC',
        'Cooper Rocks, LLC',
        'Copper Rocks, LLC',
        'Cooper Rocks'
    )
      AND properties_status IN (
        'Active',
        'Terminated by Client',
        'Terminated by VA',
        'Terminated by VL',
        'Emergency cancellation',
        'Pending'
    )
),
tablaA01 AS (
    SELECT 
        id,
        status,
        customer_company,
        creation_date,
        official_start_date,
        date_client_signed,
        last_day_of_work,
        last_admon_date,
        date_client_signed - creation_date AS time_to_sign,
        CASE
            WHEN date_client_signed IS NULL 
             AND status = 'Active'
             AND official_start_date <= :last_sunday
                THEN (official_start_date - INTERVAL '1 day')::DATE 
            WHEN (date_client_signed - creation_date) > 90 
             AND official_start_date IS NOT NULL
                THEN official_start_date
            WHEN (date_client_signed - creation_date) > 90 
             AND official_start_date IS NULL
                THEN creation_date
            ELSE date_client_signed
        END AS date_client_signed_agreement
    FROM tablaA00
),
tablaB00 AS (
    SELECT company_name, fixed_company_name
    FROM vl_analytics._companyname
),
tablaAB0 AS (
    SELECT 
        t00."id",
        t00.status,
        t00.customer_company,
        t00.creation_date,
        t00.official_start_date,
        t00.date_client_signed,
        t00.last_day_of_work,
        t00.last_admon_date,
        t00.time_to_sign,
        t00.date_client_signed_agreement,
        CASE
            WHEN t01.fixed_company_name IS NULL THEN TRIM(t00.customer_company)
            ELSE TRIM(t01.fixed_company_name)
        END AS customer_company_name,
        EXTRACT(year FROM date_client_signed_agreement) || '-' ||
        EXTRACT(week FROM date_client_signed_agreement) AS year_week
    FROM tablaA01 t00
    LEFT JOIN tablaB00 t01
           ON LOWER(TRIM(t00.customer_company)) = LOWER(TRIM(t01.company_name))
),
tablaAB1 AS (
    SELECT 
        id,
        status,
        customer_company_name,
        creation_date,
        official_start_date,
        date_client_signed_agreement,
        last_day_of_work,
        last_admon_date,
        year_week,
        MIN(last_admon_date) OVER (PARTITION BY customer_company_name) AS first_admon_date
    FROM tablaAB0
),
tablaAB2 AS (
    SELECT
        id,
        status,
        customer_company_name,
        creation_date,
        official_start_date,
        date_client_signed_agreement,
        last_day_of_work,
        last_admon_date,
        year_week,
        first_admon_date,
        CASE
            WHEN first_admon_date = last_admon_date THEN 'New'
            WHEN first_admon_date >= (last_admon_date - INTERVAL '13 day') THEN 'New'
            ELSE 'Exist'
        END AS existing_client
    FROM tablaAB1
    WHERE year_week = :year_week
),
t_dealcompanies01 AS (
    SELECT
        id,
        create_date,
        company_name,
        deposit_amount,
        base_pod
    FROM t_dealcompanies00
    ORDER BY create_date ASC
),
t_results00 AS (
    SELECT DISTINCT ON (t0.id)
        t0.id,
        t0.status,
        t0.customer_company_name,
        t0.creation_date,
        t0.official_start_date,
        t0.date_client_signed_agreement,
        t0.last_day_of_work,
        t0.last_admon_date,
        t0.year_week,
        t0.first_admon_date,
        t0.existing_client,
        t1.deposit_amount,
        CASE
            WHEN t1.base_pod IS NULL THEN 'Arc'
            ELSE t1.base_pod 
        END AS pod_base
    FROM tablaAB2 t0
    LEFT JOIN t_dealcompanies01 t1
           ON t0.customer_company_name = t1.company_name
)
SELECT
    COUNT(year_week) AS count_year_week
FROM t_results00
WHERE existing_client = 'New'
  AND pod_base = 'Arc'
GROUP BY year_week;
