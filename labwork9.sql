-- ============================================================================
-- Laboratory Work 9: Stored Procedures & User-Defined Functions in PostgreSQL
-- Complete Executable SQL Script (Setup + Parts 2–7 + Written Answers)
-- ============================================================================

-- ============================================================================
-- PART 1: DATABASE SETUP
-- ============================================================================

DROP TABLE IF EXISTS rentals, bikes, members, stations CASCADE;

CREATE TABLE stations (
    station_id   INT PRIMARY KEY,
    station_name VARCHAR(50) NOT NULL,
    city         VARCHAR(40) NOT NULL,
    capacity     INT NOT NULL
);

CREATE TABLE bikes (
    bike_id    INT PRIMARY KEY,
    model      VARCHAR(50) NOT NULL,
    station_id INT REFERENCES stations(station_id),
    daily_rate NUMERIC(8,2) NOT NULL
);

CREATE TABLE members (
    member_id INT PRIMARY KEY,
    full_name VARCHAR(60) NOT NULL,
    city      VARCHAR(40) NOT NULL,
    joined_on DATE NOT NULL
);

CREATE TABLE rentals (
    rental_id  INT PRIMARY KEY,
    member_id  INT REFERENCES members(member_id),
    bike_id    INT REFERENCES bikes(bike_id),
    start_date DATE NOT NULL,
    end_date   DATE,
    fee        NUMERIC(8,2)
);

INSERT INTO stations VALUES
    (10, 'Central Park', 'Almaty',   4),
    (20, 'Riverside',    'Almaty',   3),
    (30, 'Expo Gate',    'Astana',   5),
    (40, 'Old Town',     'Shymkent', 2),
    (50, 'Depot',        'Astana',   0);

INSERT INTO bikes VALUES
    (101, 'City Cruiser', 10, 4.50),
    (102, 'City Cruiser', 10, 4.50),
    (103, 'Mountain X',   20, 7.00),
    (104, 'Mountain X',   30, 7.00),
    (105, 'Road Sprint',  30, 9.25),
    (106, 'Folding Mini', 40, 3.75),
    (107, 'Cargo Hauler', 20, 12.00),
    (108, 'Road Sprint',  10, 9.25);

INSERT INTO members VALUES
    (1, 'Aisha Nurlanova', 'Almaty',   DATE '2023-03-14'),
    (2, 'Daniyar Serik',   'Almaty',   DATE '2023-07-02'),
    (3, 'Marta Kowalski',  'Astana',   DATE '2024-01-20'),
    (4, 'Chen Wei',        'Astana',   DATE '2024-05-11'),
    (5, 'Omar Haddad',     'Shymkent', DATE '2024-09-30'),
    (6, 'Elena Petrova',   'Almaty',   DATE '2025-02-05');

INSERT INTO rentals VALUES
    (1,  1, 101, DATE '2024-04-05', DATE '2024-04-08', 13.50),
    (2,  1, 103, DATE '2024-06-11', DATE '2024-06-16', 35.00),
    (3,  1, 108, DATE '2025-02-02', DATE '2025-02-04', 18.50),
    (4,  1, 102, DATE '2025-05-20', DATE '2025-05-27', 31.50),
    (5,  2, 101, DATE '2024-05-01', DATE '2024-05-02', 4.50),
    (6,  2, 107, DATE '2024-11-15', DATE '2024-11-19', 48.00),
    (7,  2, 107, DATE '2025-03-08', DATE '2025-03-14', 72.00),
    (8,  3, 104, DATE '2024-02-14', DATE '2024-02-18', 28.00),
    (9,  3, 105, DATE '2024-08-03', DATE '2024-08-06', 27.75),
    (10, 3, 104, DATE '2025-01-09', DATE '2025-01-10', 7.00),
    (11, 3, 105, DATE '2025-06-01', DATE '2025-06-09', 74.00),
    (12, 4, 104, DATE '2024-07-19', DATE '2024-07-21', 14.00),
    (13, 4, 105, DATE '2025-04-12', DATE '2025-04-15', 27.75),
    (14, 4, 103, DATE '2025-07-23', DATE '2025-07-29', 42.00),
    (15, 5, 106, DATE '2024-10-05', DATE '2024-10-12', 26.25),
    (16, 5, 106, DATE '2025-01-18', DATE '2025-01-20', 7.50),
    (17, 5, 106, DATE '2025-08-14', DATE '2025-08-21', 26.25),
    (18, 2, 102, DATE '2025-09-02', DATE '2025-09-05', 13.50),
    (19, 1, 101, DATE '2025-10-10', NULL,              NULL),
    (20, 4, 108, DATE '2024-12-28', DATE '2025-01-03', 55.50),
    (21, 3, 103, DATE '2025-02-26', DATE '2025-03-02', 28.00),
    (22, 5, 104, DATE '2025-05-05', DATE '2025-05-08', 21.00);

