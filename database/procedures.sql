-- ============================================================
--  ForensicDB - procedures.sql
--  Defines 2 stored procedures:
--    1. GetCaseDetails(caseID)
--    2. GetPendingInvestigations(staffID)
-- ============================================================

USE forensic_db;

DELIMITER $$

-- ============================================================
-- STORED PROCEDURE 1: GetCaseDetails(caseID)
--
-- Purpose:
--   Retrieves the complete details of a single clinical case
--   identified by caseID. Returns a multi-result set:
--     Result Set 1: Core case information + patient + status
--     Result Set 2: All examinations for the case
--     Result Set 3: All injuries recorded across examinations
--     Result Set 4: All investigations ordered for the case
--     Result Set 5: All evidence items linked to the case
--     Result Set 6: All MLEFs / court reports for the case
--
-- Usage:
--   CALL GetCaseDetails(1);
-- ============================================================
DROP PROCEDURE IF EXISTS GetCaseDetails$$

CREATE PROCEDURE GetCaseDetails(
    IN p_case_id INT UNSIGNED
)
BEGIN
    -- --------------------------------------------------------
    -- Validate that the case exists
    -- --------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM clinicalcase WHERE case_id = p_case_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Case not found. Please check the case ID.';
    END IF;

    -- --------------------------------------------------------
    -- Result Set 1: Core case info + patient + status + officer
    -- --------------------------------------------------------
    SELECT
        cc.case_id,
        cc.case_type,
        cc.incident_datetime,
        cc.incident_location,
        cc.police_station,
        cc.police_ref_no,
        cc.opened_at,
        cc.closed_at,
        cc.remarks,

        -- Status
        cs.status_name  AS case_status,

        -- Patient
        p.patient_id,
        CONCAT(p.first_name, ' ', p.last_name)           AS patient_name,
        p.nic_passport,
        p.dob,
        p.gender,
        p.blood_group,
        p.address,
        p.contact_no,

        -- Assigned officer
        CONCAT(st.first_name, ' ', st.last_name)         AS assigned_officer,
        ro.role_name                                      AS officer_role,
        st.contact_no                                     AS officer_contact,
        d.dept_name                                       AS officer_department

    FROM  clinicalcase cc
    JOIN  casestatus   cs ON cc.status_id        = cs.status_id
    JOIN  patient      p  ON cc.patient_id        = p.patient_id
    JOIN  staff        st ON cc.assigned_staff_id = st.staff_id
    JOIN  role         ro ON st.role_id           = ro.role_id
    JOIN  department   d  ON st.dept_id           = d.dept_id
    WHERE cc.case_id = p_case_id;

    -- --------------------------------------------------------
    -- Result Set 2: Examinations for this case
    -- --------------------------------------------------------
    SELECT
        e.exam_id,
        e.exam_datetime,
        e.ward_bht,
        e.exam_type,
        e.clinical_notes,
        e.photos_taken,
        CONCAT(s.first_name, ' ', s.last_name) AS examiner_name,
        r.role_name                             AS examiner_role
    FROM  examination e
    JOIN  staff       s ON e.examiner_id = s.staff_id
    JOIN  role        r ON s.role_id     = r.role_id
    WHERE e.case_id = p_case_id
    ORDER BY e.exam_datetime;

    -- --------------------------------------------------------
    -- Result Set 3: Injuries (via examinations of this case)
    -- --------------------------------------------------------
    SELECT
        i.injury_id,
        i.exam_id,
        e.exam_datetime,
        i.injury_type,
        i.body_location,
        i.description
    FROM  injury       i
    JOIN  examination  e ON i.exam_id = e.exam_id
    WHERE e.case_id = p_case_id
    ORDER BY e.exam_datetime, i.injury_id;

    -- --------------------------------------------------------
    -- Result Set 4: Investigations ordered for this case
    -- --------------------------------------------------------
    SELECT
        inv.inv_id,
        it.type_name                            AS investigation_type,
        inv.request_date,
        inv.clinical_reason,
        inv.inv_status,
        CONCAT(s.first_name, ' ', s.last_name)  AS requested_by,
        lt.test_date                             AS lab_test_date,
        lt.findings                              AS lab_findings,
        lt.test_status                           AS lab_status
    FROM  investigation  inv
    JOIN  investigationtype it ON inv.inv_type_id   = it.inv_type_id
    JOIN  staff            s  ON inv.requested_by   = s.staff_id
    LEFT JOIN laboratorytest lt ON lt.inv_id        = inv.inv_id
    WHERE inv.case_id = p_case_id
    ORDER BY inv.request_date;

    -- --------------------------------------------------------
    -- Result Set 5: Evidence items for this case
    -- --------------------------------------------------------
    SELECT
        ev.evidence_id,
        et.type_name                             AS evidence_type,
        ev.description,
        ev.collection_datetime,
        ev.evidence_status,
        sl.location_name                         AS current_storage,
        CONCAT(s.first_name, ' ', s.last_name)   AS collected_by
    FROM  evidence       ev
    JOIN  evidencetype   et ON ev.evtype_id   = et.evtype_id
    JOIN  storagelocation sl ON ev.location_id = sl.location_id
    JOIN  staff          s  ON ev.collected_by = s.staff_id
    WHERE ev.case_id = p_case_id
    ORDER BY ev.collection_datetime;

    -- --------------------------------------------------------
    -- Result Set 6: MLEFs and Court Reports
    -- --------------------------------------------------------
    SELECT
        'MLEF'                                   AS document_type,
        m.mlef_id                                AS document_id,
        m.mlef_status                            AS doc_status,
        m.issue_date                             AS doc_date,
        m.police_ref                             AS reference_no,
        CONCAT(s.first_name, ' ', s.last_name)   AS prepared_by
    FROM  mlef  m
    JOIN  staff s ON m.issued_by = s.staff_id
    WHERE m.case_id = p_case_id

    UNION ALL

    SELECT
        CONCAT('Court Report - ', cr.report_type) AS document_type,
        cr.report_id                               AS document_id,
        cr.report_status                           AS doc_status,
        cr.submission_date                         AS doc_date,
        cr.court_ref                               AS reference_no,
        CONCAT(s.first_name, ' ', s.last_name)     AS prepared_by
    FROM  courtreport cr
    JOIN  staff       s ON cr.submitted_by = s.staff_id
    WHERE cr.case_id = p_case_id

    ORDER BY doc_date DESC;

