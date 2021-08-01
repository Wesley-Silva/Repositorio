https://msdn.microsoft.com/pt-br/library/dn450975.aspx

--1- Mostre o nome do cliente para todos os clientes que já fizeram um pagamento de mais de US $ 100.000.
SELECT customerName
FROM customers c
WHERE EXISTS (
	SELECT 1
	FROM payments p
	WHERE p.customerNumber = c.customerNumber
		AND p.amount > 100000)
--2- Mostre o código do produto, o nome do produto e a quantidade em estoque de todos os produtos que 
--têm um preço de compra maior do que a média. 
SELECT productCode
	, productName
	, quantityInStock
FROM products
WHERE buyPrice > (SELECT AVG(buyPrice) FROM products)
--3- Mostre o nome do produto, a descrição do produto e a linha de produtos para o 
--produto em cada linha de produtos que tenha a maior receita bruta.
WITH cte1 AS (
	SELECT productCode
		, SUM(quantityOrdered*priceEach) AS totalOrdered
	FROM orderdetails
	GROUP BY productCode
)
SELECT productName
	, productDescription
	, productLine
FROM products p
	JOIN cte1 ON cte1.productCode = p.productCode
WHERE cte1.totalOrdered = 
	(SELECT MAX(totalOrdered)
	FROM cte1
	JOIN products p2 ON p2.productCode = cte1.productCode
	WHERE p2.productLine = p.productLine)
--4- Mostre o nome do funcionário, o sobrenome e o título do cargo para todos os funcionários com o título de representante de vendas 
SELECT firstName, lastName, jobTitle
FROM employees
WHERE jobTitle= 'Sales Rep'
--5- Precisamos obter alguns comentários de todos os funcionários que venderam a Harley Davidson Motorcycles. 
--Obtenha um relatório dos nomes dos funcionários e e-mails para todos os funcionários que já venderam uma Harley.
SELECT DISTINCT e.firstName
	, e.email
FROM products p JOIN orderdetails od ON p.productCode = od.productCode
JOIN orders o ON o.orderNumber = od.orderNumber
JOIN customers c ON c.customerNumber = o.customerNumber
 JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
WHERE p.productName LIKE '%Harley%'
--6- Queremos exibir informações sobre clientes da França e dos EUA. 
--Mostre o nome do cliente, o primeiro e último nome de contato (na mesma coluna) e o país para todos esses clientes.
SELECT customerName
	, contactFirstName + ' ' + contactLastName AS 'Contact Name'
	, country
FROM customers
WHERE country IN ('France', 'USA')
--7- Queremos cavar no histórico de pedidos do cliente. Mostre cada nome de cliente, juntamente com a data de sua ordem 
--inicial e sua ordem mais recente. Ligue para a ordem inicial 'first_order' e a última 'last_order'. Inclua também clientes que nunca fizeram um pedido.
SELECT c.customerName
	, MIN(orderDate) AS 'first_order'
	, MAX(orderDate) AS 'last_order'
FROM customers c
LEFT JOIN orders o ON c.customerNumber = o.customerNumber
GROUP BY c.customerName
--8- Mostre cada cidade do escritório e a média de pedidos por empregado por escritório (sem exibir a média individual dos funcionários). Por exemplo, diga que o escritório ABC tem 2 funcionários. O empregado # 1 era responsável por 2 ordens, e o empregado # 2 era responsável por 6 pedidos. Em seguida, o seu conjunto de resultados deve mostrar ABC para a primeira coluna (cidade) e 4 para a segunda coluna (ordens média por empregado por escritório: (2 + 6) / 2).
WITH employee_orders AS (
	SELECT e.officeCode
	, e.employeeNumber
	, COUNT(o.orderNumber) AS order_count
	FROM employees e
	LEFT JOIN customers c ON c.salesRepEmployeeNumber = e.employeeNumber
	LEFT JOIN orders o ON o.customerNumber = c.customerNumber
	GROUP BY e.officeCode, e.employeeNumber
)
SELECT o.city
	, AVG(order_count) AS avg_orders
FROM employee_orders eo
JOIN offices o ON eo.officeCode = o.officeCode
GROUP BY o.city
--9- Mostre cada linha de produtos e o número de produtos em cada linha de produtos, para todas as linhas de produtos com mais de 20 produtos.
SELECT p1.productLine
	, COUNT(*) AS num_products
FROM products p
	JOIN productLines p1 ON p.productLine = p1.productLine
GROUP BY p1.productLine
HAVING COUNT(*) > 20
--10- Queremos ter uma idéia do status das ordens de nossos clientes. Mostre cada número de cliente e, em seguida, o número de pedidos por tipo de status. Então você terá uma coluna para o número do cliente e, em seguida, uma coluna para cada envio , em processo , cancelada , disputada , resolvida e suspensa .
SELECT customerNumber
	, SUM(CASE WHEN status = 'shipped' THEN 1 ELSE 0 END) AS shipped
	, SUM(CASE WHEN status = 'in process' THEN 1 ELSE 0 END) AS 'in process'
	, SUM(CASE WHEN status = 'cancelled' THEN 1 ELSE 0 END) AS 'cancelled'
	, SUM(CASE WHEN status = 'disputed' THEN 1 ELSE 0 END) AS 'disputed'
	, SUM(CASE WHEN status = 'resolved' THEN 1 ELSE 0 END) AS 'resolved'
	, SUM(CASE WHEN status = 'on hold' THEN 1 ELSE 0 END) AS 'on hold'
FROM orders
GROUP BY customerNumber
--11- Qual é o menor pagamento a partir de 2004?
SELECT MIN(amount) AS smallest_payment_2004
FROM payments
WHERE YEAR(paymentDate) = 2004
--12 - Queremos garantir que a empresa cuide dos principais clientes. Precisamos encontrar nossos pedidos mais rentáveis ??
--que ainda não foram enviados, para que possamos dar atenção aos clientes. 
--Encontre os 5 maiores pedidos (o maior subtotal) que ainda não foram enviados. Exibir em um relatório o nome do funcionário, 
--o nome do cliente, o número do pedido, o subtotal da ordem e o status para esses 5 subtotais maiores.
SELECT TOP 5 e.firstName + ' ' + e.lastName AS employee_name
	, c.customerNumber
	, od.orderNumber
	, (od.quantityOrdered*od.priceEach) AS order_subtotal
	, o.status
