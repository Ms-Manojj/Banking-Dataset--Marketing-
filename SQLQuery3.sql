select * from Banking_marketing


--check the how meny column and how meney row we have 

--Row
--45211

	select count(*)as Total_row from Banking_marketing

--Columns
--18
	SELECT COUNT(*) AS total_columns
	FROM information_schema.columns
	WHERE table_name = 'Banking_marketing';



--Need to make a age bucket and Total balane bucket
-- First will make a age bucket
-- Balance bucket

--1 > Here is min age is 18 and max age is 95 and avg age is = 40
-- 18 to 30, 31 to 45,46 to 60, 61 to 80 and 80 above

	select min(age) from Banking_marketing;
	select max(age) from Banking_marketing;
	select avg(cast(age as int))as avg_age from Banking_marketing;

--Need to create a new columns:

Alter table Banking_marketing
ADD  Age_bkt_slab Varchar(255);

--updating the columns here;
UPDATE y
SET y.Age_bkt_slab = x.Age_bkt_slab
FROM Banking_marketing y
JOIN (
    SELECT column1,
           CASE
               WHEN CAST(age AS INT) BETWEEN 18 AND 30 THEN '18 to 30'
               WHEN CAST(age AS INT) BETWEEN 31 AND 45 THEN '31 to 45'
               WHEN CAST(age AS INT) BETWEEN 46 AND 60 THEN '46 to 60'
               WHEN CAST(age AS INT) BETWEEN 61 AND 80 THEN '61 to 80'
               WHEN CAST(age AS INT) > 80 THEN '80 Above'
               ELSE 'Outlier'
           END AS Age_bkt_slab
    FROM Banking_marketing
) x ON y.column1 = x.column1;


select * from Banking_marketing


-- Balance bucket
--check the min,max and avg balance 

	select min(balance) from Banking_marketing;
	select max(balance) from Banking_marketing;
	select avg(cast(balance as int))as avg_age from Banking_marketing;

--Need to create a new columns:

Alter table Banking_marketing
ADD  Bal_btk Varchar(255);

--updating the columns here;
UPDATE y
SET y.Bal_btk = x.Bal_btk
FROM Banking_marketing y
JOIN (
    SELECT column1,
           CASE
               WHEN CAST(balance AS INT) BETWEEN 0 AND 500 THEN '0 to 500'
               WHEN CAST(balance AS INT) BETWEEN 501 AND 1000 THEN '501 to 1000'
               WHEN CAST(balance AS INT) BETWEEN 1001 AND 5000 THEN '1000 to 5000'
               WHEN CAST(balance AS INT) BETWEEN 5001 AND 10000 THEN '5000 to 10000'
               WHEN CAST(balance AS INT) > 10000 THEN '10000 Above'
               ELSE 'Outlier'
           END AS Bal_btk
    FROM Banking_marketing
) x ON y.column1 = x.column1;



select * from Banking_marketing

SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Banking_marketing';


-- i will solve 10 basic question 

--Q1- What is the average balance of customers grouped by their marital status? Additionally, 
--determine how many customers have a zero balance and what the variance is when including and excluding zero balances.

select top 10 * from Banking_marketing

--Use CTE
with x as(
		select marital,count(*)as Total_cust,round(avg(cast(balance as float)),2)as Avg_Balance_include_zero from Banking_marketing
		group by marital),
	y as(
		select marital,count(*)as Total_cust_above_zero,round(avg(cast(balance as float)),2)as Avg_Balance_exe_zero from Banking_marketing
		where balance >0
		group by marital) 
select x.marital,x.Total_cust,y.Total_cust_above_zero,(x.Total_cust - y.Total_cust_above_zero)as total_cust_zero_bal,
	   x.Avg_Balance_include_zero,y.Avg_Balance_exe_zero,
	   abs((x.Avg_Balance_include_zero - y.Avg_Balance_exe_zero))as Bal_variance  from x
	join y on x.marital=y.marital


--Q2-Which job type has the highest average campaign duration, and what is that duration?

select top 10 job,avg(cast(duration as float))as Avg_Duration,
		avg(case when Age_bkt_slab ='18 to 30' then cast(duration as float) end) '18 to 30',
		avg(case when Age_bkt_slab ='31 to 45' then cast(duration as float) end) '31 to 45',
		avg(case when Age_bkt_slab ='46 to 60' then cast(duration as float) end) '46 to 60',
		avg(case when Age_bkt_slab ='61 to 80' then cast(duration as float) end) '61 to 80',
		avg(case when Age_bkt_slab ='80 above' then cast(duration as float) end) '80 above'
		from Banking_marketing
group by job
order by Avg_Duration desc

--count wise

