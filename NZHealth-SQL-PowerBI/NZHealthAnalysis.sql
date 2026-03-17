CREATE TABLE final_prevalences AS
SELECT 
    population,
    "short.description" AS indicator,
    year,
    "group" AS demographic_group, -- Fixed with quotes
    CAST(total AS REAL) AS percentage,
    CAST("total.low.CI" AS REAL) AS low_ci,
    CAST("total.high.CI" AS REAL) AS high_ci,
    CAST("estimated.number" AS REAL) AS estimated_count
FROM "nz_health_survey";

CREATE TABLE final_rate_ratios AS
SELECT 
    population,
    "short.description" AS indicator,
    year,
    comparison,
    CAST("adjusted.rate.ratio" AS REAL) AS rate_ratio,
    CAST("adjusted.rate.ratio.low.CI" AS REAL) AS low_ci,
    CAST("adjusted.rate.ratio.high.CI" AS REAL) AS high_ci,
    "adjusted.for" AS adjusted_factors
FROM "nz_health_rate_ratios";

CREATE TABLE clean_time_series AS
-- Combine all years into two columns: survey_year and percentage
SELECT population, "group", "short.description" AS indicator, 2011 AS survey_year, "percent.11" AS percentage FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2012, "percent.12" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2013, "percent.13" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2014, "percent.14" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2015, "percent.15" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2016, "percent.16" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2017, "percent.17" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2018, "percent.18" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2019, "percent.19" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2020, "percent.20" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2021, "percent.21" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2022, "percent.22" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2023, "percent.23" FROM "nz_health_time_series" UNION ALL
SELECT population, "group", "short.description", 2024, "percent.24" FROM "nz_health_time_series";

DROP TABLE IF EXISTS final_time_series 
CREATE TABLE final_time_series AS
SELECT 
    population, "group" as demographic_group, indicator, survey_year,
    CASE 
        WHEN percentage = 'S' THEN NULL 
        ELSE CAST(REPLACE(percentage, ' e', '') AS REAL) 
    END AS value
FROM clean_time_series;

UPDATE final_time_series
SET demographic_group = REPLACE(demographic_group, "'", '')
WHERE demographic_group LIKE "'%";


-- This finds population names in Prevalences that are MISSING in Time Series
SELECT DISTINCT population FROM final_prevalences
EXCEPT
SELECT DISTINCT population FROM final_time_series;

-- Check for indicator name mismatches
SELECT DISTINCT indicator FROM final_prevalences
EXCEPT
SELECT DISTINCT indicator FROM final_time_series;




SELECT distinct(indicator) from final_time_series

ALTER TABLE final_time_series
ADD COLUMN indicator_type TEXT;
UPDATE final_time_series
SET indicator_type = CASE

-- prevalence indicators (health outcomes)
WHEN indicator LIKE '%smoker%' THEN 'Prevalence'
WHEN indicator LIKE '%obese%' THEN 'Prevalence'
WHEN indicator LIKE '%diabetes%' THEN 'Prevalence'
WHEN indicator LIKE '%arthritis%' THEN 'Prevalence'
WHEN indicator LIKE '%asthma%' THEN 'Prevalence'
WHEN indicator LIKE '%distress%' THEN 'Prevalence'
WHEN indicator LIKE '%drinking%' THEN 'Prevalence'
WHEN indicator LIKE '%drug%' THEN 'Prevalence'
WHEN indicator LIKE '%eczema%' THEN 'Prevalence'
WHEN indicator LIKE '%ADHD%' THEN 'Prevalence'

-- behaviour indicators
WHEN indicator LIKE '%fast food%' THEN 'Behaviour'
WHEN indicator LIKE '%fruit%' THEN 'Behaviour'
WHEN indicator LIKE '%vegetable%' THEN 'Behaviour'
WHEN indicator LIKE '%physical activity%' THEN 'Behaviour'
WHEN indicator LIKE '%sleeps%' THEN 'Behaviour'

-- healthcare access
WHEN indicator LIKE '%GP%' THEN 'Healthcare Access'
WHEN indicator LIKE '%nurse%' THEN 'Healthcare Access'
WHEN indicator LIKE '%medical centre%' THEN 'Healthcare Access'
WHEN indicator LIKE '%visit%' THEN 'Healthcare Access'
WHEN indicator LIKE '%Unmet%' THEN 'Healthcare Access'

