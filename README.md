# ev-sql-toolkit

A collection of SQL queries designed for operational analytics and weekly scorecards.

This repository includes:

- KPIs by domain (Success, Recruitment, Applications, Leadership)
- Reusable patterns for time windows, filtering, and normalization
- Utility queries used in the DWH and in the KPI factory (`ev-kpi-factory`)

Queries are intended to run on a relational DWH (e.g. PostgreSQL) that centralizes data from:
- HubSpot
- Operational forms (Airtable, Jotform)
- Google Sheets
- Other integrated sources

---

## Structure

```text
core_patterns/   → reusable snippets (time windows, base templates)
success/         → KPIs for the Success scorecard
recruitment/     → KPIs for the Recruitment scorecard
applications/    → KPIs for the Applications scorecard
leadership/      → KPIs for the Leadership scorecard
utils/           → helpers (normalization, filtering internal/test, etc.)
