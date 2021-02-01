# Creating a Simple ETL Process


### Objectives

After completing this lab, you will know how to:

- Do a simple ETL with SQL from user input file
- Deal with some files formart
- Create an automated ETL pocess with Glove
- Create a simple data pipeline in Hanger

### Duration

This lab requires 40 minutes to complete.

### Overview

In this lab you will create and run ETL processes extracting from 2 different sources to load into our data lake (AWS S3). During the execution the data will be converted to parquet* files so you can have a standardized way to query the data via Redshift Spectrum. First you will manually run an ETL to make clear the concept and then in Hanger you will create a job to configure a Glove process.
  
> ***Parquet*** is a columnar file format widely used to store data in data lake instead of using others common file formats such as csv or json. As parquet is columnar (read data by column) you can achieve best query performance and cost reduction in the end of month by applying good practices.

> Another commum columnar file format similar to ***Parquet*** is the file format ***ORC***.

  
# Starting Lab
  
To complete this lab you need to be connected to VPN to access the needed resources.  
In your Workbench (you frequently use to access Redshift) create a new Redshift connection with the following credentials.  
  
**Host:** `bi-dafiti-group-dc2-dev.cofscmejxic8.us-east-1.redshift.amazonaws.com`


**Port:** `5439`


**Database:** `dftdwh_dev`


**User:** `datatrainning`


**Password:** `Training123`
  
  
  
# Task 1: Manual ETL process
  
In this task you will manually run an ETL to make clear the fundamental concept. You will manipulate the data stored in our S3 data lake using Redshift and Redshift Spectrum. You will convert CSV to Parquet and apply some treatments in the data.

### Preparing for the process

There is a compressed CSV file named `nps_origin_type.csv.gz` stored in the following S3 bucket path `s3://bi-dafiti-group-dev/dft-trainning/etl-lab/raw-data/`.
Below there is a sample of the data in this CSV file:

```
origin;desc_type;last_record_date
success-page;Custos de frete;21-DEC-2020
success-page;Disponibilidad de talles;21-DEC-2020
success-page;Informações sobre produto;14-MAY-2019
success-page;Outros;21-DEC-2020
success-page;Avaliação de produtos;24-APR-2018
success-page;Eficiência do atendimento;15-MAY-2019
API;Descrição de produtos BemVindo10;11-APR-2018
success-page;Calidad del paquete;02-JUL-2020
email;Tempo de troca/devolução;21-DEC-2020
```

Now in Redshift you will create an external table through `Redshift Spectrum` pointing to the file in S3.
Run the query bellow.
> Note there are some variables in the query you must change, replace ${YOUR_NAME} with your name ou nick name, and replace ${RANDOM} with some random numbers. **Use only lower case letters and don't forget the random number because you will use it sometimes**

```sql
create external table spc_staging.${YOUR_NAME}_${RANDOM}_raw_nps_origin_type (
	origin varchar(25),
	desc_type varchar(60),
	last_record_date varchar(11)
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ';' -- specify the csv file delimiter
STORED AS textfile -- specify the generic type of file (it also could be ORC, PARQUET, etc)
LOCATION 's3://bi-dafiti-group-dev/dft-trainning/etl-lab/raw-data/' -- specify the S3 path where files are stored
TABLE PROPERTIES ('skip.header.line.count'='1') -- define some properties of the table. In this case the property specify to skip the first line (header) of the csv file
;
```

You can query your table to view a sample of data:

```sql
select * from spc_staging.${YOUR_NAME}_${RANDOM}_raw_nps_origin_type limit 100;
```

You can notice that the data could look better, so now you will apply some treatments to do so. Now you can query the CSV file you are able to **E**xtract, **T**ransform and **L**oad the data.

### Running an ETL Process

what you will do in this step:

- **Extract:**
	- Query the external table to read the CSV file
- **Transform:**
	- Covert data to Parquet and apply some functions for transformation
	- Add a new field named `description_group` to improve organization and categorization
- **Load:** 
	- Save the new converted file back to S3 and point a new table to the treated data

Run the script bellow, it's your ETL process:
> Note there are some variables in the query you must change, you can analyze the query before running it.

