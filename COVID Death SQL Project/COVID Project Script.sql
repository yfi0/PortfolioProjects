-- Putting main table here for guidelines and reference
SELECT *
 FROM CovidDeaths
 ORDER BY 3, 4

SELECT *
 FROM CovidVaccinations
 ORDER BY 3, 4

SELECT location, total_vaccinations, people_vaccinated, people_fully_vaccinated, 
    new_vaccinations, new_vaccinations_smoothed, total_vaccinations_per_hundred
 FROM CovidVaccinations
 WHERE continent is not null
 ORDER BY 1,2


-- Select Data that we are using

SELECT location, date, total_cases, new_cases, total_deaths, new_deaths
    -- , vac.population
 FROM CovidDeaths
 ORDER BY 1,2

-- 1.
-- Global total cases, deaths, death percentage
SELECT sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
 FROM CovidDeaths
 WHERE continent is not NULL
 ORDER BY 1,2
-- Dobule checking if the numbers are close to international ones
-- no. are extremely close, so we will keep the current number
SELECT sum(new_cases) as total_cases, sum(new_deaths) as total_deaths, sum(new_deaths)/sum(new_cases)*100 as DeathPercentage
 FROM CovidDeaths
 WHERE location = 'World'
 ORDER BY 1,2


-- 2.
-- total deaths count by continent
SELECT location, sum(new_deaths) as total_deaths
 FROM CovidDeaths
 WHERE continent is NULL
    AND location not in ('World', 'High income', 'Upper middle income', 'Lower middle income', 'Low income', 'European Union')
 GROUP BY location
 ORDER BY total_deaths DESC



-- Looking at Total Cases vs Total Deaths
    -- Shows likelihood of dying if you contrat covid in specific countries
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
 FROM CovidDeaths
 -- looking further into specifics
 -- WHERE location LIKE '%states%' 
 ORDER BY 1,2

-- Looking at Total Cases vs Population
    -- Shows what % of population got Covid
SELECT dea.location, dea.date, vac.population, dea.total_cases, (dea.total_cases/vac.population)*100 as PercentPopulationInfected
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 -- WHERE location LIKE '%states%' 
 ORDER BY 1,2


-- 3.
-- Looking at Countries w/ Highest Infection Rate compared to Population w/o date
SELECT dea.location, vac.population, MAX(dea.total_cases) AS HighestInfectionCount
    , MAX(dea.total_cases/vac.Population)*100 as PercentPopulationInfected
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 -- WHERE location LIKE '%states%' 
 GROUP BY dea.location, vac.population
 ORDER BY PercentPopulationInfected DESC

-- 4.
-- Looking at Countries w/ Highest Infection Rate compared to Population w/ date
SELECT dea.location, vac.population, dea.date, MAX(dea.total_cases) AS HighestInfectionCount
    , MAX(dea.total_cases/vac.Population)*100 as PercentPopulationInfected
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 -- WHERE location LIKE '%states%' 
 GROUP BY dea.location, vac.population, dea.date
 ORDER BY PercentPopulationInfected DESC



-- Changing focus to Continent instead of location, 
    -- bc this helps drill down into data visualizing

-- Showing Continent w/ Highest Death Count per Population
    -- 1. use 'cast(as)' to convert datatype if needed
    -- 2. only Continent is wanted in location, not Continent
        -- by checking the original table, we know continent would be NULL when location is continent or World
SELECT location, MAX(total_deaths) AS TotalDeathCoun
 FROM CovidDeaths
 -- WHERE location LIKE '%states%'
 WHERE continent IS NULL 
 GROUP BY location
 ORDER BY TotalDeathCoun DESC


-- Start looking at a view point where we are trying to visualize it

-- Everything across entire world = Global numbers

-- Global Death Percentage per day
-- would encounter trouble in GROUP BY date
    --if looking at mulitiple other col/ things which requires aggrate function
SELECT date
    , SUM(new_cases_smoothed) as new_cases_smoothed, SUM(new_deaths_smoothed) as new_deaths_smoothed
    , SUM(new_deaths_smoothed)/SUM(new_cases_smoothed)*100 as DeathPercentage
 FROM CovidDeaths
 -- WHERE location LIKE '%states%' 
 -- using continent IS not NULL to filter out the rows w/ location that are not country: continent or world or international
 WHERE continent IS not NULL 
 GROUP BY date
 ORDER BY 1,2

-- Global Total Death Percentage
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as 
    DeathPercentage
 FROM CovidDeaths
 -- WHERE location LIKE '%states%' 
 -- using continent IS not NULL to filter out the rows w/ location that are not country: continent or world or international
 WHERE continent IS not NULL 
 -- GROUP BY date
 ORDER BY 1,2