SELECT (SELECT COUNT(*) FROM stations) AS stations,
       (SELECT COUNT(*) FROM bikes)    AS bikes,
       (SELECT COUNT(*) FROM members)  AS members,
       (SELECT COUNT(*) FROM rentals)  AS rentals;


-- ============================================================================
-- PART 2: YOUR FIRST FUNCTION
-- ============================================================================

-- Worked Example
CREATE OR REPLACE FUNCTION inc(val INTEGER) RETURNS INTEGER AS $$
DECLARE
    result INTEGER;
BEGIN
    result := val + 1;
    RETURN result;
END;
$$ LANGUAGE plpgsql;

SELECT inc(10);

-- Exercise 2.1: A function over one row
CREATE OR REPLACE FUNCTION rental_days(p_rental_id INT) RETURNS INT AS $$
DECLARE
    v_days INT;
BEGIN
    SELECT end_date - start_date
    INTO v_days
    FROM rentals
    WHERE rental_id = p_rental_id;

    RETURN v_days;
END;
$$ LANGUAGE plpgsql;

SELECT rental_days(2);
SELECT rental_days(11);
SELECT rental_days(19);
SELECT rental_days(999);
/* Answer 2.1:
   Both return NULL, but for different reasons:
   - rental_days(19) finds the row, but its end_date is NULL, so (NULL - start_date) evaluates to NULL.
   - rental_days(999) finds no matching row, so SELECT INTO leaves v_days at its default NULL value.
*/

-- Exercise 2.2: A function over many rows
CREATE OR REPLACE FUNCTION member_rental_count(p_member_id INT) RETURNS INT AS $$
DECLARE
    v_count INT;
BEGIN
    SELECT COUNT(*)
    INTO v_count
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_count;
END;
$$ LANGUAGE plpgsql;

SELECT member_rental_count(1);
SELECT member_rental_count(5);
SELECT member_rental_count(6);
SELECT member_rental_count(99);
/* Answer 2.2:
   COUNT(*) counts rows matching the filter; when no rows match (whether the member exists
   with zero rentals or does not exist at all), the count of matching rows is 0, never NULL.
*/

-- Exercise 2.3: Returning text
CREATE OR REPLACE FUNCTION station_city(p_station_id INT) RETURNS VARCHAR AS $$
DECLARE
    v_city VARCHAR;
BEGIN
    SELECT city
    INTO v_city
    FROM stations
    WHERE station_id = p_station_id;

    RETURN v_city;
END;
$$ LANGUAGE plpgsql;

SELECT station_city(30);
SELECT station_city(77);

-- Exercise 2.4: Using a function inside a query
SELECT rental_id,
       member_id,
       rental_days(rental_id) AS duration_days
FROM rentals
WHERE rental_days(rental_id) > 4
ORDER BY duration_days DESC;


-- ============================================================================
-- PART 3: PARAMETER MODES
-- ============================================================================

-- Exercise 3.1: IN parameters
CREATE OR REPLACE FUNCTION fee_with_discount(p_fee NUMERIC, p_percent NUMERIC)
RETURNS NUMERIC AS $$
BEGIN
    RETURN ROUND(p_fee * (1 - p_percent / 100.0), 2);
END;
$$ LANGUAGE plpgsql;

SELECT fee_with_discount(74.00, 15);

-- Exercise 3.2: OUT parameters
CREATE OR REPLACE FUNCTION member_stats(
    p_member_id INT,
    OUT rental_cnt INT,
    OUT total_fee NUMERIC,
    OUT last_start DATE)
