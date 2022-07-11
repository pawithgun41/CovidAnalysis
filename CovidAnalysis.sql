Select *
From CovidAnalysis..CovidDeaths$;

-- select data that we use
Select location, date, total_cases, new_cases, total_deaths, population
From CovidAnalysis..CovidDeaths$
order by 1,2


-- looking at total cases vs total deaths
-- show likelihood of dying if you contact covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidAnalysis..CovidDeaths$
where location like '%thai%'
order by 1,2


-- looking at total cases vs population
-- show percentage of pupulation got covid in Thailand
Select location, date, total_cases, population, (total_cases/population)*100 as TotalCasePercentage
From CovidAnalysis..CovidDeaths$
where location like '%thai%'
order by 1,2


-- lookoing at countries with highest infection compared to population
Select location, population, max(total_cases) as HighestInfectionCount,  max(total_cases/population)*100 as PercentagePopulationInfected
From CovidAnalysis..CovidDeaths$
--where location like '%thai%'
Group by location, population
order by PercentagePopulationInfected desc


-- showing countries with highest death count per population
Select location, population, max(cast(total_deaths as int)) as TotalDeathCount,  max(total_deaths/population)*100 as PercentagePopulationDeath
From CovidAnalysis..CovidDeaths$
--where location like '%thai%'
Group by location, population
order by PercentagePopulationDeath desc


-- Breaking by continent
-- showing max death count by continent
Select continent, max(cast(total_deaths as int)) as TotalDeathCount
From CovidAnalysis..CovidDeaths$
Where continent is not null
Group by continent
order by TotalDeathCount desc


-- Global numbers
-- show new case for each day
Select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, sum(cast(new_deaths as int))/sum(new_cases)*100 as DeathPercentage
From CovidAnalysis..CovidDeaths$
Where continent is not null
Group by date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select cast(dea.continent as nvarchar(150)), 
	   cast(dea.location as nvarchar(150)), 
	   dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by cast(dea.location as nvarchar(150)) 
	   Order by cast(dea.location as nvarchar(150)), dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths$ dea
Join CovidAnalysis..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Using CTE to Partition percentage
With PopulationvsVaccinated (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select cast(dea.continent as nvarchar(150)), 
	   cast(dea.location as nvarchar(150)), 
	   dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by cast(dea.location as nvarchar(150)) 
	   Order by cast(dea.location as nvarchar(150)), dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths$ dea
Join CovidAnalysis..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopulationvsVaccinated



-- Using Temp Table to Partition percentage

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(150),
Location nvarchar(150),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select cast(dea.continent as nvarchar(150)), 
	   cast(dea.location as nvarchar(150)), 
	   dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by cast(dea.location as nvarchar(150)) 
	   Order by cast(dea.location as nvarchar(150)), dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths$ dea
Join CovidAnalysis..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data of cumulative rolling people vaccinated
Create View PercentPopulationVaccinated as
Select cast(dea.continent as nvarchar(150)) continent, 
	   cast(dea.location as nvarchar(150)) location, 
	   dea.date, dea.population, vac.new_vaccinations,
	   SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by cast(dea.location as nvarchar(150)) 
	   Order by cast(dea.location as nvarchar(150)), dea.date) as RollingPeopleVaccinated
From CovidAnalysis..CovidDeaths$ dea
Join CovidAnalysis..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

------------------------------------------------------------------------------------------------------------------

-- 1.
with cte_rollingpeoplevaccinated as (
Select	dea.continent,
		dea.location, 
		dea.date,
		dea.population,
		MAX(vac.total_vaccinations) as RollingPeopleVaccinated
, (MAX(vac.total_vaccinations)/dea.population)*100 as PercentRollingPeopleVaccinated
From CovidAnalysis..CovidDeaths$ dea
Join CovidAnalysis..CovidVaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.location, dea.date, dea.population
)
select *
from cte_rollingpeoplevaccinated
where RollingPeopleVaccinated is not null
order by 1,2,3



-- 2.

Select	date,
		SUM(cast(new_cases as int)) as total_cases, 
		SUM(cast(new_deaths as int)) as total_deaths, 
		SUM(cast(new_deaths as int))/SUM(cast(new_cases as int))*100 as DeathPercentage
From CovidAnalysis..CovidDeaths$
where continent is not null 
Group By date
order by 1,2


-- 3.

Select	Location,
		Population,
		MAX(cast(total_cases as int)) as HighestInfectionCount,  
		Max(cast(total_cases as float)/population)*100 as PercentPopulationInfected
From CovidAnalysis..CovidDeaths$
Group by Location, Population
order by PercentPopulationInfected desc



-- 4.

Select	Location,
		population,
		MAX(cast(total_deaths as int)) as TotalDeaths,
		Max(cast(total_deaths as float)/population)*100 as PercentPopulationDeaths
From CovidAnalysis..CovidDeaths$
where continent is not null
group by location, population
order by PercentPopulationDeaths desc









