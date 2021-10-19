-- ***** START OF DATA EXPLORATION *****

Select * from "New York Suicide"
order by 1,3,5;

-- Select data we are going to be using and ordering them by year, race/ethnicity, and age

Select *, ("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths") as "Total Deaths"
from "New York Suicide" 
order by 1,3,5;

-- Looking at Total Deaths of all suicide related deaths

Alter table "New York Suicide" Add "Total Deaths" integer;
Select * from "New York Suicide";

-- Total Deaths is now a permanent column just need to populate the column

Update "New York Suicide" set "Total Deaths"= ("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths"); 
Select * from "New York Suicide"
order by 1,3,5;

-- Now that we have total deaths let's see the percentage of suicide deaths that result from Suicide

Select *, ("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths") as "Total Deaths", ("Suicide Deaths"/"Total Deaths") * 100 as SuicideDeathPercentage
from "New York Suicide"
where Region = 'NYC' and "Total Deaths" != '0'
order by 8 Desc, 9 Desc;

-- Now we have the percentage of suicide deaths that resulted by suicide for NYC
-- This shows most vulnerable demographic that dies by suicide the most in NYC

-- Looking at Demographic that died most from Alcohol in the rest of the state
--  **** 'ROS' = rest of New York state that isn't NYC ****
Select *, ("Alcohol-Related Deaths"/"Total Deaths") * 100 as AlcoholDeathPercentage
from "New York Suicide"
where Region = 'ROS' and "Total Deaths" != '0'
order by 7 Desc, 9 Desc;

-- Shows most vulnerable demographic that dies by alcohol that isn't in NYC

-- Looking at which Demographic had Most Deaths per Year
Select Year, "Race or Ethnicity", "Age Group", MAX(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as int)) as "HighestDeathCount"
from "New York Suicide"
Where "Age Group" != 'Total' and "Total Deaths" != '0'
Group by Year, "Race or Ethnicity", "Age Group"
Order by Year Desc, HighestDeathCount Desc;

-- Got all suicide related deaths to be integers I can add
-- See that since 2015 white people have had most suicides over other ethnic groups
-- Hispanics have had most suicides total, 45-64 age group is most vulnerable

Select Year, Region, "Race or Ethnicity", MAX(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as int)) as "HighestDeathCount"
From "New York Suicide" 
Where "Total Deaths" != '0' and "Age Group" != 'Total'
Group by Year, Region, "Race or Ethnicity"
Order by Year desc, HighestDeathCount desc, Region;

-- Shows Races/Ethnicities maximum deaths for every region and year
-- Get a clearier view of the data by not showing data with 0 total deaths

Select "Race or Ethnicity", SUM(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as int)) as "Total Deaths" 
From "New York Suicide"
Where "Total Deaths" != '0' and "Age Group" != 'Total'
Group by "Race or Ethnicity"
Order by "Total Deaths" desc;

-- Breaking down total suicide related deaths by Race or Ethnicity
-- Hispanics in NY have most total suicides by far

Select Region, SUM(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as int)) as "Total Deaths" 
From "New York Suicide"
Where "Total Deaths" != '0' and "Age Group" != 'Total'
Group by Region
Order by "Total Deaths" desc;

-- Shows region total deaths
-- Rest of the state (ROS) has 1.6 times as much suicides from 2003-2018 as NYC
-- despite NYC being roughly 40% of NY population


Select Year, SUM(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as int)) as Total_Deaths
From "New York Suicide"
Where "Age Group" != 'Total'
Group by Year
Order by 1 Desc;

-- Shows total amount of suicides in NY from 2003-2018
-- Has steadily increased over the years

Select "Race or Ethnicity", "Sex", SUM(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as int)) as "Total Deaths"
From "New York Suicide"
Where Year = '2015' and Region = 'NYC' and "Race or Ethnicity" like '%Hispanic%' and "Race or Ethnicity" not like 'Other%' and "Age Group" != 'Total'
Group by "Race or Ethnicity", Sex
Order by "Total Deaths" desc;
-- Selecting the total suicide deaths for NYC in 2015 for each Sex 
-- and for only Black, White, and Hispanic people