```sql
create table #transformation
as
	 select
	 case when origin in('success-page', 'API') then 'SUCCESS PAGE'
		 when origin = 'email' then 'EMAIL' else 'UNKNOWN' end as origin
	 , translate(coalesce(upper(desc_type), 'UNKNOWN'), 'ÁÉÍÓÚÀÈÌÒÙÂÊÎÔÛÃÕÄËÏÖÜÇÑŸÝ', 'AEIOUAEIOUAEIOUAOAEIOUCNYY') as description_type
	 , to_char(to_date(last_record_date, 'DD-MON-YYYY'), 'YYYY-MM-DD 00:00:00') as last_record_date
	 -- new field
	 , case
	 when description_type in('RAPIDEZ DO ATENDIMENTO', 'ATENDIMENTO', 'CORDIALIDADE DO ATENDIMENTO', 'EFICIENCIA DO ATENDIMENTO', 'ATENCION AL PUBLICO') then 'CUSTOMER SERVICE'
	 when description_type in('FOTOS') then 'PICTURES'
	 when description_type in('ACOMPANHAMENTO DO PEDIDO/ENTREGA', 'ACOMPANHAMENTO DO PEDIDO', 'RASTREAMENTO DA ENTREGA', 'SEGUIMIENTO DE PEDIDO') then 'ORDER TRACKING'
	 when description_type in('ACOMPANHAMENTO DA TROCA/DEVOLUCAO', 'SEGUIMIENTO DE CAMBIO Y DEVOLUCION') then 'REVERSE TRACKING'
	 when description_type in('AVALIACAO DE PRODUTOS') then 'PRODUCT RATING'
	 when description_type in('CALIDAD DEL PAQUETE', 'QUALIDADE DA EMBALAGEM') then 'PACKAGE QUALITY'
	 when description_type in('CALIDAD DEL PRODUCTO', 'QUALIDADE DO PRODUTO') then 'PRODUCT QUALITY'
	 when description_type in('CAMPO DE BUSCA') then 'SEARCH BAR'
	 when description_type in('DESCRICAO DE PRODUTOS', 'DESCRICAO DE PRODUTOS BEMVINDO10', 'DETALLES DE PRODUCTO', 'INFORMACION SOBRE PRODUCTOS', 'INFORMACOES SOBRE PRODUTO', 'INFORMACOES SOBRE PRODUTOS') then 'PRODUCT DESCRIPTION'
	 when description_type in('DISPONIBILIDADE DE TAMANHOS', 'DISPONIBILIDAD DE TALLES', 'DISPONIBILIDAD DE TALLAS') then 'SIZE AVAILABILITY'
	 when description_type in('FACILIDAD PARA ENCONTRAR PRODUCTOS', 'FACILIDADE EM ENCONTRAR PRODUTOS') then 'EASY TO FIND PRODUCTS'
	 when description_type in('FILTROS') then 'FILTERS'
	 when description_type in('OPCIONES DE ENVIO', 'OPCOES DE FRETE', 'COSTO DE ENVIO', 'COSTOS DE ENVIO', 'CUSTOS DE FRETE') then 'FREIGHT'
	 when description_type in('OTROS', 'OUTROS') then 'OTHERS'
	 when description_type in('MARKETPLACE (PRODUTOS VENDIDOS E ENTREGUES POR PARCEIROS)') then 'MARKETPLACE'
	 when description_type in('NAVEGACAO NO SITE/ APLICATIVO', 'VELOCIDAD DE NAVEGACION', 'VELOCIDADE DE NAVEGACAO', 'CARREGAMENTO DO APP', 'CARREGAMENTO DAS PAGINAS DO SITE') then 'NAVIGATION'
	 when description_type in('PRECIOS', 'PRECIOS/PROMOCIONES', 'PREÇO DO PRODUTO', 'PRECOS/PROMOCOES', 'PRECO DO PRODUTO') then 'PRICE'
	 when description_type in('SEGURANCA DO PAGAMENTO', 'SEGURIDAD EN EL PAGO', 'FORMAS DE PAGAMENTO', 'MEDIOS DE PAGO', 'PAGAMENTO') then 'PAYMENT'
	 when description_type in('TIEMPO DE ENTREGA', 'TEMPO DE ENTREGA', 'PRAZO DE ENTREGA', 'PLAZO DE ENTREGA', 'PONTUALIDADE DA ENTREGA') then 'DELIVERY'
	 when description_type in('TEMPO DE TROCA/DEVOLUCAO', 'TIEMPO DE CAMBIO Y DEVOLUCION', 'TROCAS E DEVOLUCOES') then 'REVERSE'
	 when description_type in('VARIEDAD DE PRODUCTOS/MARCAS', 'VARIEDADE DE PRODUTOS/MARCAS') then 'VARIETY OF PRODUCTS AND BRANDS'
	 when description_type in('PRAZOS DE REEMBOLSO') then 'REFUND'
	 else coalesce(description_type, 'UNKNOWN') end as description_group
	 from spc_staging.${YOUR_NAME}_${RANDOM}_raw_nps_origin_type
;

-- send result data from query to S3
UNLOAD ( 'SELECT
origin
, description_type
, description_group
, max(last_record_date) as last_record_date
FROM #transformation
group by 1,2,3' )
TO 's3://bi-dafiti-group-dev/dft-trainning/etl-lab/${YOUR_NAME}/${RANDOM}/' -- s3 path destination
iam_role 'arn:aws:iam::296025910508:role/dft-redshift-spectrum'
FORMAT AS PARQUET -- write parquet file
ALLOWOVERWRITE
PARALLEL OFF
;
```

Now you just have to create an external table pointing to the file you just loaded to S3 and then you can query the treated data.

```sql
create external table spc_staging.${YOUR_NAME}_${RANDOM}_nps_origin_type (
	origin varchar(25),
	description_type varchar(60),
	description_group varchar(80),
	last_record_date varchar(19)
)
STORED AS PARQUET -- specify the type of file
LOCATION 's3://bi-dafiti-group-dev/dft-trainning/etl-lab/${YOUR_NAME}/${RANDOM}/' -- specify the S3 path where files are stored
;
```

