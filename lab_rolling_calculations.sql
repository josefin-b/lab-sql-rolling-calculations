--  Lab | SQL Rolling calculations --

-- In this lab, you will be using the Sakila database of movie rentals.
use sakila;
#SET sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));

-- 1 Get number of monthly active customers.

drop view if exists active_customers; 
create view active_customers as
select customer_id,
convert(rental_date, date) as activity_date,
date_format(convert(rental_date,date), '%M') as activity_month,
date_format(convert(rental_date,date), '%m') as activity_month_nr,
date_format(convert(rental_date,date), '%Y') as activity_year
from sakila.rental;

select * from active_customers;


drop view if exists monthly_active_customers; 
create view monthly_active_customers as
select activity_year, activity_month, activity_month_nr, count(customer_id) as nr_of_active_customers from active_customers
group by activity_year, activity_month
order by activity_year asc, activity_month_nr asc;

select * from monthly_active_customers;


-- 2 Active users in the previous month.

with cte_activity as (
  select nr_of_active_customers, lag(nr_of_active_customers, 1) over (order by activity_year, activity_month_nr) as active_last_month, activity_year, activity_month
  from monthly_active_customers
)
select * from cte_activity
where active_last_month is not null;


-- 3 Percentage change in the number of active customers.

with cte_activity_percentage as (
  select nr_of_active_customers, lag(nr_of_active_customers, 1) over (order by activity_year, activity_month_nr) as active_last_month, activity_year, activity_month
  from monthly_active_customers
)
select *, round(((nr_of_active_customers - active_last_month) / nr_of_active_customers * 100), 2) as percentage_variation from cte_activity_percentage
where active_last_month is not null;


-- 4 Retained customers every month.

drop view if exists distinct_customers;
create view distinct_customers as
select distinct customer_id as active_id, activity_year, activity_month, activity_month_nr from active_customers;

select * from distinct_customers;

drop view if exists retained_customers;
create view retained_customers as 
select
	d1.activity_year,
    d1.activity_month,
    d1.activity_month_nr,
    count(d1.active_id) as retained_customers
from distinct_customers as d1
join distinct_customers as d2
on d1.active_id = d2.active_id
and d2.activity_month_nr = d1.activity_month_nr + 1
group by d1.activity_year, d1.activity_month_nr
order by d1.activity_year, d1.activity_month_nr;

select * from retained_customers;
