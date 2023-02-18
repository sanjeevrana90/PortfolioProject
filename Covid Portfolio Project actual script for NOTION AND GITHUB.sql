SELECT *
FROM CovidDeaths
ORDER BY 3, 4

--SELECT *
--FROM Covidvaccinations
--ORDER BY 3, 4


SELECT Location, Date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1,2



-- To get the dae range

SELECT MIN(Date) AS start_date, MAX(Date) AS end_date
FROM CovidDeaths
WHERE location = 'India'

-- Looking at Total Cases Vs Total Deaths
-- Shows likelihood of dying in you contact covid in INDIA

SELECT Location, Date, total_cases, total_deaths, (total_deaths/Total_cases)* 100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'India' 
ORDER BY 1,2

-- Looking at total case vs Population
--1% of total cases vs population in India	reached in 2021-04-15	
SELECT Location, Date, Population, total_cases, (total_cases/population)* 100 AS PercentagePopulationInfected
FROM CovidDeaths
WHERE location = 'India' 
ORDER BY 1,2

-- Looking at Countries with Highest infection rates compared to population
-- Since there are 2 max function we have to give 2 columsn name in the Group By condition/function

SELECT Location, Population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))* 100 AS PercentPopulationInfected
FROM CovidDeaths
--WHERE location = 'India'
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC


-- Showing Countries with Highest Death count per Population
-- Total_deaths data type is nvarchar(255) 

SELECT Location, MAX(Total_deaths) AS TotalDeathCount
FROM CovidDeaths
--WHERE location = 'India'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- Total_deaths data type is nvarchar(255) have to convert it to int to show the actual results

SELECT Location, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE location = 'India'
GROUP BY location
ORDER BY TotalDeathCount DESC

-- There is a slight issue above because it also captures locations like world, high income etc it is due to some of the continents
-- null which can be exploring the data a bit 
-- therefore "WHERE continent IS NOT NULL" gives us correct pictures 

SELECT Location, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
--WHERE location = 'India'
WHERE Continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Till now we are doing the exploration by location i.e. countries 
--Not Let's break things down by continent

SELECT Continent, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC

-- The above query is not perfect because the NorthAmerica only showing the death count of US and ASIA only showing count for India

-- Below is the correct one because not null exludes most of the countries it could be due to data errors 

SELECT Continent, MAX(CAST(Total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY TotalDeathCount DESC


--Now lets do Global Number 

SELECT Date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST
(new_deaths as int)) / SUM (new_cases) * 100 as DeathPercentage
FROM CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Date
ORDER BY 1,2

-- Total Global Number by Percentage

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) as total_deaths, SUM(CAST
(new_deaths as int)) / SUM (new_cases) * 100 as DeathPercentage
FROM CovidDeaths
WHERE Continent IS NOT NULL
--GROUP BY Date
ORDER BY 1,2


-- Now let's do some joins 
-- Looking at Total Population vs Vaccanations
-- Since we joining 2 tables we have to identify each column by their respective table orthersiwe there will be error (ambigous column_name)

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM covidDeaths dea
JOIN CovidVaccinations vac
ON dea.location = vac.location
AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL
ORDER BY 1, 2, 3

-- Now let's do some rolling count of New_vaccinations
-- Upon encountering the error "Arithmetic overflow error converting expression to data type int". I have decided to use the expression BIGINT

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY vac.date, vac.location)

FROM covidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--It is showing followng error
--ORDER BY list of RANGE window frame has total size of 1020 bytes. Largest size supported is 900 bytes.

-- Using "ROWS UNBOUNDED PRECEDING" solve the problem
--

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY vac.date, vac.location ROWS UNBOUNDED PRECEDING)
AS RollingPeopleVaccinated

FROM covidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3

--Using CTE
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY vac.date, vac.location ROWS UNBOUNDED PRECEDING)
AS RollingPeopleVaccinated

FROM covidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3
)

SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentagePeopleVaccinated
FROM PopvsVac

--This shows percentage of people vaccinated with rolling count by date and location



--Temp Table


DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date date,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY vac.date, vac.location ROWS UNBOUNDED PRECEDING)
AS RollingPeopleVaccinated

FROM covidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3


SELECT *, (RollingPeopleVaccinated/population)*100 AS PercentagePeopleVaccinated
FROM #PercentPopulationVaccinated



-- Creating View to store data for later visualization 

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, vac.new_vaccinations)) 
OVER (PARTITION BY dea.location ORDER BY vac.date, vac.location ROWS UNBOUNDED PRECEDING)
AS RollingPeopleVaccinated

FROM covidDeaths dea
JOIN CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.Date = vac.Date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *
FROM PercentPopulationVaccinated