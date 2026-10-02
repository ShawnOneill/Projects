create schema pdms;
use pdms;
create table customers(
	customer_id int primary key auto_increment, 
	first_name varchar(20), 
	last_name varchar(30), 
	email varchar(30), 
	phone varchar(20), 
	company varchar(30)
);