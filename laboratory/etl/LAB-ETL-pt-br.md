# Criando um Processo de ETL Simples

### Objetivo

Após completar esse laboratório, você terá aprendido como:

- Manipular com SQL puro para fazer um ETL 
- Lidar com alguns formatos de 
- Criar um processo de ETL automatizado usando Glove
- Criar um Pipeline de dados no Hanger

ashdfuahfduahf
asdhfuashdfud

kakakaka hahahha kkkkkkkkk

HASUHASUHSAUSAHAUSHSU
kkkkkkkkkkkkkkkkkkkkkkk
hahahah kkkkkkkkkkk

### Duração

São necessários 40 minutos para completar esse laboratório


### Visão Geral

Nesse laboratório você irá criar e executar processos ETL extraindo dados de 2 fontes diferentes para carregar em nosso data lake (AWS S3). Durante a execução os dados serão convertidos para arquivos Parquet* para que você tenha uma forma padronizada de acessar os dados através do Redshift Spectrum. Primeiro você vai executar um ETL manualmente para fixar o entendimento do conceito e então usar o Hanger para criar e configurar um Job Glove.

> ***Parquet*** é um formato de arquivo colunar amplamente usado para armazenar dados no data lake ao invés de usar formatos de arquivos convencionais como CSV ou JSON. Como Parquet é colunar (os dados são lidos por coluna) você pode alcançar melhores performance nas consultas e redução de custo no final do mês se forem aplicadas as boas práticas.

> Outro famoso formato de arquivo colunar similar ao ***Parquet*** é o format ***ORC***


# Iniciando o Laboratório

Para completar esse Lab você precisa estar conectado à VPN para acessar os recursos necessários.
Em seu Workbench (que você usa frequentemente para acessar o Redshift) crie uma nova conexão para Redshift com as credenciais a seguir.

**Host:** `bi-dafiti-group-dc2-dev.cofscmejxic8.us-east-1.redshift.amazonaws.com`


**Port:** `5439`


**Database:** `dftdwh_dev`


**User:** `datatrainning`


**Password:** `Training123`
  
  
# Tarefa 1: Processo ETL Manual
  
Nessa tarefa você vai executar um processo de ETL manualmente para fixar o entendimento do conceito fundamental. Você irá manipular os dados armazenados em nosso data lake fazendo uso do Redshift e Redshift Spectrum. Você irá converter um arquivo CSV para Parquet e aplicar alguns tratamentos de dados.
  
### Preparação para o Processo
  
Há um arquivo CSV comprimido nomeado como `nps_origin_type.csv.gz` armazenado no seguindo caminho de um bucket S3 `s3://bi-dafiti-group-dev/dft-trainning/etl-lab/raw-data/`.
Abaixo há um exemplo dos dados existentes nesse arquivo:
  
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

Agora no Redshift você vai criar uma tabela externa através do `Redshift Spectrum` apontando para o arquivo no S3.
Execute a query abaixo.

> Repare que há algumas variáveis na query e você precisa alterá-las, substitua ${YOUR_NAME} com seu nome ou apelido, substitua ${RANDOM} com alguns números aleatórios. **Use apenas letras minúsculas e anote e não esqueça os números aleatórios pois eles serão necessários mais algumas vezes**

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

Você pode consultar a tabela para ver alguns dados:

```sql
select * from spc_staging.${YOUR_NAME}_${RANDOM}_raw_nps_origin_type limit 100;
```

Como você pode notar os dados poderiam ter uma aparência melhor, então agora você irá aplicar alguns tratamentos para isso. Agora que você consegue consultar os dados no arquivo CSV to é capaz de **E**xtrair, **T**ransformar e **L**oad (carregar) os dados.

### Executando um ETL

O que você irá fazer nesse momento:

- **Extract:**
	-  Consultar a tabela externa para ler o arquivo CSV