FROM orderdetails od
JOIN orders o ON od.orderNumber = o.orderNumber
JOIN customers c ON c.customerNumber = o.customerNumber
JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
WHERE o.status <> 'shipped'
ORDER BY order_subtotal DESC
--13 - Encontre o número médio de dias antes da data requerida em que os pedidos enviados são enviados. 
--Rodada para 2 casas decimais.
SELECT CONVERT( DECIMAL(10, 2), AVG( CONVERT( DECIMAL(10,2), DATEDIFF(dd, requiredDate, shippedDate) ) ) ) AS AVG_SHIPPED_BEFORE_DATE
FROM orders
WHERE status = 'shipped'
--14- Queremos criar um histórico de transações para o cliente # 363 (consideramos pedidos e pagamentos como transações). 
--Mostre uma lista do número do cliente, da data do pedido / pagamento e do valor do pedido / pagamento. 
--Então, se eles fizeram um pedido em 1/12 e um pagamento em 1/15, então você mostraria o pedido 1/12 na primeira linha 
--e o pagamento 1/15 na segunda linha. Mostre os montantes do pedido como negativos.
SELECT o.customerNumber
	, o.orderDate
	, SUM(quantityOrdered*priceEach)*-1 AS subtotal
FROM orderdetails od
JOIN orders o ON od.orderNumber = o.orderNumber
WHERE o.customerNumber = 363
GROUP BY o.customerNumber, o.orderDate
UNION
SELECT p.customerNumber
	, p.paymentDate
	, p.amount
FROM payments p
WHERE p.customerNumber = 363
--15-Mostre uma lista de todos os países dos quais os clientes são originários.
SELECT DISTINCT country
FROM customers
--16- Queremos ver com quantos clientes nossos funcionários estão trabalhando. Mostre uma lista de primeiro e último nome do funcionário (mesma coluna), juntamente com o número de clientes com quem eles estão trabalhando.
select (e.firstName + ' ' + e.lastName) as 'Employee Name', count(*) as '# of Customers'
from employees e join customers c
	on e.employeeNumber = c.salesRepEmployeeNumber
group by (e.firstName + ' ' + e.lastName)
order by count(*) desc
--17- Encontre uma lista de endereços de e-mail de funcionários inválidos.
--Find a list of invalid employee email addresses.
select email from employees
where email not like '%_@__%.__%'

SELECT firstName, lastName, email AS 'Invalid eamil address'
FROM employees
WHERE (
SELECT IIF(LOWER(LEFT(firstName, 1) + lastName + '@classicmodelcars.com') = email, 'correct', 'incorrect')) = 'incorrect'
--18- Queremos ver informações sobre nossos clientes por país. Mostre uma lista de países do cliente, 
--o número de clientes desses países e o valor total dos pagamentos que esses clientes fizeram.
WITH country_totals
AS(
SELECT country
	, COUNT(*) AS customer_count
FROM customers
GROUP BY country)
SELECT ct.*
	, SUM(p.amount) AS payment_total
FROM payments p JOIN customers c ON p.customerNumber = c.customerNumber
JOIN country_totals ct ON ct.country = c.country
GROUP BY ct.country, ct.customer_count
ORDER BY customer_count DESC
--19- A empresa precisa ver quais clientes ainda devem dinheiro. Encontre clientes que tenham saldo negativo 
--(montante devido maior do que o valor pago). Mostre o número do cliente e o nome do cliente.
SELECT	customerNumber
	,	customerName
FROM customers c
WHERE
(
	SELECT	SUM(quantityOrdered*priceEach) AS order_subtotal
	FROM orderdetails od
	JOIN orders o ON od.orderNumber = o.orderNumber
	WHERE o.customerNumber = c.customerNumber
	GROUP BY o.customerNumber
	)
	>
	(
	SELECT	SUM(p.amount) AS payment_subtotal
	FROM payments p
	WHERE p.customerNumber = c.customerNumber
	GROUP BY p.customerNumber
)
--20- A empresa quer ver quais pedidos tiveram problemas. Pegue tudo da tabela de 
--pedidos onde os comentários incluem a palavra difícil .
select * from orders 
where comments like '%difficult%'
order by orderNumber
--20 -A empresa quer ver se há alguma correlação entre o sucesso do cliente e os representantes de vendas locais. 
--Para começar, queremos que você encontre quais clientes trabalham com funcionários em seu estado de origem. 
--Mostre os nomes dos clientes e os estados daqueles que se aplicam.
SELECT	customerName
	,	c.state
FROM customers c
JOIN employees e ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN offices o ON o.officeCode = e.officeCode
WHERE o.state = c.state
--21- A empresa quer ver se há alguma correlação entre o sucesso do cliente e os representantes de vendas locais. 
--Para começar, queremos que você encontre quais clientes trabalham com funcionários em seu estado de origem. 
--Mostre os nomes dos clientes e os estados daqueles que se aplicam
select c.customerName, c.state from customers c join employees e 
	on c.salesRepEmployeeNumber = e.employeeNumber
	join offices o
	on o.officeCode = e.officeCode
	WHERE o.state = c.state
--22- O chefe precisa ver uma lista de fornecedores de produtos e o número de itens que eles têm em estoque. 
--Mostre os fornecedores com a maioria dos itens em estoque primeiro.
select productVendor, sum(quantityInStock) AS vendor_total
from products
group by productVendor
order by sum(quantityInStock) desc
--23- CHALLENGE: Esta é uma continuação do desafio # 14. Para recapitular, no desafio # 14, queremos ver um histórico de 
--pedidos e pagamentos pelo cliente nº 363. Desta vez, queremos a mesma informação 
--(número do cliente, data do pedido / pagamento e quantidade do pedido / pagamento), mas também queremos para 
--incluir um total em execução do seu saldo como uma quarta coluna.
WITH transaction_history AS
(
	SELECT o.customerNumber
		, o.orderDate
		, SUM(quantityOrdered*priceEach)*-1 AS subtotal
	FROM orderdetails od
	JOIN orders o ON od.orderNumber = o.orderNumber
	WHERE o.customerNumber = 363
	GROUP BY o.customerNumber, o.orderDate
	UNION
	SELECT p.customerNumber
		, p.paymentDate
		, p.amount
	FROM payments p
	WHERE p.customerNumber = 363
)
SELECT th.*
	, SUM(subtotal) OVER(ORDER BY orderDate) AS running_total
