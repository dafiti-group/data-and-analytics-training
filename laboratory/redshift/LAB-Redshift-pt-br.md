# Redshift

### Objetivo

Depois de concluir este laboratório, você saberá como:

- Interpretar o plano de execução da sua consulta no Redshift
- Definir e usar Diststyle e Sortkey em sua tabela
- Popular uma tabela com dados do AWS S3
- Compactar dados para melhorar o desempenho da consulta e a eficiência no uso do espaço em disco


### Duração

Este laboratório leva 20 minutos para ser concluído.


### Visão Geral

Neste laboratório, você criará e preencherá algumas tabelas para entender como o Redshift lida com os dados para resolver sua consulta e retornar o resultado para você. Você entenderá o plano de consulta do Redshift e, em seguida, aplicará algumas modificações na consulta para melhorar o desempenho.


# Starting Lab

Para concluir este laboratório, você precisa estar conectado à VPN para acessar os recursos necessários.
Em seu Workbench (você costuma usar para acessar Redshift), crie uma nova conexão Redshift com as seguintes credenciais. Se você já tem a configuração em seu ambiente de trabalho do último laboratório, pode pular esta parte.
  
**Host:** `bi-dafiti-group-dc2-dev.cofscmejxic8.us-east-1.redshift.amazonaws.com`


**Port:** `5439`


**Database:** `dftdwh_dev`


**User:** `datatrainning`


**Password:** `Training123`


# Tarefa 1: criar e preencher

Nesta tarefa, você criará primeiro as tabelas para testá-las e preenchê-las. Você preencherá as tabelas obtendo dados do AWS S3 usando o comando `COPY`. Dos Labs anteriores, você deve se lembrar do comando `UNLOAD`, você pode usar esses 2 comandos para integrar o S3.

- `UNLOAD`: Carrega os dados do Redshift para S3
- `COPY`: Carrega os dados do S3 para Redshift

