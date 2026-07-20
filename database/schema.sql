-- ============================================================
--  ForensicDB - schema.sql
--  Creates the `forensic_db` database and all 26 tables.
--  Tables are 3NF normalised with PK, FK, NOT NULL & CHECK
--  constraints throughout.
-- ============================================================

DROP DATABASE IF EXISTS forensic_db;
CREATE DATABASE forensic_db
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE forensic_db;

-- ============================================================
-- 1. ROLE  - user access levels
-- ============================================================
CREATE TABLE role (
    role_id      TINYINT      UNSIGNED NOT NULL AUTO_INCREMENT,
    role_name    VARCHAR(60)  NOT NULL,
    description  VARCHAR(255) NULL,
    CONSTRAINT pk_role PRIMARY KEY (role_id),
    CONSTRAINT uq_role_name UNIQUE (role_name),
    CONSTRAINT chk_role_name CHECK (role_name IN (
        'Administrator',
        'Judicial Medical Officer',
        'Medical Officer',
        'Laboratory Staff',
        'Clerical Officer'
    ))
);

-- ============================================================
-- 2. DEPARTMENT - organisational units
-- ============================================================
CREATE TABLE department (
    dept_id    SMALLINT     UNSIGNED NOT NULL AUTO_INCREMENT,
    dept_name  VARCHAR(100) NOT NULL,
    location   VARCHAR(150) NULL,
    CONSTRAINT pk_department PRIMARY KEY (dept_id),
    CONSTRAINT uq_dept_name UNIQUE (dept_name)
);

-- ============================================================
-- 3. STAFF - personnel records (no login details here)
-- ============================================================
CREATE TABLE staff (
    staff_id      INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name    VARCHAR(80)  NOT NULL,
    last_name     VARCHAR(80)  NOT NULL,
    role_id       TINYINT      UNSIGNED NOT NULL,
    dept_id       SMALLINT     UNSIGNED NOT NULL,
    contact_no    VARCHAR(20)  NOT NULL,
    email         VARCHAR(150) NULL,
    date_joined   DATE         NOT NULL,
    is_active     TINYINT(1)   NOT NULL DEFAULT 1,
    CONSTRAINT pk_staff    PRIMARY KEY (staff_id),
    CONSTRAINT fk_staff_role  FOREIGN KEY (role_id)  REFERENCES role(role_id)       ON UPDATE CASCADE,
    CONSTRAINT fk_staff_dept  FOREIGN KEY (dept_id)  REFERENCES department(dept_id) ON UPDATE CASCADE,
    CONSTRAINT chk_staff_active CHECK (is_active IN (0, 1))
);

