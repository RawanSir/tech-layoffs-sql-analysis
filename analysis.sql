-- ============================================================
-- Global Tech Layoffs Analysis (2020-2025)
-- Author: Rawan Sir
-- Tool: DuckDB via DataLab
-- Description: End-to-end SQL analysis of global tech layoffs
-- covering data cleaning, industry trends, stability analysis,
-- funding stage severity, and geographic distribution.
-- ============================================================


-- ============================================================
-- CLEANING CTE
-- Used as the foundation for all queries in this project.
-- All cleaning decisions are documented in the README.
-- ============================================================

WITH cleaned_data AS (
    SELECT
        Company,
        Industry,
        Country,
        Region,
        Continent,
        Stage,
        Year,
        Date_layoffs,
        Company_Size_before_Layoffs,
        Company_Size_after_Layoffs,
        Laid_Off,
        Money_Raised_in__mil,
        -- Extract month from date
        SUBSTRING(Date_layoffs::TEXT, 6, 2)::INTEGER AS Month,
        -- Extract quarter
        CASE 
            WHEN SUBSTRING(Date_layoffs::TEXT, 6, 2) IN ('01','02','03') THEN 'Q1'
            WHEN SUBSTRING(Date_layoffs::TEXT, 6, 2) IN ('04','05','06') THEN 'Q2'
            WHEN SUBSTRING(Date_layoffs::TEXT, 6, 2) IN ('07','08','09') THEN 'Q3'
            ELSE 'Q4'
        END AS Quarter,
        -- Standardize inconsistent industry names
        -- Fixes typos, case inconsistencies, and duplicate categories
        CASE
            WHEN Industry = 'e-commerce' THEN 'E-Commerce'
            WHEN Industry = 'E-commerce' THEN 'E-Commerce'
            WHEN Industry = 'Game studio' THEN 'Game Studio'
            WHEN Industry = 'Online gaming' THEN 'Online Gaming'
            WHEN Industry = 'Fintech' THEN 'FinTech'
            WHEN Industry = 'Logistic' THEN 'Logistics'
            WHEN Industry = 'Transportion' THEN 'Transportation'
            WHEN Industry = 'Telecommunication' THEN 'Telecommunications'
            WHEN Industry = 'Cloud Technology Company' THEN 'Cloud Technology'
            WHEN Industry = 'Cloud technology' THEN 'Cloud Technology'
            WHEN Industry = 'cloud' THEN 'Cloud Technology'
            WHEN Industry = 'IT Services and IT Consulting' THEN 'IT Services'
            WHEN Industry = 'Financial Services' THEN 'Finance'
            WHEN Industry = 'AI startup' THEN 'AI'
            WHEN Industry = 'AI chip startup' THEN 'AI'
            WHEN Industry = 'AI companion app' THEN 'AI'
            WHEN Industry = 'AI transcription and captioning' THEN 'AI'
            ELSE Industry
        END AS Industry_Clean,
        -- Calculate actual layoff percentage
        -- NULLIF prevents division by zero
        -- ::NUMERIC ensures decimal precision is retained
        ROUND(
            (Company_Size_before_Layoffs - Company_Size_after_Layoffs)::NUMERIC /
            NULLIF(Company_Size_before_Layoffs, 0) * 100
        , 2) AS Calculated_Layoff_Pct
    FROM tech_layoffs_til_2025.csv
    -- Remove rows with missing critical values
    -- These rows cannot contribute meaningful insights
    WHERE Laid_Off IS NOT NULL
      AND Company_Size_before_Layoffs IS NOT NULL
),


-- ============================================================
-- QUERY 1A: Which year had the highest number of layoffs?
-- Shows total layoffs, companies affected, and average layoffs
-- per company by year. Ordered by worst year first.
-- ============================================================

query_1a AS (
    SELECT
        Year,
        SUM(Laid_Off) AS Total_Layoffs,
        COUNT(DISTINCT Company) AS Total_Companies_Affected,
        ROUND(AVG(Laid_Off), 0) AS Avg_Layoffs_Per_Company
    FROM cleaned_data
    GROUP BY Year
    ORDER BY Total_Layoffs DESC
)

SELECT * FROM query_1a;


-- ============================================================
-- QUERY 2A: What drove the layoffs?
-- Top 5 industries by total layoffs for 2022 and 2023
-- independently ranked per year using ROW_NUMBER window function.
-- 'Other' excluded as it provides no actionable industry insight.
-- ============================================================