Aqui você pode encontrar a documentação referente aos comandos [UNLOAD](https://docs.aws.amazon.com/redshift/latest/dg/r_UNLOAD.html) e [COPY](https://docs.aws.amazon.com/redshift/latest/dg/r_COPY.html).

Execute o script abaixo para criar e preencher as tabelas. Analise o script para entender melhor os comandos, se desejar.

> Observe que você tem algumas variáveis para substituir no script. Substitua a variável `<your_name>` com seu nome ou apelido, e substitua a variável `<random>` com alguns números aleatórios. **Use apenas letras minúsculas e não se esqueça do número aleatório, porque você o usará às vezes**

```sql
-- table DDL

create table staging.<your_name>_<random>_item_sold (
	  id_item bigint encode az64
	, fk_order bigint encode az64
	, fk_current_status bigint encode az64
	, current_status_date timestamp encode az64
	, order_date timestamp encode az64
	, item_price numeric(10, 2) encode az64
) distkey(fk_order) -- chave de negócio para esse cenário. pode ser usado para melhorar performance de join
sortkey(order_date) -- favorável para filtros
;

create table staging.<your_name>_<random>_item_paid (
	   fk_item bigint encode az64
	 , fk_order bigint encode az64
	 , paid_date timestamp encode az64
) distkey(fk_order) -- chave de negócio para esse cenário. pode ser usado para melhorar performance de join
sortkey(fk_item) -- favorável para filtros
;

-- this is a small table containing a list of a few status

create table staging.<your_name>_<random>_status (
	   id_status bigint encode az64
	 , status_name varchar(43) encode zstd
	 , status_description varchar(83) encode zstd
) diststyle all -- boa escolha para tabelas pequenas
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

> **ENCODE:** Você pode notar nas instruções `DDL` algo diferente do normal, a palavra-chave `encode`. O que é isso? É uma boa prática usar encode nas colunas ao criar uma tabela, este comando comprime os dados da coluna, desta forma a tabela precisa de menos espaço para ser armazenada e também melhora o desempenho da consulta pois o Redshift pode ler os dados mais rápido. Geralmente usamos o compression encoding [az64](https://docs.aws.amazon.com/redshift/latest/dg/az64-encoding.html) para dados numéricos e datas (TIMESTAMP, DATE, BIGINT, INT, SMALLINT) e [zstd](https://docs.aws.amazon.com/redshift/latest/dg/zstd-encoding.html) para os outros tipos de dados. Veja mais sobre [encode](https://docs.aws.amazon.com/redshift/latest/dg/c_Compression_encodings.html) na documentação.


# Tarefa 2: O Plano de Execução

Agora que você tem os dados em suas tabelas vamos entender como o Redshift lida com os dados, para isso é preciso analisar o plano de execução criado pelo banco de dados para executar uma consulta.
Quando você envia uma consulta ao Redshift, seu código é analisado e baseado em que um script interno é gerado, esse script contém informações sobre as etapas que o Redshift deve realizar para executar sua consulta da melhor maneira possível. Este script interno é o plano de execução, cada vez que você envia uma consulta, um novo plano de execução é criado.
O plano de execução determina coisas como:

- O melhor algoritmo de junção possível para usar
- Se necessário, como os dados devem ser redistribuídos
- A melhor ordem das tabelas no `join` (sim, o Redshift pode alterar a ordem das tabelas dispostas no join internamente)

A questão para nós neste momento no tópico 2: redistribuição de dados. Você pode ver como os dados são redistribuídos em uma consulta no plano de execução, mas como obter o plano de execução? Em sua consulta, use o comando `explain`.

Execute o código abaixo:

>  Lembre-se de substituir as variáveis
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
Você deve receber uma saída confusa semelhante a esta (o plano de execução):

```
```
Existem muitas informações neste resultado, se você deseja saber o significado de cada elemento neste plano de execução consulte a documentação sobre [EXPLAIN](https://docs.aws.amazon.com/redshift/latest/dg/r_EXPLAIN.html).

Vamos encontrar as informações sobre a redistribuição de dados! O Redshift pode redistribuir a tabela interna (`DS_DIST_INNER`, `DS_BCAST_INNER`, `DS_DIST_ALL_INNER`), a tabela externa (`DS_DIST_OUTER`), às vezes Redshift redistribuir ambas as tabelas no join (`DS_DIST_BOTH`) e às vezes nenhuma redistribuição é necessária (`DS_DIST_NONE`, `DS_DIST_ALL_NONE`). Provavelmente você tem um desses códigos no seu resultado, tente encontrá-lo.

Você pode entender melhor o significado de cada tipo de redistribuição [aqui](https://docs.aws.amazon.com/redshift/latest/dg/c_data_redistribution.html).

Sempre queremos obter `DS_DIST_NONE` e `DS_DIST_ALL_NONE`, se nenhuma redistribuição for necessária, a consulta terá um desempenho melhor.


**?Desafio:** Agora, com base no conhecimento que você tem sobre `Diststyle` e `Sortkey` no Redshift, faça as alterações necessárias na consulta para melhorar o desempenho e alcançar `DS_DIST_NONE` no plano de execução. *A resposta para este desafio está no final deste laboratório, se você quiser, pode ir lá e validar sua solução :)*

# Tarefa 3: Testando diferentes combinações de junção

Nesta tarefa rápida, você irá analizar uma consulta para identificar um comportamento diferente de redistribuição.

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

Observe a chave que você está usando para juntar as tabelas, não é um distkety, mas você não tem uma redistribuição. Você tem em seu plano de execução `DS_DIST_ALL_NONE`, é porque uma das tabelas tem `Diststyle all`, tabelas com esta distribuição funcionam bem em joins com tabelas usando Diststyle `KEY` ou `EVEN`.

**?Desafio:** Escreva uma consulta simples juntando as 3 tabelas que você criou neste laboratório, aplicando as melhores práticas que você aprendeu. Conte os itens e pedidos agrupados pelo status atual e flag `is_paid` (você tem que criar esta flag) filtrando apenas 3 horas de um dia específico, quando você executa o comando `explain` nenhuma redistribuição deve ser mostrada. *A resposta para este desafio está no final deste laboratório, se você quiser, pode ir lá e validar sua solução:)*

# Conclusão

Você criou algumas tabelas em Redshift definindo Diststyle e sortkey, carregou dados do S3 para preencher suas tabelas usando o comando `COPY`, compactou os dados usando o comando `encode` para melhorar o desempenho do armazenamento, você analisou o plano de execução de sua consulta e melhorou a performance com base em informações sobre redistribuição de dados. Parabéns!

Você aprendeu com sucesso como:
- Usar o comando `copy` para carregar os dados do S3 no Redshift
- Melhorar sua consulta compactando dados
- Definir e usar Diststyle e Sortkey
- Interpretar o plano de execução da sua consulta


# Desafios

## Solução do desafio - Tarefa 2

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


## Solução do desafio - Tarefa 3


Se você executar a consulta abaixo, notará que não há redistribuição de dados, e é muito bom.

> Lembre-se sempre de substituir as variáveis
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

Para o filtro foi escolhido um período aleatório de 3 horas, no `join` foi feita com base no conteúdo abordado neste Laboratório.