# Data Pipeline


### Objetivos

Depois de concluir este laboratório, você saberá como:

- Usar a ferramenta de versão git
- Criar um processo de Named Query usando o módulo query do Glove
- Implantar um processo de Named Query
- Crie um pipeline de dados no Hanger

### Duração

Este laboratório leva 40 minutos para ser concluído.


### Pré-requisitos

Você precisa de um software específico instalado em sua máquina para concluir esse laboratório devidamente.
Usaremos a ferramenta de versão git.

- Para Windows você acessar [aqui](https://gitforwindows.org/) para baixar e instalar.

- Para Linux, você pode executar o seguinte comando para instalar

```shell
sudo apt-get install git
```

Você também precisa ter uma conta na plataforma github, se necessário você pode criar sua conta clicando [aqui](https://github.com/join).

Eu recomendo que você use seu e-mail comercial para se registrar no github.


### Overview

- **Git** é uma ferramenta de versão que pode ser usada para rastrear todas as alterações em seus projetos, você pode ter várias versões de um arquivo e gerenciar todas as alterações.

- **Glove** é uma ferramenta de integração de dados que podemos usar para criar tarefas ETL, automatizar execuções de scripts SQL e muito mais. Neste laboratório, usaremos um módulo específico de Glove: módulo query.

- **Hanger** é um serviço de orquestração de workflows, que nos ajuda a automatizar, gerenciar, organizar e validar nossos jobs e workflows.


  
# Starting Lab
  
Neste laboratório, você usará a ferramenta de versão git para controlar e isolar suas modificações em um repositório git (usaremos o [Github](https://github.com/)). Você criará um processo de Named Query e implantará usando git para ser executado no Hanger com luva usando o módulo query. No Hanger, você cria um Health Check para validar a integridade do seu processo.

Em seu processo de Named Query, você criará uma tabela de fatos simples para vendas combinando alguns atributos de configuração.
  
  
# Tarefa 1: preparando o ambiente
  
Nesta tarefa, você começa definindo o repositório git para implantar seu NQ (Named Query), abra o `Git bash` instalado em seu sistema Windows ou abra o terminal se você estiver usando Linux e certifique-se de que está na pasta home de seu usuário. Você pode validar executando o seguinte comando:

```shell
pwd
```

Você deve obter uma saída semelhante a esta:

```
/home/<your.username>
```

ou semelhante a este:
```
/c/users/<your.username>
```

Se sua saída não for semelhante aos exemplos acima, você pode tentar corrigir executando o seguinte comando:

```shell
cd ~
```



### 1.1 Configure sua conta Github

O repositório que vamos usar no Laboratório tem um nível de segurança que precisa ser acessado com protocolo SSH, então você precisa gerar uma chave SSH para definir em sua conta github, se você já tiver uma chave SSH configurada em sua conta você pode pular esta etapa e ir para `1.2`.

Para fazer isso, execute o seguinte comando:

```shell
ssh-keygen
```

Em seguida, pressione `ENTER` 3 vezes até obter uma saída semelhante ao texto abaixo:

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

Agora precisamos pegar a chave gerada para configurar no Github, para imprimir a chave em seu terminal execute o seguinte comando:

```shell
cat ~/.ssh/id_rsa.pub
```

Em seguida, copie o resultado da saída.

Vá para o Github, vá para `settings`:

![github-menu](https://user-images.githubusercontent.com/57373602/106788267-c94c1700-6661-11eb-9c0f-9fa94136376a.png) 

Na barra de navegação à esquerda, encontre e selecione `SSH and GPG Keys`, clique no botão verde` New SSH Key`

![set shh](https://user-images.githubusercontent.com/57373602/106793741-e33d2800-6668-11eb-9deb-fd64b14f8521.png)

Irá abrir uma área de texto, no campo `key` após o valor que você copiou da linha de comando e clique em `Add SSH Key`.

Agora você tem uma chave SSH configurada em sua conta para segurança.


### 1.2 Clonando o repositório

Vamos criar uma pasta para hospedar o repositório clonado, execute o comando abaixo:

> **Importante:** Dependendo da configuração do seu computador e do programa instalado a pasta `Documentos` pode aparecer em outro idioma no terminal do git como no comando abaixo que está em inglês, verifique em qual idioma o git está identificando as pastas e faça as alterações no comando caso seja necessário. Para identificar o nome correto da pasta (`Documents` ou `Documentos`) use o comando `ls -l` para listar as pastas no seu diretório atual e encontar a pasta de documentos.

```shell
mkdir -p Documents/training_repo;cd Documents/training_repo;pwd
```

Observe que agora você está dentro de um diretório diferente, é aqui que iremos clonar o repositório para desenvolver o NQ.

Agora abra nosso repositório público github disponível no seguinte [link (data-and-analytics-training)](https://github.com/dafiti-group/data-and-analytics-training). Clique no botão verde `Code`, selecione `SSH` e copie o link que deve ser semelhante a este: `git@github.com:dafiti-group/data-and-analytics-training.git`.

De volta ao terminal, execute o comando git para baixar o repositório para sua máquina local.

> Substitua <copied_link> pelo link que você copiou do github

```shell
git clone <copied_link>
```
Ao executar o comando abaixo, você pode ver que uma nova pasta foi criada

```shell
ls -l
```

Agora, uma cópia do repositório foi criada para você. Navegue dentro da nova pasta com o comando abaixo:

```shell
cd data-and-analytics-training
```

### 1.3 Pasta de destino

Antes de começar a criar o NQ, precisamos criar uma área isolada no repositório recentemente clonado para evitar conflitos com as modificações de alguém. Para fazer isso, você criará um branch. Crie uma filial com seu nome:

```shell
git branch <your.name>
```
Agora que você criou no branch, você deve navegar dentro dele para manter todo o seu desenvolvimento isolado, para isso, execute o comando:

```shell
git switch <your.name>
```

Agora você está dentro de sua nova filial. Por fim, você criará uma pasta em sua filial para armazenar o NQ que criará:

> na variável <your.name|random> escreva seu nome e adicione alguns números aleatórios para evitar conflitos de nome no repositório. **Salve o valor desta variável, você precisará disso mais tarde.**

```shell
mkdir -p training/platform/<your.name|random>
```

> Para listar todos os branchs disponíveis em seu repositório execute o comando `git branch`

# Tarefa 2: Criar Named Query

Nesta tarefa, você definirá algumas etapas do NQ para criar uma tabela de fatos no Data Lake (o ideal seria criar no Data Warehouse, mas para fins didáticos usaremos uma abordagem diferente). Você extrairá dados do Athena e irá modelar a tabela no Redshift, você saberá na prática como cada escopo de Named Query funciona.

Abra seu editor de texto preferido e crie um arquivo com a seguinte consulta:

> **Nota:** existem 2 variáveis ​​nesta consulta, mas você não precisa substituí-la, você irá definir o valor das variáveis ​​nos parâmetros do Glove

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
Anteriormente, você criou uma pasta em seu repositório no seguinte caminho: `training/platform/<your.name|random>`, em seus `Documents` encontre este caminho em seu repositório e salve o arquivo com o seguinte nome:
> substitua a variável `<your-name>` com seu nome e substitua a variável `<random>` com algum valor aleatório. **Lembre-se desse valor aleatório, você precisará dele em breve.**

`1.spc_staging.fact_sales_delta_load_<your-name>_<random>.athena.full.sql`

Crie um segundo arquivo com a consulta abaixo. Na cláusula `from`, você precisa substituir as variáveis ​​pelos valores usados ​​para nomear o arquivo anterior.


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

Na mesma pasta do seu repositório, salve o arquivo com o seguinte nome:
> substitua a variável `<your-name>` com seu nome e substitua a variável `<random>` com algum valor aleatório. **Lembre-se desse valor aleatório, você precisará dele mais tarde.**

`2.spc_business_layer.fact_sales_training_<your-name>_<random>.redshift.partition.sql`

---
Basicamente quando o Glove executa essas 2 etapas, a execução do primeiro arquivo irá consultar o Amazon Athena e o resultado será usado para criar uma tabela no Spectrum, o nome da tabela será o que você definiu no nome do arquivo, neste caso será:

`spc_staging.fact_sales_delta_load_<your-name>_<random>`

Sempre que o processo for executado, os dados desta tabela serão substituídos pelos novos dados, pois o escopo desta etapa é `full`, os dados serão substituídos `full (completamente)`.

A execução do segundo arquivo consultará a tabela criada pela etapa anterior por meio do Redshift e o resultado será usado para criar a tabela fato no Spectrum. O nome da tabela será o que você definiu no nome do arquivo, neste caso será:

`spc_business_layer.fact_sales_training_<your-name>_<random>`

Sempre que o processo for executado os dados históricos desta tabela serão mantidos, os novos dados serão anexados e se houver mais de uma linha com o mesmo valor `custom_primary_key`, apenas o último registro será persistido.

Logo o entenderemos melhor na prática.


# Tarefa 3: implantar no Github

De volta à linha de comando do git, agora que você salvou os arquivos no repositório, você deve ser capaz de vê-los com o git.

### 3.1 Commit the Changes

Execute o comando:

```shell
git status
```

Ele deve mostrar o nome da pasta que você criou escrito em vermelho. Isso aparece desta forma porque o git está dizendo que há algumas modificações no repositório, mas o git não se importa com isso **ainda**.

Agora execute o comando:

```shell
git add ./
```

Este comando adiciona todos os arquivos modificados a uma área de teste. O Git aplicará as modificações ao repositório apenas para arquivos nesta área de teste. Se algum arquivo ao qual você aplicou alguma alteração não for adicionado a esta área de teste, as alterações nunca poderão ser disponibilizadas para outros usuários, elas ficarão visíveis apenas para você.
Se você precisar de qualquer arquivo na área de teste pode ser revertido.

Execute novamente o comando:

```shell
git status
```

Ele deve mostrar em verde o nome dos 2 arquivos que você acabou de criar. Quando o nome do seu arquivo aparece na cor verde quando você executa o comando `git status`, significa que o arquivo foi adicionado com sucesso à área de teste.

> Se os arquivos que você criou não aparecerem na saída do comando, revise as últimas etapas executadas e peça ajuda.

A seguir, execute este comando:

```shell
git commit -m "deploy of my first named query"
```

Este comando obtém todos os arquivos que você adicionou à área de teste e aplica as alterações permanentemente.

Para terminar, você precisa enviar os arquivos que você criou / modificou para o repositório na nuvem. Execute o comando abaixo.
> Neste caso, a variável `<your.name>` é o nome do branch que você criou anteriormente. Se necessário, revise o laboratório para se lembrar de como listar seus ramos, caso tenha esquecido o nome com que criou o ramo.

```shell
git push origin <your.name>
```

Agora seus arquivos devem estar disponíveis no Github.

### 3.2 Criar um Pull Request

Para completar a implantação no Github, as mudanças em seu branch devem ser unidas ao branch master/main. Para fazer isso volte ao repositório github em seu navegador, localize e clique no botão `branch`, uma lista de branches deverá aparecer, encontre seu branch e clique no botão `New Pull Request` no lado direito.

Uma área de texto deve aparecer para você descrever o conteúdo do seu ramo, clique no botão verde `Criar solicitação de pull`

Quando você cria um `pull request`, está solicitando que suas modificações sejam aplicadas no branch principal, para que qualquer pessoa possa ver suas alterações.

Peça ao seu instrutor para aprovar sua solicitação de pull para que você possa continuar com o laboratório.

# Tarefa 4: Job no Hanger

Agora seus arquivos estão disponíveis no repositório Github Glove pode acessá-los para rodar seu processo, para que possamos criar o Job no Hanger.

Abra o link abaixo para acessar o aplicativo Hanger:
[http://hanger-dev.dafiticorp.com:8080/hanger/](http://hanger-dev.dafiticorp.com:8080/hanger/)

Na barra lateral esquerda, clique em `Login` na parte inferior.

Faça login usando as seguintes credenciais:

**username:** `data.trainning`

**password:** `vkQL4`

Agora você deve ver a página inicial listando alguns `Subjects`.

### 4.1 Configurando o Job

Agora você criará seu Job e o organizará no Assunto que criou no último Laboratório.

1. Na barra lateral esquerda, clique no ![arrow down icon](https://user-images.githubusercontent.com/57373602/106918451-44710400-671a-11eb-86b8-ca1ba37a6c92.png) ícone em `Job` e, em seguida, clique em `Add Job`

2. Na parte superior da página, clique em `Create`

3. No campo `Template` verifique se o valor selecionado é` TEMPLATE_EMPTY`

4. no campo `Name` nome como` Trial-Trainning-${YOUR_NAME}-GLOVE_NQ_fact_sales` (não se esqueça de substituir a variável)

5. clique `>> Next`

6. Na parte inferior da página, clique no botão ![arrow up icon](https://user-images.githubusercontent.com/57373602/106918873-a7629b00-671a-11eb-8c43-2f166fb03655.png) em `Shell Script` e selecione a opção `SHELL_TEMPLATE-GLOVE-NQ-TRAINNING`

7. No campo `DAYS_GONE_FROM_DATE` digite` 14`
(Início do intervalo delta para atualizar a tabela)


9. Defina `Named Query Folder` com o nome da pasta de seu NQ que você definiu na variável `<your.name|random>`
(pasta contendo sua Named Query)

10. No campo `DAYS_GONE_TO_DATE` digite` 7`
(Fim do intervalo delta para atualizar a tabela)


Nos outros campos você pode manter o valor padrão:

 **Target:** esta variável define onde o Glove irá criar a tabela com os resultados de cada passo da sua Named Query, neste caso queremos criar as tabelas no Spectrum (S3), então você pode manter o valor padrão

13. Clique em `Add`, então deve adicionar um script de shell com os valores que você inseriu.
Este script executa um processo Glove e executa seu NQ.

14. No final da página clique em `Subject`, selecione o assunto que você criou no último Lab e clique em `Add`

15. No final da página clique no botão `Checkup`, ele irá adicionar alguns novos campos para você preencher

16. Nos campos `Name` e `Description` coloque `validação de carga`

17. Em `connection` selecione `REDSHIFT DEV`

18. No campo `SQL` coloque a query abaixo

>  Lembre-se de substituir as variáveis ​​pelos mesmos valores que você usou para definir o nome do arquivo do seu NQ
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

Esta consulta será executada quando seu processo terminar, para validar a carga e ter certeza de que está tudo bem.

19. Em `Condition` selecione `LOWER_THAN_OR_EQUAL`

20. Em `Threshold` coloque o valor `2`

21. No final da página clique em `Save` e, em seguida, clique em `Build`

Agora seu Job NQ será enfileirado e executado, pode levar algum tempo para ser executado e você pode pressionar `F5` para atualizar a página e validar o status do Job atual. Seu Job pode passar por 3 status:

*`Building` ou `Rebuilding`:* Significa que o seu Job está na fila e esperando para ser executado (o Job está esperando na fila por causa da limitação do servidor ou bloqueio de dependências)
*`Running`:* Significa que seu Job está em execução
*`Success`:* Significa que seu Job foi concluído sem nenhum erro

> Se o seu Job receber qualquer outro status diferente, você pode clicar no ícone `?` No lado direito da tela para ver a descrição de cada status.

### 4.2 Validando o comportamento do processo

Agora que seu processo foi executado com sucesso, você pode consultar a tabela que foi criada:

```sql
select * from spc_business_layer.fact_sales_training_<your-name>_<random> limit 100;
```

Agora para validar o comportamento do seu processo você irá executá-lo novamente mas alterando os valores de algumas variáveis, clique no nome do seu Job, no final da página clique em `Edit`.

No script de shell existem 2 variáveis ​​nas 2 primeiras linhas, `DAYS_GONE_FROM_DATE` e` DAYS_GONE_TO_DATE`, altere os valores dessas 2 variáveis ​​para `7` e` 0` respectivamente.

No final da página clique em `Save` e, em seguida, clique em` Build`

Quando o processo terminar, execute as 2 consultas abaixo. Você notará que a tabela na primeira consulta (gerada pela primeira etapa do seu NQ) contém dados referentes apenas aos últimos 7 dias conforme você alterou os parâmetros na configuração do Job, porque a primeira etapa do seu NQ tem escopo `full`.

A tabela da segunda consulta (gerada pela segunda etapa do seu NQ) contém dados referentes aos últimos 14 dias, Glove não substituiu os dados histocais, apenas as alterações foram aplicadas, pois a segunda etapa do seu NQ tem escopo `partition`.

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

### 4.3 Validar integridade da carga

De volta ao Hanger, na frente do nome do seu Job deve aparecer o texto `CHECKUP`. Clique neste link para abrir uma nova tela contendo uma lista de execuções do HealthCheck para o seu processo, e você pode analisar se está tudo bem. Você pode alterar a visualização do gráfico para uma visualização de tabela.

Sinta-se à vontade para explorar o Hanger.

# Conclusão

Você criou um processo de Named Query usando um módulo específico de integração de dados do Glove e fez todas as configurações no Hanger com Health Check para validar a qualidade do seu processo. Você usou git e Github para fazer a implantação do seu processo e isolar todas as suas alterações para evitar conflitos. Parabéns!

Você aprendeu com sucesso como:

- Configurar sua conta Github para usar SSH
- Usar a ferramenta git version para manipular suas modificações
- Criar e configurar um processo de Named Query
- Criar e configurar um Job no Hanger
- Adicionar HealthChecks ao seu Job

#### Referências
[Hanger - Github](https://github.com/dafiti-group/hanger)

[User friendly documentation](https://sites.google.com/dafiti.com.br/data-and-analytics-en-docs/home)