SELECT Industry_Clean, Year, Total_Layoffs
FROM (
    SELECT
        Industry_Clean,
        Year,
        SUM(Laid_Off) AS Total_Layoffs,
        -- Rank industries independently per year
        -- PARTITION BY Year resets the counter for each year
        ROW_NUMBER() OVER (
            PARTITION BY Year 
            ORDER BY SUM(Laid_Off) DESC
        ) AS Rank
    FROM cleaned_data
    WHERE Year IN (2022, 2023)
      AND Industry_Clean != 'Other'
    GROUP BY Industry_Clean, Year
) top_industries
WHERE Rank <= 5
ORDER BY Year DESC, Total_Layoffs DESC;


-- ============================================================
-- QUERY 3A: Which industries were hit hardest overall?
-- Three dimensions measured:
-- 1. Total_Layoffs: raw volume of job losses
-- 2. Pct_of_Total_Layoffs: industry share of ALL layoffs
--    using window function OVER() to access grand total
-- 3. Avg_Workforce_Pct_Lost: average severity per company
--    distinguishes high volume vs high severity industries
-- ============================================================

SELECT
    Industry_Clean,
    SUM(Laid_Off) AS Total_Layoffs,
    -- This industry's total layoffs as a % of all layoffs
    ROUND(
        SUM(Laid_Off) * 100.0 / SUM(SUM(Laid_Off)) OVER ()
    , 2) AS Pct_of_Total_Layoffs,
    ROUND(AVG(Calculated_Layoff_Pct), 2) AS Avg_Workforce_Pct_Lost
FROM cleaned_data
WHERE Industry_Clean != 'Other'
GROUP BY Industry_Clean
ORDER BY Pct_of_Total_Layoffs DESC
LIMIT 10;


-- ============================================================
-- QUERY 4: Most Stable Industries and Safer Career Paths
-- Uses statistical benchmarking to exclude industries with
-- below average company count, removing outliers that would
-- skew the stability results.
-- Step 1: Calculate industry stats
-- Step 2: Calculate average company count as benchmark
-- Step 3: Filter to industries above benchmark
-- ============================================================

WITH industry_stats AS (
    -- Step 1: Calculate per industry statistics
    SELECT
        Industry_Clean,
        SUM(Laid_Off) AS Total_Layoffs,
        ROUND(AVG(Calculated_Layoff_Pct), 2) AS Avg_Workforce_Pct_Lost,
        COUNT(DISTINCT Company) AS Company_Count
    FROM cleaned_data
    WHERE Industry_Clean != 'Other'
    GROUP BY Industry_Clean
),
-- Step 2: Calculate average company count as statistical benchmark
-- Any industry below this threshold is excluded as an outlier
avg_threshold AS (
    SELECT ROUND(AVG(Company_Count), 0) AS Avg_Company_Count
    FROM industry_stats
)
-- Step 3: Return only industries above the benchmark
-- Ordered ASC to show most stable industries first
SELECT
    i.Industry_Clean,
    i.Total_Layoffs,
    i.Avg_Workforce_Pct_Lost,
    i.Company_Count,
    a.Avg_Company_Count AS Benchmark
FROM industry_stats i
-- CROSS JOIN used because avg_threshold returns a single row
-- attaches the benchmark value to every industry row
CROSS JOIN avg_threshold a
WHERE i.Company_Count > a.Avg_Company_Count
ORDER BY i.Avg_Workforce_Pct_Lost ASC
LIMIT 10;


-- ============================================================
-- QUERY 5: Funding Stage vs Layoff Severity
-- Groups companies by funding stage to understand whether
-- early stage startups were more severely affected than
-- established companies. Ordered ASC to show safest stages first.
-- ============================================================

SELECT
    Stage,
    COUNT(DISTINCT Company) AS Company_Count,
    ROUND(AVG(Calculated_Layoff_Pct), 2) AS Avg_Workforce_Pct_Lost,
    SUM(Laid_Off) AS Total_Layoffs
FROM cleaned_data
WHERE Stage != 'Other'
AND Stage IS NOT NULL
GROUP BY Stage
ORDER BY Avg_Workforce_Pct_Lost ASC;


-- ============================================================
-- QUERY 6: Countries Most Affected
-- Ranks countries by total layoffs and share of global crisis.
-- Note: Countries with few large companies (Sweden, Japan) may
-- appear inflated due to individual corporate decisions rather
-- than nationwide trends.
-- ============================================================

SELECT
    Country,
    COUNT(DISTINCT Company) AS Company_Count,
    SUM(Laid_Off) AS Total_Layoffs,
    ROUND(
        SUM(Laid_Off) * 100.0 / SUM(SUM(Laid_Off)) OVER ()
    , 2) AS Pct_of_Total_Layoffs
FROM cleaned_data
GROUP BY Country
ORDER BY Total_Layoffs DESC
LIMIT 10;
