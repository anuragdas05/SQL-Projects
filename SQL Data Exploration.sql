/*

Covid-19 Data Exploration

Skills used : Joins, CTE's, Temp Tables, Windows, Aggregate Functions, Creating Views, Converting Data Types

*/


select *
from PortfolioProject..coviddeaths
order by 3,4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3,4

-- Select data that we are going to be starting with

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..coviddeaths
where continent is not null
order by 1,2

-- Total Cases vs Total Deaths
-- Likelihood of dying if you contract Covid in your country

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%india'
order by 1,2

-- Total Cases vs Population
-- Shows percentage of people infected with Covid

select location, date, total_cases, population, (total_cases/population)*100 as InfectedPercentage
from PortfolioProject..CovidDeaths
where location like '%india'
order by 1,2

-- Countries with the highest infection rate compared to population

select location, population, max(total_cases) as HighestInfectionCount, max(total_cases/population)*100 as
PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by PercentPopulationInfected desc

-- Countries with highest death count per population

select location, population, max(cast(total_deaths as int)) as TotalDeathCount, max(total_deaths/population)*100 as PercentPopulationDeath
from PortfolioProject..CovidDeaths
where continent is not null
group by location, population
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population

select continent, max(cast(total_deaths as int)) as TotalDeathCount, max(total_deaths/population)*100 as PercentPopulationDeath
from PortfolioProject..CovidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as bigint)) as TotalDeaths, sum(cast(new_deaths as bigint))/sum(total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
group by date
order by 1,2

-- Join the two tables of CovidDeaths and CovidVaccinations
-- Looking at total population vs vaccinations

select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location
order by dea.location, dea.date) as VaccinationCount
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to perform calculation on partition by in previous query

with PopvsVac(continent, location, date, population, new_vaccinations, PeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location
order by dea.location, dea.date) as PeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
)
select *, (PeopleVaccinated/population)*100 as VaccinationPercentage
from PopvsVac

-- Using Temp Table to perform calculation on partition by in previous query

drop table if exists #VaccinationPercentage
create table #VaccinationPercentage
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
PeopleVaccinated numeric
)

insert into #VaccinationPercentage
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location
order by dea.location, dea.date) as PeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
--where dea.continent is not null

select *, (PeopleVaccinated/population)*100 as VaccinationPercentage
from #VaccinationPercentage

-- Creating view to store date for later visualizations

create view VaccinationPercentage as
select dea.continent, dea.location, dea.date, population, vac.new_vaccinations,
sum(convert(bigint, vac.new_vaccinations)) over (partition by dea.location
order by dea.location, dea.date) as PeopleVaccinated
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
on dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
