-- ============================================================
--  ForensicDB - seed_data.sql
--  Inserts realistic sample data - minimum 5 rows per table
--  Run AFTER schema.sql
-- ============================================================

USE forensic_db;

-- ============================================================
-- 1. ROLE
-- ============================================================
INSERT INTO role (role_name, description) VALUES
('Administrator',              'Full system access — manage users, audit logs, configuration'),
('Judicial Medical Officer',   'Senior forensic doctor; issues MLEFs and PMRs'),
('Medical Officer',            'Examines patients and records clinical findings'),
('Laboratory Staff',           'Processes investigation samples and enters results'),
('Clerical Officer',           'Administrative duties; schedules and filing');

-- ============================================================
-- 2. DEPARTMENT
-- ============================================================
INSERT INTO department (dept_name, location) VALUES
('Forensic Medicine',        'Building A, Level 2'),
('Histology Laboratory',     'Building B, Level 1'),
('Toxicology Unit',          'Building B, Level 2'),
('Administration',           'Main Block, Ground Floor'),
('Radiology & Imaging',      'Building C, Level 1');

-- ============================================================
-- 3. STAFF
-- ============================================================
INSERT INTO staff (first_name, last_name, role_id, dept_id, contact_no, email, date_joined, is_active) VALUES
('Chathula',   'Wickramasinghe', 2, 1, '0711234567', 'c.wickramasinghe@forensicdb.lk', '2018-03-15', 1),
('Nalini',     'Perera',         3, 1, '0722345678', 'n.perera@forensicdb.lk',          '2020-06-01', 1),
('Kasun',      'Fernando',       4, 2, '0713456789', 'k.fernando@forensicdb.lk',         '2021-01-20', 1),
('Jane',       'Doe',            5, 4, '0724567890', 'j.doe@forensicdb.lk',              '2019-09-10', 1),
('Admin',      'User',           1, 4, '0115678901', 'admin@forensicdb.lk',              '2017-01-01', 1),
('Ruwan',      'Jayasinghe',     2, 1, '0705678901', 'r.jayasinghe@forensicdb.lk',       '2016-07-12', 1),
('Amara',      'Silva',          3, 1, '0716789012', 'a.silva@forensicdb.lk',            '2022-02-14', 1),
('Priya',      'Kumari',         4, 3, '0727890123', 'p.kumari@forensicdb.lk',           '2020-11-05', 1),
('John',       'Smith',          4, 2, '0708901234', 'j.smith@forensicdb.lk',            '2019-04-18', 0),
('Sanduni',    'Rajapaksa',      5, 4, '0719012345', 's.rajapaksa@forensicdb.lk',        '2023-01-09', 1);

-- ============================================================
-- 4. USER
-- ============================================================
-- password_hash = bcrypt('password@123') - replace with real hashes in production
INSERT INTO user (staff_id, username, password_hash, account_status) VALUES
(5,  'admin',              '$2b$12$admin_placeholder_hash_001', 'Active'),
(1,  'c_wickramasinghe',   '$2b$12$jmo01_placeholder_hash_002', 'Active'),
(2,  'n_perera_mo',        '$2b$12$mo002_placeholder_hash_003', 'Active'),
(3,  'k_fernando_lab',     '$2b$12$lab03_placeholder_hash_004', 'Active'),
(4,  'j_doe_clerk',        '$2b$12$clk04_placeholder_hash_005', 'Active'),
(6,  'r_jayasinghe_jmo',   '$2b$12$jmo06_placeholder_hash_006', 'Active'),
(7,  'a_silva_mo',         '$2b$12$mo007_placeholder_hash_007', 'Active'),
(8,  'p_kumari_lab',       '$2b$12$lab08_placeholder_hash_008', 'Active'),
(9,  'j_smith_lab',        '$2b$12$lab09_placeholder_hash_009', 'Locked'),
(10, 's_rajapaksa_clk',    '$2b$12$clk10_placeholder_hash_010', 'Active');

