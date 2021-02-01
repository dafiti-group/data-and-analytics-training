# Crear un proceso ETL simple

### Objetivo

Después de completar esta práctica de laboratorio, habrá aprendido a:

- Manipule archivos con SQL puro para hacer un ETL simple
- Manejar algunos formatos de archivo
- Crear un proceso ETL automatizado con Glove
- Crear una canalización de datos en Hanger


### Duración

Se necesitan 40 minutos para completar esta práctica de laboratorio


### Visión general

En este laboratorio, creará y ejecutará procesos ETL extrayendo datos de 2 fuentes diferentes para cargarlos en nuestro Data Lake (AWS S3). Durante la ejecución, los datos se convertirán en archivos Parquet* para que tenga una forma estandarizada de acceder a los datos a través de Redshift Spectrum. Primero, ejecutará un ETL manualmente para establecer una comprensión del concepto y luego usará el Hanger para crear y configurar un Job Glove.

> ***Parquet*** es un formato de archivo en columnas ampliamente utilizado para almacenar datos en el lago de datos en lugar de utilizar formatos de archivo convencionales como CSV o JSON. Como Parquet es columnar (los datos se leen por columna) se puede lograr un mejor desempeño en las consultas y reducción de costos a fin de mes si se aplican buenas prácticas.

> Otro famoso formato de archivo columnar similar a ***Parquet*** es el formato ***ORC***


# Iniciar el laboratorio

Para completar este laboratorio, debe estar conectado a la VPN para acceder a los recursos necesarios.
En su Workbench (que usa con frecuencia para acceder a Redshift) cree una nueva conexión para Redshift con las siguientes credenciales.

**Host:** `bi-dafiti-group-dc2-dev.cofscmejxic8.us-east-1.redshift.amazonaws.com`


**Port:** `5439`


**Database:** `dftdwh_dev`


**User:** `datatrainning`


**Password:** `Training123`
  
  
# Tarea 1: proceso ETL manual
  
En esta tarea, realizará un proceso ETL manualmente para establecer una comprensión del concepto fundamental. Manipulará los datos almacenados en nuestro lago de datos utilizando Redshift y Redshift Spectrum. Convertirá un archivo CSV a Parquet y aplicará algún procesamiento de datos.
  
### Preparación para el proceso
  
Hay un archivo CSV comprimido llamado `nps_origin_type.csv.gz` almacenado en la ruta de un contenedor S3 `s3: //bi-dafiti-group-dev/dft-trainning/etl-lab/raw-data/`.
A continuación se muestra un ejemplo de los datos de este archivo:
  
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

Ahora en Redshift creará una tabla externa a través del `Redshift Spectrum` apuntando al archivo en S3.
Ejecute la consulta a abajo.

> Observe que hay algunas variables en la consulta y necesita cambiarlas, reemplace $ {YOUR_NAME} con su nombre o apodo, reemplace $ {RANDOM} con algunos números aleatorios. **Use solo letras minúsculas y escriba y no olvide los números aleatorios, ya que los necesitará unas cuantas veces más**

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

Puedes consultar la tabla para ver algunos datos:

```sql
select * from spc_staging.${YOUR_NAME}_${RANDOM}_raw_nps_origin_type limit 100;
```

Como puede ver, los datos podrían verse mejor, por lo que ahora le aplicará algunos tratamientos. Ahora que puede consultar los datos en el archivo CSV, puede **E**xtraer, **T**ransformar y **L**oad (cargar) los datos.

### Ejecutando un ETL

Qué harás en ese momento:


- **Extract:**
	-  Consulte la tabla externa para leer el archivo CSV
- **Transform:**
	- Convierta los datos a Parquet y aplique algunas funciones de transformación
	- Agregue un nuevo campo llamado `description_group` como una forma de organizar y categorizar los datos
- **Load:** 
	- Almacene el nuevo archivo convertido nuevamente en S3 y cree una nueva tabla que apunte a los datos tratados

Ejecute el siguiente script, es su proceso ETL:
>  Tenga en cuenta que hay algunas variables en la consulta y puede cambiarlas, puede analizar el script antes de ejecutarlo.

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


Ahora solo necesitas crear una tabla externa apuntando al archivo que acabas de cargar en S3 y luego podrás consultar los datos tratados.


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


Si no recibe ningún error, ahora puede consultar su ficha de parquet y ver sus datos tratados.


```sql
select * from spc_staging.${YOUR_NAME}_${RANDOM}_nps_origin_type limit 100;
```


# Tarea 2: ETL fácil con Glove

En esta tarea, creará un trabajo en Hanger Data Orchestration y configurará un proceso ETL utilizando Glove Data Integration. Hanger facilita mucho el trabajo de crear trabajos con Glove.

Hanger trabaja en estrecha colaboración con Glove para administrar todos los flujos de procesos para garantizar el orden de ejecución, la validación de datos y más.

Extraerá datos del sistema NPS para poder ver las notas del cliente.

### Acceso a Hanger

1. Acceda al enlace de abajo para acceder a la aplicación Hanger
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

2. En la barra lateral izquierda, haga clic en `Login` en la parte inferior

3. Inicie sesión con las siguientes credenciales:


**username:** `data.trainning`


**password:** `vkQL4`

Después de iniciar sesión, debe ser redirigido a la página de inicio y ver algunos `Temas (Subjects)` en la lista.

### Creación de Temas

Antes de crear un trabajo, explorará algunas funciones de suspensión. Uno de ellos es `Subject`, puede crear temas para organizar sus trabajos, ingresar y acceder más fácilmente ya que los temas se enumeran en la página de inicio para usted.