-- ============================================================
-- 4. USER  - system login credentials
-- ============================================================
CREATE TABLE user (
    user_id       INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    staff_id      INT          UNSIGNED NOT NULL,
    username      VARCHAR(60)  NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    last_login    DATETIME     NULL,
    account_status ENUM('Active','Locked','Suspended') NOT NULL DEFAULT 'Active',
    created_at    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_user        PRIMARY KEY (user_id),
    CONSTRAINT uq_user_uname  UNIQUE (username),
    CONSTRAINT uq_user_staff  UNIQUE (staff_id),
    CONSTRAINT fk_user_staff  FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- 5. PATIENT  - patient records
-- ============================================================
CREATE TABLE patient (
    patient_id   INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name   VARCHAR(80)  NOT NULL,
    last_name    VARCHAR(80)  NOT NULL,
    nic_passport VARCHAR(20)  NOT NULL,
    dob          DATE         NULL,
    gender       ENUM('Male','Female','Other','Unknown') NOT NULL DEFAULT 'Unknown',
    blood_group  ENUM('A+','A-','B+','B-','AB+','AB-','O+','O-','Unknown') NOT NULL DEFAULT 'Unknown',
    address      VARCHAR(255) NULL,
    contact_no   VARCHAR(20)  NULL,
    registered_at DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_patient      PRIMARY KEY (patient_id),
    CONSTRAINT uq_patient_nic  UNIQUE (nic_passport)
);

-- ============================================================
-- 6. CASE STATUS - lookup table
-- ============================================================
CREATE TABLE casestatus (
    status_id    TINYINT     UNSIGNED NOT NULL AUTO_INCREMENT,
    status_name  VARCHAR(50) NOT NULL,
    CONSTRAINT pk_casestatus     PRIMARY KEY (status_id),
    CONSTRAINT uq_casestatus_name UNIQUE (status_name),
    CONSTRAINT chk_casestatus_name CHECK (status_name IN (
        'Open','MLEF Pending','Under Investigation',
        'Awaiting Report','Closed','Referred'
    ))
);

-- ============================================================
-- 7. CLINICAL CASE
-- ============================================================
CREATE TABLE clinicalcase (
    case_id           INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    patient_id        INT          UNSIGNED NOT NULL,
    case_type         VARCHAR(80)  NOT NULL,
    incident_datetime DATETIME     NOT NULL,
    incident_location VARCHAR(255) NOT NULL,
    police_station    VARCHAR(150) NULL,
    police_ref_no     VARCHAR(50)  NULL,
    assigned_staff_id INT          UNSIGNED NOT NULL,
    status_id         TINYINT      UNSIGNED NOT NULL DEFAULT 1,
    opened_at         DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    closed_at         DATETIME     NULL,
    remarks           TEXT         NULL,
    CONSTRAINT pk_clinicalcase        PRIMARY KEY (case_id),
    CONSTRAINT fk_case_patient        FOREIGN KEY (patient_id)        REFERENCES patient(patient_id)    ON UPDATE CASCADE,
    CONSTRAINT fk_case_assigned_staff FOREIGN KEY (assigned_staff_id) REFERENCES staff(staff_id)        ON UPDATE CASCADE,
    CONSTRAINT fk_case_status         FOREIGN KEY (status_id)         REFERENCES casestatus(status_id)  ON UPDATE CASCADE,
    CONSTRAINT chk_case_type CHECK (case_type IN (
        'Clinical - Assault','Clinical - Trauma','Clinical - Abuse',
        'Clinical - RTA','Clinical - Sexual Assault','Clinical - Other',
        'Postmortem - Homicidal','Postmortem - Accidental',
        'Postmortem - Suicidal','Postmortem - Natural','Postmortem - Unknown'
    ))
);

-- ============================================================
-- 8. EXAMINATION
-- ============================================================
CREATE TABLE examination (
    exam_id        INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id        INT          UNSIGNED NOT NULL,
    exam_datetime  DATETIME     NOT NULL,
    ward_bht       VARCHAR(60)  NULL,
    exam_type      VARCHAR(80)  NOT NULL,
    clinical_notes TEXT         NULL,
    photos_taken   ENUM('Yes','No','Pending') NOT NULL DEFAULT 'Pending',
    photo_path     VARCHAR(500) NULL,
    examiner_id    INT          UNSIGNED NOT NULL,
    created_at     DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_examination       PRIMARY KEY (exam_id),
    CONSTRAINT fk_exam_case         FOREIGN KEY (case_id)     REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_exam_examiner     FOREIGN KEY (examiner_id) REFERENCES staff(staff_id)       ON UPDATE CASCADE,
    CONSTRAINT chk_exam_type CHECK (exam_type IN (
        'Initial Examination','Follow-up Examination',
        'Age Estimation','Sexual Assault Examination','General'
    ))
);

-- ============================================================
-- 9. INJURY  - injuries recorded per examination
-- ============================================================
CREATE TABLE injury (
    injury_id     INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    exam_id       INT          UNSIGNED NOT NULL,
    injury_type   VARCHAR(80)  NOT NULL,
    body_location VARCHAR(120) NOT NULL,
    description   TEXT         NOT NULL,
    CONSTRAINT pk_injury      PRIMARY KEY (injury_id),
    CONSTRAINT fk_injury_exam FOREIGN KEY (exam_id) REFERENCES examination(exam_id) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_injury_type CHECK (injury_type IN (
        'Bruise / Contusion','Laceration','Fracture',
        'Burn','Abrasion','Stab Wound','Gunshot Wound','Other'
    ))
);

-- ============================================================
-- 10. MLEF  - Medico-Legal Examination Form
-- ============================================================
CREATE TABLE mlef (
    mlef_id      INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id      INT          UNSIGNED NOT NULL,
    exam_id      INT          UNSIGNED NOT NULL,
    issued_by    INT          UNSIGNED NOT NULL,
    issue_date   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    mlef_status  ENUM('Draft','Issued','Submitted','Archived') NOT NULL DEFAULT 'Draft',
    police_ref   VARCHAR(50)  NULL,
    file_path    VARCHAR(500) NULL,
    CONSTRAINT pk_mlef        PRIMARY KEY (mlef_id),
    CONSTRAINT fk_mlef_case   FOREIGN KEY (case_id)   REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_mlef_exam   FOREIGN KEY (exam_id)   REFERENCES examination(exam_id)  ON UPDATE CASCADE,
    CONSTRAINT fk_mlef_issuer FOREIGN KEY (issued_by) REFERENCES staff(staff_id)       ON UPDATE CASCADE
);

-- ============================================================
-- 11. REFERRAL
-- ============================================================
CREATE TABLE referral (
    referral_id    INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id        INT          UNSIGNED NOT NULL,
    referred_by    INT          UNSIGNED NOT NULL,
    referred_to    VARCHAR(150) NOT NULL,
    referral_date  DATE         NOT NULL,
    reason         TEXT         NOT NULL,
    status         ENUM('Pending','Accepted','Completed','Rejected') NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_referral        PRIMARY KEY (referral_id),
    CONSTRAINT fk_referral_case   FOREIGN KEY (case_id)    REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_referral_by     FOREIGN KEY (referred_by) REFERENCES staff(staff_id)      ON UPDATE CASCADE
);

-- ============================================================
-- 12. INVESTIGATION TYPE  - lookup
-- ============================================================
CREATE TABLE investigationtype (
    inv_type_id   TINYINT     UNSIGNED NOT NULL AUTO_INCREMENT,
    type_name     VARCHAR(80) NOT NULL,
    CONSTRAINT pk_investigationtype     PRIMARY KEY (inv_type_id),
    CONSTRAINT uq_investigationtype_name UNIQUE (type_name)
);

-- ============================================================
-- 13. INVESTIGATION  - requests sent to lab
-- ============================================================
CREATE TABLE investigation (
    inv_id          INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id         INT          UNSIGNED NOT NULL,
    inv_type_id     TINYINT      UNSIGNED NOT NULL,
    requested_by    INT          UNSIGNED NOT NULL,
    request_date    DATE         NOT NULL,
    clinical_reason TEXT         NOT NULL,
    inv_status      ENUM('Pending','In Progress','Completed','Inconclusive') NOT NULL DEFAULT 'Pending',
    CONSTRAINT pk_investigation       PRIMARY KEY (inv_id),
    CONSTRAINT fk_inv_case            FOREIGN KEY (case_id)      REFERENCES clinicalcase(case_id)    ON UPDATE CASCADE,
    CONSTRAINT fk_inv_type            FOREIGN KEY (inv_type_id)  REFERENCES investigationtype(inv_type_id) ON UPDATE CASCADE,
    CONSTRAINT fk_inv_requester       FOREIGN KEY (requested_by) REFERENCES staff(staff_id)          ON UPDATE CASCADE
);

-- ============================================================
-- 14. LABORATORY TEST  - results entered by lab staff
-- ============================================================
CREATE TABLE laboratorytest (
    lab_test_id   INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    inv_id        INT          UNSIGNED NOT NULL,
    performed_by  INT          UNSIGNED NOT NULL,
    test_date     DATE         NOT NULL,
    findings      TEXT         NOT NULL,
    report_path   VARCHAR(500) NULL,
    test_status   ENUM('Completed','Inconclusive - Further Testing Required') NOT NULL DEFAULT 'Completed',
    CONSTRAINT pk_laboratorytest       PRIMARY KEY (lab_test_id),
    CONSTRAINT fk_labtest_inv          FOREIGN KEY (inv_id)       REFERENCES investigation(inv_id)   ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_labtest_performer    FOREIGN KEY (performed_by) REFERENCES staff(staff_id)         ON UPDATE CASCADE
);

-- ============================================================
-- 15. EVIDENCE TYPE  - lookup
-- ============================================================
CREATE TABLE evidencetype (
    evtype_id    TINYINT     UNSIGNED NOT NULL AUTO_INCREMENT,
    type_name    VARCHAR(80) NOT NULL,
    CONSTRAINT pk_evidencetype      PRIMARY KEY (evtype_id),
    CONSTRAINT uq_evidencetype_name UNIQUE (type_name)
);

-- ============================================================
-- 16. STORAGE LOCATION  - where evidence is stored
-- ============================================================
CREATE TABLE storagelocation (
    location_id   SMALLINT     UNSIGNED NOT NULL AUTO_INCREMENT,
    location_name VARCHAR(100) NOT NULL,
    description   VARCHAR(255) NULL,
    capacity      INT          UNSIGNED NULL,
    CONSTRAINT pk_storagelocation      PRIMARY KEY (location_id),
    CONSTRAINT uq_storagelocation_name UNIQUE (location_name)
);

-- ============================================================
-- 17. EVIDENCE
-- ============================================================
CREATE TABLE evidence (
    evidence_id        INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id            INT          UNSIGNED NOT NULL,
    evtype_id          TINYINT      UNSIGNED NOT NULL,
    description        TEXT         NOT NULL,
    collection_datetime DATETIME    NOT NULL,
    collected_by       INT          UNSIGNED NOT NULL,
    location_id        SMALLINT     UNSIGNED NOT NULL,
    evidence_status    ENUM('In Storage','Sent to Lab','Handed to Police','Disposed','Lost') NOT NULL DEFAULT 'In Storage',
    CONSTRAINT pk_evidence         PRIMARY KEY (evidence_id),
    CONSTRAINT fk_evidence_case    FOREIGN KEY (case_id)      REFERENCES clinicalcase(case_id)       ON UPDATE CASCADE,
    CONSTRAINT fk_evidence_type    FOREIGN KEY (evtype_id)    REFERENCES evidencetype(evtype_id)     ON UPDATE CASCADE,
    CONSTRAINT fk_evidence_staff   FOREIGN KEY (collected_by) REFERENCES staff(staff_id)             ON UPDATE CASCADE,
    CONSTRAINT fk_evidence_loc     FOREIGN KEY (location_id)  REFERENCES storagelocation(location_id) ON UPDATE CASCADE
);

-- ============================================================
-- 18. CHAIN OF CUSTODY  - movement log for evidence
-- ============================================================
CREATE TABLE chainofcustody (
    custody_id    INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    evidence_id   INT          UNSIGNED NOT NULL,
    transferred_by INT         UNSIGNED NOT NULL,
    transferred_to VARCHAR(150) NOT NULL,
    transfer_date  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    transfer_reason TEXT        NOT NULL,
    CONSTRAINT pk_chainofcustody       PRIMARY KEY (custody_id),
    CONSTRAINT fk_custody_evidence     FOREIGN KEY (evidence_id)    REFERENCES evidence(evidence_id)  ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT fk_custody_transferredby FOREIGN KEY (transferred_by) REFERENCES staff(staff_id)       ON UPDATE CASCADE
);

-- ============================================================
-- 19. AUTOPSY  - postmortem examination
-- ============================================================
CREATE TABLE autopsy (
    autopsy_id      INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id         INT          UNSIGNED NOT NULL,
    death_datetime  DATETIME     NULL,
    autopsy_date    DATE         NOT NULL,
    type_of_death   ENUM('Natural','Accidental','Suicidal','Homicidal','Undetermined') NOT NULL,
    body_condition  VARCHAR(150) NULL,
    performed_by    INT          UNSIGNED NOT NULL,
    additional_findings TEXT     NULL,
    pmr_file_path   VARCHAR(500) NULL,
    CONSTRAINT pk_autopsy         PRIMARY KEY (autopsy_id),
    CONSTRAINT fk_autopsy_case    FOREIGN KEY (case_id)      REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_autopsy_staff   FOREIGN KEY (performed_by) REFERENCES staff(staff_id)       ON UPDATE CASCADE
);

-- ============================================================
-- 20. CAUSE OF DEATH  - detailed COD linked to autopsy
-- ============================================================
CREATE TABLE causeofdeath (
    cod_id       INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    autopsy_id   INT          UNSIGNED NOT NULL,
    primary_cod  TEXT         NOT NULL,
    secondary_cod TEXT        NULL,
    manner       ENUM('Natural','Accidental','Suicidal','Homicidal','Undetermined') NOT NULL,
    cod_notes    TEXT         NULL,
    CONSTRAINT pk_causeofdeath     PRIMARY KEY (cod_id),
    CONSTRAINT fk_cod_autopsy      FOREIGN KEY (autopsy_id) REFERENCES autopsy(autopsy_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- ============================================================
-- 21. COURT ORDER  - inquest or court request
-- ============================================================
CREATE TABLE courtorder (
    order_id       INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id        INT          UNSIGNED NOT NULL,
    order_ref      VARCHAR(80)  NOT NULL,
    issuing_court  VARCHAR(150) NOT NULL,
    issue_date     DATE         NOT NULL,
    order_type     ENUM('Postmortem','Evidence Submission','Medical Report','Witness') NOT NULL,
    order_status   ENUM('Received','In Progress','Fulfilled','Overdue') NOT NULL DEFAULT 'Received',
    CONSTRAINT pk_courtorder       PRIMARY KEY (order_id),
    CONSTRAINT fk_courtorder_case  FOREIGN KEY (case_id) REFERENCES clinicalcase(case_id) ON UPDATE CASCADE
);

-- ============================================================
-- 22. INQUEST - formal inquest proceedings
-- ============================================================
CREATE TABLE inquest (
    inquest_id     INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id        INT          UNSIGNED NOT NULL,
    autopsy_id     INT          UNSIGNED NULL,
    inquest_date   DATE         NOT NULL,
    magistrate     VARCHAR(150) NULL,
    venue          VARCHAR(200) NULL,
    verdict        TEXT         NULL,
    inquest_status ENUM('Scheduled','Ongoing','Concluded','Adjourned') NOT NULL DEFAULT 'Scheduled',
    CONSTRAINT pk_inquest         PRIMARY KEY (inquest_id),
    CONSTRAINT fk_inquest_case    FOREIGN KEY (case_id)    REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_inquest_autopsy FOREIGN KEY (autopsy_id) REFERENCES autopsy(autopsy_id)   ON UPDATE CASCADE
);

-- ============================================================
-- 23. MEDICO-LEGAL REPORT  (MLR)
-- ============================================================
CREATE TABLE medicolegalreport (
    mlr_id         INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id        INT          UNSIGNED NOT NULL,
    exam_id        INT          UNSIGNED NULL,
    prepared_by    INT          UNSIGNED NOT NULL,
    prepared_date  DATE         NOT NULL,
    report_content TEXT         NULL,
    addressed_to   VARCHAR(200) NULL,
    mlr_status     ENUM('Draft','Finalized','Submitted','Archived') NOT NULL DEFAULT 'Draft',
    file_path      VARCHAR(500) NULL,
    CONSTRAINT pk_medicolegalreport    PRIMARY KEY (mlr_id),
    CONSTRAINT fk_mlr_case             FOREIGN KEY (case_id)     REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_mlr_exam             FOREIGN KEY (exam_id)     REFERENCES examination(exam_id)  ON UPDATE CASCADE,
    CONSTRAINT fk_mlr_preparedby       FOREIGN KEY (prepared_by) REFERENCES staff(staff_id)       ON UPDATE CASCADE
);

-- ============================================================
-- 24. COURT REPORT  - MLEF / MLR / PMR submitted to courts
-- ============================================================
CREATE TABLE courtreport (
    report_id      INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id        INT          UNSIGNED NOT NULL,
    report_type    ENUM('MLEF','MLR','PMR') NOT NULL,
    court_ref      VARCHAR(80)  NULL,
    submitted_by   INT          UNSIGNED NOT NULL,
    submission_date DATE        NULL,
    report_status  ENUM('Draft','Submitted','Acknowledged','Rejected') NOT NULL DEFAULT 'Draft',
    file_path      VARCHAR(500) NULL,
    CONSTRAINT pk_courtreport      PRIMARY KEY (report_id),
    CONSTRAINT fk_courtreport_case FOREIGN KEY (case_id)      REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_courtreport_by   FOREIGN KEY (submitted_by) REFERENCES staff(staff_id)       ON UPDATE CASCADE
);

-- ============================================================
-- 25. CASE DOCUMENT  - uploaded documents per case
-- ============================================================
CREATE TABLE casedocument (
    document_id   INT          UNSIGNED NOT NULL AUTO_INCREMENT,
    case_id       INT          UNSIGNED NOT NULL,
    document_name VARCHAR(200) NOT NULL,
    document_type ENUM('MLEF','MLR','PMR','X-Ray','Lab Report','Photograph','Court Order','Other') NOT NULL,
    file_path     VARCHAR(500) NOT NULL,
    uploaded_by   INT          UNSIGNED NOT NULL,
    uploaded_at   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    description   TEXT         NULL,
    CONSTRAINT pk_casedocument      PRIMARY KEY (document_id),
    CONSTRAINT fk_casedoc_case      FOREIGN KEY (case_id)     REFERENCES clinicalcase(case_id) ON UPDATE CASCADE,
    CONSTRAINT fk_casedoc_uploader  FOREIGN KEY (uploaded_by) REFERENCES staff(staff_id)       ON UPDATE CASCADE
);

-- ============================================================
-- 26. AUDIT LOG  - security and change tracking
-- ============================================================
CREATE TABLE auditlog (
    log_id         BIGINT       UNSIGNED NOT NULL AUTO_INCREMENT,
    log_timestamp  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    user_account   VARCHAR(60)  NOT NULL,
    action_type    VARCHAR(30)  NOT NULL,
    target_table   VARCHAR(80)  NOT NULL,
    target_id      VARCHAR(40)  NULL,
    ip_address     VARCHAR(45)  NULL,
    severity       ENUM('Info','Warning','Critical') NOT NULL DEFAULT 'Info',
    details        TEXT         NULL,
    CONSTRAINT pk_auditlog PRIMARY KEY (log_id),
    CONSTRAINT chk_auditlog_action CHECK (action_type IN (
        'INSERT','UPDATE','DELETE','SELECT',
        'LOGIN','LOGOUT','FAILED_LOGIN','EXPORT'
    )),
    CONSTRAINT chk_auditlog_severity CHECK (severity IN ('Info','Warning','Critical'))
);

-- ============================================================
-- INDEXES for performance
-- ============================================================
CREATE INDEX idx_clinicalcase_patient    ON clinicalcase (patient_id);
CREATE INDEX idx_clinicalcase_status     ON clinicalcase (status_id);
CREATE INDEX idx_examination_case        ON examination (case_id);
CREATE INDEX idx_injury_exam             ON injury (exam_id);
CREATE INDEX idx_investigation_case      ON investigation (case_id);
CREATE INDEX idx_investigation_status    ON investigation (inv_status);
CREATE INDEX idx_evidence_case           ON evidence (case_id);
CREATE INDEX idx_evidence_status         ON evidence (evidence_status);
CREATE INDEX idx_autopsy_case            ON autopsy (case_id);
CREATE INDEX idx_auditlog_timestamp      ON auditlog (log_timestamp);
CREATE INDEX idx_auditlog_user           ON auditlog (user_account);
CREATE INDEX idx_mlef_status             ON mlef (mlef_status);
CREATE INDEX idx_courtreport_type        ON courtreport (report_type);
CREATE INDEX idx_casedocument_case       ON casedocument (case_id);
CREATE INDEX idx_casedocument_type       ON casedocument (document_type);