-- ============================================================
-- 5. PATIENT
-- ============================================================
INSERT INTO patient (first_name, last_name, nic_passport, dob, gender, blood_group, address, contact_no) VALUES
('John',       'Doe',         '981234567V', '1998-05-14', 'Male',    'O+',      '12 Peradeniya Rd, Kandy',         '0771112233'),
('Jane',       'Smith',       '856723451V', '1985-11-22', 'Female',  'A+',      '45 Galle Rd, Colombo 03',         '0762223344'),
('Nimal',      'Bandara',     '920453678V', '1992-03-08', 'Male',    'B+',      '78 Kandy Rd, Kegalle',            '0703334455'),
('Kumari',     'Rathnayake',  '010254321V', '2001-07-30', 'Female',  'AB+',     '33 Temple St, Matale',            '0714445566'),
('Unknown',    'Male',        'PM-2026-001','1970-01-01', 'Male',    'Unknown', 'Body found - Kadugannawa Bridge',  NULL),
('Saman',      'Perera',      '780156789V', '1978-09-18', 'Male',    'O-',      '99 Station Rd, Gampaha',          '0725556677'),
('Dilani',     'Fernando',    '940287654V', '1994-12-05', 'Female',  'B-',      '22 Lake Rd, Nuwara Eliya',        '0756667788'),
('Rohana',     'Wijesinghe',  '560312345V', '1956-04-25', 'Male',    'A-',      '55 Main St, Badulla',             '0777778899');

-- ============================================================
-- 6. CASE STATUS
-- ============================================================
INSERT INTO casestatus (status_name) VALUES
('Open'),
('MLEF Pending'),
('Under Investigation'),
('Awaiting Report'),
('Closed'),
('Referred');

-- ============================================================
-- 7. CLINICAL CASE
-- ============================================================
INSERT INTO clinicalcase (patient_id, case_type, incident_datetime, incident_location, police_station, police_ref_no, assigned_staff_id, status_id, remarks) VALUES
(1, 'Clinical - Assault',        '2026-07-19 13:30:00', 'Kandy City Centre',          'Kandy HQ',          'PS-3059', 1, 2, 'Patient brought in by police escort'),
(2, 'Clinical - RTA',            '2026-07-18 08:45:00', 'Galle Rd, Colombo 03',       'Maradana PS',       'PS-2187', 1, 3, 'Multiple fractures — urgent investigation requested'),
(3, 'Clinical - Abuse',          '2026-07-17 16:00:00', 'Kegalle',                    'Kegalle PS',        'PS-1042', 2, 2, 'Referred from Kegalle Hospital'),
(5, 'Postmortem - Accidental',   '2026-07-16 00:00:00', 'Kadugannawa Bridge',          'Kadugannawa PS',    'PS-0881', 6, 1, 'Unidentified male — inquest ordered'),
(4, 'Clinical - Sexual Assault', '2026-07-15 21:00:00', 'Matale Town',                'Matale HQ',         'PS-0762', 1, 4, 'High sensitivity — restricted access'),
(6, 'Clinical - Trauma',         '2026-07-14 11:15:00', 'Gampaha',                    'Gampaha PS',        'PS-0651', 2, 5, 'Case closed — MLEF issued and submitted'),
(7, 'Clinical - Assault',        '2026-07-12 20:30:00', 'Nuwara Eliya',               'Nuwara Eliya PS',   'PS-0544', 7, 2, 'Follow-up examination scheduled'),
(8, 'Postmortem - Natural',      '2026-07-10 03:00:00', 'Badulla General Hospital',   'Badulla HQ',        'PS-0432', 6, 5, 'PMR submitted to magistrate');

