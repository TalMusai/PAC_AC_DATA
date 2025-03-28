--1
select *, ((a.YearlyLinearIncome/lag(a.YearlyLinearIncome) over (order by a.year))-1)*100 as GrowthRate
from
(select year([OrderDate]) as [Year], sum([ExtendedPrice]-[TaxAmount])
as IncomePerYear,
count(distinct month ([OrderDate])) as NumberOfDistinctMonths,
(sum ([ExtendedPrice]-[TaxAmount])/ count(distinct month
([OrderDate])) )*12 as YearlyLinearIncome
from [Sales].[Orders] o
inner join [Sales].[Invoices] I on o.OrderID=I.OrderID
inner join [Sales].[InvoiceLines] IL on I.InvoiceID=IL.InvoiceID
group by year ([OrderDate])) a

--2
select *
from(
select TheYear, TheQuarter, CustomerName, IncomePerYear,
dense_rank() over (partition by TheQuarter, TheYear order by IncomePerYear desc) DNR
from(
select year(OrderDate) as TheYear, datepart(quarter,OrderDate) TheQuarter, CustomerName, 
sum([Quantity]*OL.[UnitPrice]) IncomePerYear
from [Sales].[Orders] o
inner join [Sales].[Invoices] I on i.OrderID = o.OrderID
inner join [Sales].[OrderLines] OL on OL.OrderID = o.OrderID
inner join [Sales].[Customers] c on c.CustomerID = i.CustomerID
group by year(OrderDate), datepart(quarter,OrderDate), CustomerName) a )b
where b.DNR <= 5
order by 1,2,5

--3
select top 10 il.StockItemID, si.StockItemName,
sum(ExtendedPrice - TaxAmount) as TotalProfit
from Sales.InvoiceLines il
inner join [Warehouse].[StockItems] si on il.StockItemID = si.StockItemID
group by il.StockItemID, si.StockItemName
order by TotalProfit desc

--4
select row_number() over (order by(RecommendedRetailPrice - UnitPrice)desc) as Rn,
StockItemID, StockItemName, UnitPrice, RecommendedRetailPrice,
(RecommendedRetailPrice - UnitPrice) as NominalProductProfit,
dense_rank() over (order by (RecommendedRetailPrice - UnitPrice)desc) as DNR
from [Warehouse].[StockItems]
where ValidTo >= getdate()
order by NominalProductProfit desc

--5
select concat(s.SupplierID, ' - ', s.SupplierName) as SupplierDetails,
string_agg(concat(si.StockItemID, ' ', si.StockItemName), ' /, ') as ProductDetails
from Purchasing.Suppliers s
inner join [Warehouse].[StockItems] si on s.SupplierID = si.SupplierID
group by s.SupplierID, s.SupplierName
order by s.SupplierID

--6
select top 5 c.CustomerID, CityName, CountryName, Continent, Region,
sum(ExtendedPrice) as TotalExtendedPrice
from [Sales].[Customers] c
inner join [Sales].[Orders] o on c.CustomerID = o.CustomerID
inner join [Sales].[Invoices] i on o.OrderID = i.OrderID
inner join [Sales].[InvoiceLines] il on i.InvoiceID = il.InvoiceID
inner join [application].[Cities] ci on c.DeliveryCityID = ci.CityID
inner join [application].[StateProvinces] sp on ci.StateProvinceID = sp.StateProvinceID
inner join [application].[Countries] co on sp.CountryID = co.CountryID
group by c.CustomerID, CityName, CountryName, Continent, Region
order by TotalExtendedPrice desc

