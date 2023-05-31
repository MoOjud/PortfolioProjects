/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

Create schema portfolio; --creating a schema to hold my portfolio objects

-- Moving the tables from the dbo schema to my portfolio schema
Alter schema portfolio transfer dbo.CovidDeaths;
Alter schema portfolio transfer dbo.CovidVaccinations;


--PRE-PROCESSING

--Changing data types
Alter table portfolio.coviddeaths
alter column [new_cases] [int]

Alter table portfolio.coviddeaths
alter column [population] [bigint]

Alter table portfolio.coviddeaths
alter column [total_cases] [float]

Alter table portfolio.coviddeaths
alter column [total_deaths] [float]

Alter table portfolio.coviddeaths
alter column [weekly_icu_admissions] [int]

Alter table portfolio.coviddeaths
alter column [weekly_icu_admissions_per_million] [float]

Alter table portfolio.coviddeaths
alter column [weekly_hosp_admissions] [int]

Alter table portfolio.coviddeaths
alter column [weekly_hosp_admissions_per_million] [float]


-- checking data was imported correctly
Select *
From portfolio.coviddeaths
order by 3, 4

Select *
From portfolio.covidvaccinations
order by 3, 4


--ANALYSIS

--Total Cases vs Total Deaths (shows the likelihood of dying if you contract covid in your country)
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From portfolio.CovidDeaths
Where location like '%states%'
Order by 1, 2

--Total cases vs population (shows the % of population with Covid)
Select Location, date, population, total_cases,  (total_cases/population)*100 AS DeathPercentage
From portfolio.CovidDeaths
Where location like '%states%'
Order by 1, 2

--Countries with highest infection rate compared to population
Select Location, population, MAX(total_cases) as HighestInfectionCount,  MAX((total_cases/population))*100 AS percentPopulationInfected
From portfolio.CovidDeaths
Group by location, population
Order by percentPopulationInfected DESC


--Countries with highest Death count per population
Select Location, MAX(total_deaths) as TotalDeathCount
From portfolio.CovidDeaths
Where continent IS NOT NULL
Group by location
Order by TotalDeathCount DESC



--BREAKING IT DOWN BY CONTINENT

--Continents with the highest death count per population
Select continent, MAX(total_deaths) as TotalDeathCount
From portfolio.CovidDeaths
Where continent IS NOT NULL
Group by continent
Order by TotalDeathCount DESC


-- GLOBAL NUMBERS

Select date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(cast(new_deaths as float))/SUM(cast(new_cases as float)))*100 AS DeathPercentage
From portfolio.CovidDeaths
Where continent is not null 
Group by date
Having SUM(new_deaths) > 0
Order by 1, 2

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, (SUM(cast(new_deaths as float))/SUM(cast(new_cases as float)))*100 AS DeathPercentage
From portfolio.CovidDeaths
Where continent is not null 
Order by 1, 2



-- Total population vs Vaccinations using 3 different methods
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

-- Using Windows Functions
Select D.continent, d.location, d.date, D.population, V.new_vaccinations, SUM(Convert(float,V.new_vaccinations)) OVER (Partition by d.location Order by D.location, D.date) as RollingPeopleVaccinated
From portfolio.CovidDeaths D
	join portfolio.CovidVaccinations V
	on d.location = V.location
	and d.date = v. date
Where d.continent is not null 
Order by 2 , 3


--Using CTE
With PopvsVac 
as 
(Select D.continent, d.location, d.date, D.population, V.new_vaccinations, SUM(Convert(float,V.new_vaccinations)) OVER (Partition by d.location Order by D.location, D.date) as RollingPeopleVaccinated
From portfolio.CovidDeaths D
	join portfolio.CovidVaccinations V
	on d.location = V.location
	and d.date = v. date
Where d.continent is not null 
--Order by 2 , 3
)
Select *, (RollingPeopleVaccinated/population)*100 AS RollingPercentVaccinated
From PopvsVac


--Using TEMPTABLE

DROP TABLE if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated(
Continent nvarchar(255),
Location varchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Rolling_People_Vaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
Select D.continent, d.location, d.date, D.population, V.new_vaccinations, SUM(Convert(float,V.new_vaccinations)) OVER (Partition by d.location Order by D.location, D.date) as RollingPeopleVaccinated
From portfolio.CovidDeaths D
	join portfolio.CovidVaccinations V
	on d.location = V.location
	and d.date = v. date
Where d.continent is not null 
--Order by 2 , 3

Select *, (Rolling_People_Vaccinated/population)*100 AS RollingPercentVaccinated
From #PercentPopulationVaccinated



--Creating View to store data for visualization

CREATE VIEW PercentPopulationVaccinated as
Select D.continent, d.location, d.date, D.population, V.new_vaccinations, SUM(Convert(float,V.new_vaccinations)) OVER (Partition by d.location Order by D.location, D.date) as RollingPeopleVaccinated
From portfolio.CovidDeaths D
	join portfolio.CovidVaccinations V
	on d.location = V.location
	and d.date = v. date
Where d.continent is not null 
--Order by 2 , 3