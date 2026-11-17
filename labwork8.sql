-- Part 1: Database Setup
CREATE TABLE departments (
    dept_id INT PRIMARY KEY,
    dept_name VARCHAR(50),
    location VARCHAR(50)
);

CREATE TABLE employees (
    emp_id INT PRIMARY KEY,
    emp_name VARCHAR(100),
    dept_id INT,
    salary DECIMAL(10,2),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
    proj_id INT PRIMARY KEY,
    proj_name VARCHAR(100),
    budget DECIMAL(12,2),
    dept_id INT,
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT', 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);


-- Part 2: Creating Basic Indexes
-- Exercise 2.1
CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

-- Answer 2.1: 2 indexes exist on the employees table (employees_pkey created automatically for the PRIMARY KEY, and emp_salary_idx).

-- Exercise 2.2
CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;

-- Answer 2.2: Indexing foreign keys speeds up JOIN operations between parent and child tables, accelerates queries filtering by the foreign key, and prevents full table scans on the child table when updating or deleting rows in the parent table.

-- Exercise 2.3
SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Answer 2.3: All indexes: departments_pkey, emp_dept_idx, emp_salary_idx, employees_pkey, projects_pkey. Automatically created: departments_pkey, employees_pkey, and projects_pkey (from PRIMARY KEY constraints).


-- Part 3: Multicolumn Indexes
-- Exercise 3.1
CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

-- Answer 3.1: No (or very inefficiently). PostgreSQL B-tree multicolumn indexes rely on the leftmost prefix rule; because dept_id is the leading column, filtering solely by salary cannot efficiently traverse the index tree from the root.

-- Exercise 3.2
CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);

SELECT * FROM employees WHERE dept_id = 102 AND salary > 50000;
SELECT * FROM employees WHERE salary > 50000 AND dept_id = 102;

-- Answer 3.2: Yes, column order matters significantly. The index is sorted first by the leading column and then by subsequent columns. Put equality-filtered columns first and range-filtered columns second, or place the most frequently queried standalone column first.


-- Part 4: Unique Indexes
-- Exercise 4.1
ALTER TABLE employees ADD COLUMN email VARCHAR(100);
UPDATE employees SET email = 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

-- Intentional error test (uncomment to run):
-- INSERT INTO employees (emp_id, emp_name, dept_id, salary, email)
-- VALUES (6, 'New Employee', 101, 55000, 'john.smith@company.com');

-- Answer 4.1: ERROR: duplicate key value violates unique constraint "emp_email_unique_idx" DETAIL: Key (email)=(john.smith@company.com) already exists.

-- Exercise 4.2
ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

-- Answer 4.2: Yes, PostgreSQL automatically created a UNIQUE B-tree index named employees_phone_key.


-- Part 5: Indexes and Sorting
-- Exercise 5.1
CREATE INDEX emp_salary_desc_idx ON employees(salary DESC);

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

-- Answer 5.1: Since the index entries are already stored in descending order, PostgreSQL can read the data directly in sequence from the index without performing an expensive in-memory or disk sort operation.

-- Exercise 5.2
CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT proj_name, budget
FROM projects
ORDER BY budget NULLS FIRST;


-- Part 6: Indexes on Expressions
-- Exercise 6.1
CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';

-- Answer 6.1: Without this expression index, PostgreSQL would have to perform a Sequential Scan (full table scan), computing LOWER(emp_name) for every single row in the table.

-- Exercise 6.2
ALTER TABLE employees ADD COLUMN hire_date DATE;
UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;


-- Part 7: Managing Indexes
-- Exercise 7.1
ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

-- Exercise 7.2
DROP INDEX emp_salary_dept_idx;

-- Answer 7.2: Unused or redundant indexes consume unnecessary disk space and slow down write operations (INSERT, UPDATE, DELETE) because PostgreSQL must update every index whenever table data changes.

-- Exercise 7.3
REINDEX INDEX employees_salary_index;


-- Part 8: Practical Scenarios
-- Exercise 8.1
CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;
-- (emp_dept_idx and emp_salary_desc_idx are already created)

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

-- Exercise 8.2
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT proj_name, budget
FROM projects
WHERE budget > 80000;

-- Answer 8.2: A partial index only indexes rows matching the WHERE condition, making it much smaller in disk size, faster to scan, and causing zero maintenance overhead when modifying rows outside the condition.

-- Exercise 8.3
EXPLAIN SELECT * FROM employees WHERE salary > 52000;

-- Answer 8.3: On this tiny 5-row table, it typically shows "Seq Scan". This tells us that the PostgreSQL query planner estimates reading a single small data page sequentially is faster than reading both the index and the heap page.


-- Part 9: Index Types Comparison
-- Exercise 9.1
CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);

SELECT * FROM departments WHERE dept_name = 'IT';

-- Answer 9.1: Use a HASH index when you only ever perform simple equality comparisons (=) on large values (like long URLs or UUIDs) and never need range queries (<, >, BETWEEN) or sorting (ORDER BY).

-- Exercise 9.2
CREATE INDEX proj_name_btree_idx ON projects(proj_name);
CREATE INDEX proj_name_hash_idx ON projects USING HASH (proj_name);

SELECT * FROM projects WHERE proj_name = 'Website Redesign';
SELECT * FROM projects WHERE proj_name > 'Database';


-- Part 10: Cleanup and Best Practices
-- Exercise 10.1
SELECT
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

-- Answer 10.1: Hash indexes (such as dept_name_hash_idx or proj_name_hash_idx) are typically the largest (often 32 kB vs 8 kB or 16 kB for B-tree) because PostgreSQL pre-allocates metadata, bitmap, and initial bucket pages for hash structures.

-- Exercise 10.2
DROP INDEX IF EXISTS proj_name_hash_idx;

-- Exercise 10.3
CREATE VIEW index_documentation AS
SELECT
    tablename,
    indexname,
    indexdef,
    'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE '%salary%';

SELECT * FROM index_documentation;