-- ============================================================
-- 8. EXAMINATION
-- ============================================================
INSERT INTO examination (case_id, exam_datetime, ward_bht, exam_type, clinical_notes, photos_taken, examiner_id) VALUES
(1, '2026-07-19 14:05:00', 'Ward 5 / BHT-00281', 'Initial Examination',  'Patient alert, multiple contusions on left arm and forehead laceration. History of assault consistent with injuries.',   'Yes', 1),
(2, '2026-07-18 10:00:00', 'Ward 8 / BHT-00192', 'Initial Examination',  'Patient presents with multiple rib fractures and right tibia fracture. Consistent with RTA mechanism.',              'Yes', 1),
(3, '2026-07-17 17:30:00', 'Ward 3 / BHT-00354', 'Initial Examination',  'Old and fresh bruising observed over trunk and upper limbs. Pattern consistent with repeated blunt force.',          'Yes', 2),
(5, '2026-07-15 22:15:00', 'Ward 6 / BHT-00487', 'Sexual Assault Examination', 'Conducted per SEAP protocol. Swabs collected and secured. Detailed findings recorded separately.',            'Yes', 1),
(6, '2026-07-14 12:00:00', 'Ward 2 / BHT-00521', 'Initial Examination',  'Trauma patient. Lacerations to scalp (5cm) and bruising to right shoulder.',                                        'Yes', 2),
(7, '2026-07-12 21:00:00', 'Ward 4 / BHT-00612', 'Initial Examination',  'Two linear abrasions on right cheek, redness over left forearm consistent with grip marks.',                        'Pending', 7),
(1, '2026-07-20 09:30:00', 'Ward 5 / BHT-00281', 'Follow-up Examination','Follow-up: bruising colour changed to yellow-green — consistent with 5-7 day aging. Healing well.',                 'No', 1),
(2, '2026-07-20 11:00:00', 'Ward 8 / BHT-00192', 'Follow-up Examination','Fractures stable. Patient on orthopaedic management. Report updated.',                                               'No', 2);

-- ============================================================
-- 9. INJURY
-- ============================================================
INSERT INTO injury (exam_id, injury_type, body_location, description) VALUES
(1, 'Bruise / Contusion', 'Left forearm',  '4cm x 3cm yellowish-brown contusion, tender on palpation'),
(1, 'Laceration',         'Forehead',      '3cm linear laceration above right eyebrow, edges clean'),
(2, 'Fracture',           'Right tibia',   'Mid-shaft fracture confirmed by X-ray — complete break'),
(2, 'Fracture',           'Ribs 5-6 (R)', 'Hairline fractures to 5th and 6th right ribs'),
(3, 'Bruise / Contusion', 'Upper back',    'Multiple contusions of varying ages — old and fresh'),
(3, 'Abrasion',           'Left shoulder', '2cm x 1cm abrasion, scabbed over'),
(5, 'Bruise / Contusion', 'Left shoulder', '5cm x 2cm contusion consistent with impact'),
(5, 'Laceration',         'Scalp (right)', '5cm laceration, sutured at referring hospital'),
(6, 'Abrasion',           'Right cheek',   'Two parallel linear abrasions, fresh'),
(6, 'Bruise / Contusion', 'Left forearm',  'Redness and mild swelling consistent with grip marks');

-- ============================================================
-- 10. MLEF
-- ============================================================
INSERT INTO mlef (case_id, exam_id, issued_by, mlef_status, police_ref) VALUES
(1, 1, 1, 'Draft',     'PS-3059'),
(2, 2, 1, 'Issued',    'PS-2187'),
(3, 3, 2, 'Draft',     'PS-1042'),
(5, 4, 1, 'Draft',     'PS-0762'),
(6, 5, 2, 'Submitted', 'PS-0651'),
(7, 6, 7, 'Draft',     'PS-0544');