AS $$
BEGIN
    SELECT COUNT(*)::INT,
           COALESCE(SUM(fee), 0),
           MAX(start_date)
    INTO rental_cnt, total_fee, last_start
    FROM rentals
    WHERE member_id = p_member_id;
END;
$$ LANGUAGE plpgsql;

SELECT member_stats(3);
SELECT * FROM member_stats(3);
SELECT * FROM member_stats(6);
/* Answer 3.2:
   - `SELECT member_stats(3);` returns a single composite/record column like `(5,164.75,2025-06-01)`.
   - `SELECT * FROM member_stats(3);` unpacks the OUT parameters into separate named columns
     (`rental_cnt`, `total_fee`, `last_start`), making it ideal inside larger queries (e.g., with LATERAL joins).
   - For member 6: rental_cnt = 0, total_fee = 0, last_start = NULL.
*/

-- Exercise 3.3: INOUT parameters
CREATE OR REPLACE FUNCTION apply_late_fee(INOUT p_fee NUMERIC) AS $$
BEGIN
    p_fee := p_fee + 5.00;
END;
$$ LANGUAGE plpgsql;

SELECT apply_late_fee(fee) FROM rentals WHERE rental_id = 1;
/* Answer 3.3:
   An INOUT parameter acts as both input and output; PostgreSQL automatically returns the final
   value of all OUT/INOUT parameters when the function exits, so RETURNS and RETURN are unnecessary.
*/

-- Exercise 3.4: VARIADIC parameters
CREATE OR REPLACE FUNCTION fee_summary(
    VARIADIC p_fees NUMERIC[],
    OUT total NUMERIC,
    OUT average NUMERIC,
    OUT largest NUMERIC)
AS $$
BEGIN
    SELECT SUM(p_fees[i]),
           ROUND(AVG(p_fees[i]), 2),
           MAX(p_fees[i])
    INTO total, average, largest
    FROM generate_subscripts(p_fees, 1) g(i);
END;
$$ LANGUAGE plpgsql;

SELECT * FROM fee_summary(13.50, 35.00, 18.50, 31.50);
/* Answer 3.4:
   - Calling `fee_summary()` with zero arguments fails with `ERROR: function fee_summary() does not exist`
     because a VARIADIC array requires at least one element unless given a DEFAULT value.
   - VARIADIC must be last because it greedily consumes all remaining positional arguments of that type;
     parameters after it could never be reached.
*/

/* Answer 3.5: Choosing a mode
   (a) IN — The caller supplies an identifier solely for lookup and expects no modification back.
   (b) INOUT — The caller passes an existing value in and expects the updated value returned in the same variable.
   (c) VARIADIC — Allows the caller to pass an arbitrary number of comma-separated station IDs that get packed into an array.
   (d) OUT — Multiple output parameters allow a single function execution to return two distinct values cleanly.
*/


-- ============================================================================
-- PART 4: DEFAULT VALUES AND FUNCTION OVERLOADING
-- ============================================================================

-- Exercise 4.1: A function with one parameter
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1);
SELECT total_fees(6);

-- Exercise 4.2: Overloading the name
CREATE OR REPLACE FUNCTION total_fees(p_member_id INT, p_from_date DATE)
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees(1, DATE '2024-01-01');
SELECT total_fees(1, DATE '2025-01-01');

SELECT proname, pg_get_function_identity_arguments(oid) AS args
FROM pg_proc
WHERE proname = 'total_fees';

-- Exercise 4.3: Giving a parameter a default value
CREATE OR REPLACE FUNCTION total_fees(
    p_member_id INT,
    p_from_date DATE DEFAULT DATE '2025-01-01')
RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(fee), 0)
    INTO v_total
    FROM rentals
    WHERE member_id = p_member_id
      AND start_date >= p_from_date;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

-- Wrapped in DO block so script continues cleanly while capturing the exact error:
DO $$
BEGIN
    PERFORM total_fees(1);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ex 4.3 Error: % | Hint: %', SQLERRM, pg_exception_detail();
END $$;
/* Answer 4.3:
   Exact Error:
   ERROR:  function total_fees(integer) is not unique
   LINE 1: SELECT total_fees(1);
                  ^
   HINT:  Could not choose a best candidate function. You might need to add explicit type casts.
   Explanation: Both `total_fees(integer)` and `total_fees(integer, date DEFAULT ...)` match a single
   integer argument equally well, creating an unresolvable ambiguity.
*/

