-- ============================================================
--  ForensicDB - views.sql
--  Defines 3 SQL views required by the project specification:
--    1. PendingMLEFs
--    2. CasesByMonth
--    3. EvidenceWithLocation
-- ============================================================

USE forensic_db;

-- ============================================================
-- VIEW 1: PendingMLEFs
-- Purpose: Lists all clinical cases where the MLEF has not
--          yet been submitted (status = Draft or Issued).
--          Useful for the dashboard and court reports module.
-- ============================================================
DROP VIEW IF EXISTS PendingMLEFs;

CREATE VIEW PendingMLEFs AS
SELECT
    m.mlef_id,
    m.mlef_status,
    m.issue_date,
    m.police_ref,

    -- Case info
    cc.case_id,
    cc.case_type,
    cc.incident_datetime,
    cc.incident_location,
    cc.police_station,
    cc.police_ref_no,

    -- Patient info
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
    p.nic_passport,
    p.gender,

    -- Assigned doctor
    CONCAT(s.first_name, ' ', s.last_name) AS assigned_officer,
    r.role_name                             AS officer_role

FROM mlef m
JOIN clinicalcase cc ON m.case_id = cc.case_id
JOIN patient      p  ON cc.patient_id = p.patient_id
JOIN staff        s  ON cc.assigned_staff_id = s.staff_id
JOIN role         r  ON s.role_id = r.role_id

WHERE m.mlef_status IN ('Draft', 'Issued')
ORDER BY m.issue_date DESC;


-- ============================================================
-- VIEW 2: CasesByMonth
-- Purpose: Aggregates the total number of clinical cases
--          opened each calendar month and year, split by
--          case category (Clinical / Postmortem).
--          Useful for management dashboards and analytics.
-- ============================================================
DROP VIEW IF EXISTS CasesByMonth;

CREATE VIEW CasesByMonth AS
SELECT
    YEAR(cc.opened_at)                         AS case_year,
    MONTH(cc.opened_at)                        AS case_month,
    DATE_FORMAT(cc.opened_at, '%b %Y')         AS month_label,

    -- Total cases
    COUNT(*)                                   AS total_cases,

    -- Clinical vs Postmortem split
    SUM(CASE WHEN cc.case_type LIKE 'Clinical%'   THEN 1 ELSE 0 END) AS clinical_cases,
    SUM(CASE WHEN cc.case_type LIKE 'Postmortem%' THEN 1 ELSE 0 END) AS postmortem_cases,

    -- Status breakdown
    SUM(CASE WHEN cs.status_name = 'Closed'           THEN 1 ELSE 0 END) AS closed_cases,
    SUM(CASE WHEN cs.status_name = 'Under Investigation' THEN 1 ELSE 0 END) AS investigating_cases,
    SUM(CASE WHEN cs.status_name = 'MLEF Pending'     THEN 1 ELSE 0 END) AS mlef_pending_cases

FROM clinicalcase cc
JOIN casestatus   cs ON cc.status_id = cs.status_id

GROUP BY
    YEAR(cc.opened_at),
    MONTH(cc.opened_at),
    DATE_FORMAT(cc.opened_at, '%b %Y')

ORDER BY
    case_year  DESC,
    case_month DESC;


-- ============================================================
-- VIEW 3: EvidenceWithLocation
-- Purpose: Provides a full evidence chain-of-custody view
--          combining evidence details, type, case info,
--          patient, collected-by staff, and current storage
--          location. Useful for the Evidence Management page
--          and court submissions.
-- ============================================================
DROP VIEW IF EXISTS EvidenceWithLocation;

CREATE VIEW EvidenceWithLocation AS
SELECT
    e.evidence_id,
    e.description                                AS evidence_description,
    e.collection_datetime,
    e.evidence_status,

    -- Evidence type
    et.type_name                                 AS evidence_type,

    -- Storage location
    sl.location_name                             AS storage_location,
    sl.description                               AS storage_description,

    -- Linked case
    cc.case_id,
    cc.case_type,
    cc.incident_datetime,
    cc.incident_location,
    cc.police_ref_no,

    -- Linked patient
    p.patient_id,
    CONCAT(p.first_name, ' ', p.last_name)       AS patient_name,
    p.nic_passport,

    -- Collected by staff member
    CONCAT(cs.first_name, ' ', cs.last_name)     AS collected_by,
    cr.role_name                                  AS collector_role,

    -- Latest custody transfer (subquery)
    (SELECT coc.transferred_to
     FROM   chainofcustody coc
     WHERE  coc.evidence_id = e.evidence_id
     ORDER BY coc.transfer_date DESC
     LIMIT 1
    )                                             AS last_transferred_to,

    (SELECT coc.transfer_date
     FROM   chainofcustody coc
     WHERE  coc.evidence_id = e.evidence_id
     ORDER BY coc.transfer_date DESC
     LIMIT 1
    )                                             AS last_transfer_date

FROM evidence       e
JOIN evidencetype   et ON e.evtype_id    = et.evtype_id
JOIN storagelocation sl ON e.location_id = sl.location_id
JOIN clinicalcase   cc ON e.case_id      = cc.case_id
JOIN patient        p  ON cc.patient_id  = p.patient_id
JOIN staff          cs ON e.collected_by = cs.staff_id
JOIN role           cr ON cs.role_id     = cr.role_id

ORDER BY e.collection_datetime DESC;