-- USE CTE, create new table name and col. names
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
as 
(
-- Looking at Total Population vs Vaccination
SELECT dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations,
    -- only partition by location so the aggragration (sum) doesnt go over everytime there is a new location
    -- order by location and date so when it adds up it will only add from each row with the same location and correct order
    SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, 
    dea.date) as RollingPeopleVaccinated
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not NULL
 -- ORDER by 2,3
)
SELECT *, (RollingPeopleVaccinated*1.0/Population)*100 as PercentPopulationVaccinated
FROM PopvsVac


-- TEMP TABLE

DROP TABLE if EXISTS #PercentPopulationVaccinated
 CREATE TABLE #PercentPopulationVaccinated
 (
 Continent NVARCHAR(255),
 Location NVARCHAR(255),
 Date DATE,
 Population NUMERIC,
 New_vaccinations NUMERIC,
 RollingPeopleVaccinated NUMERIC
 )

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations,
    -- only partition by location so the aggragration (sum) doesnt go over everytime there is a new location
    -- order by location and date so when it adds up it will only add from each row with the same location and correct order
    SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, 
        dea.date) as RollingPeopleVaccinated
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not NULL
 ORDER by 2,3

SELECT *, (RollingPeopleVaccinated*1.0/Population)*100 as PercentPopulationVaccinated
 FROM #PercentPopulationVaccinated


-- Creating View to store data for later visuaalization

Create View PercentPopulationVaccinated as 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
    -- only partition by location so the aggragration (sum) doesnt go over everytime there is a new location
    -- order by location and date so when it adds up it will only add from each row with the same location and correct order
    SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, 
    dea.date) as RollingPeopleVaccinated
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not NULL
 -- ORDER by 2,3
 
SELECT *
FROM PercentPopulationVaccinated


-- Ideas: age, poverty, cardiovasc death rate, diabetes, smokers, handwashing facilities, hospital beds, life expectancy, human development index

-- 5.
-- Check if average Stringency index of a country have correlation with total death rates/ vax rates
SELECT dea.location -- SUM(dea.new_cases) as total_cases, SUM(dea.new_deaths) as total_deaths, 
    , SUM(dea.new_deaths)/NULLIF(SUM(dea.new_cases), 0)*100 as DeathPercentage -- deaths per cases percentage
    , MAX(dea.total_deaths_per_million) as total_deaths_per_million -- DeathPerPopulation
    -- , SUM(vac.new_vaccinations_smoothed) as total_vaccinations -- Total number of COVID-19 vaccination doses administered / -- , MAX(vac.total_vaccinations) as total_vaccinations2 -- for checking / -- , SUM(vac.new_vaccinations) as total_vaccinations -- not a good representation of total_vax due to data sum error
    , SUM(vac.new_vaccinations_smoothed)/MAX(vac.population)*100 as vaccination_administered_per_hundred -- Total number of COVID-19 vaccination doses administered per 100 people in the total population
    , MAX(people_vaccinated)/MAX(vac.population)*100 as people_vaccinated_per_hundred --Exceed 100% due to non-residential vaccination / -- , MAX(vac.total_vaccinations_per_hundred) as total_vaccinations_per_hundred -- for checking / -- , MAX(people_vaccinated_per_hundred) as people_vaccinated_per_hundredD -- for checking
    , MAX(people_fully_vaccinated)/MAX(vac.population)*100 as people_fully_vaccinated_per_hundred -- , MAX(people_fully_vaccinated_per_hundred) as people_fully_vaccinated_per_hundred
    , AVG(vac.stringency_index) as average_stringency_index
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 -- Continent not null = only countries in location
 WHERE dea.continent IS not NULL 
    -- AND vac.stringency_index IS NOT NULL
 GROUP BY dea.location
 ORDER BY stringency_index DESC

-- Check if Stringency index have correlation with death rates/ vax rates based on grouping stringency level and location
SELECT dea.continent, dea.location,
    AVG(dea.new_deaths) as average_new_deaths,
    AVG(dea.new_deaths_per_million) as average_new_deaths_per_million, -- DeathPerPopulation
    AVG(vac.new_vaccinations) as average_new_vaccinations, 
    AVG(vac.new_vaccinations/ vac.population) as AverageNewVaccinationPerPopultation, 
    CAST(vac.stringency_index as int) as stringency_index
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 -- Continent not null = only countries in location
 WHERE dea.continent IS not NULL 
    AND vac.stringency_index IS NOT NULL
 GROUP BY vac.stringency_index, dea.location, dea.continent
 ORDER BY stringency_index DESC