END$$


-- ============================================================
-- STORED PROCEDURE 2: GetPendingInvestigations(staffID)
--
-- Purpose:
--   Retrieves all investigation requests that are currently
--   in 'Pending' or 'In Progress' status, filtered by a
--   specific staff member's ID. Handles two roles:
--     - Doctors (JMO / Medical Officer): returns their
--       own outgoing requests that are not yet completed.
--     - Lab Staff: returns all pending/in-progress
--       investigation requests assigned to the lab (i.e.,
--       the staffID is used to identify the department role).
--
-- Usage:
--   CALL GetPendingInvestigations(1);  -- Doctor view
--   CALL GetPendingInvestigations(3);  -- Lab staff view
-- ============================================================
DROP PROCEDURE IF EXISTS GetPendingInvestigations$$

CREATE PROCEDURE GetPendingInvestigations(
    IN p_staff_id INT UNSIGNED
)
BEGIN
    -- --------------------------------------------------------
    -- Variables
    -- --------------------------------------------------------
    DECLARE v_role_id   TINYINT UNSIGNED;
    DECLARE v_role_name VARCHAR(60);

    -- --------------------------------------------------------
    -- Validate that the staff member exists
    -- --------------------------------------------------------
    IF NOT EXISTS (SELECT 1 FROM staff WHERE staff_id = p_staff_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Staff member not found. Please check the staff ID.';
    END IF;

    -- Fetch the role of the given staff member
    SELECT s.role_id, r.role_name
    INTO   v_role_id, v_role_name
    FROM   staff s
    JOIN   role  r ON s.role_id = r.role_id
    WHERE  s.staff_id = p_staff_id;

    -- --------------------------------------------------------
    -- Branch by role
    -- --------------------------------------------------------

    IF v_role_name IN ('Judicial Medical Officer', 'Medical Officer', 'Administrator') THEN
        -- ====================================================
        -- DOCTOR VIEW: their outgoing requests not yet done
        -- ====================================================
        SELECT
            inv.inv_id,
            it.type_name                                  AS investigation_type,
            inv.request_date,
            inv.clinical_reason,
            inv.inv_status,

            -- Case info
            cc.case_id,
            cc.case_type,
            cc.police_ref_no,

            -- Patient info
            CONCAT(p.first_name, ' ', p.last_name)        AS patient_name,
            p.nic_passport,

            -- Days waiting
            DATEDIFF(CURDATE(), inv.request_date)         AS days_waiting,

            -- Lab result if partially done
            lt.findings                                    AS partial_findings,
            lt.test_status                                 AS lab_status

        FROM  investigation  inv
        JOIN  investigationtype it ON inv.inv_type_id  = it.inv_type_id
        JOIN  clinicalcase    cc   ON inv.case_id       = cc.case_id
        JOIN  patient         p    ON cc.patient_id     = p.patient_id
        LEFT JOIN laboratorytest lt ON lt.inv_id        = inv.inv_id

        WHERE inv.requested_by = p_staff_id
          AND inv.inv_status IN ('Pending', 'In Progress')

        ORDER BY inv.request_date ASC;

    ELSEIF v_role_name = 'Laboratory Staff' THEN
        -- ====================================================
        -- LAB STAFF VIEW: all pending/in-progress in queue
        --   (lab staff see the whole queue, not just their own)
        -- ====================================================
        SELECT
            inv.inv_id,
            it.type_name                                  AS investigation_type,
            inv.request_date,
            inv.clinical_reason,
            inv.inv_status,

            -- Case info
            cc.case_id,
            cc.case_type,
            cc.police_ref_no,

            -- Patient info
            CONCAT(p.first_name, ' ', p.last_name)        AS patient_name,
            p.nic_passport,

            -- Requesting doctor
            CONCAT(s.first_name, ' ', s.last_name)        AS requested_by_doctor,
            ro.role_name                                   AS requesting_role,

            -- Days waiting
            DATEDIFF(CURDATE(), inv.request_date)         AS days_waiting

        FROM  investigation  inv
        JOIN  investigationtype it ON inv.inv_type_id  = it.inv_type_id
        JOIN  clinicalcase    cc   ON inv.case_id       = cc.case_id
        JOIN  patient         p    ON cc.patient_id     = p.patient_id
        JOIN  staff           s    ON inv.requested_by  = s.staff_id
        JOIN  role            ro   ON s.role_id         = ro.role_id

        WHERE inv.inv_status IN ('Pending', 'In Progress')

        ORDER BY days_waiting DESC, inv.request_date ASC;

    ELSE
        -- ====================================================
        -- CLERICAL / OTHER: show summary counts only
        -- ====================================================
        SELECT
            inv.inv_status,
            COUNT(*)                                       AS total_count,
            MIN(inv.request_date)                          AS oldest_request,
            MAX(inv.request_date)                          AS newest_request
        FROM  investigation inv
        WHERE inv.inv_status IN ('Pending', 'In Progress')
        GROUP BY inv.inv_status;

    END IF;

END$$

DELIMITER ;

-- ============================================================
-- USAGE EXAMPLES
-- ============================================================
--
-- 1. Get complete details for clinical case #1:
--    CALL GetCaseDetails(1);
--
-- 2. Get pending investigations for Dr. Wickramasinghe (JMO):
--    CALL GetPendingInvestigations(1);
--
-- 3. Get pending investigations from lab staff view:
--    CALL GetPendingInvestigations(3);
--
-- ============================================================
