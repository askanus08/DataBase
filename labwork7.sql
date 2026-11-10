-- ============================================================================
-- LABORATORY WORK 7: SQL VIEWS AND ROLES
-- ============================================================================

-- ============================================================================
-- PART 2: CREATING BASIC VIEWS
-- ============================================================================

-- Exercise 2.1: Simple View Creation
CREATE VIEW employee_details AS
SELECT 
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 2.2: View with Aggregation
CREATE VIEW dept_statistics AS
SELECT 
    d.dept_name,
    COUNT(e.emp_id) AS employee_count,
    AVG(e.salary) AS avg_salary,
    MAX(e.salary) AS max_salary,
    MIN(e.salary) AS min_salary
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY d.dept_id, d.dept_name;

-- Exercise 2.3: View with Multiple Joins
CREATE VIEW project_overview AS
SELECT 
    p.project_name,
    p.budget,
    d.dept_name,
    d.location,
    COUNT(e.emp_id) AS team_size
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_id, d.dept_name, d.location;

-- Exercise 2.4: View with Filtering
CREATE VIEW high_earners AS
SELECT 
    e.emp_name,
    e.salary,
    d.dept_name
FROM employees e
LEFT JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 55000;


-- ============================================================================
-- PART 3: MODIFYING AND MANAGING VIEWS
-- ============================================================================

-- Exercise 3.1: Replace a View
CREATE OR REPLACE VIEW employee_details AS
SELECT 
    e.emp_name,
    e.salary,
    d.dept_name,
    d.location,
    CASE 
        WHEN e.salary > 60000 THEN 'High'
        WHEN e.salary > 50000 THEN 'Medium'
        ELSE 'Standard'
    END AS salary_grade
FROM employees e
INNER JOIN departments d ON e.dept_id = d.dept_id;

-- Exercise 3.2: Rename a View
ALTER VIEW high_earners RENAME TO top_performers;

-- Exercise 3.3: Drop a View
CREATE VIEW temp_view AS
SELECT * 
FROM employees 
WHERE salary < 50000;

DROP VIEW temp_view;


-- ============================================================================
-- PART 4: UPDATABLE VIEWS
-- ============================================================================

-- Exercise 4.1: Create an Updatable View
CREATE VIEW employee_salaries AS
SELECT 
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees;

-- Exercise 4.2: Update Through a View
UPDATE employee_salaries
SET salary = 52000
WHERE emp_name = 'John Smith';

-- Exercise 4.3: Insert Through a View
INSERT INTO employee_salaries (emp_id, emp_name, dept_id, salary)
VALUES (6, 'Alice Johnson', 102, 58000);

-- Exercise 4.4: View with CHECK OPTION
CREATE VIEW it_employees AS
SELECT 
    emp_id,
    emp_name,
    dept_id,
    salary
FROM employees
WHERE dept_id = 101
WITH LOCAL CHECK OPTION;


-- ============================================================================
-- PART 5: MATERIALIZED VIEWS
-- ============================================================================

-- Exercise 5.1: Create a Materialized View
CREATE MATERIALIZED VIEW dept_summary_mv AS
SELECT 
    d.dept_id,
    d.dept_name,
    COUNT(DISTINCT e.emp_id) AS total_employees,
    COALESCE(SUM(e.salary), 0) AS total_salaries,
    COUNT(DISTINCT p.project_id) AS total_projects,
    COALESCE(SUM(DISTINCT p.budget), 0) AS total_project_budget
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name
WITH DATA;

-- Exercise 5.2: Refresh Materialized View
INSERT INTO employees (emp_id, emp_name, dept_id, salary)
VALUES (8, 'Charlie Brown', 101, 54000);

REFRESH MATERIALIZED VIEW dept_summary_mv;

-- Exercise 5.3: Concurrent Refresh
CREATE UNIQUE INDEX idx_dept_summary_mv_dept_id ON dept_summary_mv (dept_id);

REFRESH MATERIALIZED VIEW CONCURRENTLY dept_summary_mv;

-- Exercise 5.4: Materialized View with NO DATA
CREATE MATERIALIZED VIEW project_stats_mv AS
SELECT 
    p.project_name,
    p.budget,
    d.dept_name,
    COUNT(e.emp_id) AS assigned_employees
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
LEFT JOIN employees e ON d.dept_id = e.dept_id
GROUP BY p.project_id, p.project_name, p.budget, d.dept_name
WITH NO DATA;

REFRESH MATERIALIZED VIEW project_stats_mv;


-- ============================================================================
-- PART 6: DATABASE ROLES
-- ============================================================================

-- Exercise 6.1: Create Basic Roles
CREATE ROLE analyst NOLOGIN;
CREATE ROLE data_viewer WITH LOGIN PASSWORD 'viewer123';
CREATE ROLE report_user WITH LOGIN PASSWORD 'report456';

-- Exercise 6.2: Role with Specific Attributes
CREATE ROLE db_creator WITH CREATEDB LOGIN PASSWORD 'creator789';
CREATE ROLE user_manager WITH CREATEROLE LOGIN PASSWORD 'manager101';
CREATE ROLE admin_user WITH SUPERUSER LOGIN PASSWORD 'admin999';

-- Exercise 6.3: Grant Privileges to Roles
GRANT SELECT ON employees, departments, projects TO analyst;
GRANT ALL PRIVILEGES ON employee_details TO data_viewer;
GRANT SELECT, INSERT ON employees TO report_user;

