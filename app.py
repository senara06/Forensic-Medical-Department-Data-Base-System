from flask import Flask, render_template, request, redirect, url_for, session, flash
import bcrypt
from functools import wraps
from config import Config, get_db_connection
from datetime import datetime

app = Flask(__name__, template_folder='app/templates', static_folder='app/static')
app.config.from_object(Config)

# ==========================================
# Helpers & Decorators
# ==========================================

def log_audit(action_type, target_table, target_id=None, severity='Info', details=None):
    """Logs actions to the auditlog table."""
    try:
        conn = get_db_connection()
        cursor = conn.cursor()
        user_account = session.get('username', 'System')
        ip_address = request.remote_addr

        sql = """
            INSERT INTO auditlog (user_account, action_type, target_table, target_id, ip_address, severity, details)
            VALUES (%s, %s, %s, %s, %s, %s, %s)
        """
        cursor.execute(sql, (user_account, action_type, target_table, target_id, ip_address, severity, details))
        conn.close()
    except Exception as e:
        print(f"Failed to write to audit log: {e}")

def role_required(*roles):
    """Decorator to restrict access based on user role."""
    def wrapper(fn):
        @wraps(fn)
        def decorated_view(*args, **kwargs):
            if 'user_id' not in session:
                return redirect(url_for('login'))
            user_role = session.get('role')
            if user_role not in roles and user_role != 'Administrator':
                flash("You do not have permission to access this page.", "danger")
                return redirect(url_for('dashboard'))
            return fn(*args, **kwargs)
        return decorated_view
    return wrapper

# ==========================================
# Authentication Routes
# ==========================================

@app.route('/', methods=['GET'])
def index():
    if 'user_id' in session:
        return redirect(url_for('dashboard'))
    return redirect(url_for('login'))

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        username = request.form.get('username')
        password = request.form.get('password')

        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        
        # Join user, staff, and role tables to get the user's role
        sql = """
            SELECT u.user_id, u.username, u.password_hash, u.account_status, 
                   s.staff_id, s.first_name, s.last_name, r.role_name
            FROM user u
            JOIN staff s ON u.staff_id = s.staff_id
            JOIN role r ON s.role_id = r.role_id
            WHERE u.username = %s
        """
        cursor.execute(sql, (username,))
        user = cursor.fetchone()

        if user and user['account_status'] == 'Active':
            # Check bcrypt password
            if bcrypt.checkpw(password.encode('utf-8'), user['password_hash'].encode('utf-8')):
                # Success
                session['user_id'] = user['user_id']
                session['staff_id'] = user['staff_id']
                session['username'] = user['username']
                session['role'] = user['role_name']
                session['full_name'] = f"{user['first_name']} {user['last_name']}"

                # Update last_login
                cursor.execute("UPDATE user SET last_login = %s WHERE user_id = %s", (datetime.now(), user['user_id']))
                conn.close()

                # Audit log
                log_audit('LOGIN', 'user', str(user['user_id']), 'Info', 'Successful login')
                
                return redirect(url_for('dashboard'))
        
        conn.close()
        # Failure
        # We need to temporarily set session username to log properly if user exists
        temp_username = session.get('username')
        session['username'] = username if username else 'Unknown'
        log_audit('FAILED_LOGIN', 'user', None, 'Warning', 'Invalid credentials or inactive account')
        if temp_username:
            session['username'] = temp_username
        else:
            session.pop('username', None)

        flash("Invalid username or password, or account is inactive.", "danger")

    return render_template('login.html')

@app.route('/logout')
def logout():
    user_id = session.get('user_id')
    if user_id:
        log_audit('LOGOUT', 'user', str(user_id), 'Info', 'User logged out')
    session.clear()
    return redirect(url_for('login'))

# ==========================================
# Main Routes
# ==========================================