-- ============================================================
-- 11. REFERRAL
-- ============================================================
INSERT INTO referral (case_id, referred_by, referred_to, referral_date, reason, status) VALUES
(3, 2, 'Kegalle Teaching Hospital - Psychiatry',         '2026-07-17', 'Suspected psychological trauma from prolonged abuse',       'Pending'),
(2, 1, 'Radiology & Imaging - Kandy Teaching Hospital',  '2026-07-18', 'CT scan required to confirm internal injuries',             'Accepted'),
(5, 1, 'Government Analyst Department - DNA Unit',       '2026-07-15', 'DNA profiling for identification of unidentified deceased', 'Pending'),
(7, 7, 'Nuwara Eliya General Hospital - Ophthalmology',  '2026-07-13', 'Possible orbital injury from assault',                      'Completed'),
(6, 2, 'Gampaha District Hospital - Physiotherapy',      '2026-07-14', 'Rehabilitation following trauma injuries',                   'Completed');

-- ============================================================
-- 12. INVESTIGATION TYPE
-- ============================================================
INSERT INTO investigationtype (type_name) VALUES
('X-Ray'),
('CT Scan'),
('Blood Analysis'),
('DNA Analysis'),
('Toxicology Screen'),
('Histology'),
('Urine Analysis'),
('Wound Swab Culture');

-- ============================================================
-- 13. INVESTIGATION
-- ============================================================
INSERT INTO investigation (case_id, inv_type_id, requested_by, request_date, clinical_reason, inv_status) VALUES
(1, 1, 1, '2026-07-19', 'Suspected fracture of left ulna based on clinical findings',          'In Progress'),
(2, 2, 1, '2026-07-18', 'CT scan to assess internal organ damage following RTA',               'Completed'),
(2, 5, 1, '2026-07-18', 'Toxicology screen - patient admitted with altered consciousness',      'Completed'),
(3, 3, 2, '2026-07-17', 'FBC and CRP to assess extent of injuries',                           'Completed'),
(5, 4, 1, '2026-07-15', 'DNA profiling for victim identification',                             'In Progress'),
(4, 5, 1, '2026-07-15', 'Toxicology screen requested as per SEAP protocol',                    'Pending'),
(7, 1, 7, '2026-07-13', 'X-ray to rule out orbital fracture',                                  'Completed'),
(1, 8, 1, '2026-07-19', 'Wound swab from forehead laceration for culture',                     'Pending');

-- ============================================================
-- 14. LABORATORY TEST
-- ============================================================
INSERT INTO laboratorytest (inv_id, performed_by, test_date, findings, test_status) VALUES
(2, 3, '2026-07-19', 'CT scan shows no evidence of internal organ damage. Fractures confirmed as previously noted.', 'Completed'),
(3, 8, '2026-07-19', 'Toxicology negative for all common agents. Alcohol at 0.0 g/dL.',                              'Completed'),
(4, 3, '2026-07-18', 'FBC: Hb 11.2, WBC 12.5 (elevated), CRP 45 (elevated) - consistent with acute trauma.',        'Completed'),
(7, 3, '2026-07-14', 'X-ray of right orbital region - no fracture identified. Soft tissue swelling noted.',           'Completed'),
(5, 8, '2026-07-18', 'DNA sample extracted and profiled. Reference profile submitted to police lab. Awaiting match.', 'Completed');

-- ============================================================
-- 15. EVIDENCE TYPE
-- ============================================================
INSERT INTO evidencetype (type_name) VALUES
('Blood Swab'),
('Clothing'),
('Weapon'),
('Toxicology Sample'),
('DNA Sample'),
('Photograph'),
('Document'),
('Digital Media');

-- ============================================================
-- 16. STORAGE LOCATION
-- ============================================================
INSERT INTO storagelocation (location_name, description, capacity) VALUES
('Cold Storage A',      'Refrigerated unit for biological samples',       50),
('Cold Storage B',      'Secondary refrigerated unit',                    50),
('Locker A1',           'Secure metal locker - weapons and hard items',   20),
('Locker B2',           'Secure metal locker - clothing and documents',   30),
('Laboratory Handover', 'Temporary holding for items sent to lab',        15),
('Sealed Evidence Room','High-security room for critical evidence',       100),
('Digital Archive',     'Encrypted server store for digital evidence',   500);

