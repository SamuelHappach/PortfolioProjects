-- ***** START OF DATA CLEANING *****

-- First we look at the dataset

Select * from DataCleaning..ComputerJobs


---------------------------------------------------------------------------------------------

-- Break out Location and Headquarters into Individual Columns (City, State)

-- First lets break into State
-- ** SHOWCASING SUBSTRING, CHARINDEX, PARSENAME, and REPLACE functions **

Select Location
From DataCleaning..ComputerJobs

Select
SUBSTRING(Location, CHARINDEX(',', Location) +1, LEN(Location)) as Location_State
From DataCleaning..ComputerJobs;

Alter Table ComputerJobs
Add Location_State Nvarchar(255);

Update DataCleaning..ComputerJobs
Set Location_State = SUBSTRING(Location, CHARINDEX(',', Location) +1, LEN(Location));

-- Now Headquarters into State

Select Headquarters
From DataCleaning..ComputerJobs;

Select
SUBSTRING(Headquarters, CHARINDEX(',', Headquarters) +1, LEN(Headquarters)) as Headquarters_State
From DataCleaning..ComputerJobs;

Alter Table ComputerJobs
Add Headquarters_State Nvarchar(255);

Update DataCleaning..ComputerJobs
Set Headquarters_State = SUBSTRING(Headquarters, CHARINDEX(',', Headquarters) +1, LEN(Headquarters));

-- Now let's break into City

Select Location, Headquarters
From DataCleaning..ComputerJobs;

Select SUBSTRING(Location, 1, CHARINDEX(',',Location)) as Location_City,
SUBSTRING(Headquarters, 1, CHARINDEX(',', Headquarters)) as Headquarters_City
From DataCleaning..ComputerJobs;

Alter Table ComputerJobs
Add Headquarters_City Nvarchar(255);

Alter Table ComputerJobs
Add Location_City Nvarchar(255);

Update DataCleaning..ComputerJobs
Set Location_City = SUBSTRING(Location, 1, CHARINDEX(',', Location));

Update DataCleaning..ComputerJobs
Set Headquarters_City = SUBSTRING(Headquarters, 1, CHARINDEX(',', Headquarters));

-- There are some problems with Location_State such as United States, Remote, and States
-- not being converted to their initials so let's fix that first
-- I see that 061 is from NY and there are Countires not in USA in Headquarters_State
-- Location and Headquarters City I am unable to remove the comma for every row 
-- using SUBSTRING/CHARINDEX so let's fix these 

Select Location_City, Location_State, Headquarters_City, Headquarters_State
From DataCleaning..ComputerJobs;

Select PARSENAME(REPLACE(Location_City, ',', ''), 1) as Location_City,
PARSENAME(REPLACE(Location_State, 'Anne Arundel, MD', 'MD'), 1) as Location_State,
PARSENAME(REPLACE(Headquarters_City, ',', ''), 1) as Headquarters_City,
PARSENAME(REPLACE(Headquarters_State, '061', 'NY'), 1) as Headquarters_State
From DataCleaning..ComputerJobs

Update DataCleaning..ComputerJobs
SET Location_City = PARSENAME(REPLACE(Location_City, ',', ''), 1),
Location_State = PARSENAME(REPLACE(Location_State, 'Anne Arundel, MD', 'MD'), 1),
Headquarters_City = PARSENAME(REPLACE(Headquarters_City, ',', ''), 1),
Headquarters_State = PARSENAME(REPLACE(Headquarters_State, '061', 'NY'), 1)

Select Location_City, Location_State, Headquarters_City, Headquarters_State
From DataCleaning..ComputerJobs;

-- Need to move Remote and United States from Location_State into the Location_City Column

Update DataCleaning..ComputerJobs
Set Location_City = 'Remote'
Where Location_State = 'Remote'

Update DataCleaning..ComputerJobs
Set Location_City = 'United States'
Where Location_State = 'United States'

Update DataCleaning..ComputerJobs
Set Location_State = 'N/A'
Where Location_City = 'Remote' or Location_City = 'United States'

