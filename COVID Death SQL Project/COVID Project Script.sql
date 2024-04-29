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

-- teableau 9 sheet 8.2
-- COVID-19 mortality for ageing population in the above median group versus the below median group.
-- COVID-19 mortality for median age and life expectancy at birth in the above median group versus the below median group. 
-- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC7803535/
-- a Mortality is case fatality rate of COVID-19, which is the number of confirmed deaths per the number of confirmed COVID-19 cases.
-- teableau 9 sheet 8.3
-- COVID-19 mortality for ageing population in the above median group versus the below median group.
SELECT dea.continent, dea.location
    , SUM(dea.new_deaths) as total_deaths
    , MAX(vac.population) as population
    , SUM(dea.new_deaths)/NULLIF(SUM(dea.new_cases), 0) as covid_mortality
    , vac.median_age
    , vac.life_expectancy
    , vac.aged_65_older as aging_population
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location, vac.median_age, vac.life_expectancy, vac.aged_65_older
 ORDER BY vac.median_age DESC


-- Tbale and sheet 10
-- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC8879784/
-- Are countries with higher GDP per capita more likely to have a higher percentage of their population vaccinated against COVID-19?
-- Only the most recent date recorded (mostly 240303)
SELECT dea.continent, dea.location, MAX(dea.date) as date, MAX(vac.people_vaccinated_per_hundred) as people_vaccinated_per_hundred, 
    MAX(vac.people_fully_vaccinated_per_hundred) as people_fully_vaccinated_per_hundred, MAX(vac.gdp_per_capita) as gdp_per_capita
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
GROUP BY dea.continent, dea.location
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
-- manually smoothed and group by weekly
-- sheet 11.
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
-- Sheet 12
-- https://www.ncbi.nlm.nih.gov/pmc/articles/PMC9315865/
-- The study aimed to analyze the correlation between regional differences in COVID-19 mortality and different regional care models, 
-- by retrospectively analyzing the association between the COVID-19 mortality and the number of hospital beds
SELECT dea.continent, dea.location
    -- , dea.date
    , MAX(vac.hospital_beds_per_thousand) AS hospital_beds_per_thousand
    , SUM(dea.new_cases)  AS total_cases
    -- Checking Calculation
    -- , MAX(dea.total_cases)
    , SUM(dea.new_deaths) As total_deaths
    -- Checking Calculation
    -- , MAX(dea.total_deaths)
    ,  SUM(dea.new_deaths) / NULLIF(SUM(dea.new_cases), 0) * 100 As covid_mortality
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location
 ORDER BY 3


-- How does the availability of handwashing facilities impact the spread of COVID-19, particularly in densely populated areas?
-- Sheet 13.
SELECT dea.continent, dea.location
    -- , dea.date
    , MAX(vac.handwashing_facilities) AS handwashing_facilities
    , SUM(dea.new_cases)  AS total_cases
    , SUM(dea.new_deaths) As total_deaths
    , SUM(dea.new_deaths) / NULLIF(SUM(dea.new_cases), 0) * 100 As covid_mortality
    , MAX(vac.population_density) AS population_density
 FROM CovidDeaths dea
 JOIN CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
 WHERE dea.continent is not null
 GROUP BY dea.continent, dea.location
 ORDER BY 3