FROM transaction_history th
--24- Encontre o produto que foi encomendado mais. Mostre o nome do produto e quantas vezes foi encomendado.
WITH totalOrdered AS (
SELECT productcode, SUM(quantityOrdered) AS totalOrd
FROM orderdetails
GROUP BY productcode
)
SELECT top 1 p.productName, m.totalOrd
FROM products p JOIN totalOrdered m ON p.productCode = m.productCode
ORDER BY m.totalOrd DESC
--25- Encontre datas em que foram feitas ordens e pagamentos.
SELECT DISTINCT o.compare_date
FROM ( SELECT orderDate AS compare_date FROM orders ) o
JOIN ( SELECT paymentDate AS compare_date FROM payments ) p ON o.compare_date = p.compare_date

SELECT DISTINCT orderDate AS [Same Order & Payment Date]
FROM orders
WHERE orderDate IN (SELECT paymentDate FROM payments)

SELECT O.orderDate
FROM Orders O
JOIN Payments P ON P.paymentDate = O.orderDate
GROUP BY O.orderDate
--26- Mostre uma lista de todas as datas da transação e o número combinado de pedidos e pagamentos feitos naqueles dias.
WITH transactions AS(
	SELECT	orderDate as transaction_date
		,	'order' AS transaction_type
	FROM orders
	UNION ALL
	SELECT	paymentDate as transaction_date
		,	'payment' AS transaction_type
	FROM payments
)
SELECT	transaction_date
	,	COUNT(*) AS transaction_count
FROM transactions
GROUP BY transaction_date;
--27- Exibir uma porcentagem de clientes que fizeram pedidos de mais de um produto. Redirecione sua resposta para 2 
--casas decimais.
WITH customer_product_information AS (
	SELECT  c.customerNumber
		,	od.productCode
	FROM customers c
	LEFT JOIN orders o ON c.customerNumber = o.customerNumber
	LEFT JOIN orderdetails od ON o.orderNumber = od.orderNumber
)
, customer_product_aggregation AS (
	SELECT  customerNumber
		,	COUNT( DISTINCT productCode ) AS product_count
		,	CONVERT( DECIMAL(28, 7), CASE WHEN COUNT( DISTINCT productCode ) >= 2 THEN 1 ELSE 0 END ) AS qualified_customer
	FROM customer_product_information
	GROUP BY customerNumber
)
SELECT  CONVERT( DECIMAL(28, 2), SUM( qualified_customer ) / COUNT(*) ) AS 'Qualified Customer Percentage'
FROM customer_product_aggregation
--28- CHALLENGE: Encontre o número de clientes que cada funcionário do nível de gerenciamento (não representantes de vendas) 
--é responsável. Isso inclui clientes vinculados diretamente aos gerentes, bem como clientes vinculados a funcionários 
--que informam aos gerentes. Mostre o nome do funcionário (primeiro e último), o título do trabalho e o número de 
--clientes que supervisionam.
WITH cust_per_emp AS
(
	SELECT e.reportsTo
		, COUNT(*) cust_count
	FROM employees e
	JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
	GROUP BY e.reportsTo
)
SELECT boss.firstName + ' ' + boss.lastName AS employee_name
	, boss.jobTitle
	, emp.cust_count
FROM cust_per_emp emp
JOIN employees boss ON emp.reportsTo = boss.employeeNumber
--29- DESAFIO: queremos um relatório de funcionários e pedidos que ainda estão em andamento (não enviados, cancelados ou 
--resolvidos). Mostre o nome do funcionário (primeiro e último), número do cliente, número do pedido e o status do pedido.
SELECT e.firstName + ' ' + e.lastName as employee_name
, c.customerNumber
	, o.orderNumber
	, o.status
FROM employees e
JOIN customers c ON e.employeeNumber = c.salesRepEmployeeNumber
JOIN orders o ON o.customerNumber = c.customerNumber
WHERE status NOT IN ('shipped', 'cancelled', 'resolved')
--30- mostre todos os montantes de pedidos acima de US $ 60.000. Ordem-os em ordem crescente.
SELECT DISTINCT SUM(quantityOrdered*priceEach) AS orderPrice
FROM orderdetails
GROUP BY orderNumber
HAVING SUM(quantityOrdered*priceEach) > 60000
ORDER BY orderPrice
--31- mostre todos os números de pedidos para encomendas que consistem em apenas um produto.
SELECT orderNumber
FROM orderdetails
GROUP BY orderNumber
HAVING COUNT(productCode) = 1
--32- queremos ver os comentários que nossos clientes estão deixando. Mostre todos os comentários do pedido 
--(deixe de fora aqueles em que não há comentários).
SELECT comments
FROM orders
WHERE comments IS NOT NULL
--33- hoje vamos trabalhar com o banco de dados WORLD. Mostre todas as informações do país e da língua do país para 
--países que falam francês e possuem um GNB superior a 10.000.
select *
from country c join countrylanguage cl
	on c.Code = cl.CountryCode
where cl.Language = 'france'
and c.GNP > 10000

select *
from country
where code in (select countrycode
from countryLanguage
where language = 'french'
)
AND gnp > 10000
--34- usando o banco de dados WORLD, mostre o número de países onde o inglês é uma língua oficial e mostra o 
--número de países onde o inglês é falado. Exibir cada resultado em sua própria coluna (2 no total).
--https://www.sqlprep.com/sql-prep-daily-sql-challenge-34/
SELECT (SELECT COUNT(*) FROM countryLanguage WHERE isOfficial = 'T' and Language = 'English') AS official_English_count
	, COUNT(*) AS total_English_count
FROM countryLanguage
WHERE Language = 'English'