-- Exercise 4.4: Resolving the ambiguity
DROP FUNCTION total_fees(INTEGER);
SELECT total_fees(1);
/* Answer 4.4:
   - `total_fees(integer, date)` now answers the call using its default `2025-01-01` date, returning `50.00`.
   - Dropping the two-argument version instead would have left `total_fees(integer)`, which sums all years
     and would have returned `98.50`.
*/

-- Exercise 4.5: Overloading on type, not just on count
CREATE OR REPLACE FUNCTION total_fees(p_member_name VARCHAR) RETURNS NUMERIC AS $$
DECLARE
    v_total NUMERIC;
BEGIN
    SELECT COALESCE(SUM(r.fee), 0)
    INTO v_total
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.full_name = p_member_name;

    RETURN v_total;
END;
$$ LANGUAGE plpgsql;

SELECT total_fees('Aisha Nurlanova');
SELECT total_fees(1);
/* Answer 4.5:
   - No ambiguity occurs because VARCHAR and INTEGER are distinct, non-conflicting input types.
   - `total_fees('Aisha Nurlanova')` calls `total_fees(character varying)` and sums all rentals across all dates (98.50).
   - `total_fees(1)` calls `total_fees(integer, date)` with the default cut-off `2025-01-01`, summing only 2025+ rentals (50.00).
*/


-- ============================================================================
-- PART 5: FUNCTIONS THAT RETURN A TABLE
-- ============================================================================