--  ORDER BY average_new_deaths, stringency_index

-- 6. https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9758449/
-- Check if average Stringency index vs new case and new death thru years
SELECT dea.location, dea.date
    , dea.new_cases/vac.population*100000 as cases_per_100K
    , dea.new_deaths/vac.population*100000 as deaths_per_100K
    , dea.new_deaths/NULLIF(dea.new_cases, 0)*100 as DeathPercentage -- deaths per cases percentage
    , vac.stringency_index 
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 -- Continent not null = only countries in location
 WHERE dea.continent IS not NULL 
 ORDER BY date

-- Doesnt really show relation from what i see
    -- cardiovasc_death_rate, diabetes_prevalence, female_smokers, male_smokers and death
    SELECT dea.continent, dea.location, 
        -- SUM(dea.new_cases) as total_cases, SUM(dea.new_deaths) as total_deaths, 
        MAX(dea.total_deaths)/MAX(dea.total_cases)*100 as DeathPercentage, -- deaths per cases percentage
        MAX(dea.total_deaths_per_million) as total_deaths_per_million, -- DeathPerPopulation
        MAX(vac.cardiovasc_death_rate) as cardiovasc_death_rate, 
        MAX(vac.diabetes_prevalence) as diabetes_prevalence, 
        MAX(vac.female_smokers) as female_smokers, 
        MAX(vac.male_smokers) as male_smokers,
        MAX(vac.female_smokers) + MAX(vac.male_smokers) as Total_smokers
    From CovidDeaths dea
    JOIN CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    -- Continent not null = only countries in location
    WHERE dea.continent IS not NULL 
    GROUP BY dea.location, dea.continent
    ORDER BY Total_smokers
    -- ORDER BY male_smokers, DeathPercentage

-- 7.
-- How does the total number of COVID-19 cases per million people vary across different continents?
-- Only the most recent date recorded (mostly 240303), location vs total case per million
WITH PopvsCases (Continent, Location, total_cases, Population)
as 
(
SELECT dea.continent, dea.location
    , SUM(dea.new_cases) as total_cases
    , MAX(vac.population) as population
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location
--  ORDER BY dea.location
)
SELECT Continent, SUM(total_cases) as total_cases, SUM(Population) as Population
    , SUM(total_cases)/SUM(population)*1000000 as total_cases_per_million
 FROM PopvsCases 
 GROUP BY Continent
 ORDER BY total_cases_per_million


-- All dates to show changes throuout time, location vs total case per million w/ dates
SELECT dea.continent, dea.location
    , dea.date
    , new_cases/vac.population*1000000 as total_cases_per_million
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
--  GROUP BY dea.continent, dea.location, dea.date
 ORDER BY dea.continent, dea.location, dea.date


-- 8.
-- Is there a correlation between the median age of a population and the severity of COVID-19 outbreaks in terms of total cases per million people?
-- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7803535/
-- median age, life_expectancy
SELECT dea.continent, dea.location
    , SUM(dea.new_deaths) as total_deaths
    , MAX(vac.population) as population
    , SUM(dea.new_deaths)/MAX(vac.population)*1000000 as total_deaths_per_million
    , vac.median_age
    , vac.life_expectancy
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location, vac.median_age, vac.life_expectancy
 ORDER BY vac.median_age DESC

-- 9.
-- COVID-19 mortality for ageing population in the above median group versus the below median group.
-- COVID-19 mortality for median age and life expectancy at birth in the above median group versus the below median group. 
-- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7803535/
-- a Mortality is case fatality rate of COVID-19, which is the number of confirmed deaths per the number of confirmed COVID-19 cases.
SELECT dea.continent, dea.location
    , SUM(dea.new_deaths) as total_deaths
    , MAX(vac.population) as population
    , SUM(dea.new_deaths)/NULLIF(SUM(dea.new_cases), 0) as covid_mortality
    , vac.median_age
    , vac.life_expectancy
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location, vac.median_age, vac.life_expectancy
 ORDER BY vac.median_age DESC



-- Are countries with higher GDP per capita more likely to have a higher percentage of their population vaccinated against COVID-19?
-- Only the most recent date recorded (mostly 240303)
SELECT dea.location, MAX(dea.date) as date, MAX(vac.people_vaccinated_per_hundred) as people_vaccinated_per_hundred, 
    MAX(vac.people_fully_vaccinated_per_hundred) as people_fully_vaccinated_per_hundred, MAX(vac.gdp_per_capita) as gdp_per_capita
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
GROUP BY dea.location
 ORDER BY 1,2