Select sum(case when Isofficial='T' then 1 else 0 end ) as eng_off
,sum(case when Language='English' then 1 else 0 end) as eng_lang
from countrylanguage where Language='English'
--35- usando o banco de dados WORLD, queremos ver se existe uma correlação entre população e expectativa de vida. 
--Mostre o nome de cada país, a classificação da população (1 sendo o mais alto e a partir daí), a taxa de 
--expectativa de vida (igual) e a pontuação geral (classificação da população e classificação da expectativa de vida).
WITH rank_base AS
(
SELECT name
	, RANK() OVER (ORDER BY population DESC) AS pr
	, RANK() OVER (ORDER BY LifeExpectancy DESC) AS ler
FROM country
)
SELECT name
	, pr AS 'Population Rank (DESC)'
	, ler AS 'Life Expectancy Rank (DESC)'
	, pr + ler AS 'Total Rank'
FROM rank_base
ORDER BY 'Total Rank'
--36- Using the WORLD database, I noticed that the United States doesn't have Thai listed as one of their languages. 
--After looking through census data, it shows that 0.3 % of people in the USA speak Thai at home. 
--So let's add it to the list in our query result. Show all information about the languages spoken in the USA, and add a 
--row to your results including Thai as well.
select * 
from countrylanguage
where countrycode = 'usa'
union all
select 'USA', 'Thai', 'F', '.3'
--37- usando o banco de dados WORLD, mostre o nome do país e a população para o segundo país mais populoso.
WITH pop_rank AS
(
SELECT name
	, population
	, RANK() OVER (ORDER BY population DESC) AS ranking
FROM country
)
SELECT name
	, population
FROM pop_rank
WHERE ranking = 2
--38- usando o banco de dados WORLD, queremos ver quais idiomas representam mais de 50% da população em mais de 5 países. Mostre o idioma e o número de países que se enquadram nesse critério.
SELECT language
	, COUNT(*) AS country_count
FROM countrylanguage
WHERE percentage>50
GROUP BY language
HAVING COUNT(*)>5
--39- usando o banco de dados WORLD, queremos ver os países com menor densidade populacional. Mostre o nome, a classificação da densidade e a população por superfície para os 10 países com a menor densidade populacional.
WITH pop_area_data AS
(
SELECT name
	, SurfaceArea/Population AS Pop_Per_Area
FROM country
WHERE Population <> 0
)
	, pop_area_ranking AS
(
SELECT name
	, RANK() OVER (ORDER BY Pop_Per_Area) AS pa_rank
	, Pop_Per_Area
FROM pop_area_data
)
SELECT *
FROM pop_area_ranking
WHERE pa_rank <= 10
--40- Usando o banco de dados WORLD, mostre todas as informações do país sobre o país com maior expectativa de vida.
SELECT *
FROM country
WHERE LifeExpectancy =
	(SELECT MAX(LifeExpectancy) FROM country)
--41- usando a base de dados WORLD, mostre todas as informações do país sobre o país com maior expectativa de vida para cada continente.
SELECT *
FROM country c1
WHERE LifeExpectancy =
	(SELECT MAX(LifeExpectancy)
	FROM country c2
	WHERE c1.continent = c2.continent)
--42- Usando o banco de dados WORLD, mostre todas as informações do país para países cujo PNB diminuiu.
SELECT *
FROM country
WHERE GNPOld > GNP
--43- Usando o banco de dados WORLD, mostre todas as informações do país para os 3 países maiores (área) por continente.
WITH country_rank AS
(
SELECT RANK() OVER (PARTITION BY continent ORDER BY SurfaceArea DESC) AS ranking, *
FROM country
)
SELECT *
FROM country_rank
WHERE ranking < 4
--44- usando o banco de dados WORLD, queremos ver as 3 maiores cidades mais populadas para os 3 países mais populosos de cada continente. Mostre o ranking da cidade, o nome da cidade, a população da cidade, a classificação do país, o nome do país e o continente para cada cidade.
WITH country_rank AS
(
SELECT RANK() OVER (PARTITION BY continent ORDER BY SurfaceArea DESC) AS country_ranking
	, c.code
	, c.name AS country_name
	, c.continent
FROM country c
), top_three_country AS
(
SELECT *
FROM country_rank
WHERE country_ranking < 4
), top_three_city AS
(
SELECT RANK() OVER (PARTITION BY countrycode ORDER BY ci.population DESC) AS city_ranking
	, ci.name AS city_name
	, ci.population
	, tt.country_ranking
	, tt.country_name
	, tt.continent
FROM city ci
JOIN top_three_country tt ON tt.code = ci.countrycode
)
SELECT *
FROM top_three_city
WHERE city_ranking < 4
ORDER BY continent, country_ranking, city_ranking
--45- Usando o banco de dados WORLD, mostre os vários tipos de governo e o número de países que usam cada tipo. Mostra-os dos mais usados ​​para os menos usados.
SELECT GovernmentForm
	, COUNT(*) AS gov_count
FROM country
GROUP BY GovernmentForm
ORDER BY COUNT(*) DESC
--46- usando o banco de dados WORLD, queremos ver os países com uma população acima da média. Mostre o nome do país e a população.
SELECT name
	, population
FROM country
WHERE population > (SELECT AVG(CAST(population AS BIGINT)) FROM country)
--47- Mostre o primeiro nome, o cargo e o código do escritório dos funcionários que possuem o código de escritório 2, 4 e 7, respectivamente. Ordem por código de escritório ascendente.
select firstname
    ,jobtitle
    ,officecode
from employees 
where officecode in (2,4,7)
order by officecode asc;
--48- Encontre o número total de clientes que cada funcionário representa. Prepare um relatório neste formato - "Andy Fixter representa 5 clientes". Nomeie a coluna "Não. de clientes "e ordená-lo por contagem de clientes ascendentes.
select concat(e.firstname,' ', e.lastname, ' represents ', count(c.customernumber), ' customers.') as "No. of customers"
from employees e
join customers c on e.employeenumber=c.salesrepemployeenumber
group by c.salesrepemployeenumber, e.firstname, e.lastname
order by count(c.customernumber);
--49- O cheque que enviamos para o terceiro valor mais alto foi extraviado! Queremos informações sobre esse cheque. Escreva uma consulta para encontrar o terceiro valor de verificação mais alto e exiba o nome do cliente, o número do cheque, o valor e a data de pagamento.
select c.customername
    , p.checknumber
    , p.amount
    , p.paymentdate 
