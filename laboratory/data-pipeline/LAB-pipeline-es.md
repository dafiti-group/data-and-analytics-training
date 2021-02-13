# Data Pipeline



### Objetivos

Después de completar esta práctica de laboratorio, sabrá cómo:

- Usar la herramienta de versión git
- Crear un proceso de Named Query utilizando el módulo query de Glove
- Implementar un proceso de Named Query
- Crear una canalización de datos en Hanger

### Duración

Esta práctica de laboratorio requiere 40 minutos para completarse.


### Prerrequisitos

Necesita un software específico instalado en su máquina para poder completar esta propiedad de laboratorio.
Usaremos la herramienta de versión git.

- Para Windows puedes acceder [aquí](https://gitforwindows.org/) para descargar e instalar.

- Para Linux, puede ejecutar el siguiente comando para instalar

```shell
sudo apt-get install git
```

También necesita tener una cuenta en la plataforma github, si es necesario puede crear su cuenta haciendo clic aquí

Le recomiendo que utilice su correo electrónico comercial para registrarse en github.


### Visión general


- **Git** es una herramienta de versión que puede usarse para rastrear todos los cambios en sus proyectos, puede tener muchas versiones de un archivo y administrar todos los cambios.

- **Glove** es una herramienta de integración de datos que podemos usar para crear trabajos ETL, automatizar ejecuciones de scripts SQL y más. En este laboratorio, utilizaremos un módulo específico de Glove: módulo query.

- **Hanger** es un servicio para la organización del flujo de trabajo, nos ayuda a automatizar, administrar, organizar y validar nuestros trabajos y flujos de trabajo.


# Laboratorio de inicio



En este laboratorio, usará la herramienta de versión git para controlar y aislar sus modificaciones en un repositorio de git (estaremos usando [Github](https://github.com/)). Creará un proceso de Named Query y lo implementará utilizando git para ejecutarlo en Hanger con Glove utilizando módulo query. En Hanger, crea un Health Check para validar la integridad de su proceso.

En su proceso de Consulta nombrada, creará una tabla de hechos simple para las ventas combinando algunos atributos de configuración.


# Tarea 1: Preparar el entorno

En esta tarea, comenzará configurando el repositorio de un git para implementar su NQ (Named Query), abra `Git bash` instalado en su sistema Windows o abra la terminal si está usando Linux y asegúrese de estar en la carpeta de inicio de su usuario. Puede validar la ejecución del siguiente comando:

```shell
pwd
```

Debería obtener una salida similar a esta:

```
/home/<your.username>
```

o similar a esto:
```
/c/users/<your.username>
```

Si su resultado no es similar a los ejemplos anteriores, puede intentar solucionarlo ejecutando el siguiente comando:

```shell
cd ~
```



### 1.1 Configura tu cuenta de Github

El repositorio que vamos a utilizar en el laboratorio tiene un nivel de seguridad que requiere ser accedido con el protocolo SSH, por lo que debe generar una clave SSH para configurar en su cuenta de github, si ya tiene configurada una clave SSH en su cuenta. puede omitir este paso y pasar a `1.2`.

Para hacerlo, ejecute el siguiente comando:

```shell
ssh-keygen
```

Luego presione `ENTER` 3 veces hasta que obtenga un resultado similar al texto a continuación:

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

Ahora necesitamos obtener la clave generada para configurar en Github, para imprimir la clave en tu terminal ejecuta el siguiente comando:

```shell
cat ~/.ssh/id_rsa.pub
```

Luego copie el resultado de salida.

Vaya a Github, vaya a `configuración`:

![github-menu](https://user-images.githubusercontent.com/57373602/106788267-c94c1700-6661-11eb-9c0f-9fa94136376a.png) 

En la barra de navegación izquierda, busque y seleccione `SSH and GPG Keys`, haga clic en el botón verde `New SSH key`

![set shh](https://user-images.githubusercontent.com/57373602/106793741-e33d2800-6668-11eb-9deb-fd64b14f8521.png)

Se abrirá un área de texto, en el campo `clave` pasando el valor que copió desde la línea de comando y haga clic en `Add clave SSH`.

Ahora tiene una clave SSH configurada en su cuenta por seguridad.


### 1.2 Clonando el repositorio

Creemos una carpeta para alojar el repositorio clonado, ejecute el siguiente comando:

```shell
mkdir -p Documents/training_repo;cd Documents/training_repo;pwd
```

Note que ahora está dentro de un directorio diferente, aquí es donde vamos a clonar el repositorio para desarrollar el NQ.

Ahora abra nuestro repositorio público de github disponible en el siguiente [link (data-and-analytics-training)](https://github.com/dafiti-group/data-and-analytics-training). Haga clic en el botón verde `Código`, seleccione `SSH` y copie el enlace que debería ser similar a este: `git@github.com: dafiti-group/data-and-analytics-training.git`.

De vuelta a la terminal, ejecute el comando git para descargar el repositorio en su máquina local.

> Reemplaza <copied_link> con el enlace que copiaste de github

```shell
git clone <copied_link>
```
Al ejecutar el comando a continuación, puede ver que se creó una nueva carpeta

```shell
ls -l
```

Ahora se creó una copia del repositorio para usted. Navegue dentro de la nueva carpeta con el siguiente comando:

```shell
cd data-and-analytics-training
```

### 1.3 Carpeta de destino

Antes de comenzar a crear el NQ, necesitamos crear un área aislada en el repositorio clonado recientemente para evitar conflictos con las modificaciones de alguien. Para hacerlo, creará una rama. Crea una rama con tu nombre:

```shell
git branch <your.name>
```
Ahora que creaste en la sucursal, debes navegar dentro de ella para mantener todo tu desarrollo aislado, para hacerlo, ejecuta el comando:

```shell
git switch <your.name>
```

Ahora estás dentro de tu nueva rama. Por último, creará una carpeta en su sucursal para almacenar el NQ que creará:

> en la variable <your.name|random> escriba su nombre y agregue algunos números aleatorios para evitar conflictos de nombres en el repositorio. **Guarde el valor de esta variable, lo necesitará más tarde.**

```shell
mkdir -p training/platform/<your.name|random>
```

> Para enumerar todas las ramas disponibles en su repositorio, ejecute el comando `git branch`

# Tarea 2: Crear Named Query

En esta tarea, establecerá algunos pasos NQ para crear una tabla de hechos en Data Warehouse. Extraerá datos de Athena y modelará la tabla en Redshift, sabrá en la práctica cómo funciona cada ámbito de Named Query.

Abra su editor de texto preferido y cree un archivo con la siguiente consulta:

> **Note:** hay 2 variables en esta consulta pero no es necesario que las reemplace, establecerá el valor de las variables en los parámetros de Glove

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
Anteriormente, creó una carpeta en su repositorio en la siguiente ruta: `training/platform/<your.name|random>`, en sus `Documentos` busque esta ruta en su repositorio y guarde el archivo con el siguiente nombre:
> reemplace la variable `<your-name>` con su nombre y reemplace la variable `<random>` con algún valor aleatorio. **Recuerde este valor aleatorio, lo necesitará pronto.**

`1.spc_staging.fact_sales_delta_load_<your-name>_<random>.athena.full.sql`

Cree un segundo archivo con la consulta a continuación. En la cláusula `from` debe reemplazar las variables con los valores que usó para nombrar el archivo anterior.


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

En la misma carpeta de su repositorio, guarde el archivo con el siguiente nombre:
> reemplace la variable `<your-name>` con su nombre y reemplace la variable `<random>` con algún valor aleatorio. **Recuerde este valor aleatorio, lo necesitará más tarde.**

`2.spc_business_layer.fact_sales_training_<your-name>_<random>.redshift.partition.sql`

---
Básicamente cuando Glove ejecute esos 2 pasos, la ejecución del primer archivo consultará a Amazon Athena y el resultado se usará para crear una tabla en Redshift, el nombre de la tabla será el que definiste en el nombre del archivo, en este caso estarán:

`spc_staging.fact_sales_delta_load_<your-name>_<random>`

Siempre que se ejecute el proceso, los datos de esta tabla se reemplazarán con los nuevos datos porque el alcance de este paso es `full`, los datos se reemplazarán `completo`.

La ejecución del segundo archivo consultará la tabla creada por el paso anterior a través de Redshift y el resultado se utilizará para crear la tabla de hechos en Redshift. El nombre de la tabla será el que definiste en el nombre del archivo, en este caso será:

`spc_business_layer.fact_sales_training_<your-name>_<random>`

Siempre que el proceso se ejecute, los datos históricos de esta tabla se mantendrán, los nuevos datos se agregarán y si hay más de una fila con el mismo valor de `custom_primary_key`, solo se conservará el último registro.

Lo entenderemos mejor en la práctica pronto.


# Tarea 3: Implementar en Github

De vuelta a la línea de comandos de git, ahora que guardó los archivos en el repositorio, debería poder verlos con git.

### 3.1 Confirmar los cambios

Ejecute el comando:

```shell
git status
```

Debería mostrarte el nombre de la carpeta que creaste escrito en rojo. Esto aparece de esta manera porque git te está diciendo que hay algunas modificaciones en el repositorio, pero a git no le importa **todavía**.

Ahora ejecuta el comando:

```shell
git add ./
```
Este comando agrega todos los archivos modificados a un área de preparación. Git aplicará las modificaciones al repositorio solo para los archivos en esta área de prueba. Si algún archivo en el que aplicó algún cambio no se agrega a esta área de prueba, los cambios nunca podrían estar disponibles para otros usuarios, solo serán visibles para usted.
Si necesita algún archivo en el área de ensayo se puede revertir.

Ejecute nuevamente el comando:

```shell
git status
```

Debería mostrarle en color verde el nombre de los 2 archivos que acaba de crear. Cuando el nombre de su archivo aparece en color verde cuando ejecuta el comando `git status`, significa que el archivo se agregó correctamente al área de ensayo.

> Si los archivos que creó no aparecen en la salida del comando, revise los últimos pasos que realizó y solicite ayuda.

A continuación, ejecute este comando:

```shell
git commit -m "deploy of my first named query"
```

Este comando obtiene todos los archivos que agregó al área de ensayo y aplica los cambios de forma permanente.

Para finalizar, debe enviar los archivos que creó/modificó al repositorio en la nube. Ejecute el siguiente comando.
> En este caso, la variable `<your.name>` es el nombre de la rama que creó anteriormente. Si es necesario, revise el laboratorio para recordar cómo enumerar sus sucursales si olvidó el nombre con el que creó la sucursal.

```shell
git push origin <your.name>
```
Ahora sus archivos deberían estar disponibles en Github.

### 3.2 Crear una solicitud de extracción

Para completar la implementación en Github, los cambios en su rama deben fusionarse en branch master/main. Para hacerlo, regrese al repositorio de github en su navegador, busque y haga clic en el botón `branch`, debería aparecer una lista de ramas, busque su rama y haga clic en el botón` Nueva solicitud de extracción` en el lado derecho.

Debería aparecer un área de texto para describir el contenido de su rama, haga clic en el botón verde `Create pull Request`

Cuando crea un `pull request`, está solicitando que sus modificaciones se apliquen en la rama principal, para que cualquiera pueda ver sus cambios.

Pídale a su instructor que apruebe su solicitud de extracción para que pueda continuar con el laboratorio.

# Tarea 4: Job en Hanger

Ahora sus archivos están disponibles en el repositorio de Github, Glove puede acceder a ellos para ejecutar su proceso, por lo que podemos crear el trabajo en Hanger.

Abra el enlace a continuación para acceder a la aplicación Hanger:
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

En la barra lateral izquierda, haga clic en `Login` en la parte inferior.

Inicie sesión con las siguientes credenciales:

**username:** `data.trainning`

**password:** `vkQL4`

Ahora debería ver la página de inicio con una lista de algunos `Temas`.

### 4.1 Configurar un Job

Ahora creará su trabajo y lo organizará en el tema que creó en el último laboratorio.

1. En la barra lateral izquierda, haga clic en el ![arrow down icon](https://user-images.githubusercontent.com/57373602/106918451-44710400-671a-11eb-86b8-ca1ba37a6c92.png) en `Job` y luego haga clic en `Add Job`

2. En la parte superior de la página, haga clic en `Create`.

3. En el campo `Template` asegúrese de que el valor seleccionado sea `TEMPLATE_EMPTY`

4. en el campo `Name` nombre como `Trial-Trainning-${YOUR_NAME}-GLOVE_NQ_fact_sales` (no olvides reemplazar la variable)

5.  Haga clic en `>> Next`

6. En la parte inferior de la página, haga clic en el ![arrow up icon](https://user-images.githubusercontent.com/57373602/106918873-a7629b00-671a-11eb-8c43-2f166fb03655.png) en `Shell Script` y seleccione la opción `SHELL_TEMPLATE-GLOVE-NQ-TRAINNING`

7. En el campo `DAYS_GONE_FROM_DATE` escriba `14` 
(Inicio del rango delta para actualizar la tabla)


9. Establezca `Named Query Folder` con el nombre de la carpeta de su NQ que definió en la variable `<your.name|random>`
(carpeta que contiene su consulta nombrada)

10. En el campo `DAYS_GONE_TO_DATE` escriba `7` 
(Fin del rango delta para actualizar la tabla)


Los otros campos puede mantener el valor predeterminado:

 **Target:** esta variable define dónde Glove creará la tabla con los resultados de cada paso de su consulta nombrada, en este caso queremos crear las tablas en Redshift, para que pueda mantener el valor predeterminado

13. Click `Add`, entonces debería agregar un script de shell con los valores que insertó.
Este script ejecuta un proceso Glove y ejecuta su NQ.

14. Al final de la página, haga clic en `Subject`, seleccione el tema que creó en el último laboratorio y haga clic en `Add`

15. Al final de la página, haga clic en el botón `Checkup`, agregará algunos campos nuevos para que complete

16. En los campos `Name` y `Description` ponga `validación de carga`

17. En `connection` seleccione `REDSHIFT DEV`

18. En el campo `SQL` ponga la consulta debajo

>  Recuerde reemplazar las variables con los mismos valores que utilizó para definir el nombre de archivo de su NQ
```sql
select
max(abs((1 - (b.gmv / a.gmv)) * 100)) as check_
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

Esta consulta se ejecutará cuando finalice su proceso, para validar la carga y asegurarse de que todo esté bien.

19. En `Condition` seleccione `LOWER_THAN_OR_EQUAL`

20. En `Threshold` ponga `2`

21. Al final de la página, haga clic en `Save` y luego haga clic en `Build`

Ahora su trabajo de NQ se pondrá en cola y se ejecutará, puede tardar un tiempo en ejecutarse y puede presionar `F5` para actualizar la página y validar el estado actual del trabajo. Su trabajo puede pasar por 3 estados:

*`Building` o `Rebuilding`:* Significa que su trabajo está en cola y esperando para ejecutarse (el trabajo espera en la cola debido a la limitación del servidor o al bloqueo de dependencias)
*`Running`:* Significa que su trabajo está actualmente en ejecución
*`Success`:* Significa que su trabajo se completó sin ningún error

> Si su trabajo recibe cualquier otro estado diferente, puede hacer clic en el icono `?` En el lado derecho de la pantalla para ver la descripción de cada estado.

### 4.2 Validación del comportamiento del proceso

Ahora que su proceso se ha ejecutado con éxito, puede consultar la tabla que se creó:

```sql
select * from spc_business_layer.fact_sales_training_<your-name>_<random> limit 100;
```

Ahora para validar el comportamiento de su proceso lo volverá a ejecutar pero cambiando los valores de algunas variables, haga clic en el nombre de su Trabajo, al final de la página haga clic en `Edit`.

En el script de shell hay 2 variables en las primeras 2 líneas, `DAYS_GONE_FROM_DATE` y `DAYS_GONE_TO_DATE`, cambie los valores de esas 2 variables a `7` y` 0` respectivamente.

Al final de la página, haga clic en `Save` y luego haga clic en `Build`

Cuando finalice el proceso, ejecute las 2 consultas siguientes. Notarás que la tabla en la primera consulta (generada por el primer paso de tu NQ) contiene datos referentes solo a los últimos 7 días cuando cambiaste los parámetros en la configuración del Trabajo, porque el primer paso de tu NQ tiene alcance `full`.

La tabla en la segunda consulta (generada por el segundo paso de su NQ) contiene datos referentes a los últimos 14 días, Glove no reemplazó los datos histocales, solo se aplicaron los cambios, porque el segundo paso de su NQ tiene alcance `partition`.

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

### 4.3 Validar la integridad de la carga

De vuelta en Hanger, delante del nombre de su Job debería aparecer un texto `CHECKUP`. Haga clic en este enlace, se abrirá una nueva pantalla que contiene una lista de ejecuciones de HealthCheck para su proceso, y puede analizar si está bien. Puede cambiar la vista de gráfico a una vista de tabla.

Siéntete libre de explorar Hanger.

# Conclusión

Creó un proceso de Named Query utilizando un módulo específico de integración de datos de Glove y realizó todas las configuraciones en Hanger con Health Check para validar la calidad de su proceso. Usó git y Github para realizar la implementación de su proceso y aislar todos sus cambios para evitar conflictos. ¡Felicidades!

Ha aprendido con éxito cómo:

- Configure su cuenta de Github para usar SSH
- Use la herramienta de versión git para manipular sus modificaciones
- Crear y configurar un proceso de Named Query
- Crear y configurar un Job en Hanger
- Agregue HealthChecks a su Job

#### Referencias
[Hanger - Github](https://github.com/dafiti-group/hanger)

[User friendly documentation](https://sites.google.com/dafiti.com.br/data-and-analytics-en-docs/home)
