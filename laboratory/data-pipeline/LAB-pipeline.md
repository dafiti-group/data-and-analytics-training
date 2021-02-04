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

```bash
sudo apt-get install git
```

You also need to have an account in github platform, if necessary you can create your accont by clicking [here](https://github.com/join).

I recomend you to use your commercial e-mail to register to github.


### Overview

- **Git** is a version tool that can be used to track all changes in your projects, you can have many version of a file and manage all changes.

- **Glove** is a data integration tool, we can use to create ETL jobs, automate SQL script executions and more. In this lab we will be using one specific module of Glove: Module query.

- **Hanger** is service for workflow orchquestration, it help us automate, manage, organize and validate our jobs and workflows.


  
# Starting Lab
  
In this Lab you will use git version tool to control and isolate your modifications in a git repository (we will be using [github](https://github.com/)). You will create a Named Query process and deploy using git to run in Hanger with Glove using the Module query. In Hanger you create a Health Check to validate the integrity of your process.

In your Named Query process you will create a simple fact table for sales combining some configuration attributes.
  
  
# Task 1: Preparing the Environment
  
In this task you will start by setting the a git repostiry to deploy your NQ (Named Query), open `Git bash` installed in your windows system or open the terminal if you are using linux and make sure you are in the home folder of your user. You can validate running the following command:

```bash
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

```bash
cd ~
```



### 1.1 Configure your Github account

The repository we are going to use in the Lab has a security level that requires to be accessed with SSH protocol, so you need to generate a SSH key to set in your github account, if you already have a SSH key setted up to your account you can skip this step and go to `1.2`.

To do so, run the following command:

```bash
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

```bash
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

```bash
mkdir -p Documents/training_repo;cd Documents/training_repo;pwd
```

Notice now you are inside a different directory, this is where we are going to clone the repository to develop the NQ.

Now open our public github repository available in the following [link (data-and-analytics-training)](https://github.com/dafiti-group/data-and-analytics-training). Click in the green button `Code`, select `SSH` and copy the link that sould be similar to this: `git@github.com:dafiti-group/data-and-analytics-training.git`.

Back to terminal run the git command to download the repository to your local machine.

> Replace <copied_link> with the link you copied from github

```bash
git clone <copied_link>
```
By running the command below, you can see a new folder was created

```bash
ls -l
```

Now a copy of the repository was created for you. Navigate inside the new folder with the command below:

```bash
cd data-and-analytics-training
```

### 1.3 Target folder

Before start creating the NQ we need to create an isolated area in the recently cloned repository to avoid conflicts with someone modifications.  To do so you will create a branch. Create a branch with your name:

```bash
git branch <your.name>
```
Now you created at branch, you must natigate inside it to keep all your development isolated, to do so, run the command:

```bash
git switch <your.name>
```

Now you are inside your new branch. Lastly you will create a folder in your branch  to store the NQ you will create:

> in the <your.name|random> variable write your name and add some random numbers to avoid name conflicts in the repository. **Save the value of this variable, you will need this later.**

```bash
mkdir -p training/platform/<your.name|random>
```

> To list all avalilable branchs in your repository run the command `git branch` 

# Task 2: Create Named Query

In this task you will set some NQ steps to to create a fact table in Data Warehouse. You will extract data from Athena and model the table in Redshift, you will know in practice how each scope of named query works.

Open you prefered text editor and create a file with the following query:

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
, so.fk_address_billing
, so.fk_address_shipping
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

`1.staging.fact_sales_delta_load_<your-name>_<random>.athena.full.sql`

Create a second file with the query below. In the `from` clause you need to replace the variables with the values you used to name the previous file.


```sql
select
 to_char(sale_order_store_date, 'YYYYMMDD') 		as partition_field
, src_fk_sale_order_store_item||2 					as custom_primary_key
, src_fk_sale_order_store_item
, src_fk_sale_order_store
, sale_order_store_number
, cast(sale_order_store_date as timestamp) 			as sale_order_store_date
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
from staging.fact_sales_delta_load_<your-name>_<random>
;
```

In the same folder in your repository, save the file with the following name:
> replace the variable `<your-name>` with your name and replace the variable `<random>` with some random value. **Remember this random value, you will need it later.**

`2.business_layer.fact_sales_training_<your-name>_<random>.redshift.partition.sql`

---
Basically when Glove run those 2 steps, the execution of the first file will query Amazon Athena and the result will be used to create a table in Redshift, the name of the table will be what you defined in the file name, in this case it will be:

`staging.fact_sales_delta_load_<your-name>_<random>`

Always the process runs the data of this table will be replaced with the new data because the scope of this step is `full`, the data will be `full` replaced.

The execution of the second file will query the table created by the previous step through Redshift and the result will be used to craete the fact table in Redshift. The name of the table will be what you defined in the file name, in this case it will be:

`business_layer.fact_sales_training_<your-name>_<random>`

Always the process runs the historical data of this table will be kept, the new data will be appended and if there is more than one row with the same `custom_primary_key` value, only the last record will be persisted.

We will undertand it better in practice soon.


# Task 3: Deploy to Github

Back to git command line, now you saved the files in the repository you should be able to see them with git.

### 3.1 Commit the Changes

Run the command:

```bash
git status
```

It should show you the name of the folder you created written in red. This appears this way because git is telling you there are some modifications in the repository but git does not care about it **yet**.

Now run the command:

```bash
git add ./
```
This command add all files modificated to a staging area. Git will apply the modifications to the repository only for files in this staging area. If some file you applied some change is not added to this staging area, the changes could never be able to be available to other users, it will be visible only for you.
If you need any file in staging area can be reverted.

Run again the command:

```bash
git status
```

It should show you in green color the named of the 2 files you have just created. When the name of your file appears in green color when you run the command `git status`, it means the file was successfully added to the staging area.

> If the files you created don't appear in the output of the command, review the last steps you take and ask for help.

Following, run this command:

```bash
git commit -m "deploy of my first named query"
```

This command get all files you added to staging area and apply the changes permanently.

To finish, you need to send the files you created/modified to the repository in the cloud. Run the command below.
> In this case, the variable `<your.name>` is the name of the branch you created previously. If needed, review the lab to remember how to list your branchs if you forgot the name you created the branch.

```bash
git push origin <your.name>
```
Now your files should be available in Github.

### 3.2 Create a Pull Request

To complete the deployment to Github the changes in your branch should be merged to branch master/main. To do so go back to github repository in you browser, find and click in the button `branch`, a list of branchs should appears, find your branch and click the button `New Pull Request` in the right side.

A text area should appears to you describe the content of your branch, click in the green button `Create pull Request`

When you create a `pull request` your are requesting your modifications to be applied in main branch, so anyone can see yout changes.

Ask your instructor to approve your pull request so you can continue the laboratory.

# Task 4: Create Job in Hanger

Now your files are available in the Github repository Glove can access them to run your process, so we can create the Job in Hanger.

Open the link below to access Hanger application:
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

In the left side bar click `Login` in the lower part.

Log In with using the following credentials:

**username:** `data.trainning`

**password:** `pass`

Now you should see the home page listing some `Subjects`.



# Conclusion

You used Redshift and Redshift Spectrum to deal with some file formarts and run a simple ETL. You have successfully created your own ETL process using Glove and managed with Hanger by setting the necessary parameters to extract data from a system database to load into our data lake. Congratulations!

You have successfully learned how to:

- Configure your github account to use SSH
- Use git version tool to manipulate your modifications
- Create and configure a Named Query process
- Create and configure a Job in Hanger
- Add HealthChecks to your Job