1. En la barra de navegación de la izquierda, haga clic en el símbolo de la flecha hacia abajo en `Subject` y luego seleccione `Add Subject`

2. En el primer campo `Subject Name`, ingrese su nombre para que sea más fácil encontrarlo más tarde

3. Haga clic en `Save`, se agregará el asunto


### Crear y configurar un trabajo ETL

Ahora va a crear su propio trabajo ETL y organizarlo en el tema que creó

1. En la barra lateral izquierda, haga clic en el icono de flecha hacia abajo debajo de ´Job` y haga clic en `Add Job`

2. En la parte superior de la página, haga clic en `Create`

3. En el campo `Template`, asegúrese de que el valor seleccionado sea `TEMPLATE_EMPTY`

4. En el campo `Name`, nombre el trabajo `Trial-Trainning-${YOUR_NAME}-Glove_raw_nps_feedback` (no olvides reemplazar la variable)

5. Haga clic en `>> Next`

6. En la parte inferior de la pantalla, haga clic en el icono de flecha hacia arriba en `Shell Script` y seleccione la opción `SHELL_TEMPLATE-GLOVE-DATABASE-TRAINNING`

7. En el campo `Source Table Name`, ingrese `nps_feedback`
(nombre de la tabla en los datos de origen)

8. Ponga `Target` como `spectrum` 
(*Target* es el destino para almacenar datos)

9. Ponga `Output Table Schema` como `spc_staging`
(Esquema de destino de datos extraídos)

10. Ponga `Output Table Name` como `raw_nps_feedback_${YOUR_NAME}_${RANDOM}`. No olvide cambiar las variables*
(tabla de destino para los datos extraídos)

11. Ponga `Connection name` como `raw_nps` 
(referencia de conexión para acceder a la base de datos de origen)

12. Ponga `Source Table Schema` como `public` 
(nombre de esquema en la base de datos de origen)

Los otros campos pueden mantener el valor predeterminado (o vacío):
**Storage Bucket:** Define el depósito de S3 donde se almacenarán los datos
**Output Format:** Define el formato de archivo que se escribirá en S3, el predeterminado es Parquet
**Dataset Name:** Define el nombre de la base de datos en Redshift
**Delta Field:** Cuando creamos un proceso ETL no podemos extraer todos los datos de la fuente en todas las ejecuciones, es necesario hacer esto una vez y en las próximas ejecuciones solo extraer datos nuevos y datos actualizados. Para eso debemos definir un campo delta de la tabla que será la base para extraer solo los datos necesarios, generalmente el campo utilizado es `updated_at`.
 
 13. Haga clic en `Add` y debería aparecer un script de shell que contiene los valores que ingresó.
 Este script que ejecutará el ETL
 
 14. En la parte inferior de la página, haga clic en `Subject`, seleccione el tema que creó y haga clic en ´Add`.
 
 15. Al final de la página, haga clic en `Save` y luego haga clic en `Build`
 
 Ahora su trabajo ETL estará en cola para ser ejecutado, la ejecución puede demorar un tiempo en finalizar, por lo que puede actualizar la página presionando `F5` y verificar el estado actual del trabajo. Su trabajo puede pasar por 3 estados:
 
*`Building` o `Rebuilding`:* Estado que indica que su trabajo está en la cola esperando ser ejecutado (el trabajo está esperando en la cola debido a limitaciones del servidor o alguna dependencia que está bloqueando)
*`Running`:* Estado que indica que su trabajo se está ejecutando
*`Success`:* Estado que indica que su trabajo finalizó sin errores


> Si su Trabajo recibe algunos estados diferentes, puede hacer clic en el icono `?` En el lado derecho de la pantalla para ver la descripción del significado de cada estado.


Una vez finalizado el trabajo, puede intentar consultar la tabla extraída

```sql
select * from spc_staging.raw_nps_feedback_${YOUR_NAME}_${RANDOM} limit 100;
```


# Tarea 3: Automatizar el proceso en Hanger

En esta tarea, aplicará una configuración a su trabajo ETL para automatizarlo, y lo hará agregando otro trabajo como dependencia a su proceso. Puede agregar tantas dependencias como sea necesario a su proceso, en Hanger las dependencias se tratan como `Parent (Padres)`.


### Add Parent


1. Navegue a la página de inicio de Hanger haciendo clic en `Monitor` en la barra de navegación izquierda

2. Haga clic en el nombre del tema (`Subject`) que creó anteriormente, y luego debería aparecer su trabajo

3. Haga clic en el botón `Flow`

4. Haga clic derecho en su trabajo, seleccione `= Actions` > `+ Parent`, seleccione `DEV`

5. En el campo `Jobs`, busque y seleccione el Trabajo `DATA-TRAINNING-ETL-GLOVE_raw_trigger_05hr`. haga clic en `Add`

Notará que hay un nuevo trabajo conectado al suyo. Este trabajo que se agregó es un disparador que activará automáticamente su proceso todos los días a las 5 am.


# Conclusión

Usó Redshift y Redshift Spectrum para manejar algunos tipos de datos y realizar un proceso ETL simple. Ha completado con éxito la creación de su propio proceso ETL utilizando el Glove administrado por Hanger configurando los parámetros necesarios para extraer los datos del sistema y cargarlos en nuestro Data Lake. ¡Felicidades!

Has aprendido:

- Leer archivos en S3 usando Redshift Spectrum
- Escribir archivos en S3 con Redshift
- Crea temas en la percha para organizar tus Jobs
- Cree y configure un proceso ETL usando Glove
- Agregue dependencias en proceso para la automatización


El Glove tiene muchas posibilidades por explorar, puede encontrar la documentación en [GitHub](https://github.com/dafiti-group/glove).