Select Location_City, Location_State, Headquarters_City, Headquarters_State
From DataCleaning..ComputerJobs


-- We need to update spelled out California, Utah, New Jersey, Texas into initials in 
-- Location State and Update Null/-1 values in Headquarters City/State to N/A then we 
-- are done!!!!

Update DataCleaning..ComputerJobs
Set Headquarters_City = 'N/A'
Where Headquarters_State = '-1';

Update DataCleaning..ComputerJobs
Set Headquarters_State = 'N/A'
Where Headquarters_State = '-1';

Update DataCleaning..ComputerJobs
Set Location_State = 'CA'
Where Location_State = 'California';

Update DataCleaning..ComputerJobs
Set Location_State = 'UT'
Where Location_State = 'Utah';

Update DataCleaning..ComputerJobs
Set Location_State = 'NJ'
Where Location_State = 'New Jersey';

Update DataCleaning..ComputerJobs
Set Location_State = 'TX'
Where Location_State = 'Texas';

Update DataCleaning..ComputerJobs
Set Location_City = 'N/A'
Where Location_City is NULL;

Select Location_City, Location_State, Headquarters_City, Headquarters_State
From DataCleaning..ComputerJobs

-- Deleting original uncleaned columns

Alter table DataCleaning..ComputerJobs
Drop Column Location, Headquarters;

Select * From DataCleaning..ComputerJobs;
---------------------------------------------------------------------------------------------------

-- Remove Duplicate data

-- ** SHOWCASING INNER JOIN and the RANK function **

Select D."Salary Estimate", D."Job Title", 
	D."Job Description", D."Company Name", D.Size, D.Industry, R.row_num
From DataCleaning..ComputerJobs D
	INNER JOIN
(
SELECT *,
	RANK() OVER (PARTITION BY "Salary Estimate", "Job Title", 
	"Job Description", "Company Name", Size, Industry
	ORDER BY "index") row_num
	FROM DataCleaning..ComputerJobs
	) R on D."index" = R."index";

--- Now we delete any rows that are duplicates

Delete D
From DataCleaning..ComputerJobs D
	INNER JOIN
	(
		SELECT *, 
		RANK() OVER(PARTITION BY "Salary Estimate", "Job Title", 
	"Job Description", "Company Name", Size, Industry
	ORDER BY "index") row_num
	FROM DataCleaning..ComputerJobs
	) R on D."index" = R."index"
	WHERE row_num > 1;

------------------------------------------------------------------------------------------

-- Replacing Unnecessary NULL data (-1) with N/A and
-- Removing Rating Data from Company Name column

-- ** SHOWCASING CASE PROCESS ** 

Select Rating, "Company Name" 
from DataCleaning..ComputerJobs

-- Change data type of Rating from float to nvarchar so I can
-- update the column 
Alter table DataCleaning..ComputerJobs
Alter column Rating nvarchar(255);

--- Alternative way I could do that is down below 

-- Select Rating, Convert(nvarchar(255), Rating)
-- From DataCleaning..ComputerJobs;

-- Update DataCleaning..ComputerJobs
-- Set Rating = Convert(nchar(255), Rating);

Update DataCleaning..ComputerJobs
Set Rating = CASE When Rating = '5' Then '5.0'
	When Rating = '4' Then '4.0'
	When Rating = '3' Then '3.0'
	When Rating = '2' Then '2.0'
	When Rating = '1' Then '1.0'
	Else SUBSTRING(Rating, 1, LEN(Rating))
	END;

Update DataCleaning..ComputerJobs
Set Rating = 'N/A'
Where Rating = '-1'

Select Rating, "Company Name" 
from DataCleaning..ComputerJobs;

Select Rating, PARSENAME(REPLACE("Company Name", Rating, ''), 1)
From DataCleaning..ComputerJobs

Update DataCleaning..ComputerJobs
Set "Company Name" = PARSENAME(REPLACE("Company Name", Rating, ''), 1)

------------------------------------------------------------------------------------------

-- ***** END OF DATA CLEANING *****