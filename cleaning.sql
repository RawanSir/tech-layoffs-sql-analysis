-- CTE: Clean and transform the data
WITH cleaned_data AS (
    SELECT
        -- Company identifiers
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
        -- Standardize Industry names
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
        ROUND(
            (Company_Size_before_Layoffs - Company_Size_after_Layoffs)::NUMERIC /
            NULLIF(Company_Size_before_Layoffs, 0) * 100
        , 2) AS Calculated_Layoff_Pct
    FROM tech_layoffs_til_2025.csv
    -- Remove rows with missing critical values
    WHERE Laid_Off IS NOT NULL
      AND Company_Size_before_Layoffs IS NOT NULL
)