-- Exercise 5.1: Search by pattern
CREATE OR REPLACE FUNCTION find_bikes(p_pattern VARCHAR)
RETURNS TABLE(found_id INT, found_model VARCHAR, found_rate NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model, daily_rate
    FROM bikes
    WHERE model ILIKE p_pattern
    ORDER BY bike_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM find_bikes('%road%');
SELECT * FROM find_bikes('%Mini');
SELECT find_bikes('%road%');
/* Answer 5.1:
   Calling `SELECT find_bikes('%road%');` without `FROM` returns a single column of composite record
   values (e.g., `(105,"Road Sprint",9.25)`) instead of separate unpacked columns because the function
   is evaluated in the SELECT target list rather than as a table source in the FROM clause.
*/

-- Exercise 5.2: A table from a join
CREATE OR REPLACE FUNCTION member_history(p_member_id INT)
RETURNS TABLE(
    rental_id INT,
    bike_model VARCHAR,
    station_name VARCHAR,
    duration_days INT,
    fee NUMERIC)
AS $$
BEGIN
    RETURN QUERY
    SELECT r.rental_id,
           b.model,
           s.station_name,
           (r.end_date - r.start_date) AS duration_days,
           r.fee
    FROM rentals r
    JOIN bikes b ON b.bike_id = r.bike_id
    JOIN stations s ON s.station_id = b.station_id
    WHERE r.member_id = p_member_id
    ORDER BY r.start_date;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM member_history(3);

-- Exercise 5.3: When the column names collide
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE(bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY SELECT bike_id, model FROM bikes WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    PERFORM * FROM bike_list(10);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ex 5.3 Error: %', SQLERRM;
END $$;
/* Answer 5.3:
   Error: `column reference "bike_id" is ambiguous`
   It appears only at call time because PostgreSQL validates `CREATE FUNCTION` syntax lightly and only
   compiles/plans the embedded SQL query upon first execution.
*/

-- Fix 1: Rename output columns
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE(out_bike_id INT, out_model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT bike_id, model
    FROM bikes
    WHERE station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Fix 2: Keep output names and qualify table columns with an alias
DROP FUNCTION bike_list(INT);
CREATE OR REPLACE FUNCTION bike_list(p_station_id INT)
RETURNS TABLE(bike_id INT, model VARCHAR) AS $$
BEGIN
    RETURN QUERY
    SELECT b.bike_id, b.model
    FROM bikes b
    WHERE b.station_id = p_station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM bike_list(10);

-- Exercise 5.4: Casting the output
-- Demonstrating uncast error first:
CREATE OR REPLACE FUNCTION station_board_bad(p_city VARCHAR)
RETURNS TABLE(s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id),
           s.capacity - COUNT(b.bike_id)
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
    PERFORM * FROM station_board_bad('Almaty');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ex 5.4 Error: %', SQLERRM;
END $$;
DROP FUNCTION station_board_bad(VARCHAR);
/* Answer 5.4:
   Error: `structure of query does not match function result type`
   Detail: `Returned type bigint does not match expected type integer in column 2.`
*/

-- Corrected version with explicit ::INT casts:
CREATE OR REPLACE FUNCTION station_board(p_city VARCHAR)
RETURNS TABLE(s_name VARCHAR, s_bikes INT, s_free INT) AS $$
BEGIN
    RETURN QUERY
    SELECT s.station_name,
           COUNT(b.bike_id)::INT,
           (s.capacity - COUNT(b.bike_id))::INT
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.city = p_city
    GROUP BY s.station_id, s.station_name, s.capacity
    ORDER BY s.station_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM station_board('Almaty');


-- ============================================================================
-- PART 6: BLOCK STRUCTURE, DO BLOCKS AND SUBBLOCKS
-- ============================================================================

-- Exercise 6.1: An anonymous block
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
BEGIN
    SELECT COUNT(*) INTO total_rentals FROM rentals;
    RAISE NOTICE 'The rentals table holds % rows.', total_rentals;
END rental_report $$;
/* Answer 6.1:
   If the closing label after END does not match the opening label, PostgreSQL raises a syntax error:
   `ERROR: end label "wrong_name" differs from block's label "rental_report"`.
*/

-- Exercise 6.2: A subblock and a hidden variable
DO $$
<<rental_report>>
DECLARE
    total_rentals INTEGER := 0;
    fee_total     NUMERIC := 0;
BEGIN
    SELECT COUNT(*), COALESCE(SUM(fee), 0)
    INTO total_rentals, fee_total
    FROM rentals;

    RAISE NOTICE '1. Outer fee_total before subblock: %', fee_total;

    DECLARE
        fee_total NUMERIC := 0;
    BEGIN
        SELECT COALESCE(SUM(fee), 0)
        INTO fee_total
        FROM rentals
        WHERE start_date >= DATE '2025-01-01';

        RAISE NOTICE '2. Subblock fee_total (2025+): %', fee_total;
        RAISE NOTICE '3. Outer fee_total via label: %', rental_report.fee_total;
    END;

    RAISE NOTICE '4. Outer fee_total after subblock: %', fee_total;
END rental_report $$;
/* Answer 6.2:
   The four values printed are: 625.25, 365.75, 625.25, and 625.25.
   The assignment inside the subblock did NOT change the outer variable because declaring `fee_total`
   inside the subblock created a separate local variable that shadowed the outer variable.
*/

-- Exercise 6.3: Declarations are local
-- Demonstrating scope error when reading subblock 1's variable from subblock 2:
DO $$
BEGIN
    DECLARE
        sub1_var INT := 42;
    BEGIN
        RAISE NOTICE 'Subblock 1 sees: %', sub1_var;
    END;

    BEGIN
        EXECUTE format('SELECT %s', sub1_var);
    EXCEPTION WHEN OTHERS THEN
        RAISE NOTICE 'Ex 6.3 Error: %', SQLERRM;
    END;
END $$;
/* Answer 6.3:
   Error: `column "sub1_var" does not exist` (a subblock's variables are destroyed when that subblock exits).
*/

-- Moving the declaration up into the outer block so both subblocks can see it:
DO $$
DECLARE
    shared_var INT := 42;
BEGIN
    BEGIN
        RAISE NOTICE 'Subblock 1 sees shared_var: %', shared_var;
        shared_var := shared_var + 8;
    END;

    BEGIN
        RAISE NOTICE 'Subblock 2 sees updated shared_var: %', shared_var;
    END;
END $$;

-- Exercise 6.4: From a block to a function
CREATE OR REPLACE FUNCTION fee_split(
    p_from_date DATE,
    OUT before_total NUMERIC,
    OUT after_total NUMERIC)
AS $$
BEGIN
    SELECT COALESCE(SUM(fee) FILTER (WHERE start_date < p_from_date), 0),
           COALESCE(SUM(fee) FILTER (WHERE start_date >= p_from_date), 0)
    INTO before_total, after_total
    FROM rentals;
END;
$$ LANGUAGE plpgsql;

SELECT *, (before_total + after_total) AS combined_total
FROM fee_split(DATE '2025-01-01');


-- ============================================================================
-- PART 7: PRACTICAL SCENARIOS
-- ============================================================================

-- Exercise 7.1: Station occupancy
CREATE OR REPLACE FUNCTION station_load(
    p_station_id INT,
    OUT bikes_parked INT,
    OUT capacity_pct NUMERIC)
AS $$
DECLARE
    v_capacity INT;
BEGIN
    SELECT s.capacity, COUNT(b.bike_id)::INT
    INTO v_capacity, bikes_parked
    FROM stations s
    LEFT JOIN bikes b ON b.station_id = s.station_id
    WHERE s.station_id = p_station_id
    GROUP BY s.capacity;

    IF v_capacity IS NULL OR v_capacity = 0 THEN
        capacity_pct := NULL;
    ELSE
        capacity_pct := ROUND((bikes_parked::NUMERIC / v_capacity) * 100, 1);
    END IF;
END;
$$ LANGUAGE plpgsql;

SELECT s.station_id, s.station_name, l.*
FROM stations s, LATERAL station_load(s.station_id) l;
/* Answer 7.1:
   For station 50 (capacity = 0), returning NULL for `capacity_pct` is the cleanest choice because
   occupancy percentage is mathematically undefined when capacity is zero (whereas 0.0% would falsely
   imply available dock space).
*/

-- Exercise 7.2: Top members, with a default
CREATE OR REPLACE FUNCTION top_members(p_limit INT DEFAULT 3)
RETURNS TABLE(member_name VARCHAR, rental_cnt INT, total_spent NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0) AS total_spent
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    GROUP BY m.member_id, m.full_name
    ORDER BY total_spent DESC, m.member_id
    LIMIT p_limit;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM top_members();
SELECT * FROM top_members(6);
/* Answer 7.2:
   Aisha Nurlanova has 5 rentals (4 closed + 1 open) compared to Daniyar Serik's 4 rentals, yet
   Aisha ranks below Daniyar ($98.50 vs. $138.00). This is not a bug because the ranking orders
   by total amount spent (`total_spent DESC`), and Daniyar rented expensive Cargo Hauler bikes.
*/

-- Exercise 7.3: An invoice for an open rental
CREATE OR REPLACE FUNCTION rental_invoice(p_rental_id INT)
RETURNS TABLE(
    member_name VARCHAR,
    bike_model VARCHAR,
    days INT,
    amount_owed NUMERIC,
    status VARCHAR)
AS $$
BEGIN
    RETURN QUERY
    SELECT m.full_name,
           b.model,
           (COALESCE(r.end_date, CURRENT_DATE) - r.start_date)::INT AS days,
           ROUND((COALESCE(r.end_date, CURRENT_DATE) - r.start_date) * b.daily_rate, 2) AS amount_owed,
           CASE WHEN r.end_date IS NULL THEN 'OPEN'::VARCHAR ELSE 'CLOSED'::VARCHAR END AS status
    FROM rentals r
    JOIN members m ON m.member_id = r.member_id
    JOIN bikes b ON b.bike_id = r.bike_id
    WHERE r.rental_id = p_rental_id;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM rental_invoice(11);
SELECT * FROM rental_invoice(19);
/* Answer 7.3:
   - For rental 11, the calculated amount (74.00) matches the stored fee exactly.
   - For open rental 19, `end_date` is NULL, so `CURRENT_DATE` is used; each passing day increases
     the elapsed day count and therefore the amount owed.
   - Because its output depends on `CURRENT_DATE` (which changes over time for the same input),
     the function CANNOT be marked `IMMUTABLE` (at most `STABLE`).
*/

-- Exercise 7.4: A report per city
CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR)
RETURNS TABLE(member_cnt INT, rental_cnt INT, total_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r ON r.member_id = m.member_id
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION city_report(p_city VARCHAR, p_from_date DATE)
RETURNS TABLE(member_cnt INT, rental_cnt INT, total_revenue NUMERIC) AS $$
BEGIN
    RETURN QUERY
    SELECT COUNT(DISTINCT m.member_id)::INT,
           COUNT(r.rental_id)::INT,
           COALESCE(SUM(r.fee), 0)
    FROM members m
    LEFT JOIN rentals r
           ON r.member_id = m.member_id
          AND r.start_date >= p_from_date
    WHERE m.city = p_city;
END;
$$ LANGUAGE plpgsql;

SELECT * FROM city_report('Almaty');
SELECT * FROM city_report('Almaty', DATE '2025-01-01');
/* Answer 7.4:
   The date condition MUST go in the `ON` clause of the `LEFT JOIN`.
   - In the `ON` clause: Almaty has 3 members (Elena Petrova has 0 rentals and is preserved).
   - In the `WHERE` clause: `r.start_date >= p_from_date` turns the outer join into an inner join
     by filtering out NULL-extended rows, dropping Almaty's member count from 3 to 2.
*/


-- ============================================================================
-- LAB QUESTIONS (1–10)
-- ============================================================================
/*
1. Name vs. Signature:
   A function's name is just its identifier (e.g., `total_fees`), whereas its signature is the
   combination of its name and its ordered input parameter data types (e.g., `total_fees(integer, date)`).
   Because overloaded functions share the same name, PostgreSQL requires the signature in `DROP FUNCTION`
   to know unambiguously which overload to remove.

2. Dollar Quoting ($$):
   Dollar quoting delimits string literals without requiring internal single quotes to be escaped
   (`''`). Without `$$`, writing SQL string literals inside a function body becomes messy, e.g.:
   `'SELECT * FROM stations WHERE city = ''Almaty'''` instead of `$$SELECT * FROM stations WHERE city = 'Almaty'$$`.

3. Multiple OUT Parameters vs. RETURNS TABLE:
   Use `OUT` parameters when returning a single composite row (or scalar values) without needing a table
   result set. Use `RETURNS TABLE(...)` when returning zero, one, or many rows (a set-returning function)
   directly from a `RETURN QUERY`.

4. Why VARIADIC Must Be Last:
   VARIADIC collects all trailing positional arguments of the same type into an array. If another parameter
   followed it—e.g., `fn(VARIADIC a INT[], b INT)`—a call like `fn(1, 2, 3)` could never determine whether
   `3` belongs to `a` or `b`.

5. RETURN vs. RETURN QUERY:
   `RETURN expr;` immediately exits a scalar function and hands back a single value. `RETURN QUERY SELECT ...;`
   appends the rows produced by a query to a set-returning function's output buffer without immediately
   exiting the function.

6. DEFAULT Parameter Ambiguity:
   Adding a `DEFAULT` to an `N`-parameter overload allows it to be called with `N-1` arguments, colliding
   with an existing `(N-1)`-parameter overload. In production, avoid maintaining separate overloads whose
   argument prefixes overlap with defaulted parameters—either use one function with defaults or drop the
   shorter overload cleanly during migration.

7. Subblock Variable Lifetime & Shadowing:
   When a subblock ends, any variables declared in its `DECLARE` section go out of scope and are
   destroyed. While inside the subblock, a shadowed variable from an outer block can still be read or
   assigned by qualifying it with the outer block's label (`outer_label.var_name`).

8. Stored Function Trade-offs:
   - Advantage: Centralizes business rules in the database so every client application shares identical
     logic with fewer network round trips.
   - Disadvantage: Harder to version-control, unit-test, and horizontally scale than stateless application code.

9. Trusted vs. Untrusted Languages:
   A trusted language (like PL/pgSQL) runs inside a sandbox with no access to the OS filesystem or network,
   so regular database users with `USAGE` privilege can create functions in it. An untrusted language
   (like PL/PythonU or C) has unrestricted OS access, so only database superusers may create functions in it.

10. Changing Argument Types with CREATE OR REPLACE FUNCTION:
    `CREATE OR REPLACE` only replaces a function if its name and input argument types match an existing
    signature. Changing argument types silently creates a *new overloaded function* alongside the old one,
    leaving stale code in the catalog and potentially causing ambiguous-call errors.
*/
```[cite: 1, 2, 3, 4, 5, 6, 7, 8, 9]