- **Transform:**
	- Converter os dados para Parquet e aplicar algumas funções de transformação
	- Adicionar um campo novo chamado `description_group` como uma forma de organização e categorização dos dados
- **Load:** 
	- Armazenar o novo arquivo covertido de volta para o S3 e criar uma nova tabela apontando para o dado tratado

Execute o script a seguir, é o seu processo de ETL:
> Note que há algumas variáveis na query e você deve alterá-las, você pode analisar o script antes de executar.

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


Agora você só precisa criar uma tabela externa apontando para o arquivo que você acabou de carregar no S3 e então você vai poder consultar o dado tratado.


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


Se você não receber nenhum erro, você pode agora consultar seu arquivo parquet e ver o seu dado tratado.


```sql
select * from spc_staging.${YOUR_NAME}_${RANDOM}_nps_origin_type limit 100;
```


# Tarefa 2: ETL Fácil com o Glove

Nessa tarefa você irá criar um Job no Hanger Data Orchestration e configurar um processo ETL usando o Glove Data Integration. O Hanger deixa nosso trabalho de criação de Jobs usando o Glove muito mais fácil.

Hanger trabalha junto com o Glove para gerenciar todos os fluxos de processos para garantir a ordem de execução, validação de dados e mais.

Você vai extrair dados do sistema de NPS para ser capaz de visualizar as notas do clientes.

### Acesso ao Hanger

1. Acesse o link abaixo para acessar a aplicação do Hanger
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

2. Na barra lateral esquerda clique em `Login` na parte inferior

3. Faça login usando as seguintes credenciais:


**username:** `data.trainning`


**password:** `vkQL4`


Após o login você deve ser redirecionado para a página inicial e ver alguns `Subjects` listados.

### Criação de Assunto

Antes de criar um Job você vai explorar algumas features do Hanger. Uma delas é o `Subject`, você pode criar assuntos para organizar seus jobs, entrar e acessar de forma mais fácil pois os assuntos são listados na página inicial para você.

