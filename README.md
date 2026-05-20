# Global Tech Layoffs Analysis (2020–2025)

## Project Overview
This project analyses 2,412 global layoff events recorded across multiple 
industries, countries, and company funding stages between 2020 and 2025. 
The goal is to uncover trends, identify the hardest hit sectors, and 
determine which industries and company stages offer the most stability 
for career decision making.

## Dataset
Two datasets were used in this analysis:

**tech_layoffs_til_2025.csv** : 2,412 layoff events including company name, 
industry, country, funding stage, employees laid off, and company size 
before and after layoffs.

**layoffs_location_with_coordinates.csv** : 243 unique headquarters 
locations with geographic coordinates.

Source: Kaggle — Tech Layoffs 2020 to 2025

## Tools Used
- SQL (DuckDB via DataLab)
- Python (pandas) for initial data exploration

## Analysis Questions
1. Which year had the highest number of layoffs?
2. What drove the layoffs — which industries were hit hardest?
3. Which industries were hit hardest overall by volume and severity?
4. Which industries show the most stability and safer career paths?
5. How does company funding stage relate to layoff severity?
6. Which countries were most affected?

## Key Findings
- 2023 recorded the highest number of documented layoffs at 176,946 
across 432 companies, driven by post COVID over-hiring corrections 
and rising interest rates
- Consumer and Retail were the most consistently affected industries 
across both 2022 and 2023
- Seed stage startups lost an average of 55.89% of their workforce 
when laying off, compared to only 15.17% for Post-IPO companies
- The USA accounted for 73.12% of all recorded layoffs, reflecting 
the concentration of large tech companies headquartered there
- Sales, Security, and Marketing emerged as the most stable industries 
based on lowest average workforce percentage lost
- 2025 shows the highest average layoffs per company at 901, consistent 
with structural workforce changes driven by AI and automation

## Data Cleaning Summary
- 656 rows removed due to missing critical values
- 1,756 clean rows retained representing 73% of the original dataset
- 13 industry name inconsistencies standardized
- Calculated layoff percentage column derived and validated
- Month and Quarter columns added for time series analysis

## Repository Structure
- README.md — project overview and findings
- cleaning.sql — data cleaning CTE
- analysis.sql — all analysis queries with findings
