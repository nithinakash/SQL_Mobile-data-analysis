--**********************************--
-->Data Preparation & Understanding<--
--**********************************--

-->1.List all the states in which we have customers who have bought cellphones from 2005 till today.
select L.State,COUNT(T.IDCustomer) Count_Cust from FACT_TRANSACTIONS T
inner join DIM_LOCATION L on L.IDLocation = T.IDLocation
where DATEPART(YEAR,T.date) >= 2005
group by L.State

--------------------------------------------------------------------------------------------------------------------------------------

-->2.What state in the US is buying the most 'Samsung' cell phones?
select Top 1 L.State,SUM(T.TotalPrice)Total from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
inner join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
inner join DIM_LOCATION L on L.IDLocation = T.IDLocation
where L.Country = 'US' and MA.Manufacturer_Name = 'Samsung'
group by L.State
order by Total Desc

--------------------------------------------------------------------------------------------------------------------------------------

-->3.Show the number of transactions for each model per zip code per state.
select M.Model_Name,L.ZipCode,L.State,COUNT(T.IDCustomer) [Count_Transac] from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
inner join DIM_LOCATION L on L.IDLocation = T.IDLocation
group by M.Model_Name,L.ZipCode,L.State

--------------------------------------------------------------------------------------------------------------------------------------

-->4.Show the cheapest cellphone (Output should contain the price also)
select Top 1 MA.Manufacturer_Name,M.Model_Name,M.Unit_price from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
inner join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
order by M.Unit_price 

--------------------------------------------------------------------------------------------------------------------------------------

-->5.Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price
select M.Model_Name,ROUND(AVG(T.TotalPrice/T.Quantity),2)[AVG] from FACT_TRANSACTIONS T 
inner join DIM_MODEL M on M.IDModel = T.IDModel
inner join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
where M.IDManufacturer in
(select Top 5 M.IDManufacturer from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
group by M.IDManufacturer
order by SUM(T.Quantity) Desc)
group by M.Model_Name
order by [AVG]

--------------------------------------------------------------------------------------------------------------------------------------

-->6.List the names of the customers and the average amount spent in 2009, where the average is higher than 500
select C.Customer_Name,AVG(T.TotalPrice)[AVG] from FACT_TRANSACTIONS T 
inner join DIM_CUSTOMER C on C.IDCustomer = T.IDCustomer
where DATEPART(YEAR,T.Date) = 2009
group by C.Customer_Name
having AVG(T.TotalPrice) > 500
order by [AVG]

--------------------------------------------------------------------------------------------------------------------------------------

-->7.List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010
select * from (
(select Top 5 M.Model_Name from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
where year(T.Date) = 2008
group by M.Model_Name
order by SUM(T.Quantity) Desc)
intersect
(select Top 5 M.Model_Name from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
where year(T.Date) = 2009
group by M.Model_Name
order by SUM(T.Quantity) Desc)
intersect
(select Top 5 M.Model_Name from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
where year(T.Date) = 2010
group by M.Model_Name
order by SUM(T.Quantity) Desc)) as T1

--------------------------------------------------------------------------------------------------------------------------------------

-->8.Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
select * from
(Select ROW_NUMBER() Over (Order by Sum(F.TotalPrice) Desc)[Rws], MA.Manufacturer_Name, 
YEAR(F.Date)[Yrs],Sum(F.TotalPrice)[Total] from FACT_TRANSACTIONS F
inner join DIM_MODEL M on M.IDModel = F.IDModel
Inner Join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
where YEAR(F.Date) = 2009
Group by MA.Manufacturer_Name, YEAR(F.Date)) as T1
where Rws = 2
union all
select * from
(Select ROW_NUMBER() Over (Order by Sum(F.TotalPrice) Desc)[Rws], MA.Manufacturer_Name, 
YEAR(F.Date)[Yrs],Sum(F.TotalPrice)[Total] from FACT_TRANSACTIONS F
inner join DIM_MODEL M on M.IDModel = F.IDModel
Inner Join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
where YEAR(F.Date) = 2010
Group by MA.Manufacturer_Name, YEAR(F.Date)) as T2
where Rws = 2

--------------------------------------------------------------------------------------------------------------------------------------

-->9.Show the manufacturers that sold cellphones in 2010 but did not in 2009.
select Manufacturer_Name,COUNT(Manufacturer_Name)[cnt] from
(select * from
(select MA.Manufacturer_Name, Sum(T.Quantity)[Qty_sum] from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
inner join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
where Year(T.Date) = 2010
group by MA.Manufacturer_Name) as T1 
union all
select * from
(select MA.Manufacturer_Name, Sum(T.Quantity)[Qty_sum] from FACT_TRANSACTIONS T
inner join DIM_MODEL M on M.IDModel = T.IDModel
inner join DIM_MANUFACTURER MA on MA.IDManufacturer = M.IDManufacturer
where Year(T.Date) = 2009
group by MA.Manufacturer_Name) as T2) as T3
group by Manufacturer_Name
having COUNT(Manufacturer_Name) = 1

--------------------------------------------------------------------------------------------------------------------------------------

-->10.Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend
select Top 100 *,
case when T2.yrs is not null then (T2.Avg_spend / T1.Avg_spend) else null end [Per_Change]  from
(select C.Customer_Name,Year(T.Date)[yrs],AVG(T.TotalPrice)[Avg_spend], AVG(T.Quantity)[Avg_qty] from DIM_CUSTOMER C
inner join FACT_TRANSACTIONS T on T.IDCustomer = C.IDCustomer
group by C.Customer_Name,YEAR(T.Date)) as T1
left join
(select C.Customer_Name,Year(T.Date)[yrs],AVG(T.TotalPrice)[Avg_spend], AVG(T.Quantity)[Avg_qty] from DIM_CUSTOMER C
inner join FACT_TRANSACTIONS T on T.IDCustomer = C.IDCustomer
group by C.Customer_Name,YEAR(T.Date)) as T2 on T2.Customer_Name = T1.Customer_Name and T2.yrs = T1.yrs + 1

--------------------------------------------------------------------------------------------------------------------------------------