-- ============================================================
-- 17. EVIDENCE
-- ============================================================
INSERT INTO evidence (case_id, evtype_id, description, collection_datetime, collected_by, location_id, evidence_status) VALUES
(1, 1, 'Blood swab from forehead laceration wound - labelled EVI-9921',              '2026-07-19 14:30:00', 1, 2, 'In Storage'),
(2, 2, 'Torn clothing from RTA victim - jeans and shirt, bloodstained',              '2026-07-18 11:00:00', 1, 4, 'In Storage'),
(1, 3, 'Metal rod recovered from scene - alleged assault weapon, 45cm length',       '2026-07-19 16:00:00', 1, 3, 'Handed to Police'),
(5, 5, 'Buccal swab from unidentified deceased for DNA profiling',                   '2026-07-16 09:00:00', 6, 2, 'Sent to Lab'),
(3, 1, 'Blood swab from back contusions for typing - CAS-2026-003',                  '2026-07-17 18:00:00', 2, 2, 'In Storage'),
(4, 5, 'Sexual assault kit evidence - collected per SEAP protocol',                  '2026-07-15 23:00:00', 1, 6, 'In Storage'),
(6, 2, 'Grey T-shirt of trauma patient - minor blood staining on right shoulder',    '2026-07-14 12:30:00', 2, 4, 'Handed to Police'),
(2, 4, 'Blood sample for toxicology - 10mL EDTA tube',                              '2026-07-18 10:30:00', 1, 5, 'Sent to Lab');

-- ============================================================
-- 18. CHAIN OF CUSTODY
-- ============================================================
INSERT INTO chainofcustody (evidence_id, transferred_by, transferred_to, transfer_reason) VALUES
(3, 1, 'Kandy HQ Police Station - OIC Crimes',         'Handing over weapon to police for further investigation'),
(4, 6, 'Government Analyst Department - DNA Lab',      'Sending swab for DNA profiling and identification'),
(8, 1, 'Toxicology Unit - Lab Staff P. Kumari',        'Sending blood sample for toxicology analysis'),
(7, 2, 'Gampaha PS - OIC',                             'Handing over clothing as police exhibit'),
(1, 1, 'Cold Storage B - Shelf 3',                     'Transfer from collection point to cold storage');

-- ============================================================
-- 19. AUTOPSY
-- ============================================================
INSERT INTO autopsy (case_id, death_datetime, autopsy_date, type_of_death, body_condition, performed_by, additional_findings) VALUES
(4, '2026-07-16 00:00:00', '2026-07-16', 'Accidental',    'Moderate decomposition - body in water 12-24hrs', 6, 'Evidence of drowning; no signs of external violence found'),
(8, '2026-07-10 02:30:00', '2026-07-10', 'Natural',       'Fresh - admitted to hospital and died',           6, 'Advanced coronary artery disease; MI confirmed histologically'),
(4, '2026-07-16 00:00:00', '2026-07-17', 'Accidental',    'Secondary examination after CT imaging',          1, 'No new findings; accidental drowning confirmed'),
(8, '2026-07-10 02:30:00', '2026-07-11', 'Natural',       'Post-fixation histology sections taken',          6, 'Histology confirms acute MI with LAD occlusion'),
(8, '2026-07-10 02:30:00', '2026-07-12', 'Natural',       'Final review - PMR completed',                    6, 'PMR finalised and submitted to Badulla Magistrate Court');

-- ============================================================
-- 20. CAUSE OF DEATH
-- ============================================================
INSERT INTO causeofdeath (autopsy_id, primary_cod, secondary_cod, manner, cod_notes) VALUES
(1, 'Asphyxia due to drowning', 'Hypothermia', 'Accidental', 'Water found in lungs - fresh water consistent with river'),
(2, 'Acute myocardial infarction due to severe coronary artery disease', NULL, 'Natural', 'LAD occlusion > 90% confirmed at autopsy'),
(3, 'Asphyxia due to drowning', 'No new findings', 'Accidental', 'Confirmed on secondary examination'),
(4, 'Acute MI - histologically confirmed', 'Atherosclerosis', 'Natural', 'Histology sections confirm acute MI'),
(5, 'Acute myocardial infarction', 'Hypertensive heart disease', 'Natural', 'PMR finalised - submitted to court');

