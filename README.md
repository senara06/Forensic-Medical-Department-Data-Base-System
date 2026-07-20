# Forensic Medical Department Database System

> **Teammate A — Database Engineer**
> All MySQL scripts. No Python required.
> Branch: `feature/database`

---

## 📁 Project Structure

```
database/
├── schema.sql        ← CREATE DATABASE + all 26 tables (PK, FK, NOT NULL, CHECK)
├── seed_data.sql     ← INSERT realistic sample data (min 5 rows per table)
├── views.sql         ← 3 SQL views
├── triggers.sql      ← 2 audit-log triggers on clinicalcase
└── procedures.sql    ← 2 stored procedures
```

---

## 🗄️ Database Schema — `forensic_db`

### Tables (26 Total — 3NF Normalised)

| #  | Table               | Category              | Description                                    |
|----|---------------------|-----------------------|------------------------------------------------|
| 1  | `role`              | Auth & Users          | User access levels (Admin, JMO, MO, Lab, Clerk)|
| 2  | `department`        | Auth & Users          | Organisational units                           |
| 3  | `staff`             | Auth & Users          | Personnel records                              |
| 4  | `user`              | Auth & Users          | System login credentials (bcrypt hashed)       |
| 5  | `patient`           | Core                  | Patient demographic records                    |
| 6  | `casestatus`        | Core                  | Lookup table for case statuses                 |
| 7  | `clinicalcase`      | Core                  | Central case record (clinical + postmortem)     |
| 8  | `examination`       | Clinical              | Clinical examinations per case                 |
| 9  | `injury`            | Clinical              | Injuries recorded per examination              |
| 10 | `mlef`              | Clinical              | Medico-Legal Examination Forms                 |
| 11 | `referral`          | Clinical              | Patient referrals to other institutions        |
| 12 | `investigationtype` | Investigations        | Lookup for investigation types                 |
| 13 | `investigation`     | Investigations        | Lab investigation requests                     |
| 14 | `laboratorytest`    | Investigations        | Lab test results                               |
| 15 | `evidencetype`      | Evidence              | Lookup for evidence types                      |
| 16 | `storagelocation`   | Evidence              | Physical storage locations                     |
| 17 | `evidence`          | Evidence              | Evidence items linked to cases                 |
| 18 | `chainofcustody`    | Evidence              | Evidence movement/transfer log                 |
| 19 | `autopsy`           | Autopsy               | Postmortem examination records                 |
| 20 | `causeofdeath`      | Autopsy               | Detailed cause-of-death per autopsy            |
| 21 | `courtorder`        | Autopsy               | Court orders / inquest requests                |
| 22 | `inquest`           | Autopsy               | Formal inquest proceedings                     |
| 23 | `medicolegalreport` | Reports & Docs        | Medico-Legal Reports (MLR)                     |
| 24 | `courtreport`       | Reports & Docs        | Court submissions (MLEF / MLR / PMR)           |
| 25 | `casedocument`      | Reports & Docs        | Uploaded case documents (PDFs, images, scans)  |
| 26 | `auditlog`          | Security              | Security & change tracking log                 |

### Views (3)

| View                   | Purpose                                                    |
|------------------------|------------------------------------------------------------|
| `PendingMLEFs`         | Cases where MLEF status is Draft or Issued                 |
| `CasesByMonth`         | Aggregated case counts by year/month (clinical vs PM)      |
| `EvidenceWithLocation` | Full evidence detail + storage location + custody chain     |

### Triggers (2)

| Trigger                         | Event           | Description                                    |
|---------------------------------|-----------------|------------------------------------------------|
| `after_clinicalcase_update`     | AFTER UPDATE    | Logs case updates into `auditlog` (Info/Warning)|
| `after_clinicalcase_delete`     | AFTER DELETE    | Logs case deletions into `auditlog` (Critical)  |

### Stored Procedures (2)

| Procedure                      | Parameters           | Description                                     |
|--------------------------------|----------------------|-------------------------------------------------|
| `GetCaseDetails`               | `caseID INT`         | Returns 6 result sets: case, exams, injuries, investigations, evidence, documents |
| `GetPendingInvestigations`     | `staffID INT`        | Role-based pending investigation list (Doctor / Lab / Clerk views) |

---

## 🚀 Setup Instructions

### Prerequisites
- MySQL 8.0+ installed and running
- MySQL client or MySQL Workbench

### Step 1 — Create Database & Tables
```bash
mysql -u root -p < database/schema.sql
```

### Step 2 — Insert Sample Data
```bash
mysql -u root -p forensic_db < database/seed_data.sql
```

### Step 3 — Create Views
```bash
mysql -u root -p forensic_db < database/views.sql
```

### Step 4 — Create Triggers
```bash
mysql -u root -p forensic_db < database/triggers.sql
```

### Step 5 — Create Stored Procedures
```bash
mysql -u root -p forensic_db < database/procedures.sql
```

---

## 🧪 Testing

### Test Views
```sql
USE forensic_db;

-- Pending MLEFs (should return 4 rows with Draft/Issued status)
SELECT * FROM PendingMLEFs;

-- Cases aggregated by month
SELECT * FROM CasesByMonth;

-- Evidence with storage location and custody info
SELECT * FROM EvidenceWithLocation;
```

### Test Triggers
```sql
-- Set session variables (simulates application layer)
SET @current_user_ = 'c_wickramasinghe';
SET @current_ip_   = '192.168.1.45';

-- Update a case status → should auto-insert into auditlog
UPDATE clinicalcase SET status_id = 5 WHERE case_id = 1;

-- Verify the audit log entry
SELECT * FROM auditlog ORDER BY log_id DESC LIMIT 1;
```

### Test Stored Procedures
```sql
-- Full case details (6 result sets)
CALL GetCaseDetails(1);

-- Pending investigations — Doctor view
CALL GetPendingInvestigations(1);

-- Pending investigations — Lab staff view
CALL GetPendingInvestigations(3);
```

---

## 👥 Team

| Role            | Teammate | Branch              |
|-----------------|----------|---------------------|
| Database Engineer | **A**  | `feature/database`  |
| Backend Developer | B      | `feature/backend`   |
| Frontend Developer| C      | `feature/frontend`  |
| Testing & Docs    | D      | `feature/testing`   |

---

## 📝 Notes

- All passwords in `seed_data.sql` use placeholder bcrypt hashes — replace with real hashes in production.
- Session variables `@current_user_` and `@current_ip_` must be set by the application layer before UPDATE/DELETE on `clinicalcase` for triggers to capture the correct user.
- The database uses `utf8mb4` character set with `utf8mb4_unicode_ci` collation for full Unicode support.