from customers c
join payments p on c.customernumber=p.customernumber 
where (select count(distinct(p1.amount)) 
      from payments p1 
      where p1.amount>p.amount)=2;
--50- Quantos países tem nomes de sete caracteres, onde o nome também começa com a letra A ou B?
SELECT count(len(name)) FROM country where name like '[A-B]%' and len(name)=7;
--51- Crie uma consulta que exiba o número total de produtos enviados nos anos de 2003, 2004 e 2005. Exibe o resultado em linhas horizontais, com o ano como o título da coluna e os produtos totais no respectivo ano da coluna.
select count(case when year(o.shippeddate)=2003 then ord.productcode end) as "2003"
    , count(case when year(o.shippeddate)=2004 then ord.productcode end) as "2004"
    , count(case when year(o.shippeddate)=2005 then ord.productcode end) as "2005"
from orders o 
join orderdetails ord on o.ordernumber=ord.ordernumber 
where o.status='Shipped' 
    and year(o.shippeddate) is not null;
--52- Exibir o nome completo de 'Sales Rep' cujo código de escritório é 6. O resultado deve estar no formato de "firstName lastName" (espaço entre os nomes).
select concat(firstname,' ',lastname) 
from employees 
where jobtitle='Sales Rep' and officecode=6;
--53- Qual produto tem status de pedido 'On Hold'? Exibir o nome do produto e seu status.
select DISTINCT p.productName, ISNULL(o.status, '') as Status
from products p join orderdetails od
	on p.productCode = od.productCode
	join orders o
	on o.orderNumber = od.orderNumber
where status = 'On Hold'
--54- Nomeie o cliente que possui o maior valor de pagamento médio entre todos os clientes. Mostre tanto o nome do cliente como seu valor médio de pagamento.
SELECT TOP 1
c.customerName AS 'Customer Name',
AVG(p.amount) AS 'Average Payment Amount'
FROM
customers AS c
LEFT JOIN
payments AS p ON p.customerNumber = c.customerNumber
GROUP BY
c.customerName
ORDER BY
AVG(p.amount) DESC

select top 1 c.customerName, AVG(p.amount) as AvgPaymentAmt
from customers c
join payments p on c.customerNumber = p.customerNumber
group by c.customerName
order by 2 desc
--55- Obtenha uma contagem do número total de clientes como "Total de Clientes" e um somatório de seu limite de crédito como "Total de Crédito" na tabela de clientes.
SELECT count(customernumber) as "Total Customers"
    ,sum(creditlimit) as "Total Credit"
from customers;
--56- Encontre os produtos que foram enviados nos últimos 6 meses do ano 2004. Mostre o nome do produto e a data enviada
select distinct p.productname,o.shippeddate,o.status
from products p join orderdetails ord on p.productcode=ord.productcode
join orders o on ord.ordernumber=o.ordernumber
where datepart(mm,o.shippeddate)>6 
    and datepart(yy,o.shippeddate)=2004 
    and o.status='Shipped';

SELECT p.productName, shippedDate, status
FROM orders o
JOIN orderdetails od ON od.orderNumber=o.orderNumber
JOIN products p ON p.productCode=od.productCode
WHERE shippedDate >= '20040701' AND shippedDate < '20050101'
AND status='shipped'
--57- A empresa varejista quer organizar seus clientes nas categorias 'Regular', 'Premium', 'Sliver' e 'Gold'. Os clientes que pagaram um valor médio entre US $ 1.000 e US $ 9.999 devem estar na categoria "Regular". $ 10 000 - $ 29,999 é 'Premium', $ 30,000 - $ 39,999 é 'Silver', e $ 40,000 e acima seria um cliente de ouro. Crie uma consulta para esse cenário, exibindo o nome do cliente e sua categoria. Peça a categoria 'Gold' para 'Regular'.
select c.customername, 
case when avg(p.amount) BETWEEN 1000 and 9999 then 'Regular'
     when avg(p.amount) BETWEEN 10000 and 29999 then 'Premium'
     when avg(p.amount) BETWEEN 30000 and 39999 then 'Silver'
     else 'Gold' end as Category
from payments p,customers c
where c.customernumber=p.customernumber
group by c.customername,c.customernumber
order by avg(p.amount) desc;
--58- Aumente o limite de crédito em US $ 10.000 para clientes que tenham um limite de crédito inferior ou igual a US $ 65.700,00 (pré-incremento). Mostre o nome do cliente e o limite de crédito incrementado como "Incremento de crédito".
select customername
    ,creditlimit+10000 as "Credit Increment"
from customers 
where creditlimit<=65700.00;
--59- Queremos ver as ordens que estão em processo. Mostre o nome do produto, a data de entrega, a data enviada e o status dessas ordens. Se não houver data enviada, então deve exibir 'Não disponível'.
select p.productname
    ,o.requireddate
    ,isnull(convert(varchar(25),o.shippeddate,120),'Unavailable') as shippeddate
    ,o.status 
from products p,orderdetails ord,orders o
where p.productcode=ord.productcode and ord.ordernumber=o.ordernumber
and o.status='In process';

SELECT p.productname, o.requireddate,
CASE
WHEN o.shippeddate IS NULL THEN 'Unavailable'
END
, o.status
FROM products p INNER JOIN orderdetails ord ON p.productcode=ord.productcode
INNER JOIN orders o ON ord.ordernumber=o.ordernumber
WHERE o.status='in process'
--60- Liste todos os títulos de trabalho distintos a "Representante de vendas" da tabela de funcionários.
select distinct(jobtitle) 
from employees
where jobtitle <> 'Sales Rep';

Select distinct jobtitle
from employees
Where jobtitle not in ('Sales Rep')
--61- Encontre o estado do escritório de todos os funcionários que representa clientes de 'Queensland'. Mostre os nomes dos funcionários, o estado do escritório e o nome do cliente correspondente. Se o estado do escritório não for mencionado, ele deve exibir o país.
select e.lastname
    ,coalesce(o.state,o.country) Region 
    ,c.customername 
from employees e 
join customers c on c.salesrepemployeenumber=e.employeenumber 
join offices o on e.officecode=o.officecode
where c.state='Queensland';