-- ============================================================
-- 21. COURT ORDER
-- ============================================================
INSERT INTO courtorder (case_id, order_ref, issuing_court, issue_date, order_type, order_status) VALUES
(4, 'CO-2026-KAD-001', 'Kadugannawa Magistrate Court',   '2026-07-16', 'Postmortem',           'In Progress'),
(8, 'CO-2026-BAD-001', 'Badulla Magistrate Court',       '2026-07-10', 'Postmortem',           'Fulfilled'),
(1, 'CO-2026-KAN-001', 'Kandy Magistrate Court',         '2026-07-19', 'Medical Report',       'Received'),
(5, 'CO-2026-MAT-001', 'Matale Magistrate Court',        '2026-07-15', 'Medical Report',       'In Progress'),
(2, 'CO-2026-COL-001', 'Colombo Chief Magistrate Court', '2026-07-18', 'Evidence Submission',  'Received');

-- ============================================================
-- 22. INQUEST
-- ============================================================
INSERT INTO inquest (case_id, autopsy_id, inquest_date, magistrate, venue, inquest_status, verdict) VALUES
(4, 1, '2026-07-20', 'M. Weerasinghe',         'Kadugannawa Magistrate Court',  'Scheduled',  NULL),
(8, 2, '2026-07-15', 'S. Jayalath',            'Badulla Magistrate Court',      'Concluded',  'Death by natural causes — no suspicious circumstances'),
(4, 3, '2026-07-25', 'M. Weerasinghe',         'Kadugannawa Magistrate Court',  'Scheduled',  NULL),
(8, 4, '2026-07-22', 'S. Jayalath',            'Badulla Magistrate Court',      'Adjourned',  NULL),
(8, 5, '2026-07-28', 'S. Jayalath',            'Badulla Magistrate Court',      'Concluded',  'Cause of death confirmed as acute MI — natural death');

-- ============================================================
-- 23. MEDICO-LEGAL REPORT
-- ============================================================
INSERT INTO medicolegalreport (case_id, exam_id, prepared_by, prepared_date, addressed_to, mlr_status, report_content) VALUES
(1, 1, 1, '2026-07-19', 'OIC, Kandy HQ Police Station',       'Draft',     'This is to certify that I examined the above-named patient on 19/07/2026 at 14:05 hrs...'),
(2, 2, 1, '2026-07-18', 'Maradana Police Station',            'Finalized', 'Patient presented with multiple fractures consistent with RTA mechanism...'),
(6, 5, 2, '2026-07-14', 'Gampaha Police Station',             'Submitted', 'Injuries noted are consistent with the history provided of a fall...'),
(3, 3, 2, '2026-07-17', 'Kegalle Police Station',             'Draft',     'Multiple injuries of varying ages noted — concern for ongoing domestic abuse...'),
(7, 6, 7, '2026-07-12', 'Nuwara Eliya Police Station',        'Draft',     'Patient examined following alleged assault — findings detailed below...');

-- ============================================================
-- 24. COURT REPORT
-- ============================================================
INSERT INTO courtreport (case_id, report_type, court_ref, submitted_by, submission_date, report_status) VALUES
(1, 'MLEF', 'PS-3059',              1, NULL,           'Draft'),
(2, 'MLEF', 'PS-2187',              1, '2026-07-19',  'Submitted'),
(8, 'PMR',  'BAD-MAGISTRATE-2026',  6, '2026-07-12',  'Acknowledged'),
(6, 'MLR',  'PS-0651',              2, '2026-07-15',  'Submitted'),
(5, 'MLEF', 'PS-0762',              1, NULL,           'Draft'),
(4, 'PMR',  'KAD-MAGISTRATE-2026',  6, NULL,           'Draft');

