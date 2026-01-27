Select *
From CovidPortfolioDB..CovidDeaths$
where continent is not null
order by 3,4

--Select *
--From CovidPortfolioDB..CovidVaccinations$
--order by 3,4

--Select Data that we're going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From CovidPortfolioDB..CovidDeaths$
order by 1,2


-- looking at Total Cases vs Total Deaths (number of deaths for the number of cases)
-- shows likelihood of drying if you contract covid in your country
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidPortfolioDB..CovidDeaths$
Where location like '%states%'
order by 1,2


-- looking at Total Cases vs Population
-- shows percentage of population got Covid
Select Location, date, population, total_cases, (total_cases/population)*100 as InfectedPercentage
From CovidPortfolioDB..CovidDeaths$
-- Where location like '%states%'
order by 1,2

-- looking at country with highest Infection rate compared to Population

Select Location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as InfectedPercentage
From CovidPortfolioDB..CovidDeaths$
-- Where location like '%states%'
Group by Location, Population
order by InfectedPercentage desc


-- showing countries with Highest Death Count per population

Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolioDB..CovidDeaths$
-- Where location like '%states%'
where continent is not null
Group by Location
order by TotalDeathCount desc



-- BREAK THINGS DOWN BY CONTINENT

-- showing continents with highest death counts

-- anything above, group by just replace by 'continent'

Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolioDB..CovidDeaths$
-- Where location like '%states%'
where continent is not null
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

-- why group by 'date' error? because there're other variables so can't just group by date
-- so if want to group, use aggregate on everything else
-- sum of new cases = no of total_cases

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, 
SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidPortfolioDB..CovidDeaths$
-- Where location like '%states%'
where continent is not null
-- group by date
order by 1,2

-- Overall, across the world, chance of death is 2.11% if got infected


-- looking at Total Population vs Vaccinations

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

-- calculate a running total (cummulative sum) of vaccinations per country
, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.Location Order by dea.location, dea.Date)
As RollingPeopleVaccinated
-- ,(RollingPeopleVaccinated/population)*100

-- PARTITION BY dea.location: reset the calculation for each country, with it country would start at 0
-- ORDER BY dea.Date: sequence in which to add value, e.g., day 3 = day 1+2+3, without it sql compute total not cum total
-- dea.location is actually redundant because you already partitioned by it

From CovidPortfolioDB..CovidDeaths$ dea
Join CovidPortfolioDB..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
-- remove aggregate rows
where dea.continent is not null
order by 2,3 -- location and date for readability

-- cast(var as int) = convert(int, var)



-- USE CTE

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.Location Order by dea.location, dea.Date)
As RollingPeopleVaccinated

From CovidPortfolioDB..CovidDeaths$ dea
Join CovidPortfolioDB..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date

where dea.continent is not null
-- order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated

-- Why? SQL does not overwrite objects by default, when it sees CREATE TABLE it reads as Create a BRAND NEW table with this name
-- So the 2nd time we run the same code, SQL says I can't create sth that already exists so script fails before it even reaches INSERT
-- Why SQL doesn't just replace the table? Dangerous, If it auto-overwrote, could accidentally delete data, one typo could wipe real data

Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations

, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.Location Order by dea.location, dea.Date)
As RollingPeopleVaccinated

From CovidPortfolioDB..CovidDeaths$ dea
Join CovidPortfolioDB..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date

-- where dea.continent is not null
-- order by 2,3


Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated



-- Create View to store data for visualizations
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as int))
OVER (Partition by dea.Location Order by dea.location, dea.Date)
As RollingPeopleVaccinated

From CovidPortfolioDB..CovidDeaths$ dea
Join CovidPortfolioDB..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
-- order by 2,3


Select *
From PercentPopulationVaccinated
