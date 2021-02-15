# Redshift

### Objetive

After completing this lab, you will know how to:

- Interpret the execution plan of your query in Redshift
- Define and use the Diststyle and Sortkey in your table
- Populate a table with data from AWS S3
- Compress data to improve query performance and efficiency in disk space usage


### Duration

This lab requires 20 minutes to complete.


### Overview

In this lab you will create and populate some tables to undertand how Redshift deal with data to resolve your query and return the result to you. You will understand the query plan of Redshift and then apply some modifications in the query to improve performance.


# Starting Lab

To complete this lab you need to be connected to VPN to access the needed resources.  
In your Workbench (you frequently use to access Redshift) create a new Redshift connection with the following credentials.  If you have already the configuration in your workbench from the last Lab you can skip this part.
  
**Host:** `bi-dafiti-group-dc2-dev.cofscmejxic8.us-east-1.redshift.amazonaws.com`


**Port:** `5439`


**Database:** `dftdwh_dev`


**User:** `datatrainning`


**Password:** `Training123`


# Task 1: Create and Populate

In this task you will first create the tables to test and populate them. You will populate the tables by getting data from AWS S3 using the `COPY` command. From the previous Labs you may remember about the command `UNLOAD`, you can use those 2 command to ingrate with S3.

- `UNLOAD`: Loads data from Redshift to S3
- `COPY`: Loads data from S3 to Redshift

