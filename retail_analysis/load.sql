-- Create and load customers
DROP TABLE customers;
CREATE TABLE customers (
    customer_id         int,
    customer_fname      string,
    customer_lname      string,
    customer_email      string,
    customer_password   string,
    customer_street     string,
    customer_city       string,
    customer_state      string,
    customer_zipcode    string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

load data local inpath '/tmp/customers.txt' into table customers;

-- Create and load departments
DROP TABLE departments;
CREATE TABLE departments (
    department_id       int,
    department_name     string)
ROW FORMAT DELIMITED FIELDS TERMINATED BY '\t'
STORED AS TEXTFILE;

load data local inpath '/tmp/departments.txt' into table departments;
