# Redshift

### objetivo

Después de completar esta práctica de laboratorio, sabrá cómo:

- Interprete el plan de ejecución de su consulta en Redshift
- Defina y use Diststyle y Sortkey en su tabla
- Llene una tabla con datos de AWS S3
- Comprimir datos para mejorar el rendimiento de las consultas y la eficiencia del espacio en disco


### Duración

Esta práctica de laboratorio tarda 20 minutos en completarse.


### Visión general

En este laboratorio, creará y completará algunas tablas para comprender cómo Redshift maneja los datos para resolver su consulta y devolverle el resultado. Comprenderá el plan de consultas de Redshift y luego aplicará algunas modificaciones a la consulta para mejorar el rendimiento.


# Starting Lab

Para completar esta práctica de laboratorio, debe estar conectado a la VPN para acceder a los recursos necesarios.
En su Workbench (normalmente lo usa para acceder a Redshift), cree una nueva conexión a Redshift con las siguientes credenciales. Si ya tiene la configuración en su escritorio en la última práctica de laboratorio, puede omitir esta parte.
  
**Host:** `bi-dafiti-group-dc2-dev.cofscmejxic8.us-east-1.redshift.amazonaws.com`


**Port:** `5439`


**Database:** `dftdwh_dev`


**User:** `datatrainning`


**Password:** `Training123`


# Tarea 1: crear y completar

En esta tarea, primero creará las tablas para probarlas y completarlas. Completará las tablas obteniendo datos de AWS S3 mediante el comando `COPY`. De los laboratorios anteriores, debe recordar el comando `UNLOAD`, puede usar estos 2 comandos para integrar S3.

- `UNLOAD`: Carga datos de Redshift a S3
- `COPY`: Cargar datos de S3 a Redshift