Here you can find the documentation about [UNLOAD](https://docs.aws.amazon.com/redshift/latest/dg/r_UNLOAD.html) and [COPY](https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html) commands.

Run the script below to create and populate the tables. Analyze the script to better understand the commands if you want.

> Notice that you have some variables to replace in the script. Replace the variable `<your_name>` with your name or nickname, and replace the variable `<random>` wirth some random numbers. **Use only lower case letters and don't forget the random numbera because you will use it sometimes**

```sql
-- table DDL

create table staging.<your_name>_<random>_item_sold (
	  id_item bigint encode az64
	, fk_order bigint encode az64
	, fk_current_status bigint encode az64
	, current_status_date timestamp encode az64
	, order_date timestamp encode az64
	, item_price numeric(10, 2) encode az64
) distkey(fk_order) -- business key for this scenario. Can be used in join to improve performance
sortkey(order_date) -- good to use in where clause
;

create table staging.<your_name>_<random>_item_paid (
	   fk_item bigint encode az64
	 , fk_order bigint encode az64
	 , paid_date timestamp encode az64
) distkey(fk_order) -- business key for this scenario. Can be used in join to improve performance
sortkey(fk_item) -- good to use in join
;

-- this is a small table containing a list of a few status

create table staging.<your_name>_<random>_status (
	   id_status bigint encode az64
	 , status_name varchar(43) encode zstd
	 , status_description varchar(83) encode zstd
) diststyle all -- good for small tables
;

-- load the items sold
COPY staging.<your_name>_<random>_item_sold
FROM 's3://bi-dafiti-group-dev/dft-trainning/rs-lab/item_sold/'
iam_role 'arn:aws:iam::296025910508:role/dft-redshift-spectrum'
DELIMITER ';'
NULL AS '<NULL>'
ESCAPE
GZIP
REMOVEQUOTES
TIMEFORMAT 'YYYY-MM-DD HH:MI:SS'
STATUPDATE OFF
COMPUPDATE OFF
EXPLICIT_IDS
;

-- load the items paid
COPY staging.<your_name>_<random>_item_paid
FROM 's3://bi-dafiti-group-dev/dft-trainning/rs-lab/item_paid/'
iam_role 'arn:aws:iam::296025910508:role/dft-redshift-spectrum'
DELIMITER ';'
NULL AS '<NULL>'
ESCAPE
GZIP
REMOVEQUOTES
TIMEFORMAT 'YYYY-MM-DD HH:MI:SS'
STATUPDATE OFF
COMPUPDATE OFF
EXPLICIT_IDS
;

-- load the lsit of status
COPY staging.<your_name>_<random>_status
FROM 's3://bi-dafiti-group-dev/dft-trainning/rs-lab/status/'
iam_role 'arn:aws:iam::296025910508:role/dft-redshift-spectrum'
DELIMITER ';'
NULL AS '<NULL>'
ESCAPE
GZIP
REMOVEQUOTES
TIMEFORMAT 'YYYY-MM-DD HH:MI:SS'
STATUPDATE OFF
COMPUPDATE OFF
EXPLICIT_IDS
;
```

> **ENCODE:** You can notice in the `DDL` statements something different than usual, the `encode` keyword. What is that? It's a good practice to use encode in the columns when you create a table, this command compress the data of the column, this way the table needs less space to be stored and also improves query performance because Redshift can read data faster. Usually we use the compression encoding [az64](https://docs.aws.amazon.com/redshift/latest/dg/az64-encoding.html) for numerical data and dates (TIMESTAMP, DATE, BIGINT, INT, SMALLINT) and [zstd](https://docs.aws.amazon.com/redshift/latest/dg/zstd-encoding.html) for any other data type. See more about [encode](https://docs.aws.amazon.com/redshift/latest/dg/c_Compression_encodings.html) in the documentation.


# Task 2: The Execution Plan

Now you have the data in your tables let's understand how Redshift deal with data, to do so need to analyze the execution plan created by the database to run a query.
When you submit a query to Redshift, your code is analyzed and based on that a internal script is generated, this script contains information about the steps Redshift must take to execute your query the best way possible. This internal script is the execution plan, every time you submit a query a new execution plan is created.
The execution plan determine somethings like:

- The best possible join algorithm to use
- If needed, how data should be redistributed
- The best order of tables in `join` (yes, Redshift may change the order tables are joined internally)

The matter for us in this moment in the topic 2: data redistribution. You can see how data is redistributed in a query in the execution plan, but how can you get the execution plan? In your query use the command `explain`.

run the code below:

>  Rembember to replace the variables
```sql
explain
select
case when p.fk_item is null then 'NOT PAID' else 'PAID' end as is_paid
, count(s.id_item) as item_qty
, count(distinct s.fk_order) as order_qty
from staging.<your_name>_<random>_item_sold as s
left join staging.<your_name>_<random>_item_paid as p on p.fk_item = s.id_item
where 1=1
and date(s.order_date) = '2021-02-13'
group by 1
;
```
You should receive a messy output similar to this (the execution plan):

```
```
There are many information in this result, if you want to know the meaning of each element in this execution plan see the documentation about [EXPLAIN](https://docs.aws.amazon.com/redshift/latest/dg/r_EXPLAIN.html).

Let's find the information about data redistribution, Redshift may redistribute the inner table (`DS_DIST_INNER`, `DS_BCAST_INNER`, `DS_DIST_ALL_INNER`), the outer table (`DS_DIST_OUTER`), sometimes Redshift redistribute both tables in join (`DS_DIST_BOTH`) and sometimes no redistribution is needed (`DS_DIST_NONE`, `DS_DIST_ALL_NONE`). Probably you have one of those codes in your output, try to find it.

You can understand better the meaning of each type of redistribution [here](https://docs.aws.amazon.com/redshift/latest/dg/c_data_redistribution.html).

We always want to achieve `DS_DIST_NONE` and `DS_DIST_ALL_NONE`, if no redistribution is needed then the query will perform better.


**?Challenge:** Now based on the knowledge you have about `Diststyle` and `Sortkey` in Redshift, make the necessary changes in the query to improve performance and achieve `DS_DIST_NONE` in the execution plan. *The answear for this challenge is in the end of this lab, if you want you can go there and validate your solution :)*

# Task 3: Trying Different Join Combinations

In this quick task you will analyze a query to identify a different redistribution behavior.

```sql
explain
select
st.status_name
, date(s.order_date) as order_date
, count(s.id_item) as item_qty
, count(distinct s.fk_order) as order_qty
from staging.<your_name>_<random>_item_sold as s
inner join staging.<your_name>_<random>_status as st on st.id_status = s.fk_current_status
group by 1,2
;
```

Note the key your are using to join the tables, it's not a distkety but you don't have a redistribution. You have in your execution plan `DS_DIST_ALL_NONE`, it's because one of the tables has `Diststyle all`, tables with this distribution perform well in joins with tables using Diststyle `KEY` or `EVEN`.

**?Challenge:** Write a simple query joining the 3 tables you have created in this lab appling the best practices you have  learned. Count the items and orders grouped by current status and flag `is_paid` (you have to create this flag) filtering only 3 hours of a specific day, when you run the `explain` command no redistribution should be shown. *The answear for this challenge is in the end of this lab, if you want you can go there and validate your solution :)*

# Conclusion

You created some tables in Redshift defining Diststyle and sortkey, loaded data from S3 to populate your tables using the `COPY` command, compressed the data using the command `encode` to improve performance the storage, you analyzed the execution plan of your query and improved performance based on information about data redistribution. Congratulations!

You have successfuly learned how to:
- Use `copy` command to load data from S3 into Redshift
- Improve your query by compressing data
- Define and use Diststyle and Sortkey
- Interpret the execution plan of your query


# Challenges

## Challenge Solution Task 2

In the query below you can notice the suitable changes to improve performance.

> Always remember to replace the variables
```sql
explain
select
case when p.fk_item is null then 'NOT PAID' else 'PAID' end as is_paid
, count(s.id_item) as item_qty
, count(distinct s.fk_order) as order_qty
from staging.<your_name>_<random>_item_sold as s
left join staging.<your_name>_<random>_item_paid as p on p.fk_item = s.id_item and p.fk_order = s.fk_order
where 1=1
and s.order_date between '2021-02-13 00:00:00' and '2021-02-13 23:59:59'
group by 1
;
```

First of all the distkey of both tables has been added in the `join` statement, although the join is by the id of item the tables are distributed by the id of oder, this way you can use distkey to join tables of different granularities without producing cartesian product. When we use the Distkey in `join` we say where the data is stored and Redshift does not lost time rearranging the data.

The second change was the filter, now the column in the filer doesn't suffer any transformation, this way Redshift can use the power of Sortkey. Unfortunately there isn't a easy way to indentify performance improvement related to Sortkey in the execution plan because Redshift will only know what data blocks to skip in the runtime.


## Challenge Solution Task 3


If you run the query below you will notice that there isn't data redistribution, and it's so good.

> Always remember to replace the variables
```sql
explain
select
case when p.fk_item is null then 'NOT PAID' else 'PAID' end as is_paid
, st.status_name
, count(s.id_item) as item_qty
, count(distinct s.fk_order) as order_qty
from staging.<your_name>_<random>_item_sold as s
inner join staging.<your_name>_<random>_status as st on st.id_status = s.fk_current_status
left join staging.<your_name>_<random>_item_paid as p on p.fk_item = s.id_item and p.fk_order = s.fk_order
where 1=1
and s.order_date between '2021-02-13 18:00:00' and '2021-02-13 21:59:59'
group by 1,2
;
```

For the filter a random period of 3 hours was chosen, and the join was made based on the content covered in this Lab.