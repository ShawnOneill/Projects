-- ============================================================
-- THIS SQL FILE CONTAINS ITEMS TO BE RUN ONCE AND ITEMS TO BE RUN MULTIPLE TIMES. 
-- IT IS A BLUEPRINT FOR CLEANING DATA. IT IS NOT INTENDED TO BE RUN AS A SINGLE SCRIPT.
-- ============================================================

-- ============================================================
-- CREATE DATABASE AND TABLES
-- ============================================================
-- *** RUN ONCE SECTION ***

CREATE SCHEMA github;
USE github;

-- Creating tables with foreign key
CREATE TABLE employee (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(30),
    last_name VARCHAR(30),
    email VARCHAR(50),
    location VARCHAR(20)
);

CREATE TABLE job_info (
    id INT PRIMARY KEY,
    title VARCHAR(50),
    department VARCHAR(30),
    salary INT,
    date_of_hire DATE,
    bonus_count INT,
    office VARCHAR(30),
    FOREIGN KEY (id) REFERENCES employee(employee_id)
);

CREATE TABLE bulk_data_all (
    employee_id INT PRIMARY KEY,
    first_name VARCHAR(50),
    last_name VARCHAR(50),
    email VARCHAR(50),
    location VARCHAR(50),
    title VARCHAR(50),
    department VARCHAR(50),
    salary INT,
    date_of_hire VARCHAR(50),
    bonus_count INT,
    office VARCHAR(50)
);

CREATE TABLE clean_error_log (
    id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT,
    date_time DATETIME,
    table_n VARCHAR(20),
    error_field VARCHAR(20),
    _error VARCHAR(50)
);

-- *** END OF RUN ONCE SECTION ***

-- RAW DATA IMPORTED VIA PYTHON. See pythonUploadData.py.

--- *** AFTER INTIAL RUN STORED PROCEDURES ONLY NEED TO BE CALLED. ***

-- Created as stored procedure for copying the raw data into employee_stage and job_info_stage
DELIMITER $$

CREATE PROCEDURE create_stage_tables()
BEGIN

-- Changed data in raw data table to match job_info date column.
-- NOTE this assumes all data is m/d/Y or Y/m/d or m-d-Y or Y-m-d(the correct format). If the data is d/m/Y or d-m-Y it will not be corrected.
-- used CASE (simular to an if/elseif)
UPDATE bulk_data_all
SET date_of_hire =
    CASE
        -- m/d/Y (slashes)
        WHEN date_of_hire LIKE '%/%/%'
             AND NOT (SUBSTRING(date_of_hire, 1, 4) BETWEEN '0000' AND '9999')
        THEN DATE_FORMAT(STR_TO_DATE(date_of_hire, '%m/%d/%Y'), '%Y-%m-%d')
        -- Y/m/d (slashes)
        WHEN date_of_hire LIKE '%/%/%'
             AND  (SUBSTRING(date_of_hire, 1, 4) BETWEEN '0000' AND '9999')
        THEN DATE_FORMAT(STR_TO_DATE(date_of_hire, '%Y/%m/%d'), '%Y-%m-%d')
        -- m-d-Y (hyphens)
        WHEN date_of_hire LIKE '%-%-%'
             AND NOT (SUBSTRING(date_of_hire, 1, 4) BETWEEN '0000' AND '9999')
        THEN DATE_FORMAT(STR_TO_DATE(date_of_hire, '%m-%d-%Y'), '%Y-%m-%d')

        ELSE date_of_hire
    END;

    -- Drop existing stage tables
    DROP TABLE IF EXISTS job_info_stage;
	DROP TABLE IF EXISTS employee_stage;

    -- Create and populate employee_stage
    CREATE TABLE employee_stage LIKE employee;

    INSERT INTO employee_stage (employee_id, first_name, last_name, email, location)
    SELECT 
        employee_id,
        first_name,
        last_name,
        email,
        location
    FROM bulk_data_all;

    -- Create and populate job_info_stage
    CREATE TABLE job_info_stage LIKE job_info;

    INSERT INTO job_info_stage (
        id,
        title,
        department,
        salary,
        date_of_hire,
        bonus_count,
        office
    )
    SELECT 
        employee_id,
        title,
        department,
        salary,
        STR_TO_DATE(date_of_hire, '%Y-%m-%d'),
        bonus_count,
        office
    FROM bulk_data_all
    WHERE date_of_hire IS NOT NULL
      AND date_of_hire <> '';

END $$
DELIMITER ;

CALL create_stage_tables();

-- ============================================================
-- DATA CHECKING/CLEANING
-- ============================================================

DELIMITER $$

CREATE PROCEDURE check_data()
BEGIN
-- TODO rewrite procedure using UNIONs and REGEXP

-- Along with being a data validity log, I designed the clean_error_log as an audit trail 
-- to show the same errors if the client does not fix the errors on their side. 

-- Checking for invalid values in employee_stage
INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), employee_id, "employee_stage", "first_name", first_name FROM employee_stage
WHERE first_name IS NULL 
	OR first_name = '' 
    OR first_name LIKE "%;%" 
    OR first_name LIKE "%.%" 
	OR first_name LIKE "%,%" 
    OR first_name LIKE "%&%" 
    OR first_name LIKE "%@%";
    
INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), employee_id, "employee_stage", "last_name", last_name FROM employee_stage
WHERE last_name IS NULL 
	OR last_name = '' 
    OR last_name LIKE "%;%" 
    OR last_name LIKE "%.%" 
	OR last_name LIKE "%,%" 
    OR last_name LIKE "%&%" 
    OR last_name LIKE "%@%";