@app.route('/dashboard')
@role_required('Judicial Medical Officer', 'Medical Officer', 'Laboratory Staff', 'Clerical Officer', 'Administrator')
def dashboard():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # 1. Pending MLEFs
    cursor.execute("SELECT COUNT(*) as count FROM PendingMLEFs")
    pending_mlef = cursor.fetchone()['count']
    
    # 2. Pending Postmortems (Cases not closed)
    cursor.execute("SELECT COUNT(*) as count FROM clinicalcase WHERE case_type LIKE 'Postmortem%' AND status_id != 5")
    pending_pm = cursor.fetchone()['count']
    
    # 3. Active Court Orders
    cursor.execute("SELECT COUNT(*) as count FROM courtorder WHERE order_status != 'Fulfilled'")
    active_court = cursor.fetchone()['count']
    
    # 4. Evidence Today
    cursor.execute("SELECT COUNT(*) as count FROM evidence WHERE DATE(collection_datetime) = CURDATE()")
    evidence_today = cursor.fetchone()['count']
    
    # Recent cases for the table
    cursor.execute("""
        SELECT c.case_id, p.first_name, p.last_name, c.case_type, c.opened_at, cs.status_name 
        FROM clinicalcase c
        JOIN patient p ON c.patient_id = p.patient_id
        JOIN casestatus cs ON c.status_id = cs.status_id
        ORDER BY c.opened_at DESC LIMIT 5
    """)
    recent_cases = cursor.fetchall()
    
    conn.close()
    
    return render_template('dashboard.html', 
                           pending_mlef=pending_mlef, 
                           pending_pm=pending_pm, 
                           active_court=active_court, 
                           evidence_today=evidence_today,
                           recent_cases=recent_cases)

@app.route('/patients', methods=['GET', 'POST'])
@role_required('Judicial Medical Officer', 'Medical Officer', 'Clerical Officer', 'Administrator')
def patients():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        nic_passport = request.form.get('nic_passport')
        dob = request.form.get('dob') or None
        gender = request.form.get('gender', 'Unknown')
        blood_group = request.form.get('blood_group', 'Unknown')
        address = request.form.get('address')
        contact_no = request.form.get('contact_no')
        
        try:
            cursor.execute("""
                INSERT INTO patient (first_name, last_name, nic_passport, dob, gender, blood_group, address, contact_no)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (first_name, last_name, nic_passport, dob, gender, blood_group, address, contact_no))
            conn.commit()
            
            # Log audit
            log_audit('INSERT', 'patient', str(cursor.lastrowid), 'Info', 'Registered new patient')
            flash("Patient registered successfully.", "success")
        except Exception as e:
            flash(f"Error registering patient: {e}", "danger")
            
        return redirect(url_for('patients'))
        
    cursor.execute("SELECT * FROM patient ORDER BY registered_at DESC")
    patients_list = cursor.fetchall()
    conn.close()
    
    return render_template('patients.html', patients=patients_list)

@app.route('/cases', methods=['GET', 'POST'])
@role_required('Judicial Medical Officer', 'Medical Officer', 'Clerical Officer', 'Administrator')
def cases():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        patient_id = request.form.get('patient_id')
        case_type = request.form.get('case_type')
        incident_datetime = request.form.get('incident_datetime')
        incident_location = request.form.get('incident_location')
        police_station = request.form.get('police_station')
        police_ref_no = request.form.get('police_ref_no')
        assigned_staff_id = request.form.get('assigned_staff_id')
        remarks = request.form.get('remarks')
        
        try:
            # Note: triggers will auto-log this insertion if configured, but we log the insert
            # Actually trigger only logs UPDATE and DELETE according to schema
            # We must log INSERT
            
            cursor.execute("""
                INSERT INTO clinicalcase (patient_id, case_type, incident_datetime, incident_location, 
                                          police_station, police_ref_no, assigned_staff_id, remarks)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, (patient_id, case_type, incident_datetime, incident_location, police_station, police_ref_no, assigned_staff_id, remarks))
            conn.commit()
            
            log_audit('INSERT', 'clinicalcase', str(cursor.lastrowid), 'Info', 'Created new case')
            flash("Case created successfully.", "success")
        except Exception as e:
            flash(f"Error creating case: {e}", "danger")
            
        return redirect(url_for('cases'))
    
    cursor.execute("""
        SELECT c.case_id, p.first_name, p.last_name, c.case_type, c.opened_at, cs.status_name,
               CONCAT(s.first_name, ' ', s.last_name) as assigned_doctor
        FROM clinicalcase c
        JOIN patient p ON c.patient_id = p.patient_id
        JOIN casestatus cs ON c.status_id = cs.status_id
        JOIN staff s ON c.assigned_staff_id = s.staff_id
        ORDER BY c.opened_at DESC
    """)
    cases_list = cursor.fetchall()
    
    # Also fetch patients and staff for the creation form
    cursor.execute("SELECT patient_id, first_name, last_name, nic_passport FROM patient")
    patients_for_form = cursor.fetchall()
    
    cursor.execute("SELECT staff_id, first_name, last_name FROM staff WHERE is_active=1")
    staff_for_form = cursor.fetchall()
    
    conn.close()
    
    return render_template('cases.html', cases=cases_list, patients=patients_for_form, staff=staff_for_form)