SELECT e.lastName
, IIF(o.state IS NULL, o.country, o.state) AS [office state/location]
, c.customerName
FROM customers c
JOIN employees e ON e.employeeNumber=c.salesRepEmployeeNumber
JOIN offices o ON o.officeCode=e.officeCode
WHERE c.state='Queensland'
--62- Mostre todas as informações para os funcionários cujo sobrenome começa com 'K'.
SELECT * 
FROM employees 
WHERE lastname LIKE '[K]%';
--63- Encontre os produtos que foram enviados nos últimos 6 meses do ano 2004. Exibir o nome do produto e a data enviada, encomendando por mês ascendendo.
SELECT distinct p.productname
    ,o.shippeddate
FROM products p 
JOIN orderdetails ord ON p.productcode=ord.productcode
JOIN orders o ON ord.ordernumber=o.ordernumber
WHERE datepart(mm,o.shippeddate)>6 
    AND datepart(yyyy,o.shippeddate)=2004 
    AND o.status='Shipped'
ORDER BY shippeddate;
--64- Encontre o número total de pessoas que relatam a cada funcionário. Ordem por número total de relatórios descendentes.
SELECT m.firstname 
    ,COUNT(e.firstname) as total_reporter
FROM employees e
JOIN employees m ON e.reportsto=m.employeenumber
GROUP BY m.firstname;
--65- Encontre os nomes dos clientes para clientes que não estão associados a um representante de vendas.
SELECT customername 
FROM customers 
WHERE salesrepemployeenumber IS NULL;
--66- Encontre todos os funcionários cujo nome comece com 'D', 'M' e 'J'. Apenas exiba seus primeiros nomes e ordene o resultado pelo primeiro nome.
SELECT firstname 
FROM employees 
WHERE SUBSTRING(firstname,1,1) in ('D','M','J')
ORDER BY firstname ;

SELECT firstname
FROM employees
WHERE firstname like '[D,M,J]%'
ORDER BY firstname;
--67- Exibir todos os clientes atribuídos e não atribuídos a um representante de vendas, com os clientes não representados exibidos em último lugar. Mostre o nome do cliente e as colunas de nome do funcionário.
select c.customername
    ,e.firstname as salesrep 
from employees e 
right outer join customers c 
on e.employeenumber=c.salesrepemployeenumber 
order by e.firstname DESC;

select
c.customername,
e.firstname
from
customers c
left outer join employees e on
c.salesRepEmployeeNumber = e.employeeNumber
order by
e.employeeNumber desc
--68- A empresa decidiu dar um bônus aos funcionários que trabalham como representantes de vendas. Calcule um bônus que seja 10% do valor médio pago pelo respectivo cliente para esse representante de vendas. Indique o nome do funcionário, o nome do cliente, o valor total pago por esse cliente como "Valor" e o bônus em uma coluna chamada "10% de Bônus". Você deve ter uma linha para cada representante de vendas - relacionamento com o cliente.
select e.firstname
    ,c.customername
    ,sum(p.amount) as Amount
    , (0.1*avg(amount)) as "10% Bonus"
from customers c
join employees e on c.salesrepemployeenumber=e.employeenumber
join payments p on c.customernumber=p.customernumber
group by e.firstname
    ,c.customername;
--69- Descubra o valor médio máximo pago pelo cliente. Reduzir o resultado até dois pontos decimais. Dica: Primeiro, calcule o valor médio pago e descubra o seu máximo.
select round(max(average),2) 
from (
         SELECT avg(amount) as average
         from payments 
         group by customernumber
     ) as cust_pay;
--70- Qual é a maior quantidade em estoque para cada linha de produtos? Mostre cada linha de produtos, juntamente com a maior quantidade em estoque para cada linha de produtos.
select productline
    , max(quantityInStock) 
from products
group by productline ;
--71- Calcule o preço total de compra da tabela de produtos e arredondar o resultado para uma casa decimal.
select round(sum(buyPrice),1) 
from products;
--72- Crie uma consulta que exiba o número total de produtos enviados nos anos 2003, 2004 e 2005 combinados. Também tem uma coluna para cada um desses anos com o número total de produtos enviados em cada ano, respectivamente. Seus resultados devem ser exibidos no seguinte formato - Total 2003 2004 2005 ------------------------------------- ---------------------------------------- xx xx
select (select sum(product) 
        from (select count(ord.productcode) product
              from orders o,orderdetails ord 
              where o.ordernumber=ord.ordernumber and o.status='Shipped' 
              and year(o.shippeddate) is not null 
              group by year(o.shippeddate)) as i1) as Total,
count(case when year(o.shippeddate)=2003 then ord.productcode end) as "2003",
count(case when year(o.shippeddate)=2004 then ord.productcode end) as "2004",
count(case when year(o.shippeddate)=2005 then ord.productcode end) as "2005"
from orders o
join orderdetails ord on o.ordernumber=ord.ordernumber 
where o.status='Shipped' 
    and year(o.shippeddate) is not null;
--73- Aumente o limite de crédito em US $ 10.000 para aqueles clientes que tenham um limite de crédito superior ou igual a $ 65.700,00. Mostre apenas o nome do cliente e o limite de crédito como "Incremento de crédito".
select customername
    , creditlimit+10000 as "Credit Increment"
from customers 
where creditlimit>=65700.00;
--74- Qual é a maior quantidade em estoque para cada linha de produtos? Mostre cada linha de produtos, juntamente com a maior quantidade em estoque para cada linha de produtos.
select productline
    , max(quantityInStock) 
from products
group by productline;
--75- Crie um relatório para saber qual funcionário está relatando a quem. Capitalize todo o primeiro nome da pessoa que está sendo relatada. Por exemplo - "Mary relata ao DIANE"
select concat(e.firstname,' reports to ',upper(m.firstname)) 
from employees e 
join employees m on e.reportsto=m.employeenumber;
select concat(e.firstname,' reports to ',upper(m.firstname)) 
from employees e 
join employees m on e.reportsto=m.employeenumber;

SELECT Emp.Firstname + ' reports to ' + UPPER(E.Firstname)
FROM Employees E
INNER JOIN Employees Emp
ON E.EmployeeNumber = Emp.ReportsTo
--76- Escreva uma consulta que retornará todos os registros da tabela de funcionários onde não há registros na tabela de contatos para as colunas correspondentes contactlastname e contactfirstname. Dica: use a cláusula NÃO existir.
SELECT *
FROM employees e
WHERE Not EXISTS (SELECT *
                  FROM customers c
                  WHERE e.lastname = c.contactlastname
                  AND e.firstname = c.contactfirstname);