-- Exercise 6.4: Create Group Roles
CREATE ROLE hr_team NOLOGIN;
CREATE ROLE finance_team NOLOGIN;
CREATE ROLE it_team NOLOGIN;

CREATE ROLE hr_user1 WITH LOGIN PASSWORD 'hr001';
CREATE ROLE hr_user2 WITH LOGIN PASSWORD 'hr002';
CREATE ROLE finance_user1 WITH LOGIN PASSWORD 'fin001';

GRANT hr_team TO hr_user1, hr_user2;
GRANT finance_team TO finance_user1;

GRANT SELECT, UPDATE ON employees TO hr_team;
GRANT SELECT ON dept_statistics TO finance_team;

-- Exercise 6.5: Revoke Privileges
REVOKE UPDATE ON employees FROM hr_team;
REVOKE hr_team FROM hr_user2;
REVOKE ALL PRIVILEGES ON employee_details FROM data_viewer;

-- Exercise 6.6: Modify Role Attributes
ALTER ROLE analyst WITH LOGIN PASSWORD 'analyst123';
ALTER ROLE user_manager WITH SUPERUSER;
ALTER ROLE analyst PASSWORD NULL;
ALTER ROLE data_viewer CONNECTION LIMIT 5;


-- ============================================================================
-- PART 7: ADVANCED ROLE MANAGEMENT
-- ============================================================================

-- Exercise 7.1: Role Hierarchies
CREATE ROLE read_only NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO read_only;

CREATE ROLE junior_analyst WITH LOGIN PASSWORD 'junior123';
CREATE ROLE senior_analyst WITH LOGIN PASSWORD 'senior123';

GRANT read_only TO junior_analyst, senior_analyst;
GRANT INSERT, UPDATE ON employees TO senior_analyst;

-- Exercise 7.2: Object Ownership
CREATE ROLE project_manager WITH LOGIN PASSWORD 'pm123';

ALTER VIEW dept_statistics OWNER TO project_manager;
ALTER TABLE projects OWNER TO project_manager;

-- Exercise 7.3: Reassign and Drop Roles
CREATE ROLE temp_owner WITH LOGIN;
CREATE TABLE temp_table (id INT);
ALTER TABLE temp_table OWNER TO temp_owner;

REASSIGN OWNED BY temp_owner TO postgres;
DROP OWNED BY temp_owner;
DROP ROLE temp_owner;

-- Exercise 7.4: Row-Level Security with Views
CREATE VIEW hr_employee AS
SELECT * 
FROM employees 
WHERE dept_id = 102;

GRANT SELECT ON hr_employee TO hr_team;

CREATE VIEW finance_employee_view AS
SELECT emp_id, emp_name, salary 
FROM employees;

GRANT SELECT ON finance_employee_view TO finance_team;


-- ============================================================================
-- PART 8: PRACTICAL SCENARIOS
-- ============================================================================

-- Exercise 8.1: Department Dashboard View
CREATE VIEW dept_dashboard AS
SELECT 
    d.dept_name,
    d.location,
    COUNT(DISTINCT e.emp_id) AS employee_count,
    ROUND(COALESCE(AVG(e.salary), 0), 2) AS avg_salary,
    COUNT(DISTINCT p.project_id) AS active_projects,
    COALESCE(SUM(DISTINCT p.budget), 0) AS total_project_budget,
    ROUND(
        CASE 
            WHEN COUNT(DISTINCT e.emp_id) = 0 THEN 0
            ELSE COALESCE(SUM(DISTINCT p.budget), 0) / COUNT(DISTINCT e.emp_id)
        END, 2
    ) AS budget_per_employee
FROM departments d
LEFT JOIN employees e ON d.dept_id = e.dept_id
LEFT JOIN projects p ON d.dept_id = p.dept_id
GROUP BY d.dept_id, d.dept_name, d.location;

-- Exercise 8.2: Audit View
ALTER TABLE projects 
ADD COLUMN created_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

CREATE VIEW high_budget_projects AS
SELECT 
    p.project_name,
    p.budget,
    d.dept_name,
    p.created_date,
    CASE 
        WHEN p.budget > 150000 THEN 'Critical Review Required'
        WHEN p.budget > 100000 THEN 'Management Approval Needed'
        ELSE 'Standard Process'
    END AS approval_status
FROM projects p
LEFT JOIN departments d ON p.dept_id = d.dept_id
WHERE p.budget > 75000;

-- Exercise 8.3: Create Access Control System
-- Level 1 - Viewer Role
CREATE ROLE viewer_role NOLOGIN;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO viewer_role;
GRANT SELECT ON ALL SEQUENCES IN SCHEMA public TO viewer_role;

-- Level 2 - Entry Role
CREATE ROLE entry_role NOLOGIN;
GRANT viewer_role TO entry_role;
GRANT INSERT ON employees, projects TO entry_role;

-- Level 3 - Analyst Role
CREATE ROLE analyst_role NOLOGIN;
GRANT entry_role TO analyst_role;
GRANT UPDATE ON employees, projects TO analyst_role;

-- Level 4 - Manager Role
CREATE ROLE manager_role NOLOGIN;
GRANT analyst_role TO manager_role;
GRANT DELETE ON employees, projects TO manager_role;

-- Create Users
CREATE ROLE alice WITH LOGIN PASSWORD 'alice123';
CREATE ROLE bob WITH LOGIN PASSWORD 'bob123';
CREATE ROLE charlie WITH LOGIN PASSWORD 'charlie123';

-- Assign Users to Roles
GRANT viewer_role TO alice;
GRANT analyst_role TO bob;
GRANT manager_role TO charlie;