@app.route('/examinations', methods=['GET', 'POST'])
@role_required('Judicial Medical Officer', 'Medical Officer', 'Administrator')
def examinations():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        case_id = request.form.get('case_id')
        exam_datetime = request.form.get('exam_datetime')
        ward_bht = request.form.get('ward_bht')
        exam_type = request.form.get('exam_type')
        clinical_notes = request.form.get('clinical_notes')
        
        try:
            cursor.execute("""
                INSERT INTO examination (case_id, exam_datetime, ward_bht, exam_type, clinical_notes, examiner_id)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (case_id, exam_datetime, ward_bht, exam_type, clinical_notes, session.get('staff_id')))
            conn.commit()
            
            log_audit('INSERT', 'examination', str(cursor.lastrowid), 'Info', 'Recorded new examination')
            flash("Examination recorded successfully.", "success")
        except Exception as e:
            flash(f"Error recording examination: {e}", "danger")
            
        return redirect(url_for('examinations'))

    cursor.execute("""
        SELECT e.exam_id, c.police_ref_no, e.exam_datetime, e.exam_type, 
               CONCAT(s.first_name, ' ', s.last_name) as examiner_name
        FROM examination e
        JOIN clinicalcase c ON e.case_id = c.case_id
        JOIN staff s ON e.examiner_id = s.staff_id
        ORDER BY e.exam_datetime DESC
    """)
    exams_list = cursor.fetchall()
    
    cursor.execute("SELECT case_id, police_ref_no FROM clinicalcase WHERE status_id != 5")
    active_cases = cursor.fetchall()
    
    conn.close()
    return render_template('examinations.html', examinations=exams_list, active_cases=active_cases)

@app.route('/investigations', methods=['GET', 'POST'])
@role_required('Judicial Medical Officer', 'Medical Officer', 'Laboratory Staff', 'Administrator')
def investigations():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        # Simple handler: could be requesting a test or entering results
        action = request.form.get('action')
        
        if action == 'request_test':
            case_id = request.form.get('case_id')
            inv_type_id = request.form.get('inv_type_id')
            request_date = request.form.get('request_date')
            clinical_reason = request.form.get('clinical_reason')
            try:
                cursor.execute("""
                    INSERT INTO investigation (case_id, inv_type_id, requested_by, request_date, clinical_reason)
                    VALUES (%s, %s, %s, %s, %s)
                """, (case_id, inv_type_id, session.get('staff_id'), request_date, clinical_reason))
                conn.commit()
                log_audit('INSERT', 'investigation', str(cursor.lastrowid), 'Info', 'Requested new lab investigation')
                flash("Investigation requested successfully.", "success")
            except Exception as e:
                flash(f"Error requesting investigation: {e}", "danger")
                
        elif action == 'enter_result':
            inv_id = request.form.get('inv_id')
            test_date = request.form.get('test_date')
            findings = request.form.get('findings')
            test_status = request.form.get('test_status', 'Completed')
            try:
                cursor.execute("""
                    INSERT INTO laboratorytest (inv_id, performed_by, test_date, findings, test_status)
                    VALUES (%s, %s, %s, %s, %s)
                """, (inv_id, session.get('staff_id'), test_date, findings, test_status))
                
                # Update investigation status
                new_status = 'Completed' if test_status == 'Completed' else 'Inconclusive'
                cursor.execute("UPDATE investigation SET inv_status = %s WHERE inv_id = %s", (new_status, inv_id))
                
                conn.commit()
                log_audit('INSERT', 'laboratorytest', str(cursor.lastrowid), 'Info', 'Entered lab test result')
                flash("Result entered successfully.", "success")
            except Exception as e:
                flash(f"Error entering result: {e}", "danger")
                
        return redirect(url_for('investigations'))

    # Call the stored procedure based on staff_id
    staff_id = session.get('staff_id')
    cursor.callproc('GetPendingInvestigations', [staff_id])
    
    pending_investigations = []
    # Fetch results from stored procedure
    for result in cursor.stored_results():
        pending_investigations = result.fetchall()
        break # Assuming we only care about the first result set
    
    cursor.execute("SELECT case_id, police_ref_no FROM clinicalcase WHERE status_id != 5")
    active_cases = cursor.fetchall()
    
    cursor.execute("SELECT * FROM investigationtype")
    inv_types = cursor.fetchall()
    
    conn.close()
    return render_template('investigations.html', pending_investigations=pending_investigations, active_cases=active_cases, inv_types=inv_types)

@app.route('/autopsies', methods=['GET', 'POST'])
@role_required('Judicial Medical Officer', 'Administrator')
def autopsies():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        case_id = request.form.get('case_id')
        autopsy_date = request.form.get('autopsy_date')
        type_of_death = request.form.get('type_of_death')
        body_condition = request.form.get('body_condition')
        
        try:
            cursor.execute("""
                INSERT INTO autopsy (case_id, autopsy_date, type_of_death, body_condition, performed_by)
                VALUES (%s, %s, %s, %s, %s)
            """, (case_id, autopsy_date, type_of_death, body_condition, session.get('staff_id')))
            conn.commit()
            
            log_audit('INSERT', 'autopsy', str(cursor.lastrowid), 'Info', 'Recorded new autopsy')
            flash("Autopsy recorded successfully.", "success")
        except Exception as e:
            flash(f"Error recording autopsy: {e}", "danger")
            
        return redirect(url_for('autopsies'))

    cursor.execute("""
        SELECT a.autopsy_id, c.police_ref_no, a.autopsy_date, a.type_of_death,
               CONCAT(s.first_name, ' ', s.last_name) as performed_by
        FROM autopsy a
        JOIN clinicalcase c ON a.case_id = c.case_id
        JOIN staff s ON a.performed_by = s.staff_id
        ORDER BY a.autopsy_date DESC
    """)
    autopsies_list = cursor.fetchall()
    
    cursor.execute("SELECT case_id, police_ref_no FROM clinicalcase WHERE case_type LIKE 'Postmortem%' AND status_id != 5")
    pm_cases = cursor.fetchall()
    
    conn.close()
    return render_template('autopsies.html', autopsies=autopsies_list, pm_cases=pm_cases)

@app.route('/evidence', methods=['GET', 'POST'])
@role_required('Judicial Medical Officer', 'Medical Officer', 'Laboratory Staff', 'Administrator')
def evidence():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        action = request.form.get('action')
        
        if action == 'log_evidence':
            case_id = request.form.get('case_id')
            evtype_id = request.form.get('evtype_id')
            description = request.form.get('description')
            collection_datetime = request.form.get('collection_datetime')
            location_id = request.form.get('location_id')
            
            try:
                cursor.execute("""
                    INSERT INTO evidence (case_id, evtype_id, description, collection_datetime, collected_by, location_id)
                    VALUES (%s, %s, %s, %s, %s, %s)
                """, (case_id, evtype_id, description, collection_datetime, session.get('staff_id'), location_id))
                evidence_id = cursor.lastrowid
                
                # Chain of custody entry
                cursor.execute("""
                    INSERT INTO chainofcustody (evidence_id, transferred_by, transferred_to, transfer_reason)
                    VALUES (%s, %s, %s, %s)
                """, (evidence_id, session.get('staff_id'), 'Storage', 'Initial Collection'))
                
                conn.commit()
                log_audit('INSERT', 'evidence', str(evidence_id), 'Info', 'Logged new evidence')
                flash("Evidence logged successfully.", "success")
            except Exception as e:
                flash(f"Error logging evidence: {e}", "danger")
                
        elif action == 'transfer':
            evidence_id = request.form.get('evidence_id')
            transferred_to = request.form.get('transferred_to')
            transfer_reason = request.form.get('transfer_reason')
            try:
                cursor.execute("""
                    INSERT INTO chainofcustody (evidence_id, transferred_by, transferred_to, transfer_reason)
                    VALUES (%s, %s, %s, %s)
                """, (evidence_id, session.get('staff_id'), transferred_to, transfer_reason))
                conn.commit()
                log_audit('INSERT', 'chainofcustody', str(cursor.lastrowid), 'Info', f'Transferred evidence {evidence_id}')
                flash("Chain of custody updated.", "success")
            except Exception as e:
                flash(f"Error transferring evidence: {e}", "danger")
                
        return redirect(url_for('evidence'))

    # Fetch from View
    cursor.execute("SELECT * FROM EvidenceWithLocation ORDER BY collection_datetime DESC")
    evidence_list = cursor.fetchall()
    
    cursor.execute("SELECT * FROM evidencetype")
    ev_types = cursor.fetchall()
    
    cursor.execute("SELECT * FROM storagelocation")
    locations = cursor.fetchall()
    
    cursor.execute("SELECT case_id, police_ref_no FROM clinicalcase WHERE status_id != 5")
    active_cases = cursor.fetchall()
    
    conn.close()
    return render_template('evidence.html', evidence=evidence_list, ev_types=ev_types, locations=locations, active_cases=active_cases)

@app.route('/court_reports', methods=['GET'])
@role_required('Judicial Medical Officer', 'Clerical Officer', 'Administrator')
def court_reports():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM PendingMLEFs")
    pending_mlefs = cursor.fetchall()
    
    cursor.execute("""
        SELECT cr.report_id, c.police_ref_no, cr.report_type, cr.submission_date, cr.report_status
        FROM courtreport cr
        JOIN clinicalcase c ON cr.case_id = c.case_id
        ORDER BY cr.submission_date DESC
    """)
    court_reports_list = cursor.fetchall()
    
    conn.close()
    return render_template('court_reports.html', pending_mlefs=pending_mlefs, court_reports=court_reports_list)

@app.route('/reports', methods=['GET'])
@role_required('Judicial Medical Officer', 'Clerical Officer', 'Administrator')
def reports():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    # 1. Monthly Aggregate Report
    cursor.execute("SELECT * FROM CasesByMonth ORDER BY case_year DESC, case_month DESC")
    cases_by_month = cursor.fetchall()
    
    # 2. Daily Case Report (All cases ordered by newest opened_at)
    cursor.execute("""
        SELECT c.case_id, CONCAT(p.first_name, ' ', p.last_name) as patient_name, 
               p.nic_passport, c.case_type, c.police_station, c.opened_at, 
               cs.status_name, CONCAT(s.first_name, ' ', s.last_name) as staff_name
        FROM clinicalcase c
        JOIN patient p ON c.patient_id = p.patient_id
        JOIN casestatus cs ON c.status_id = cs.status_id
        JOIN staff s ON c.assigned_staff_id = s.staff_id
        ORDER BY c.opened_at DESC
    """)
    daily_cases = cursor.fetchall()
    
    # 3. Pending Cases Report (Status != Closed)
    cursor.execute("""
        SELECT c.case_id, CONCAT(p.first_name, ' ', p.last_name) as patient_name, 
               c.case_type, c.police_station, c.opened_at, cs.status_name, 
               CONCAT(s.first_name, ' ', s.last_name) as staff_name,
               DATEDIFF(NOW(), c.opened_at) as days_pending
        FROM clinicalcase c
        JOIN patient p ON c.patient_id = p.patient_id
        JOIN casestatus cs ON c.status_id = cs.status_id
        JOIN staff s ON c.assigned_staff_id = s.staff_id
        WHERE cs.status_name != 'Closed'
        ORDER BY days_pending DESC
    """)
    pending_cases = cursor.fetchall()
    
    # 4. Court Report Summary
    cursor.execute("""
        SELECT cr.report_id, cr.case_id, cr.report_type, cr.court_ref, 
               cr.submission_date, cr.report_status, 
               CONCAT(s.first_name, ' ', s.last_name) as submitted_by, 
               CONCAT(p.first_name, ' ', p.last_name) as patient_name
        FROM courtreport cr
        JOIN clinicalcase c ON cr.case_id = c.case_id
        JOIN patient p ON c.patient_id = p.patient_id
        JOIN staff s ON cr.submitted_by = s.staff_id
        ORDER BY cr.report_id DESC
    """)
    court_reports_list = cursor.fetchall()
    
    # 5. Statistical Analytics
    cursor.execute("SELECT COUNT(*) as total FROM clinicalcase")
    total_cases = cursor.fetchone()['total']
    
    cursor.execute("SELECT COUNT(*) as pending FROM clinicalcase c JOIN casestatus cs ON c.status_id = cs.status_id WHERE cs.status_name != 'Closed'")
    pending_count = cursor.fetchone()['pending']
    
    cursor.execute("SELECT COUNT(*) as closed FROM clinicalcase c JOIN casestatus cs ON c.status_id = cs.status_id WHERE cs.status_name = 'Closed'")
    closed_count = cursor.fetchone()['closed']
    
    cursor.execute("SELECT COUNT(*) as total_reports FROM courtreport")
    court_count = cursor.fetchone()['total_reports']
    
    cursor.execute("""
        SELECT case_type, COUNT(*) as count 
        FROM clinicalcase 
        GROUP BY case_type
    """)
    type_stats = cursor.fetchall()
    
    stats = {
        'total_cases': total_cases,
        'pending_count': pending_count,
        'closed_count': closed_count,
        'court_count': court_count,
        'type_stats': type_stats
    }
    
    conn.close()
    return render_template(
        'reports.html', 
        cases_by_month=cases_by_month,
        daily_cases=daily_cases,
        pending_cases=pending_cases,
        court_reports_list=court_reports_list,
        stats=stats
    )

@app.route('/staff', methods=['GET', 'POST'])
@role_required('Administrator')
def staff():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    if request.method == 'POST':
        first_name = request.form.get('first_name')
        last_name = request.form.get('last_name')
        role_id = request.form.get('role_id')
        dept_id = request.form.get('dept_id')
        contact_no = request.form.get('contact_no')
        email = request.form.get('email')
        date_joined = request.form.get('date_joined', datetime.now().strftime('%Y-%m-%d'))
        
        username = request.form.get('username')
        password = request.form.get('password')
        
        try:
            cursor.execute("""
                INSERT INTO staff (first_name, last_name, role_id, dept_id, contact_no, email, date_joined)
                VALUES (%s, %s, %s, %s, %s, %s, %s)
            """, (first_name, last_name, role_id, dept_id, contact_no, email, date_joined))
            staff_id = cursor.lastrowid
            
            if username and password:
                hashed_pw = bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt())
                cursor.execute("""
                    INSERT INTO user (staff_id, username, password_hash)
                    VALUES (%s, %s, %s)
                """, (staff_id, username, hashed_pw.decode('utf-8')))
            
            conn.commit()
            log_audit('INSERT', 'staff', str(staff_id), 'Warning', f'Added new staff member {first_name} {last_name}')
            flash("Staff member added successfully.", "success")
        except Exception as e:
            flash(f"Error adding staff member: {e}", "danger")
            
        return redirect(url_for('staff'))

    cursor.execute("""
        SELECT s.staff_id, s.first_name, s.last_name, r.role_name, d.dept_name, s.contact_no, s.is_active, u.username
        FROM staff s
        JOIN role r ON s.role_id = r.role_id
        JOIN department d ON s.dept_id = d.dept_id
        LEFT JOIN user u ON s.staff_id = u.staff_id
        ORDER BY s.staff_id
    """)
    staff_list = cursor.fetchall()
    
    cursor.execute("SELECT * FROM role")
    roles = cursor.fetchall()
    
    cursor.execute("SELECT * FROM department")
    departments = cursor.fetchall()
    
    conn.close()
    return render_template('staff.html', staff_list=staff_list, roles=roles, departments=departments)

@app.route('/audit', methods=['GET'])
@role_required('Administrator')
def audit():
    conn = get_db_connection()
    cursor = conn.cursor(dictionary=True)
    
    cursor.execute("SELECT * FROM auditlog ORDER BY log_timestamp DESC LIMIT 200")
    logs = cursor.fetchall()
    
    conn.close()
    return render_template('audit.html', logs=logs)

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