If you did not get any error, you can now query your parquet file and see your treated data.

```sql
select * from spc_staging.${YOUR_NAME}_${RANDOM}_nps_origin_type limit 100;
```

# Task 2: Easy ETL with Glove

In this task you will create a Job in Hanger Data Orchestration and set an ETL process using Glove Data Integration. Hanger helps the process of creating a job using Glove so much easier.

Hanger works together with Glove to manage all processes flow to ensure execution order, data validation and more.

You will extract the data from NPS system to be able to see the the customer rating.

### Accessing Hanger

1. Open the link below to access Hanger application:
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

2. In the left side bar click `Login` in the lower part.

3. Log In with using the following credentials:


**username:** `data.trainning`


**password:** `vkQL4`

Now you should see the home page listing some `Subjects`.

### Create a Subject

Before creating the Job you will explore some features of Hanger. One of them is the `Subject`, you can create Subjects as a easy and fast way to find and access your jobs because it will be listed in the home page for you.

1. In the left side bar, click in the arow down icon in `Subject` and then click `Add Subject`

2. In the first field `Subject name` type your name to be easy to find later

3.  Click `Save`, the subject will be added

### Create a Job and Cofigure ETL

Now you will create your ETL Job and organize in the Subject you have just created.

1. In the left side bar, click in the arrow down icon in `Job` and then click `Add Job`

2. In the top part of the page click `Create`

3. In the field `Template` make sure the selected value is `TEMPLATE_EMPTY`

4. in the field `Name` name as `Trial-Trainning-${YOUR_NAME}-Glove_raw_nps_feedback` (don't forget to replace the variable)

5.  Click `>> Next`

6. In the bottom of the page click in the arrow up icon in `Shell Script` and select the option `SHELL_TEMPLATE-GLOVE-DATABASE-TRAINNING`

7. In the field `Source Table Name` type `nps_feedback` 
(name of the table in the source database)

8.  Set `Target` to `spectrum` 
(*Target* is the destination storage)

9. Set `Output Table Schema` to `spc_staging` 
(destination schema for the extracted data)

10.  Set `Output Table Name` to `raw_nps_feedback_${YOUR_NAME}_${RANDOM}`. Dont't forget to change de variables*
(destination table for the extracted data)

11. Set `Connection name` to `raw_nps` 
(connection reference to access source database)

12. Set `Source Table Schema` to `public` 
(schema name in source database)

The others fields you can keep the default value:
**Storage Bucket:** Define the S3 bucket where the data will be stored
**Output Format:** Define the file format to write in S3, the default is parquet
**Dataset Name:** Define the database name in Redshift
 **Delta Field:** When we create an ETL process, we can not extract all data from source every type the process runs, we should do it once and in the next times we extract only the new and updated data. To do so we define a field of the table to be base to extract only the needed data, usually the field is the `updated_at`

13. Click `Add`, then it should add a shell script with values you inserted.
This script runs a Glove process and execute an ETL.

14. In the end of the page click `Subject`, select the subject you created and click `Add`

15. In the end of the page click `Save` and then click `Build`

Now your ETL job will be queued and executed, it may take a time to run and you can press `F5` to upate the page and validate the current job status. Your job may pass by 3 status:

*`Building` or `Rebuilding`:* Means your Job is queued and waiting to run (the Job wait in the queue because of server limitation or dependecies block)
*`Running`:* Means your Job is current in execution
*`Success`:* Means your Job completed without any error

> If your job receive any other different status you can click in the `?` icon in right side of the screen to see the description of each status.

After the job has completed you can try to query the table you extracted

```sql
select * from spc_staging.raw_nps_feedback_${YOUR_NAME}_${RANDOM} limit 100;
```


# Task 3: Automate process in Hanger

In this task you will apply a new configuration to automate your ETL Job, and you will achieve this by adding another Job as dependency to your process. You can add several dependencies to your job, in Hanger the dependencies are treated as `Parents`.

### Add Parent

1. Go to Hanger's home page by clicking `Monitor` in the left navigation bar

2. Click in the name of Subject you created and it should list your Job

3. Click in the `Flow` button

4.  Right click in your Job, go to `= Actions` > `+ Parent`, click `DEV`

5. in the field `Jobs` find and select the job named `DATA-TRAINNING-ETL-GLOVE_raw_trigger_05hr`. Click `Add`


You have just added a Job trigger to run automatically your ETL Job, you will notice that a new Job is connected to yours. Now your Job will be fired daily at 5 a.m by the trigger.


# Conclusion

You used Redshift and Redshift Spectrum to deal with some file formarts and run a simple ETL. You have successfully created your own ETL process using Glove and managed with Hanger by setting the necessary parameters to extract data from a system database to load into our data lake. Congratulations!

You have successfully learned how to:

- Read files in S3 with Redshift Spectrum
- Write files to S3 with Redshift
- Create a Subject in Hanger to organize your Jobs
- Create and configure an ETL process with Glove
- Add Parents to your Job for automation

Glove has many possibilies to be explored, you can find the documentation in [GitHub](https://github.com/dafiti-group/glove). Avaliable only in portuguese currently.