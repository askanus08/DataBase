-- Table 1: employees
CREATE TABLE employees (
    employee_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    department VARCHAR(50),
    salary NUMERIC(10,2),
    hire_date DATE,
    manager_id INTEGER,
    email VARCHAR(100)
);

-- Table 2: projects
CREATE TABLE projects (
    project_id SERIAL PRIMARY KEY,
    project_name VARCHAR(100),
    budget NUMERIC(12,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);

-- Table 3: assignments
CREATE TABLE assignments (
    assignment_id SERIAL PRIMARY KEY,
    employee_id INTEGER REFERENCES employees (employee_id),
    project_id INTEGER REFERENCES projects (project_id),
    hours_worked NUMERIC(5,1),
    assignment_date DATE
);

-- ==========================================
-- INSERT SAMPLE DATA
-- ==========================================

-- Insert into employees
INSERT INTO employees (first_name, last_name, department, salary, hire_date, manager_id, email) VALUES
('John', 'Smith', 'IT', 75000, '2020-01-15', NULL, 'john.smith@company.com'),
('Sarah', 'Johnson', 'IT', 65000, '2020-03-20', 1, 'sarah.j@company.com'),
('Michael', 'Brown', 'Sales', 55000, '2019-06-10', NULL, 'mbrown@company.com'),
('Emily', 'Davis', 'HR', 60000, '2021-02-01', NULL, 'emily.davis@company.com'),
('Robert', 'Wilson', 'IT', 70000, '2020-08-15', 1, NULL),
('Lisa', 'Anderson', 'Sales', 58000, '2021-05-20', 3, 'lisa.a@company.com');

-- Insert into projects
INSERT INTO projects (project_name, budget, start_date, end_date, status) VALUES
('Website Redesign', 150000, '2024-01-01', '2024-06-30', 'Active'),
('CRM Implementation', 200000, '2024-02-15', '2024-12-31', 'Active'),
('Marketing Campaign', 80000, '2024-03-01', '2024-05-31', 'Completed'),
('Database Migration', 120000, '2024-01-10', NULL, 'Active');

-- Insert into assignments
INSERT INTO assignments (employee_id, project_id, hours_worked, assignment_date) VALUES
(1, 1, 120.5, '2024-01-15'),
(2, 1, 95.0, '2024-01-20'),
(1, 4, 80.0, '2024-02-01'),
(3, 3, 60.0, '2024-03-05'),
(5, 2, 110.0, '2024-02-20'),
(6, 3, 75.5, '2024-03-10');

-- ==========================================
-- PART 1: BASIC SELECT QUERIES
-- ==========================================

-- Task 1.1: Select all employees with concatenated full name, department, and salary.
SELECT
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM employees;

-- Task 1.2: Unique departments in the company.
SELECT DISTINCT
    department
FROM employees;

-- Task 1.3: Projects with budget_category based on budget amounts.
SELECT
    project_name,
    budget,
    CASE
        WHEN budget > 150000 THEN 'Large'
        WHEN budget BETWEEN 100000 AND 150000 THEN 'Medium'
        ELSE 'Small'
    END AS budget_category
FROM projects;

-- Task 1.4: Employee names and emails with COALESCE for NULL values.
SELECT
    first_name || ' ' || last_name AS full_name,
    COALESCE(email, 'No email provided') AS email
FROM employees;


-- PART 2: WHERE CLAUSE AND COMPARISON OPERATORS

-- Task 2.1: Find all employees hired after January 1, 2020.
SELECT *
FROM employees
WHERE hire_date > '2020-01-01';

-- Task 2.2: Find all employees whose salary is between 60000 and 70000 using BETWEEN.
SELECT *
FROM employees
WHERE salary BETWEEN 60000 AND 70000;

-- Task 2.3: Find all employees whose last name starts with 'S' or 'J' using LIKE.
SELECT *
FROM employees
WHERE last_name LIKE 'S%' OR last_name LIKE 'J%';

-- Task 2.4: Find all employees who have a manager and work in the IT department.
SELECT *
FROM employees
WHERE manager_id IS NOT NULL
  AND department = 'IT';


-- PART 3: STRING AND MATHEMATICAL FUNCTIONS

-- Task 3.1: Uppercase names, length of last names, and first 3 characters of email.
SELECT
    UPPER(first_name || ' ' || last_name) AS uppercase_name,
    LENGTH(last_name) AS last_name_length,
    SUBSTRING(email FROM 1 FOR 3) AS email_prefix
FROM employees;

-- Task 3.2: Annual salary, monthly salary (rounded to 2 decimal places), and 10% raise amount.
SELECT
    first_name || ' ' || last_name AS full_name,
    salary AS annual_salary,
    ROUND(salary / 12, 2) AS monthly_salary,
    ROUND(salary * 0.10, 2) AS raise_amount_10_percent
FROM employees;

-- Task 3.3: Formatted string for each project using format().
SELECT
    FORMAT('Project: %s Budget: $%s Status: %s', project_name, budget, status) AS project_info
FROM projects;

-- Task 3.4: Years each employee has been with the company.
SELECT
    first_name || ' ' || last_name AS full_name,
    hire_date,
    EXTRACT(YEAR FROM AGE(CURRENT_DATE, hire_date)) AS years_with_company
FROM employees;


-- PART 4: AGGREGATE FUNCTIONS AND GROUP BY

-- Task 4.1: Average salary for each department.
SELECT
    department,
    ROUND(AVG(salary), 2) AS avg_salary
FROM employees
GROUP BY department;

-- Task 4.2: Total hours worked on each project, including project name.
SELECT
    p.project_name,
    SUM(a.hours_worked) AS total_hours_worked
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name;

-- Task 4.3: Departments with more than 1 employee using HAVING.
SELECT
    department,
    COUNT(*) AS employee_count
FROM employees
GROUP BY department
HAVING COUNT(*) > 1;

-- Task 4.4: Maximum salary, minimum salary, and total payroll.
SELECT
    MAX(salary) AS max_salary,
    MIN(salary) AS min_salary,
    SUM(salary) AS total_payroll
FROM employees;

-- ==========================================
-- PART 5: SET OPERATIONS
-- ==========================================

-- Task 5.1: Combine queries using UNION.
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000

UNION

SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE hire_date > '2020-01-01';


-- Task 5.2: Employees in IT AND with salary > 65000 using INTERSECT.
SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE department = 'IT'

INTERSECT

SELECT employee_id, first_name || ' ' || last_name AS full_name, salary
FROM employees
WHERE salary > 65000;


-- Task 5.3: Employees NOT assigned to any projects using EXCEPT.
SELECT employee_id, first_name || ' ' || last_name AS full_name
FROM employees

EXCEPT

SELECT DISTINCT e.employee_id, e.first_name || ' ' || e.last_name AS full_name
FROM employees e
JOIN assignments a ON e.employee_id = a.employee_id;


-- ==========================================
-- PART 6: SUBQUERIES
-- ==========================================

-- Task 6.1: Employees with at least one project assignment using EXISTS.
SELECT 
    e.employee_id,
    e.first_name || ' ' || e.last_name AS full_name,
    e.department
FROM employees e
WHERE EXISTS (
    SELECT 1 
    FROM assignments a 
    WHERE a.employee_id = e.employee_id
);


-- Task 6.2: Employees working on projects with status 'Active' using IN.
SELECT 
    employee_id,
    first_name || ' ' || last_name AS full_name,
    department
FROM employees
WHERE employee_id IN (
    SELECT a.employee_id
    FROM assignments a
    JOIN projects p ON a.project_id = p.project_id
    WHERE p.status = 'Active'
);


-- Task 6.3: Employees with salary greater than ANY employee in Sales using ANY.
SELECT 
    employee_id,
    first_name || ' ' || last_name AS full_name,
    department,
    salary
FROM employees
WHERE salary > ANY (
    SELECT salary
    FROM employees
    WHERE department = 'Sales'
);


-- ==========================================
-- PART 7: COMPLEX QUERIES
-- ==========================================

-- Task 7.1: Employee details, average assigned hours, and salary rank within department.
SELECT 
    e.first_name || ' ' || e.last_name AS full_name,
    e.department,
    e.salary,
    ROUND(AVG(a.hours_worked), 2) AS avg_hours_worked,
    DENSE_RANK() OVER (PARTITION BY e.department ORDER BY e.salary DESC) AS dept_salary_rank
FROM employees e
LEFT JOIN assignments a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, e.first_name, e.last_name, e.department, e.salary;


-- Task 7.2: Projects where total hours worked exceeds 150 hours.
SELECT 
    p.project_name,
    SUM(a.hours_worked) AS total_hours,
    COUNT(DISTINCT a.employee_id) AS num_assigned_employees
FROM projects p
JOIN assignments a ON p.project_id = a.project_id
GROUP BY p.project_id, p.project_name
HAVING SUM(a.hours_worked) > 150;


-- Task 7.3: Department summary report with GREATEST / LEAST usage.
SELECT 
    department,
    COUNT(employee_id) AS total_employees,
    ROUND(AVG(salary), 2) AS avg_salary,
    MAX(salary) AS highest_salary,
    -- Using GREATEST and LEAST to demonstrate boundary evaluation on max/min metrics
    GREATEST(MAX(salary), 50000) AS adjusted_department_cap,
    LEAST(MIN(salary), 60000) AS floor_salary_metric
FROM employees
GROUP BY department;