-- All dates to show changes throuout time
SELECT dea.location, dea.date, vac.people_vaccinated_per_hundred, vac.people_fully_vaccinated_per_hundred ,vac.gdp_per_capita
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 ORDER BY 1,2


-- What is the relationship between the stringency of government responses to COVID-19 and the number of new cases reported per million people?
-- provided cases/deaths are sometimes reported in 7 days/ periodically, smoothed -> 7days smoothed
-- techincally can also manually smooth it out
SELECT dea.location, dea.date, vac.stringency_index, dea.new_cases_per_million, dea.new_cases_smoothed_per_million, 
    dea.new_deaths_per_million, dea.new_deaths_smoothed_per_million
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 ORDER BY 1,2
-- manually smoothed and group by weekly
SELECT   dea.location
    , MIN(dea.date)  AS [Start_Date]
    , MAX(dea.date)  AS [End_Date]
    , AVG(vac.stringency_index)  AS [weekly_Avg_stringency_index]
    , AVG(dea.new_cases_per_million)  AS [weekly_Avg_new_cases_per_million]
    -- for checking if calculation is correct
    -- , AVG(dea.new_cases_smoothed_per_million)  AS [weekly_Avg_new_cases_smoothed_per_million]
    , AVG(dea.new_deaths_per_million)  AS [weekly_Avg_new_deaths_smoothed_per_million]
    -- for checking if calculation is correct
    -- , AVG(dea.new_deaths_smoothed_per_million)  AS [weekly_Avg_new_deaths_smoothed_per_million]
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date  
GROUP BY DATEDIFF(DAY, '2020-01-05', dea.date) / 7, dea.location
ORDER BY dea.location, [Start_Date]



-- Is there a difference in the distribution of hospital beds per thousand people between continents, 
-- and does this correlate with the severity of COVID-19 outbreaks?
SELECT dea.continent, dea.location
    -- , dea.date
    , MAX(vac.hospital_beds_per_thousand) AS hospital_beds_per_thousand
    , SUM(dea.new_cases)  AS total_cases
    -- Checking Calculation
    -- , MAX(dea.total_cases)
    , SUM(dea.new_deaths) As total_deaths
    -- Checking Calculation
    -- , MAX(dea.total_deaths)
    ,  SUM(dea.new_deaths) / NULLIF(SUM(dea.new_cases), 0) * 100 As DeathPercentage
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location
 ORDER BY 3


-- How does the availability of handwashing facilities impact the spread of COVID-19, particularly in densely populated areas?
SELECT dea.continent, dea.location
    -- , dea.date
    , MAX(vac.handwashing_facilities) AS handwashing_facilities
    , SUM(dea.new_cases)  AS total_cases
    , SUM(dea.new_deaths) As total_deaths
    , MAX(vac.population_density) AS population_densityandwashing_facilities
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location
 ORDER BY 3


-- Are there significant differences in excess mortality rates between countries with varying levels of human development index?
-- How does the excess mortality rate vary between countries with different levels of cardiovascular disease death rates?
-- excess_mortality
-- excess_mortality_cumulative
-- excess_mortality_cumulative_absolute
-- excess_mortality_cumulative_per_million
-- Percentage difference between the reported number of weekly or monthly deaths in 2020–2021 and the projected number of deaths for the same period based on previous years. For more information, see https://github.com/owid/covid-19-data/tree/master/public/data/excess_mortality
-- Percentage difference between the cumulative number of deaths since 1 January 2020 and the cumulative projected deaths for the same period based on previous years. For more information, see https://github.com/owid/covid-19-data/tree/master/public/data/excess_mortality
-- Cumulative difference between the reported number of deaths since 1 January 2020 and the projected number of deaths for the same period based on previous years. For more information, see https://github.com/owid/covid-19-data/tree/master/public/data/excess_mortality
-- Cumulative difference between the reported number of deaths since 1 January 2020 and the projected number of deaths for the same period based on previous years, per million people. For more information, see https://github.com/owid/covid-19-data/tree/master/public/data/excess_mortality

-- across all dates
SELECT dea.continent, dea.location
    , dea.date
    , excess_mortality
    , excess_mortality_cumulative
    , excess_mortality_cumulative_absolute
    , excess_mortality_cumulative_per_million
    , human_development_index
    , cardiovasc_death_rate
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
    AND vac.excess_mortality is not null
--  GROUP BY dea.continent, dea.location
 ORDER BY 2,3

