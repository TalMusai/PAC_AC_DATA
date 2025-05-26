--1     
SELECT TOP 5 p.Name as ProductName, SUM(sod.LineTotal) AS TotalSales
FROM Product p 
INNER JOIN SalesOrderDetail sod ON p.ProductID = sod.ProductID
GROUP BY p.Name
ORDER BY TotalSales DESC

--2      
SELECT pc.Name as CategoryName, AVG(s.UnitPrice) as AveragePrice
FROM ProductCategory pc
INNER JOIN ProductSubcategory psc ON pc.ProductCategoryID = psc.ProductCategoryID
INNER JOIN Product p ON psc.ProductSubcategoryID = p.ProductSubcategoryID
INNER JOIN SalesOrderDetail s ON p.ProductID = s.ProductID
WHERE pc.Name IN ('Bikes', 'Components')
GROUP BY pc.Name

--3   
SELECT p.Name, SUM(OrderQty) as TotalOrdered
FROM Product p
INNER JOIN ProductSubcategory psc ON p.ProductSubcategoryID = psc.ProductSubcategoryID
INNER JOIN ProductCategory pc ON psc.ProductCategoryID = pc.ProductCategoryID
INNER JOIN SalesOrderDetail s ON p.ProductID = s.ProductID
WHERE pc.Name NOT IN ('Clothing', 'Components')
GROUP BY p.Name

--4
SELECT TOP 3 Name as TerritoryName, SUM(so.SubTotal) as TotalSales
FROM SalesTerritory st
INNER JOIN SalesOrderHeader so ON st.TerritoryID = so.TerritoryID
GROUP BY st.Name
ORDER BY TotalSales DESC

--5
SELECT c.CustomerID, p.FirstName+ ' '+p.LastName as FullName
FROM Customer c
LEFT JOIN Person p ON c.PersonID = p.BusinessEntityID
LEFT JOIN SalesOrderHeader so ON c.CustomerID = so.CustomerID
WHERE so.SalesOrderID IS NULL

--6
DELETE st
FROM SalesTerritory st
LEFT JOIN SalesPerson sp
ON st.TerritoryID = sp.TerritoryID
WHERE sp.TerritoryID IS NULL

--7
SET IDENTITY_INSERT SalesTerritory ON
INSERT INTO SalesTerritory([TerritoryID],[Name],[CountryRegionCode],[Group],[SalesYTD]
,[SalesLastYear],[CostYTD],[CostLastYear],[rowguid],[ModifiedDate])
SELECT [TerritoryID],[Name],[CountryRegionCode],[Group],[SalesYTD]
,[SalesLastYear],[CostYTD],[CostLastYear],[rowguid],[ModifiedDate]
FROM AdventureWorks2022.Sales.SalesTerritory
WHERE TerritoryID NOT IN (SELECT TerritoryID FROM SalesTerritory)
SET IDENTITY_INSERT SalesTerritory OFF

--8
SELECT p.FirstName, p.LastName, COUNT(so.SalesOrderID) as OrderCount
FROM Person p
INNER JOIN Customer c ON p.BusinessEntityID = c.PersonID
INNER JOIN SalesOrderHeader so ON c.CustomerID = so.CustomerID
GROUP BY p.FirstName, p.LastName
HAVING COUNT(so.SalesOrderID) > 20

--9
SELECT GroupName,COUNT(DepartmentID) as DepartmentCount
FROM Department
GROUP BY GroupName
HAVING COUNT(DepartmentID) > 2

--10
SELECT p.FirstName + ' ' + p.LastName as EmployeeName, d.Name as DepartmentName, s.Name as ShiftName
FROM Employee e
INNER JOIN Person p ON e.BusinessEntityID = p.BusinessEntityID
INNER JOIN EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
INNER JOIN Department d ON edh.DepartmentID = d.DepartmentID
INNER JOIN Shift s ON edh.ShiftID = s.ShiftID
WHERE YEAR(e.HireDate) > 2010
AND d.GroupName IN ('quality assurance', 'Manufactoring')