--77- Encontre todas as informações do cliente para clientes que nunca fizeram um pedido
SELECT *
FROM customers c
WHERE NOT EXISTS 
    (SELECT 1 
    FROM orders o
    WHERE o.customerNumber = c.customerNumber)

SELECT DISTINCT C.* from Customers C
Left Join Orders O on O.customerNumber=C.customerNumber
Where O.OrderNumber is null;
--78- Queremos ver os montantes para alguns dos nossos maiores pagamentos. Mostre os montantes para o 5º ao 10º pagamentos maiores, do mais alto ao menor.
WITH amount_order AS
(
SELECT ROW_NUMBER() OVER (ORDER BY amount DESC) AS ordering
    , amount
FROM payments
)
SELECT *
FROM amount_order
WHERE ordering BETWEEN 5 and 10

WITH amtList AS (
SELECT ROW_NUMBER() OVER (ORDER BY amount DESC) AS amtRank, amount
FROM payments
)
SELECT amtRank, amount
FROM amtList
WHERE amtRank >=5 and amtRank <=10
--79- Definir o número de vezes que o filme "Agente Truman" foi alugado.
SELECT COUNT(*)
FROM rental 
WHERE inventory_id IN (
    SELECT inventory_id FROM inventory WHERE film_id = 6)

select count(*)
from rental r
join inventory i
on i.inventory_id = r.inventory_id
where film_id=6
--80- Queremos ver todos os filmes com mais de 10 atores / atrizes. Mostre o filme_id, título e número de atores para cada filme que atenda a este critério.
SELECT f.film_id
    , f.title
    , COUNT(actor_id)
FROM film f
JOIN film_actor fa ON fa.film_id = f.film_id
GROUP BY f.film_id, f.title
HAVING COUNT(fa.actor_id) > 10
--81- Encontre informações sobre o aluguel mais caro. Se houver mais de um aluguel ao mesmo preço, vá com o mais recente. Mostre o primeiro e último nome do cliente com este aluguel, juntamente com o seu ID de aluguel.
SELECT first_name, last_name, rental_id
FROM customer c
JOIN rental r ON r.customer_id = c.customer_id
WHERE rental_id =
    (
    SELECT rental_id 
    FROM 
        (
        SELECT TOP 1 payment_date, MAX(amount) AS rental_amount, rental_id
        FROM payment
        GROUP BY payment_date, rental_id
        ORDER BY MAX(amount) DESC, payment_date DESC
        ) a
    )
--82- Encontre o aluguel mais caro. Se houver laços, vá com o mais recente. Em seguida, mostre que o ID do aluguel, juntamente com os aluguéis anterior e seguinte (por data de pagamento).
WITH rental_amount_rank AS (
    SELECT	rental_id
    	,	customer_id
    	,	payment_date
    	,	amount
    	,	RANK() OVER( ORDER BY amount DESC ) AS amount_rank_desc
    	,   ROW_NUMBER() OVER( ORDER BY payment_date DESC) AS payment_date_desc
    FROM payment
), rental_date_rank AS (
    SELECT  rental_id
        ,   customer_id
        ,   payment_date
        ,   amount
        ,   amount_rank_desc
        ,   payment_date_desc
        ,   ROW_NUMBER() OVER( PARTITION BY amount_rank_desc ORDER BY payment_date DESC) AS amount_payment_date_desc
    FROM rental_amount_rank
), rental_assoc AS (
    SELECT  rental_id
        ,   customer_id
        ,   payment_date
        ,   amount
        ,   amount_rank_desc
        ,   payment_date_desc
        ,   amount_payment_date_desc
        ,   LAG( rental_id ) OVER( ORDER BY payment_date_desc ) AS previous_rental_id
        ,   LEAD( rental_id ) OVER( ORDER BY payment_date_desc ) AS next_rental_id
    FROM rental_date_rank
)
SELECT TOP 1 * 
FROM rental_assoc
WHERE amount_rank_desc = 1
ORDER BY amount_payment_date_desc
--83- Crie uma repartição dos filmes pelo preço do aluguel. Queremos ver quantos filmes são alugados entre 0 e $ 0,99. Então $ 1 - $ 1.99 e $ 2 - $ 2.99, em até $ 4.99.
SELECT SUM(CASE WHEN rental_rate BETWEEN 0 AND 0.99 THEN 1 ELSE 0 END) AS [0-0.99]
     , SUM(CASE WHEN rental_rate BETWEEN 1 AND 1.99 THEN 1 ELSE 0 END) AS [1-1.99]
     , SUM(CASE WHEN rental_rate BETWEEN 2 AND 2.99 THEN 1 ELSE 0 END) AS [2-2.99]
     , SUM(CASE WHEN rental_rate BETWEEN 3 AND 3.99 THEN 1 ELSE 0 END) AS [3-3.99]
     , SUM(CASE WHEN rental_rate BETWEEN 4 AND 4.99 THEN 1 ELSE 0 END) AS [4-4.99]
FROM film
--84- Mostre todos os pedidos com um tempo anexado. Defina a hora para 8 AM (não precisa mostrar AM embora) para todos os pedidos.
SELECT DATEADD(hh, 8, CAST(orderdate AS datetime)) AS [Order Date and Time]
FROM orders
--85- Mostre o código do produto, a quantidade em estoque e o preço de compra para cada 5º produto (ordenado pelo código do produto) na tabela de produtos.
WITH orderingTable AS
(
SELECT ROW_NUMBER() OVER (ORDER BY productCode) AS productCodeOrder
    , productCode
    , quantityInStock
    , buyPrice
FROM products
)
SELECT productCode
    , quantityInStock
    , buyPrice
FROM orderingTable
WHERE productCodeOrder % 5 = 0
--86- Mostre os 3 números de pagamentos mais pequenos e 3 maiores. Então, se os 3 menores forem 1, 2 e 3, e os maiores são 55, 56 e 57, mostre todos eles em uma série de linhas em uma coluna.
SELECT * 
FROM (SELECT TOP 3 payment_id
      FROM payment
      ORDER BY payment_id) a