Aquí puede encontrar la documentación de los comandos. [UNLOAD](https://docs.aws.amazon.com/redshift/latest/dg/r_UNLOAD.html) y [COPY](https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html).

Ejecute el siguiente script para crear y completar las tablas. Analice el script para comprender mejor los comandos, si lo desea.

> Tenga en cuenta que tiene algunas variables para reemplazar en el script. Reemplace la variable `<your_name>` con su nombre o apodo, y reemplace la variable `<random>` con algunos números aleatorios. **Use solo letras minúsculas y no olvide el número aleatorio, porque lo usará a veces**

```sql
-- table DDL

create table staging.<your_name>_<random>_item_sold (
	  id_item bigint encode az64
	, fk_order bigint encode az64
	, fk_current_status bigint encode az64
	, current_status_date timestamp encode az64
	, order_date timestamp encode az64
	, item_price numeric(10, 2) encode az64
) distkey(fk_order) -- clave empresarial para este escenario. se puede utilizar para mejorar el rendimiento de la unión
sortkey(order_date) -- favorable para filtros
;

create table staging.<your_name>_<random>_item_paid (
	   fk_item bigint encode az64
	 , fk_order bigint encode az64
	 , paid_date timestamp encode az64
) distkey(fk_order) -- clave empresarial para este escenario. se puede utilizar para mejorar el rendimiento de la unión
sortkey(fk_item) -- favorable para filtros
;

-- this is a small table containing a list of a few status

create table staging.<your_name>_<random>_status (
	   id_status bigint encode az64
	 , status_name varchar(43) encode zstd
	 , status_description varchar(83) encode zstd
) diststyle all -- buena opción para mesas pequeñas
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

> **ENCODE:** Puede notar en las instrucciones de `DDL` algo diferente de lo normal, la palabra clave` codificar`. ¿Que es eso? Es una buena práctica usar codificar en columnas al crear una tabla, este comando comprime los datos de la columna, por lo que la tabla necesita menos espacio para almacenarse y también mejora el rendimiento de la consulta porque Redshift puede leer los datos más rápido. Generalmente usamos el compression encoding [az64](https://docs.aws.amazon.com/redshift/latest/dg/az64-encoding.html) para datos numéricos y fechas (TIMESTAMP, DATE, BIGINT, INT, SMALLINT) y [zstd](https://docs.aws.amazon.com/redshift/latest/dg/zstd-encoding.html) para los otros tipos de datos. Ver más sobre  [encode](https://docs.aws.amazon.com/redshift/latest/dg/c_Compression_encodings.html) na documentação.


# Tarea 2: El plan de ejecución

Ahora que tienes los datos en tus tablas entenderemos cómo Redshift maneja los datos, para eso es necesario analizar el plan de ejecución creado por la base de datos para ejecutar una consulta.
Cuando envías una consulta a Redshift, se analiza tu código y en base a esto se genera un script interno, este script contiene información sobre los pasos que debe seguir Redshift para ejecutar tu consulta de la mejor manera posible. Este script interno es el plan de ejecución, cada vez que envía una consulta, se crea un nuevo plan de ejecución.
El plan de ejecución determina cosas como:

- El mejor algoritmo de unión posible para usar
- Si es necesario, cómo se deben redistribuir los datos
- El mejor orden de las tablas en `join` (sí, Redshift puede cambiar el orden de las tablas organizadas en join internamente)

El problema para nosotros en este momento es el tema 2: la redistribución de datos. Puede ver cómo se redistribuyen los datos en una consulta de plan de ejecución, pero ¿cómo se obtiene el plan de ejecución? En su consulta, use el comando `explain`.

Ejecute el siguiente código:

>  Recuerda reemplazar las variables
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
Debería recibir un resultado confuso similar a este (el plan de ejecución):

```
XN HashAggregate  (cost=2739041021.68..2739041022.46 rows=156 width=48)
  ->  XN Subquery Scan volt_dt_0  (cost=2739041018.56..2739041020.51 rows=156 width=48)
        ->  XN HashAggregate  (cost=2739041018.56..2739041018.95 rows=156 width=24)
              ->  XN Hash Right Join DS_DIST_BOTH  (cost=467.74..2739041017.39 rows=156 width=24)
                    Outer Dist Key: p.fk_item
                    Inner Dist Key: s.id_item
                    Hash Cond: ("outer".fk_item = "inner".id_item)
                    ->  XN Seq Scan on gui_1425_item_paid p  (cost=0.00..168.85 rows=16885 width=8)
                    ->  XN Hash  (cost=467.35..467.35 rows=156 width=16)
                          ->  XN Seq Scan on gui_1425_item_sold s  (cost=0.00..467.35 rows=156 width=16)
                                Filter: (date(order_date) = '2021-02-13'::date)
```
Hay mucha información en este resultado, si desea conocer el significado de cada elemento en este plan de ejecución consulte la documentación de [EXPLAIN](https://docs.aws.amazon.com/redshift/latest/dg/r_EXPLAIN.html).

¡Busquemos información sobre la redistribución de datos! Redshift puede redistribuir la tabla interna (`DS_DIST_INNER`, `DS_BCAST_INNER`, `DS_DIST_ALL_INNER`), la tabla externa (`DS_DIST_OUTER`), a veces Redshift redistribuye ambas tablas en la unión (`DS_DIST_BOTH`) y, a veces, no se requiere redistribución (`DS_DIST_NONE`, `DS_DIST_ALL_NONE`). Probablemente tenga uno de estos códigos en su resultado, intente encontrarlo.

Puede comprender mejor el significado de cada tipo de redistribución [aquí](https://docs.aws.amazon.com/redshift/latest/dg/c_data_redistribution.html).

Siempre queremos obtener `DS_DIST_NONE` y `DS_DIST_ALL_NONE`, si no se necesita redistribución, la consulta funcionará mejor.


**?Desafio:** Ahora, basándose en el conocimiento que tiene sobre `Diststyle` y `Sortkey` en Redshift, realice los cambios necesarios en la consulta para mejorar el rendimiento y lograr `DS_DIST_NONE` en el plan de ejecución. *La respuesta a este desafío está al final de este laboratorio, si lo desea, puede ir allí y validar su solución :)*

# Tarea 3: Probar diferentes combinaciones de JOIN

En esta tarea rápida, analizará una consulta para identificar un comportamiento diferente a la redistribución.

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

Tenga en cuenta la clave que está utilizando para unirse a las mesas, no es una distkety, pero no tiene una redistribución. Tienes en tu plan de ejecución `DS_DIST_ALL_NONE`, es porque una de las tablas tiene `Diststyle all`, las tablas con esta distribución funcionan bien en combinaciones con tablas que usan Diststyle `KEY` o `EVEN`.

**?Desafio:** Escreva uma consulta simples juntando as 3 tabelas que você criou neste laboratório, aplicando as melhores práticas que você aprendeu. Conte os itens e pedidos agrupados pelo status atual e flag `is_paid` (você tem que criar esta flag) filtrando apenas 3 horas de um dia específico (os dados nas suas tabelas estão entre 2021-02-13 18:00:00 e 2021-02-14 06:00:00), quando você executar o comando `explain` nenhuma redistribuição deve ser mostrada. *A resposta para este desafio está no final deste laboratório, se você quiser, pode ir lá e validar sua solução:)*

# Conclusión

Creaste algunas tablas en Redshift definiendo Diststyle y sortkey, cargaste datos desde S3 para llenar tus tablas usando el comando `COPY`, comprimiste los datos usando el comando` encode` para mejorar el rendimiento del almacenamiento, analizaste el plan de ejecución de tu consulta y rendimiento mejorado basado en información sobre redistribución de datos. ¡Felicidades!

Ha aprendido con éxito cómo:
- Utilice el comando `copy` para cargar datos de S3 en Redshift
- Mejore su consulta comprimiendo datos
- Definir y usar Diststyle y Sortkey
- Interprete su plan de ejecución de consultas


# Desafíos

## Solución de desafío - Tarea 2

En la consulta a continuación, puede notar los cambios adecuados para mejorar el rendimiento.

> Recuerde siempre reemplazar las variables
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

Primero, se agregó la clave dist para ambas tablas a la declaración `join`, aunque la unión es por el ID del elemento, las tablas se distribuyen por el ID del pedido (fk_order), por lo que puede usar distkey para unir tablas de diferentes granularidades sin causar Productos cartesianos. Cuando usamos Distkey en el `join` decimos dónde se almacenan los datos y Redshift no pierde tiempo reorganizando los datos.

El segundo cambio fue el filtro, ahora la columna en el filtro no sufre ninguna transformación, por lo que Redshift puede usar el poder de Sortkey. Desafortunadamente, no hay una manera fácil de identificar la mejora del rendimiento relacionada con Sortkey en el plan de ejecución porque Redshift solo sabrá qué bloques de datos omitir en tiempo de ejecución.


## Solução do desafio - Tarefa 3


Si ejecuta la consulta a continuación, notará que no hay redistribución de datos y es muy buena.

> Recuerde siempre reemplazar las variables
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

Para el filtro se eligió un período aleatorio de 3 horas, en el `join` se realizó en base al contenido cubierto en este Laboratorio.

Tenga en cuenta que la tabla `status` es la primera tabla en la combinación, pero en el resultado del comando `explain` la combinación aparece después de la combinación con item_paid, esto no significa que Redshift haya cambiado necesariamente el orden de las tablas en la combinación , pero las uniones en el plan de ejecución se muestran de abajo hacia arriba.