--7
select t.OrderYear, case when t.OrderMonth is null then 'Grand Total'
else cast(t.OrderMonth as varchar) end as OrderMonth,
cast(t.MonthlyTotal as decimal(10,2)) AS MonthlyTotal,
cast(t.CumulativeTotal as decimal(10,2)) as CumulativeTotal
from (select year(o.OrderDate) as OrderYear, month(o.OrderDate) as OrderMonth,
sum(il.Quantity * il.UnitPrice) as MonthlyTotal,
sum(sum(il.Quantity * il.UnitPrice)) over (partition by year(o.OrderDate) 
order by month(o.OrderDate)) as CumulativeTotal
from [Sales].[Orders] o
inner join [Sales].[Invoices] i on o.OrderID = i.OrderID
inner join [Sales].[InvoiceLines] il on i.InvoiceID = il.InvoiceID
group by year(o.OrderDate), month(o.OrderDate)
UNION ALL
select year(o.OrderDate), null, sum(il.Quantity * il.UnitPrice), sum(il.Quantity * il.UnitPrice)
from [Sales].[Orders] o
inner join [Sales].[Invoices] i on o.OrderID = i.OrderID
inner join [Sales].[InvoiceLines] il on i.InvoiceID = il.InvoiceID
group by year(o.OrderDate)) t
order by t.OrderYear, case when t.OrderMonth is null then 13 else t.OrderMonth end

--8
select OrderMonth, [2013], [2014], [2015], [2016]
FROM (select month(OrderDate) AS OrderMonth,
year(OrderDate) AS OrderYear, OrderID from Sales.Orders) as SourceTable
pivot (
count(OrderID)
for OrderYear in ([2013], [2014], [2015], [2016])) AS PivotTable
order by OrderMonth

--9
with base as (
select x.CustomerID, x.OrderID, x.OrderDate,
lag(x.OrderDate) over (partition by x.CustomerID order by x.OrderDate) as previousOrderDate,
case 
when lag(x.OrderDate) over (partition by x.CustomerID order by x.OrderDate) is not null 
then datediff(day, lag(x.OrderDate) over (partition by x.CustomerID ORDER BY x.OrderDate), x.OrderDate) 
else 0 end as days_between, datediff(day, LAST_VALUE(x.OrderDate) over (partition by
x.CustomerID order by x.OrderDate range between unbounded preceding and unbounded following), 
sysdatetime()) as DaysSinceLastOrder
from [Sales].[Orders] x)
select x.CustomerID, c.CustomerName, x.OrderDate, x.previousOrderDate, x.DaysSinceLastOrder
as DaysSinceLastOrder, avg(x.days_between) over (partition by x.CustomerID) as AvgDaysBetweenOrders,
case 
when x.DaysSinceLastOrder > 2 * avg(x.days_between) over (partition by x.CustomerID) 
then 'Potential Churn' 
else 'Active' 
end as CustomerStatus
from base x
inner join [Sales].[Customers] c on x.CustomerID = c.CustomerID

--10
with NormalizedCustomers as (
select c.CustomerCategoryID,
case
when c.CustomerName like 'Wingtip%' then 'Wingtip Generic'
when c.CustomerName like 'Tailspin%' then 'Tailspin Generic'
else c.CustomerName
end as NormalizedName
from Sales.Customers c),
CategoryCounts as (
select cc.CustomerCategoryName, count(distinct nc.NormalizedName) as CustomerCOUNT,
(select count(distinct NormalizedName)
from NormalizedCustomers) as TotalCustCount,
cast(count(distinct nc.NormalizedName) * 100.0 /
(select count(distinct NormalizedName)
from NormalizedCustomers) as decimal(5,2)) as DistributionFactor
from [Sales].[CustomerCategories] cc
inner join [Sales].[Customers] c on cc.CustomerCategoryID = c.CustomerCategoryID
inner join NormalizedCustomers nc on c.CustomerCategoryID = nc.CustomerCategoryID
group by cc.CustomerCategoryName)
select
CustomerCategoryName, CustomerCOUNT, TotalCustCount,
cast(DistributionFactor as varchar(10)) + '%' as DistributionFactor
from CategoryCounts
order by CustomerCategoryName



