-- ============================================================
-- 25. CASE DOCUMENT
-- ============================================================
INSERT INTO casedocument (case_id, document_name, document_type, file_path, uploaded_by, description) VALUES
(1, 'MLEF_CAS2026001_draft.pdf',       'MLEF',         '/docs/cases/1/MLEF_CAS2026001_draft.pdf',      1, 'Draft MLEF for assault case — pending JMO signature'),
(2, 'CT_Scan_RTA_case2.pdf',           'X-Ray',        '/docs/cases/2/CT_Scan_RTA_case2.pdf',          1, 'CT scan results showing rib and tibia fractures'),
(6, 'MLR_Trauma_case6.pdf',            'MLR',          '/docs/cases/6/MLR_Trauma_case6.pdf',           2, 'Finalized medico-legal report submitted to Gampaha PS'),
(8, 'PMR_NaturalDeath_case8.pdf',      'PMR',          '/docs/cases/8/PMR_NaturalDeath_case8.pdf',     6, 'Postmortem report — acute MI confirmed'),
(5, 'CourtOrder_MAT001.pdf',           'Court Order',  '/docs/cases/5/CourtOrder_MAT001.pdf',          4, 'Court order from Matale Magistrate for medical report'),
(1, 'Injury_Photos_Forearm.zip',       'Photograph',   '/docs/cases/1/Injury_Photos_Forearm.zip',      1, 'Photographs of contusions on left forearm'),
(3, 'Blood_Analysis_Report.pdf',       'Lab Report',   '/docs/cases/3/Blood_Analysis_Report.pdf',      3, 'FBC and CRP results — elevated values consistent with trauma');

-- ============================================================
-- 26. AUDIT LOG
-- ============================================================
INSERT INTO auditlog (log_timestamp, user_account, action_type, target_table, target_id, ip_address, severity, details) VALUES
('2026-07-19 08:01:11', 'admin',             'LOGIN',        'user',         'user_id:5',   '192.168.1.10',  'Info',     'Admin logged in successfully'),
('2026-07-19 08:05:44', 'c_wickramasinghe',  'LOGIN',        'user',         'user_id:2',   '192.168.1.45',  'Info',     'JMO logged in successfully'),
('2026-07-19 14:05:22', 'c_wickramasinghe',  'INSERT',       'examination',  'exam_id:1',   '192.168.1.45',  'Info',     'New examination recorded for CAS-2026-001'),
('2026-07-19 14:10:01', 'c_wickramasinghe',  'UPDATE',       'clinicalcase', 'case_id:1',   '192.168.1.45',  'Info',     'Case status changed from Open to MLEF Pending'),
('2026-07-19 15:12:01', 'unknown_user',      'FAILED_LOGIN', 'user',         NULL,          '10.0.0.99',     'Warning',  'Failed login attempt with unknown username'),
('2026-07-19 15:15:33', 'unknown_user',      'FAILED_LOGIN', 'user',         NULL,          '10.0.0.99',     'Critical', '3rd consecutive failed login from same IP — possible brute force'),
('2026-07-19 16:30:12', 'admin',             'UPDATE',       'user',         'user_id:9',   '192.168.1.10',  'Warning',  'Account for j_smith_lab set to Locked'),
('2026-07-19 17:00:55', 'n_perera_mo',       'INSERT',       'clinicalcase', 'case_id:3',   '192.168.1.52',  'Info',     'New clinical case opened — abuse category'),
('2026-07-19 17:45:33', 'k_fernando_lab',    'INSERT',       'laboratorytest','lab_test_id:3','192.168.1.67','Info',     'Lab result entered for investigation INV-3'),
('2026-07-20 00:01:00', 'admin',             'EXPORT',       'auditlog',     NULL,          '192.168.1.10',  'Info',     'Audit log exported by administrator — daily backup');
