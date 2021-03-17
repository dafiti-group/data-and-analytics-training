
# Data Pipeline


### Objectives

After completing this lab, you will know how to:

- Use git version tool
- Create a Named Query process using Glove query module
- Deploy a Named Query process
- Create a data pipeline in Hanger

### Duration

This lab requires 40 minutes to complete.


### Prerequisites

You need an specific software installed in your machine to be able to complete this lab property.
We will use git version tool.

- For Windows you can access [here](https://gitforwindows.org/) to download and install.

- For linux you can run the following command to install

```shell
sudo apt-get install git
```

You also need to have an account in github platform, if necessary you can create your account by clicking [here](https://github.com/join).

I recommend you to use your commercial e-mail to register to github.


### Overview

- **Git** is a version tool that can be used to track all changes in your projects, you can have many version of a file and manage all changes.

- **Glove** is a data integration tool, we can use to create ETL jobs, automate SQL script executions and more. In this lab we will be using one specific module of Glove: Module query.

- **Hanger** is service for workflow orchestration, it help us automate, manage, organize and validate our jobs and workflows.


  
# Starting Lab
  
In this Lab you will use git version tool to control and isolate your modifications in a git repository (we will be using [github](https://github.com/)). You will create a Named Query process and deploy using git to run in Hanger with Glove using the Module query. In Hanger you create a Health Check to validate the integrity of your process.

In your Named Query process you will create a simple fact table for sales combining some configuration attributes.
  
  
# Task 1: Preparing the Environment
  
In this task you will start by setting the a git repository to deploy your NQ (Named Query), open `Git bash` installed in your windows system or open the terminal if you are using linux and make sure you are in the home folder of your user. You can validate running the following command:

```shell
pwd
```

You should get an output similar to this:

```
/home/<your.username>
```

or similar to this:
```
/c/users/<your.username>
```

If your output is not similar to the above examples you can try to fix by running the following command:

```shell
cd ~
```



### 1.1 Configure your Github account

The repository we are going to use in the Lab has a security level that requires to be accessed with SSH protocol, so you need to generate a SSH key to set in your github account, if you already have a SSH key setted up to your account you can skip this step and go to `1.2`.

To do so, run the following command:

```shell
ssh-keygen
```

Then press `ENTER` 3 times until you get an output similar to the text below:

```
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:kabvg85odSLc+yTsjoCz8JDR++WbDxRF5fGlmRXlWbg root@9c19732b1a1c
The key's randomart image is:
+---[RSA 3072]----+
|       .o.o   ++o|
|       . o o *..o|
|      . + . =  o.|
| .     + .    E  |
|. .. .o S        |
| + .oo+..        |
|* o  o==o        |
|.= o.Bo*.        |
|. ..+oO++.       |
+----[SHA256]-----+
```

Now we need to get the generated key to configure in Github, to print the key in your terminal run the following command:

```shell
cat ~/.ssh/id_rsa.pub
```

Then copy the output result.

Go to Github, go to `settings`:

![github-menu](https://user-images.githubusercontent.com/57373602/106788267-c94c1700-6661-11eb-9c0f-9fa94136376a.png) 

In the left navigation bar find and select `SSH and GPG Keys`, click in the green button `New SSH key`

![set shh](https://user-images.githubusercontent.com/57373602/106793741-e33d2800-6668-11eb-9deb-fd64b14f8521.png)

It will open a text area, in the field `key` past the value you copied from command line and click `Add SSH key`.

Now you have a SSH key configured in your account for security.


### 1.2 Cloning the repository

Let's create a folder to host the cloned repository, run the command below:

> **Important:** Depending on the configuration of your computer and the program installed, the `Documents` folder may appear in another language in the git terminal as in the command below that is in English, check in which language git is identifying the folders and make changes to the command if necessary. To identify the correct folder name (`Documents` or` Documentos`) use the `ls -l` command to list the folders in your current directory and find the documents folder.

```shell
mkdir -p Documents/training_repo;cd Documents/training_repo;pwd
```

Notice now you are inside a different directory, this is where we are going to clone the repository to develop the NQ.

Now open our public github repository available in the following [link (data-and-analytics-training)](https://github.com/dafiti-group/data-and-analytics-training). Click in the green button `Code`, select `SSH` and copy the link that sould be similar to this: `git@github.com:dafiti-group/data-and-analytics-training.git`.

Back to terminal run the git command to download the repository to your local machine.

> Replace <copied_link> with the link you copied from github

```shell
git clone <copied_link>
```
By running the command below, you can see a new folder was created

```shell
ls -l
```

Now a copy of the repository was created for you. Navigate inside the new folder with the command below:

```shell
cd data-and-analytics-training
```

### 1.3 Target folder

Before start creating the NQ we need to create an isolated area in the recently cloned repository to avoid conflicts with someone modifications.  To do so you will create a branch. Create a branch with your name:

```shell
git branch <your.name>
```
Now you created at branch, you must navigate inside it to keep all your development isolated, to do so, run the command:

```shell
git switch <your.name>
```

Now you are inside your new branch. Lastly you will create a folder in your branch  to store the NQ you will create:

> in the <your.name|random> variable write your name and add some random numbers to avoid name conflicts in the repository. **Save the value of this variable, you will need this later.**

```shell
mkdir -p training/platform/<your.name|random>
```

> To list all available branchs in your repository run the command `git branch` 

# Task 2: Create Named Query

In this task you will set some NQ steps to to create a fact table in Data Lake (the ideal would be to create in the Data Warehouse, but for didactic purposes we will use a different approach). You will extract data from Athena and model the table in Redshift, you will know in practice how each scope of named query works.

Open your preferred text editor and create a file with the following query:

> **Note:** there are 2 variables in this query but you don't need to replace it, you will set the value of the variables in Glove parameters

```sql
select
  soi.id_sales_order_item 					as src_fk_sale_order_store_item
, so.id_sales_order 						as src_fk_sale_order_store
, cast(so.order_nr as bigint) 				as sale_order_store_number
, so.created_at								as sale_order_store_date
, soi.paid_price							as gross_merchandise_value
, soi.original_unit_price - soi.unit_price 	as markdown_discount_value
, soi.unit_price - soi.paid_price			as cart_discount_value
, coalesce(cs.id_catalog_simple, 0)			as fk_product_simple
, coalesce(cc.id_catalog_config, 0)			as fk_product_config
, so.fk_customer
, so.fk_sales_order_address_billing 		as fk_address_billing
, so.fk_sales_order_address_shipping 		as fk_address_shipping
, so.shipping_amount / count(soi.id_sales_order_item) over(partition by so.id_sales_order) as gross_shipping_chaged_to_customer
from spc_raw_bob_dafiti_ar.sales_order_item 	as soi
inner join spc_raw_bob_dafiti_ar.sales_order 	as so on so.id_sales_order = soi.fk_sales_order
left join spc_raw_bob_dafiti_ar.catalog_simple	as cs on cs.sku = soi.sku
left join spc_raw_bob_dafiti_ar.catalog_config	as cc on cc.id_catalog_config = cs.fk_catalog_config
where 1=1
and soi.partition_value >= cast(date_format(date_add('month', -1, current_date), '%Y%m') as bigint)
and so.partition_value >= cast(date_format(date_add('month', -1, current_date), '%Y%m') as bigint)
and cast(so.created_at as timestamp) between cast(date_add('day', -${DAYS_GONE_FROM_DATE}, current_date) as timestamp) and cast(date_add('day', -${DAYS_GONE_TO_DATE}, current_date) as timestamp)
;
```
Previously you created a folder in your repository in the following path: `training/platform/<your.name|random>`, in your `Documents` find the this path in your repository and save the file with the following name:
> replace the variable `<your-name>` with your name and replace the variable `<random>` with some random value. **Remember this random value, you will need it soon.**

`1.spc_staging.fact_sales_delta_load_<your-name>_<random>.athena.full.sql`

Create a second file with the query below. In the `from` clause you need to replace the variables with the values you used to name the previous file.


```sql
select
 to_char(sale_order_store_date::timestamp, 'YYYYMMDD') as partition_field
, src_fk_sale_order_store_item||2 					as custom_primary_key
, src_fk_sale_order_store_item
, src_fk_sale_order_store
, sale_order_store_number
, sale_order_store_date::timestamp 					as sale_order_store_date
, fk_product_simple
, fk_product_config
, fk_customer
, fk_address_billing
, fk_address_shipping
, 2 as fk_country
, 2 as fk_company
, coalesce(gross_merchandise_value, 0) 				as gross_merchandise_value
, coalesce(markdown_discount_value, 0) 				as markdown_discount_value
, coalesce(cart_discount_value, 0) 					as cart_discount_value
, coalesce(gross_shipping_chaged_to_customer, 0) 	as gross_shipping_chaged_to_customer
, coalesce(gross_merchandise_value, 0) + coalesce(gross_shipping_chaged_to_customer, 0) as gross_total_value
from spc_staging.fact_sales_delta_load_<your-name>_<random>
;
```

In the same folder in your repository, save the file with the following name:
> replace the variable `<your-name>` with your name and replace the variable `<random>` with some random value. **Remember this random value, you will need it later.**

`2.spc_business_layer.fact_sales_training_<your-name>_<random>.redshift.partition.sql`

---
Basically when Glove run those 2 steps, the execution of the first file will query Amazon Athena and the result will be used to create a table in Spectrum, the name of the table will be what you defined in the file name, in this case it will be:

`spc_staging.fact_sales_delta_load_<your-name>_<random>`

Always the process runs the data of this table will be replaced with the new data because the scope of this step is `full`, the data will be `full` replaced.

The execution of the second file will query the table created by the previous step through Redshift and the result will be used to craete the fact table in Spectrum. The name of the table will be what you defined in the file name, in this case it will be:

`spc_business_layer.fact_sales_training_<your-name>_<random>`

Always the process runs the historical data of this table will be kept, the new data will be appended and if there is more than one row with the same `custom_primary_key` value, only the last record will be persisted.

We will undertand it better in practice soon.


# Task 3: Deploy to Github

Back to git command line, now you saved the files in the repository you should be able to see them with git.

### 3.1 Commit the Changes

Run the command:

```shell
git status
```

It should show you the name of the folder you created written in red. This appears this way because git is telling you there are some modifications in the repository but git does not care about it **yet**.

Now run the command:

```shell
git add ./
```
This command add all files modificated to a staging area. Git will apply the modifications to the repository only for files in this staging area. If some file you applied some change is not added to this staging area, the changes could never be able to be available to other users, it will be visible only for you.
If you need any file in staging area can be reverted.

Run again the command:

```shell
git status
```

It should show you in green color the named of the 2 files you have just created. When the name of your file appears in green color when you run the command `git status`, it means the file was successfully added to the staging area.

> If the files you created don't appear in the output of the command, review the last steps you take and ask for help.

Following, run this command:

```shell
git commit -m "deploy of my first named query"
```

This command get all files you added to staging area and apply the changes permanently.

To finish, you need to send the files you created/modified to the repository in the cloud. Run the command below.
> In this case, the variable `<your.name>` is the name of the branch you created previously. If needed, review the lab to remember how to list your branchs if you forgot the name you created the branch.

```shell
git push origin <your.name>
```
Now your files should be available in Github.

### 3.2 Create a Pull Request

To complete the deployment to Github the changes in your branch should be merged to branch master/main. To do so go back to github repository in you browser, find and click in the button `branch`, a list of branchs should appears, find your branch and click the button `New Pull Request` in the right side.

A text area should appears to you describe the content of your branch, click in the green button `Create pull Request`

When you create a `pull request` your are requesting your modifications to be applied in main branch, so anyone can see yout changes.

Ask your instructor to approve your pull request so you can continue the laboratory.

# Task 4: Job in Hanger

Now your files are available in the Github repository Glove can access them to run your process, so we can create the Job in Hanger.

Open the link below to access Hanger application:
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

In the left side bar click `Login` in the lower part.

Log In with using the following credentials:

**username:** `data.trainning`

**password:** `vkQL4`

Now you should see the home page listing some `Subjects`.

### 4.1 Configure a Job

Now you will create your Job and organize in the Subject you created in the last Lab.

1. In the left side bar, click in the ![arrow down icon](https://user-images.githubusercontent.com/57373602/106918451-44710400-671a-11eb-86b8-ca1ba37a6c92.png) icon in `Job` and then click `Add Job`

2. In the top part of the page click `Create`

3. In the field `Template` make sure the selected value is `TEMPLATE_EMPTY`

4. in the field `Name` name as `Trial-Training-${YOUR_NAME}-GLOVE_NQ_fact_sales` (don't forget to replace the variable)

5.  Click `>> Next`

6. In the bottom of the page click in the ![arrow up icon](https://user-images.githubusercontent.com/57373602/106918873-a7629b00-671a-11eb-8c43-2f166fb03655.png) icon in `Shell Script` and select the option `SHELL_TEMPLATE-GLOVE-NQ-TRAINNING`

7. In the field `DAYS_GONE_FROM_DATE` type `14` 
(Start of delta range to update the table)


9. Set `Named Query Folder` with the name of folder of your NQ you defined in variable `<your.name|random>`
(folder containing your named query)

10.  In the field `DAYS_GONE_TO_DATE` type `7` 
(End of delta range to update the table)


The others fields you can keep the default value:

 **Target:** this variable defines where Glove will create the table with the results of each step of your named query, in this case we want to create the tables in Spectrum (S3), so you can keep the default value

13. Click `Add`, then it should add a shell script with values you inserted.
This script runs a Glove process and execute your NQ.

14. In the end of the page click `Subject`, select the subject you created in the last Lab and click `Add`

15. In the end of the page click in the button `Checkup`, it will add some new fields to you fill up

16. In the fields `name` and `description` put `load validation`

17. In `connection` select `REDSHIFT DEV`

18. In the field `SQL` put the query below

>  Remember to replace the variables with the same values you used to define the file name of your NQ
```sql
select
max(abs(((b.gmv / a.gmv) - 1) * 100)) as check_
from (
	 select
	 to_char(cast(so.created_at as timestamp), 'YYYYMMDD')::bigint as id_date
	 , sum(soi.paid_price) as gmv
	 from spc_raw_bob_dafiti_ar.sales_order_item as soi
	 inner join spc_raw_bob_dafiti_ar.sales_order as so on so.id_sales_order = soi.fk_sales_order
	 where 1=1
	 and soi.partition_value >= to_char(date_add('month', -1, current_date), 'YYYYMM')::bigint
	 and so.partition_value >= to_char(date_add('month', -1, current_date), 'YYYYMM')::bigint
	 group by 1
) as a
inner join (
	 select
	 to_char(sale_order_store_date::timestamp, 'YYYYMMDD')::bigint as id_date
	 , sum(gross_merchandise_value) as gmv
	 from spc_business_layer.fact_sales_training_<your-name>_<random>
	 group by 1
) b on a.id_date = b.id_date
```

This query will be executed when your process finishes, to validate the load and make sure every thing is ok.

19. In `Condition` select `LOWER_THAN_OR_EQUAL`

20. In `Threshold` put the value `2`

21. In the end of the page click `Save` and then click `Build`

Now your NQ job will be queued and executed, it may take a time to run and you can press `F5` to upate the page and validate the current job status. Your job may pass by 3 status:

*`Building` or `Rebuilding`:* Means your Job is queued and waiting to run (the Job wait in the queue because of server limitation or dependencies block)
*`Running`:* Means your Job is current in execution
*`Success`:* Means your Job completed without any error

> If your job receive any other different status you can click in the `?` icon in right side of the screen to see the description of each status.

### 4.2 Validating Process Behavior

Now your process have successfully executed you can query the table that was created:

```sql
select * from spc_business_layer.fact_sales_training_<your-name>_<random> limit 100;
```

Now to validate the behavior of your process you will run it again but changing the values of some variables, click in the name of your Job, in the end of page click `edit`.

In the shell script there are 2 variables in the first 2 lines, `DAYS_GONE_FROM_DATE` and `DAYS_GONE_TO_DATE`, change de values of those 2 variables to `7` and `0` respectively.

In the end of the page click `Save` and then click `Build`

When the process finishs, run the 2 queries below. You will notice the table in the first query (generated by the first step of your NQ) contains data referent only to the last 7 days as you changed the parameters in the Job configuration, because the first step of your NQ has scope `full`.

The table in the second query (generated by the second step of your NQ) contains data referent to the last 14 days, Glove didn't replaced the histocal data, only the changes were applied, because the second step of your NQ has scope `partition`.

```sql
select
  min(sale_order_store_date)
, max(sale_order_store_date)
from spc_staging.fact_sales_delta_load_<your-name>_<random>
;

select
  min(sale_order_store_date)
, max(sale_order_store_date)
from spc_business_layer.fact_sales_training_<your-name>_<random>
;
```

### 4.3 Validate Load Integrity

Back in Hanger, in front of the name your Job should appears a text `CHECKUP`. Click in this link, it will open a new screen containing a list of HealthCheck executions for your process, and you can analyse if it's ok. You can change the chart view to a table view.

Feel free to explore Hanger.

# Conclusion

You created a Named Query process using an specific module of Glove data integration and made all configurations in Hanger with Health Check to validate the quality of your process. You used git and Github to do the deployment of your process and isolate all your changes to avoid conflicts. Congratulations!

You have successfully learned how to:

- Configure your Github account to use SSH
- Use git version tool to manipulate your modifications
- Create and configure a Named Query process
- Create and configure a Job in Hanger
- Add HealthChecks to your Job

#### References
[Hanger - Github](https://github.com/dafiti-group/hanger)

[User friendly documentation](https://sites.google.com/dafiti.com.br/data-and-analytics-en-docs/home)