-- Looking at Suicide deaths vs Total population by Race/Ethnicity, Region, and Year
Select sui.Year, sui.Region, sui."Race or Ethnicity", SUM(cast("Firearm Deaths" + "Alcohol-Related Deaths" + "Suicide Deaths" as real)) as "Suicide Deaths", pop.TotalPop
From "New York Suicide" sui
Join "nyc census tracts" pop
On sui.region = pop.region
and sui.Year = pop.Year
and sui."Race or Ethnicity" = pop."Race or Ethnicity" 
Where "Age Group" != 'Total'
Group by sui."Race or Ethnicity", sui.Year, sui.Region, pop.TotalPop
Order by pop.TotalPop desc;

-- Let's get a running total of total alcohol-related suicide deaths for 2015 in NYC for each Race/Ethnicity

Select sui.Year, sui.Region, sui."Race or Ethnicity", sui."Alcohol-Related Deaths", SUM(cast(sui."Alcohol-Related Deaths" as int)) OVER (Partition by sui."Race or Ethnicity" Order by sui."Alcohol-Related Deaths" asc) as RollingAlcoholDeaths, pop.TotalPop
From "New York Suicide" sui
Join "nyc census tracts" pop
On sui.region = pop.region
and sui.Year = pop.Year
and sui."Race or Ethnicity" = pop."Race or Ethnicity"
Where sui."Alcohol-Related Deaths" != '0' and "Age Group" != '0'
Group by sui."Race or Ethnicity", sui.Year, sui.Region, sui."Alcohol-Related Deaths", pop.TotalPop;

-- Showcasing CTE
-- As well as a RollingAlcoholDeath vs Population Percentage

With AlcoholDeathvsPop (Year, Region, "Race or Ethnicity", "Alcohol-Related Deaths", RollingAlcoholDeaths, TotalPop)
as 
(
Select sui.Year, sui.Region, sui."Race or Ethnicity", sui."Alcohol-Related Deaths", SUM(cast(sui."Alcohol-Related Deaths" as int)) OVER (Partition by sui."Race or Ethnicity" Order by sui."Alcohol-Related Deaths" asc) as RollingAlcoholDeaths, pop.TotalPop
From "New York Suicide" sui
Join "nyc census tracts" pop
On sui.region = pop.region
and sui.year = pop.year
and sui."Race or Ethnicity" = pop."Race or Ethnicity"
Where sui."Alcohol-Related Deaths" != '0'
)
Select *, (cast(RollingAlcoholDeaths as real)/cast(TotalPop as real))*100 as RollingDeathvsPopPercentage
From AlcoholDeathvsPop;

-- Making a Temporary Table

Drop Table if exists PercentSuicidebyAlcohol;
Create Table PercentSuicidebyAlcohol
(
Year nvarchar(255),
Region nvarchar(255),
"Race or Ethnicity" nvarchar(255),
"Alcohol-Related Deaths" int,
RollingAlcoholDeaths int,
TotalPop int
);

Insert into PercentSuicidebyAlcohol
Select sui.Year, sui.Region, sui."Race or Ethnicity", sui."Alcohol-Related Deaths", SUM(cast(sui."Alcohol-Related Deaths" as int)) OVER (Partition by sui."Race or Ethnicity" Order by sui."Alcohol-Related Deaths" asc) as RollingAlcoholDeaths, pop.TotalPop
From "New York Suicide" sui
Join "nyc census tracts" pop
On sui.region = pop.region
and sui.year = pop.year
and sui."Race or Ethnicity" = pop."Race or Ethnicity"
Where sui."Alcohol-Related Deaths" != '0';

Select *,(cast(RollingAlcoholDeaths as real)/cast(TotalPop as real))*100 as RollingDeathvsPopPercentage
From PercentSuicidebyAlcohol;


-- Creating new view for data visualization

Create view ViewPercentSuicidebyAlcohol as
Select sui.Year, sui.Region, sui."Race or Ethnicity", sui."Alcohol-Related Deaths", SUM(cast(sui."Alcohol-Related Deaths" as int)) OVER (Partition by sui."Race or Ethnicity" Order by sui."Alcohol-Related Deaths" asc) as RollingAlcoholDeaths, pop.TotalPop
From "New York Suicide" sui
Join "nyc census tracts" pop
On sui.region = pop.region
and sui.year = pop.year
and sui."Race or Ethnicity" = pop."Race or Ethnicity"
Where sui."Alcohol-Related Deaths" != '0';

Select * From ViewPercentSuicidebyAlcohol;

-- ***** END OF DATA EXPLORATION *****