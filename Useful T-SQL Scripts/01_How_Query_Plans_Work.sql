USE Adventureworks;
GO

--Index scan -- reads the whole table?
SELECT *
  FROM Production.Product;
GO

--What really controls a scan?
SELECT TOP (100) *
  FROM Production.Product;
GO

--Insight: Number of Executions
SELECT TOP (1000) P.Productid,
       Th.Transactionid
  FROM Production.Product AS P
       INNER LOOP JOIN Production.Transactionhistory AS Th WITH (FORCESEEK) ON P.Productid = Th.Productid
 WHERE Th.Actualcost > 50
   AND P.Standardcost < 10;
GO