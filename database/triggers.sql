-- ============================================================
--  ForensicDB - triggers.sql
--  Defines 2 triggers on the `clinicalcase` table that
--  automatically insert records into `auditlog` whenever
--  a case is UPDATED or DELETED.
-- ============================================================

USE forensic_db;

DELIMITER $$

-- ============================================================
-- TRIGGER 1: after_clinicalcase_update
-- Fires AFTER an UPDATE on clinicalcase.
-- Logs the action into auditlog with severity = 'Info'.
-- Captures: old status - new status, user via @current_user_
--           session variable, and the current timestamp.
-- Usage: Before calling UPDATE, application layer should SET
--        @current_user_ = 'username' and @current_ip_ = 'ip'.
-- ============================================================
DROP TRIGGER IF EXISTS after_clinicalcase_update$$

CREATE TRIGGER after_clinicalcase_update
AFTER UPDATE ON clinicalcase
FOR EACH ROW
BEGIN
    -- Determine severity: escalate if case is DELETED-equivalent status
    DECLARE v_severity ENUM('Info','Warning','Critical') DEFAULT 'Info';
    DECLARE v_detail   TEXT;

    -- Build a meaningful detail message capturing what changed
    SET v_detail = CONCAT(
        'Case #', NEW.case_id, ' updated. ',
        'Patient: ', NEW.patient_id, '. ',
        'Status changed from [',
        (SELECT status_name FROM casestatus WHERE status_id = OLD.status_id),
        '] to [',
        (SELECT status_name FROM casestatus WHERE status_id = NEW.status_id),
        ']. ',
        'Assigned officer: ', NEW.assigned_staff_id, '.'
    );

    -- Escalate severity if case is being closed
    IF NEW.status_id = 5 THEN   -- status_id 5 = Closed
        SET v_severity = 'Warning';
    END IF;

    INSERT INTO auditlog (
        log_timestamp,
        user_account,
        action_type,
        target_table,
        target_id,
        ip_address,
        severity,
        details
    )
    VALUES (
        NOW(),
        IFNULL(@current_user_, 'system'),
        'UPDATE',
        'clinicalcase',
        CONCAT('case_id:', NEW.case_id),
        IFNULL(@current_ip_,   '0.0.0.0'),
        v_severity,
        v_detail
    );
END$$


-- ============================================================
-- TRIGGER 2: after_clinicalcase_delete
-- Fires AFTER a DELETE on clinicalcase.
-- Logs the deletion into auditlog with severity = 'Critical'
-- because deleting a forensic case record is a high-impact
-- action that must always be traceable.
-- ============================================================
DROP TRIGGER IF EXISTS after_clinicalcase_delete$$

CREATE TRIGGER after_clinicalcase_delete
AFTER DELETE ON clinicalcase
FOR EACH ROW
BEGIN
    DECLARE v_detail TEXT;

    SET v_detail = CONCAT(
        'DELETED: Case #', OLD.case_id,
        ' | Type: ', OLD.case_type,
        ' | Patient ID: ', OLD.patient_id,
        ' | Police Ref: ', IFNULL(OLD.police_ref_no, 'N/A'),
        ' | Opened: ', OLD.opened_at,
        ' | Was assigned to staff_id: ', OLD.assigned_staff_id, '.'
    );

    INSERT INTO auditlog (
        log_timestamp,
        user_account,
        action_type,
        target_table,
        target_id,
        ip_address,
        severity,
        details
    )
    VALUES (
        NOW(),
        IFNULL(@current_user_, 'system'),
        'DELETE',
        'clinicalcase',
        CONCAT('case_id:', OLD.case_id),
        IFNULL(@current_ip_,   '0.0.0.0'),
        'Critical',
        v_detail
    );
END$$

DELIMITER ;

-- ============================================================
-- USAGE NOTES
-- ============================================================
-- Before performing an UPDATE or DELETE on clinicalcase, the
-- application layer should set the session variables:
--
--   SET @current_user_ = 'c_wickramasinghe';
--   SET @current_ip_   = '192.168.1.45';
--   UPDATE clinicalcase SET status_id = 5 WHERE case_id = 1;
--
-- The trigger will then automatically log this action into
-- the auditlog table with full details and severity.
-- ============================================================