1. Na barra de navegação no lado esquerdo, clique no icone ![arrow down icon](https://user-images.githubusercontent.com/57373602/106918451-44710400-671a-11eb-86b8-ca1ba37a6c92.png) em `Subject` e então selecione `Add Subject`

2. No primeiro campo `Subject Name` coloque seu nome para ser mais fácil de encontrar mais tarde

3. Clique `Save`, o assunto será adicionado


### Criando e Configurando um Job ETL

Agora você vai criar seu próprio Job ETL e organizar no assunto que você criou.

1. Na barra lateral esquerda, clique no ícone ![arrow down icon](https://user-images.githubusercontent.com/57373602/106918451-44710400-671a-11eb-86b8-ca1ba37a6c92.png) em `Job` e clique em `Add Job`

2. Na parte superior da página clique em `Create`

3. No campo `Template` garanta que o valor selecionado seja `TEMPLATE_EMPTY`

4. No campo `Name` nomeie o Job como `Trial-Training-${YOUR_NAME}-Glove_raw_nps_feedback` (não esqueça de substituir a variável)

5. Clique em `>> Next`

6. Na parte inferior da tela clique no ícone ![arrow up icon](https://user-images.githubusercontent.com/57373602/106918873-a7629b00-671a-11eb-8c43-2f166fb03655.png) em `Shell Script` and select the option `SHELL_TEMPLATE-GLOVE-DATABASE-TRAINNING`

7. No campo `Source Table Name` coloque `nps_feedback` 
(nome da tabela no dados de dados de origem)

8. Coloque `Target` como `spectrum` 
(*Target* é o destino de armazenamento dos dados)

9. Coloque `Output Table Schema` como `spc_staging`
(Schema de destino dos dados extraídos)

10. Coloque `Output Table Name` como `raw_nps_feedback_${YOUR_NAME}_${RANDOM}`. Não esqueça de substituir as variáveis*
(Nome da tabela destino para guardar os dados extraídos)

11. Coloque `Connection name` como `raw_nps` 
(Referência da conexão para acessar a fonte de dados)

12. Coloque `Source Table Schema` como `public` 
(Nome do schema na fonte de dados)

Os outros campos você pode manter o valor padrão:
**Storage Bucket:** Define o bucket S3 onde os dados serão armazenados
**Output Format:** Define o formato de arquivo que será escrito no S3, o padrão é Parquet
**Dataset Name:** Define o nome do database no Redshift
 **Delta Field:** Quando criamos um processo ETL não podemos extrair todos os dados da fonte em todas as execuções, é necessário fazer isso uma vez e nas próximas execuções extrair apenas os novos dados e os dados atualizados. Para isso devemos definir um campo de delta da tabela que será a base para extrair apenas o dado necessário, geralmente o campo usado é o `updated_at`.
 
 13. Clique `Add` e um script shell deve aparecer contendo os valores que você inseriu.
 Esse script que vai executar o ETL
 
 14. No fim da página clique em `Subject`, selecione o assunto que você criou e clique em `Add`
 
 15. No final da página clique em `Save` e depois clique em `Build`
 
 Agora seu Job ETL entrará na fila para ser executado, pode levar algum tempo para a execução finalizar então você pode atualizar a pagina pressionando `F5` e verificar o status atual do job. Seu Job pode passar por 3 status:
 
*`Building` ou `Rebuilding`:* Status que indica que seu Job está na fila esperando para ser executado (o job espera na fila devido a limitações do servidor ou alguma dependência que está bloqueando)
*`Running`:* Status que indica que seu Job está executando
*`Success`:* Status que indica que seu Job finalizou sem erros


> Se o seu Job receber algum status diferente você pode clicar no ícone `?` que está no lado direito da tela para ver a descrição do significado de cada status.


Após o Job estar concluído você pode tentar consultar a tabela extraída

```sql
select * from spc_staging.raw_nps_feedback_${YOUR_NAME}_${RANDOM} limit 100;
```


# Tarefa 3: Automatização do processo no Hanger

Nessa tarefa você irá aplicar uma configuração em seu Job ETL para automatiza-lo, e você fará isso adicionando um outro Job como dependência ao seu processo. Você pode adicionar quantas dependências forem necessárias ao seu processo, no Hanger as dependências são tratadas como `Parents (pais)`.


### Add Parent


1. Navegue até a página inicial do Hanger clicando em `Monitor` na barra de navegação que está a esquerda

2. Clique no nome do assunto (`Subject`) que você criou anteriormente, e então seu job deve aparecer

3. Clique no botão `Flow`

4. Clique com o botão direito no seu Job, selecione `= Actions` > `+ Parent`, selecione `DEV`

5. No campo `Jobs` pesquise e selecione o Job `DATA-TRAINNING-ETL-GLOVE_raw_trigger_05hr`. clique em `Add`

Você irá perceber que um novo Job está conectado ao seu. Esse Job que foi adicionado é uma Trigger que irá disparar o seu processo automaticamente todos os dias as 5hr.


# Conclusão

Você usou o Redshift e o Redshift Spectrum para lidar com alguns tipos dados e executar um processo simples de ETL. Você completou com sucesso a criação do seu próprio processo de ETL usando o Glove gerenciado pelo Hanger configuração os parâmetros necessários para extrair os dados do sistema e carregar em nosso Data Lake. Parabéns!

Você aprendeu:

- Ler arquivos no S3 usando o Redshift Spectrum
- Escrever arquivos no S3 com o Redshift
- Criar assuntos no hanger para organizar os seus Jobs
- Criar e configurar um processo de ETL usando o Glove
- Adicionar dependências in em processo para automatização


O glove possui muitas possibilidades para serem exploradas, você pode encontrar a documentação no [GitHub](https://github.com/dafiti-group/glove).