-- mean measurements
WHEN indicator LIKE 'Mean %' THEN 'Measurement'

-- demographics
WHEN indicator LIKE '%sexual identity%' THEN 'Demographic'
WHEN indicator IN ('Bisexual','Gay or lesbian','Heterosexual or straight','Other sexual identity')
THEN 'Demographic'

ELSE 'Other'
END;



-- ANALYSIS
-- Overall health trend. Chart: year vs average health outcome to detect national trends
SELECT 
	survey_year,
	AVG(value) as avg_health
FROM final_time_series
WHERE demographic_group = 'Total'
GROUP BY survey_year
ORDER BY survey_year;

-- Age health differences. Line chart (each line = age group)
-- Insights: young adults vs older adults health trends
SELECT
survey_year,
demographic_group,
value
FROM final_time_series
WHERE demographic_group LIKE '%-%'
AND indicator = 'Good, very good, or excellent self-rated health'
ORDER BY survey_year;


SELECT indicator, value
FROM final_time_series
WHERE demographic_group = 'Total'
AND indicator_type = 'Prevalence'
AND survey_year = 2024
ORDER BY value DESC
LIMIT 10;


-- exploring health indicators, choose a few then look at the trend overtime
SELECT DISTINCT indicator
FROM final_time_series
WHERE population = 'adults'
ORDER BY indicator;

-- Smoking trends overtime
SELECT
survey_year,
value
FROM final_time_series
WHERE indicator = 'Daily smokers'
AND demographic_group = 'Total'
AND population = 'adults'
ORDER BY survey_year;

-- Blood pressure trend
SELECT
survey_year,
value
FROM final_time_series
WHERE indicator = 'High blood pressure (medicated)'
AND demographic_group = 'Total'
AND population = 'adults'
ORDER BY survey_year;

--Distress trend
SELECT
survey_year,
value
FROM final_time_series
WHERE indicator = 'Psychological distress - high'
AND demographic_group = 'Total'
AND population = 'adults'
ORDER BY survey_year;

-- Obsesity trend
SELECT
survey_year,
value
FROM final_time_series
WHERE indicator = 'Obese'
AND demographic_group = 'Total'
AND population = 'adults'
ORDER BY survey_year;

-- GOAL: Health inequality trends in New Zealand (2011–2024)
-- Which Disparities are "Statistically Significant"?
-- Want to find where the Equality Gap is widest.
SELECT 
    indicator,
    comparison,
    rate_ratio,
    low_ci,
    high_ci
FROM final_rate_ratios
WHERE low_ci > 1.0
  AND year = 2024
ORDER BY rate_ratio DESC



SELECT 
    t.indicator,
    t.value AS national_avg,
    r.rate_ratio,
    r.low_ci,
    r.high_ci
FROM final_time_series t
JOIN final_rate_ratios r ON t.indicator = r.indicator AND t.survey_year = r.year
WHERE t.survey_year = 2024 
  AND t.demographic_group = 'Total' 
  AND r.comparison = 'Māori vs non-Māori'
  AND r.low_ci > 1.0 -- Only show where the risk is "statistically significant"
ORDER BY r.rate_ratio DESC
LIMIT 10;


-- Trend Inequality Analysis: "Are health disparities getting worse over time?"
-- Most analyses only show one year. Analysts want to know whether the gap is widening or narrowing.
SELECT DISTINCT demographic_group
FROM final_time_series
WHERE indicator = 'Use food grants - often';

SELECT
survey_year,

MAX(CASE 
WHEN demographic_group = 'Total Māori'
THEN value END) AS maori_rate,

MAX(CASE 
WHEN demographic_group = 'Total European/Other'
THEN value END) AS european_rate,

MAX(CASE 
WHEN demographic_group = 'Total Māori'
THEN value END) /
MAX(CASE 
WHEN demographic_group = 'Total European/Other'
THEN value END) AS inequality_ratio

FROM final_time_series
WHERE indicator = 'Daily smokers'
AND demographic_group IN ('Total Māori','Total European/Other')

GROUP BY survey_year
ORDER BY survey_year;