UNION ALL
SELECT *
FROM (SELECT TOP 3 payment_id
      FROM payment
      ORDER BY payment_id DESC) b
--87- Encontre os países com mais de 10 idiomas, mas menos de 100.000.000 de pessoas. Mostre o nome do país, o número de idiomas e a população.
SELECT c.name
    , a.numLang
    , c.population 
FROM country c
JOIN
(
SELECT countryCode
    , COUNT(*) AS numLang
FROM countryLanguage
GROUP BY countryCode
HAVING COUNT(*) > 10
) a ON a.countryCode = c.code
WHERE c.population < 100000000 
--88- Queremos ver o país que tem a maior população e aquele com menor população. Mostre o ranking da população (1 sendo o mais populoso), nome e população para esses 2 países.
WITH population_cte AS
(
SELECT row_number() OVER (ORDER BY population DESC) AS pop_rank
    , name
    , population
FROM country
)
SELECT *
FROM population_cte pc1
WHERE pop_rank = 1 
    OR NOT EXISTS (SELECT 1 FROM population_cte pc2 WHERE pc2.pop_rank > pc1.pop_rank)
--89- Crie um relatório que mostre todos os países com uma população arredondada de 100.000.000 ou mais (arredondando para o cem milhões mais próximo). Mostre o nome do país, a população arredondada e a população original.
WITH population_cte AS
(
SELECT name
    , ROUND(population, -8) AS pop
    , population
FROM country
)
SELECT *
FROM population_cte pc1
WHERE pop >= 100000000
--90- Hoje queremos testar nossas habilidades usando a função CAST (). Mostre o nome e a população de todos os países, exceto a coluna da população, de modo que os valores sejam todos VARCHAR. 
SELECT name
    , CAST(population AS varchar(50)) AS population
FROM country
--91- Tempo para testar a função CONVERT (). Converta o PNP no VARCHAR e mostre-o junto com o nome de cada país. 
SELECT name
    , CONVERT(VARCHAR(50), GNP) AS GNP
FROM country
--92- Encontre todos os países cujas cidades tenham populações acima de 1.000.000.
SELECT co.name
FROM country co
WHERE NOT EXISTS 
                (SELECT 1 
                FROM city ci 
                WHERE co.code = ci.countrycode 
                    AND ci.population < 1000000)
    AND co.population <> 0
--93- Encontre o número de funcionários por escritório. A saída deve incluir o código do escritório, a cidade do escritório e o número de funcionários.
select b.officecode, b.city, count(distinct a.employeenumber)
from employees a 
join offices b
on a.officecode = b.officecode
group by b.officecode, b.city
--94- Calcule o número de funcionários no maior escritório (escritório que possui a maioria dos funcionários). Nomeie a coluna de saída como "maxemployeecount".
select max(c.employeecount) as maxemployeecount
from (select b.officecode, b.city, count(distinct a.employeenumber) as employeecount
      from employees a 
      join offices b
      on a.officecode = b.officecode
      group by b.officecode, b.city)C 
--95- Selecione todas as cidades cuja população seja superior a 1 milhão. Classifique os nomes das cidades em ordem alfabética.
Select name
from city
where  population > 1000000
order by name
--96- Encontre todos os gerentes que foram contratados após seus subordinados. A saída deve ser nomeada como "managerfirstname", "managerlastname", "managerhiredate", "employeefirstname", "employeelastname", "employeehiredate".
select a.firstname as managerfirstname, a.lastname as managerlastname, a.hiredate as managerhiredate, 
b.firstname as employeefirstname, b.lastname as employeelastname, b.hiredate as employeehiredate
from employees a
right join employees b
on a.employeeID = b.reportsto
where a.hiredate > b.hiredate
--97- selecione todos os nomes dos clientes e seus pagamentos totais cujo pagamento total seja superior a 100.000. Nomeie os pagamentos totais como "totalamount". Classificar por quantidade total (ordem decrescente) e nome do cliente.
select a.customername, sum(b.amount) as totalamount
from customers a
join payments b
on a.customernumber = b.customernumber
group by a.customername
having  sum(b.amount) > 100000
order by totalamount desc, a.customername
--98- Selecione os códigos de país onde a língua do país é o inglês. Classifique o código do país em ordem alfabética.
Select countrycode
from countrylanguage
where  upper(language) = 'ENGLISH'
order by countrycode
--99- Exibir linha de produtos, descrição do texto da linha de produtos e receita para cada linha de produtos. Classifique por receita em ordem decrescente.
select b.productline, b.textdescription, sum(c.quantityordered * c.priceEach) as revenue
from products a 
join productlines b
on a.productline = b.productline
join orderdetails c
on c.productcode = a.productcode
group by b.productline, b.textdescription
order by revenue desc
--100- Exibe a linha de produtos que tem a receita de ordem mais alta. O produto deve incluir e ser rotulado como "linha de produtos", "descrição de texto" e "receita".
select b.productline, b.textdescription, sum(c.quantityordered * c.priceEach) as revenue
from products a 
join orderdetails c
on c.productcode = a.productcode
join productlines b
on a.productline = b.productline
group by b.productline, b.textdescription
having sum(c.quantityordered * c.priceEach) = (select max(D.revenue) as maxrevenue
                                                from (select a.productline, sum(c.quantityordered * c.priceEach) as revenue
                                                    from products a 
                                                    join orderdetails c
                                                    on c.productcode = a.productcode
                                                    group by a.productline) D)
--101- Encontre o nome do cliente que possui o limite de crédito mais alto. Se houver mais de um, classifique os nomes dos clientes em ordem alfabética. 
select a.customername, a.creditlimit
from customers a
where a.creditlimit = (select max(creditlimit) from customers)
order by customername
--102- Calcule o número de produtos para cada fornecedor. A saída deve incluir ID do fornecedor, nome da empresa do fornecedor e contagem do produto. Classificar por contagem de produtos (decrescente) e nome da empresa (ordem alfabética).
select b.supplierID, b.companyName, count(distinct a.productID) as productcount
from products a
join suppliers b
on a.supplierID = b.supplierID
group by b.supplierID, b.companyName
order by productcount desc, b.companyName
--103- 