-- location refers to the state the employee lives in.
INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), employee_id, "employee_stage", "location", location FROM employee_stage
WHERE location IS NULL 
	OR location = '' 
	OR location LIKE "%;%" 
	OR location LIKE "%.%" 
	OR location LIKE "%,%" 
	OR location LIKE "%&%" 
	OR location LIKE "%@%";
    
INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
	SELECT now(), employee_id, "employee_stage", "email", email FROM employee_stage
	WHERE email not LIKE "%@%.%" 
	OR email IS NULL;
	

-- These searches found missing and null values in location,
-- missing, null and invalid values from email
-- first_name had all valid values, but last_name had a value with a ";" in it.
-- Also, checking for an "@" sign in the row before and after the email field
-- can reveal data corruption where a missing value has shifted all values to the right or left.

-- I don't know all the titles, departments so I just did null or '' checks for them.

INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), id, "job_info_stage", "title", title FROM job_info_stage
WHERE title IS NULL 
	OR title ="";

INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), id, "job_info_stage", "department", department FROM job_info_stage
WHERE department IS NULL 
	OR department = "";

INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), id, "job_info_stage", "office", office FROM job_info_stage
WHERE office IS NULL 
	OR office = ""
	OR office LIKE "%@%" 
	OR office LIKE "%.%" 
	OR office LIKE "%,%" 
	OR office LIKE "%&%";
	
-- the company started in April 1st 2010 so any date that was before then or after today would not be valid
INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), id, "job_info_stage", "date_of_hire", date_of_hire FROM job_info_stage
WHERE date_of_hire IS NULL  
	OR date_of_hire > CURRENT_DATE()
	OR date_of_hire < "2010-04-01";

INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), id, "job_info_stage", "bonus_count", bonus_count FROM job_info_stage
WHERE bonus_count IS NULL;

INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error) 
SELECT now(), id, "job_info_stage", "salary", salary FROM job_info_stage
WHERE salary IS NULL
	OR salary = 0;

-- this is syntax for MySQL 8+ 
INSERT INTO clean_error_log (date_time, employee_id, table_n, error_field, _error)
SELECT 
    NOW(),
    employee_id,
	"",
	"",
    "duplicate user"
FROM (
    SELECT 
        employee_id,
        ROW_NUMBER() OVER (
            PARTITION BY first_name, last_name, email, location
        ) AS row_num
    FROM employee_stage
) AS d
WHERE row_num > 1;

END $$
DELIMITER ;

CALL check_data();

-- UPDATES

-- TODO Investigate the feasibility of creating a trigger to update the clean_error_log, (might need to add a date field for when it was updated)
-- when an issue is resolved in the stage tables. (might need to add a date field for when it was resolved)

-- to clean up the values in the location and office fields I joined the employee_stage and job_info_stage tables
-- and copied the values from office where location was null and location where office was null, 
-- figuring they probably live in the state they work. 
-- I would usually NOT make that assumption, but for the sake of this project I did.
UPDATE employee_stage e 
	JOIN job_info_stage j 
	ON e.employee_id = j.id
	SET e.location = j.office
	WHERE e.location IS NULL OR e.location = "";

UPDATE job_info_stage j
	JOIN employee_stage e
	ON j.id = e.employee_id
	SET j.office = e.location
	WHERE j.office IS NULL OR j.office ="";

--- *** THIS SECTION PROVIDES EXAMPLES OF HOW TO MANUALLY UPDATE DATA IN THE STAGE TABLES. ***

-- manual updates from stored procedure findings
UPDATE employee_stage SET last_name = "Frenzel" -- originally "Frenzel,"
	WHERE employee_id = 883;
UPDATE employee_stage SET email = "achaster1@mozilla.com" -- originally achaster1.mozilla.com
	WHERE employee_id = 443;
UPDATE employee_stage SET email = "bovid3@ask.com" -- originally bovid3@ask,com
	WHERE employee_id = 445;
UPDATE employee_stage SET email = "rheart1b@cnn.com" -- originally rheart1b@cnncom
	WHERE employee_id = 489;
UPDATE employee_stage SET email = "nmalia9e@msn.com" -- originally nmalia9e.msn.com
	WHERE employee_id = 780;

-- for this project I decided to change the nulls to empty strings for the email field, 
-- but in a real world scenario I would probably want to check with HR to see if they could provide the missing data.	
UPDATE employee_stage SET email = ""
	WHERE employee_id IN (533, 606, 651, 874); -- changing nulls to empty

-- employee_id 447 and 448 are duplicates
-- after checking with HR there is no employee with an employee_id of 448
DELETE FROM job_info_stage WHERE id = 448;
DELETE FROM employee_stage WHERE employee_id = 448;

-- ============================================================
-- COPY CLEANED DATA TO PRODUCTION
-- ============================================================

-- stored procedure for copying cleaned data to prod tables
DELIMITER $$
CREATE PROCEDURE copy_to_prod()
BEGIN

INSERT INTO employee SELECT employee_id, first_name, last_name, email, location
FROM employee_stage es
WHERE NOT EXISTS (
    SELECT 1
    FROM employee e
    WHERE e.employee_id = es.employee_id
);

INSERT INTO job_info SELECT id, title, department, salary, date_of_hire, bonus_count, office
FROM job_info_stage js
WHERE NOT EXISTS (
    SELECT 1
    FROM job_info j
    WHERE j.id = js.id
);
END $$
DELIMITER ;

CALL copy_to_prod();