select top 10 job,avg(cast(duration as float))as Avg_Duration,
		count(case when Age_bkt_slab ='18 to 30' then cast(duration as float) end) '18 to 30',
		count(case when Age_bkt_slab ='31 to 45' then cast(duration as float) end) '31 to 45',
		count(case when Age_bkt_slab ='46 to 60' then cast(duration as float) end) '46 to 60',
		count(case when Age_bkt_slab ='61 to 80' then cast(duration as float) end) '61 to 80',
		count(case when Age_bkt_slab ='80 above' then cast(duration as float) end) '80 above'
		from Banking_marketing
group by job
order by Avg_Duration desc



--Q3-Find the correlation between having a housing loan and the average balance.

select * from Banking_marketing


WITH housing_balance AS (
    SELECT 
        CASE WHEN housing = 'yes' THEN 1 ELSE 0 END AS housing_loan,
        cast(balance as float)as balance
    FROM Banking_marketing
),
stats AS (
    SELECT 
        AVG(housing_loan) AS mean_housing,
        AVG(balance) AS mean_balance,
        COUNT(*) AS n
    FROM housing_balance
),
deviations AS (
    SELECT
        housing_loan,
        balance,
        (housing_loan - (SELECT mean_housing FROM stats)) AS dev_housing,
        (balance - (SELECT mean_balance FROM stats)) AS dev_balance
    FROM housing_balance
),
squares AS (
    SELECT
        dev_housing,
        dev_balance,
        (dev_housing * dev_housing) AS sq_dev_housing,
        (dev_balance * dev_balance) AS sq_dev_balance,
        (dev_housing * dev_balance) AS prod_dev_housing_balance
    FROM deviations
)
SELECT
    SUM(prod_dev_housing_balance) / 
    (SQRT(SUM(sq_dev_housing)) * SQRT(SUM(sq_dev_balance))) AS correlation
FROM squares


--Q4-Determine the percentage of customers in each job type who have taken a loan.

select * from Banking_marketing


WITH main AS (
    SELECT job, COUNT(*) AS total_cnt
    FROM Banking_marketing
    WHERE loan = 'yes'
    GROUP BY job
)
SELECT 
    main.*, 
    (main.total_cnt*100 /(SELECT SUM(main.total_cnt) FROM main)) AS total_percnt
FROM main
order by total_percnt desc


--Q5 Identify any significant trends or patterns in the campaign duration over different age groups.


WITH base_data AS (
    SELECT 
        day, 
        ROUND(sum(CAST(duration AS float)), 2) AS campaign_duration,
        sum(CASE WHEN Age_bkt_slab = '18 to 30' THEN CAST(duration AS float) END) AS "18 to 30",
        sum(CASE WHEN Age_bkt_slab = '31 to 45' THEN CAST(duration AS float) END) AS "31 to 45",
        sum(CASE WHEN Age_bkt_slab = '46 to 60' THEN CAST(duration AS float) END) AS "46 to 60",
        sum(CASE WHEN Age_bkt_slab = '61 to 80' THEN CAST(duration AS float) END) AS "61 to 80",
        sum(CASE WHEN Age_bkt_slab = '80 above' THEN CAST(duration AS float) END) AS "80 above"
    FROM Banking_marketing
    GROUP BY day
)
SELECT 
    day, 
    campaign_duration,
    "18 to 30",
    ROUND("18 to 30" / campaign_duration * 100, 2) AS "18 to 30 %",
    "31 to 45",
    ROUND("31 to 45" / campaign_duration * 100, 2) AS "31 to 45 %",
    "46 to 60",
    ROUND("46 to 60" / campaign_duration * 100, 2) AS "46 to 60 %",
    "61 to 80",
    ROUND("61 to 80" / campaign_duration * 100, 2) AS "61 to 80 %",
    "80 above",
    ROUND("80 above" / campaign_duration * 100, 2) AS "80 above %"
FROM base_data
ORDER BY day ASC;

--Q6 List all customers who are married and have a tertiary education.
--Here is a list of 7,000 customers who meet the above conditions.

select * from Banking_marketing
where marital='married' and education='tertiary'


--Q7 Count the number of customers who have a default status of 'no' and have a balance greater than 500.

SELECT count(*)as total_cnt
FROM Banking_marketing
WHERE "default" = 'no' AND balance > 500;


--Q8 Find the details of customers who have been contacted on the 5th of May and have a loan.

--	--Total customer count is = 215 who meet above condition
select count(*) from Banking_marketing	
where duration>0 and day='5' and y='yes'


--Q9 Retrieve the number of customers with an unknown job type who have a balance less than 100.
-- total 60 customer have meet the condition 

select  * from Banking_marketing
where job='unknown' and balance <100



--Q10 Select the records of customers who have been contacted more than once (campaign > 1) and their outcome was 'unknown'
--Total customer- 181 

select  count(*) from Banking_marketing
where job='unknown' and campaign >1


select * from Banking_marketing