-- only the furthest date that still have excess_mortality
SELECT vac.continent, vac.location
    , vac.date
    , vac.excess_mortality
    , vac.excess_mortality_cumulative
    , vac.excess_mortality_cumulative_absolute
    , vac.excess_mortality_cumulative_per_million
    , vac.human_development_index
 FROM CovidVaccinations vac
 INNER JOIN
    -- find the furthest date that still have excess_mortality for every location and what date it is 
    (SELECT location
        , MAX(date) AS MaxDateTime
     FROM CovidVaccinations
     WHERE excess_mortality is not null
     GROUP BY location) as maxdate
 ON vac.location = maxdate.location
 AND vac.date = maxdate.MaxDateTime
 WHERE vac.continent is not null
 ORDER BY 2,3
-- can be expended by using the date where most location still have excess_mortality rate

-- How does the excess mortality rate vary between countries with different levels of cardiovascular disease death rates?
SELECT vac.continent, vac.location
    , vac.date
    , vac.excess_mortality
    , vac.excess_mortality_cumulative
    , vac.excess_mortality_cumulative_absolute
    , vac.excess_mortality_cumulative_per_million
    , vac.cardiovasc_death_rate
 FROM CovidVaccinations vac
 INNER JOIN
    -- find the furthest date that still have excess_mortality for every location and what date it is 
    (SELECT location
        , MAX(date) AS MaxDateTime
     FROM CovidVaccinations
     WHERE excess_mortality_cumulative_per_million is not null
     GROUP BY location) as maxdate
 ON vac.location = maxdate.location
 AND vac.date = maxdate.MaxDateTime
 WHERE vac.continent is not null
--  GROUP BY vac.[location], vac.date, vac.cardiovasc_death_rate
 ORDER BY 2,3
-- can be expended by using the date where most location still have excess_mortality_cumulative_per_million rate



-- Is there a correlation between the prevalence of diabetes in a population and the severity of COVID-19 outbreaks, 
-- as measured by total deaths per million people?
SELECT dea.location
    -- , dea.date
    , SUM(dea.new_cases) as total_cases
    , vac.population
    , SUM(dea.new_deaths)/vac.population*1000000 as total_deaths_per_million
    -- , MAX(dea.total_deaths_per_million)
    , vac.diabetes_prevalence
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.location, vac.population, vac.diabetes_prevalence
 ORDER BY diabetes_prevalence



-- What is the trend of COVID-19 vaccination rates over time, and how does it vary across different regions of the world?
-- new_vaccinations: no. of vax administrated --> vax adminisstrated per person
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccination, RollingPeopleVaccinated)
as 
(
-- Looking at Total Population vs Vaccination by location
SELECT dea.continent, dea.location, dea.date, vac.population, vac.new_vaccinations,
    -- only partition by location so the aggragration (sum) doesnt go over everytime there is a new location
    -- order by location and date so when it adds up it will only add from each row with the same location and correct order
    SUM(vac.new_vaccinations) OVER (Partition by dea.location ORDER by dea.location, 
    dea.date) as RollingVaccineAdministrated
 From CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not NULL
 -- ORDER by 2,3
)
SELECT *, (RollingPeopleVaccinated*1.0/Population)*100 as PercentPopulationVaccinated
FROM PopvsVac



-- Looking at Total Population vs Vaccination by date
DROP TABLE if EXISTS #PercentWorldPopulationVaccinated
 CREATE TABLE #PercentWorldPopulationVaccinated
 (
 Date DATE,
 population NUMERIC,
 new_vaccinations NUMERIC,
 RollingVaccineAdministrated NUMERIC,
 people_fully_vaccinated NUMERIC,
 PercentWorldPopulationVaccinated NUMERIC
 )

Insert into #PercentWorldPopulationVaccinated
SELECT 
    vac.date, 
    SUM(vac.population) as population, 
    SUM(vac.new_vaccinations) as new_vaccinations,
    SUM(SUM(vac.new_vaccinations)) OVER (ORDER by vac.date) 
        as RollingVaccineAdministrated, -- aka total_vaccination, which is total administrated vax
    -- SUM(vac.total_vaccinations) as total_vaccinations,
    SUM(people_fully_vaccinated) as people_fully_vaccinated,
    SUM(people_fully_vaccinated)*1.0/SUM(vac.population)*100 as PercentWorldPopulationVaccinated
 From CovidVaccinations vac
 WHERE vac.continent is not NULL
 GROUP BY vac.date
 ORDER by vac.date

SELECT *, (RollingVaccineAdministrated*1.0/population)*100 as PercentWorldPopulationVaccinatedCal
 FROM #PercentWorldPopulationVaccinated
