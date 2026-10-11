-- =====================================================================
-- Layoffs Exploratory Data Analysis (MySQL)
-- Source table: layoffs_staging2 (output of the data cleaning project)
-- =====================================================================

USE world_layoffs;

-- Preview the cleaned data
SELECT *
FROM layoffs_staging2;


-- ---------------------------------------------------------------------
-- 1. Size of the largest and smallest layoff events
-- ---------------------------------------------------------------------
SELECT
    MAX(total_laid_off) AS max_laid_off,
    MIN(total_laid_off) AS min_laid_off
FROM layoffs_staging2;


-- ---------------------------------------------------------------------
-- 2. Time span covered by the data
-- ---------------------------------------------------------------------
SELECT
    MIN(`date`) AS first_date,
    MAX(`date`) AS last_date
FROM layoffs_staging2;


-- ---------------------------------------------------------------------
-- 3. Total layoffs by company
-- ---------------------------------------------------------------------
SELECT
    company,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;


-- ---------------------------------------------------------------------
-- 4. Total layoffs by industry
-- ---------------------------------------------------------------------
SELECT
    industry,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY industry
ORDER BY total_laid_off DESC;


-- ---------------------------------------------------------------------
-- 5. Total layoffs by country
-- ---------------------------------------------------------------------
SELECT
    country,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY country
ORDER BY total_laid_off DESC;


-- ---------------------------------------------------------------------
-- 6. Total layoffs by year
-- ---------------------------------------------------------------------
SELECT
    YEAR(`date`) AS layoff_year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE YEAR(`date`) IS NOT NULL
GROUP BY YEAR(`date`)
ORDER BY layoff_year DESC;


-- ---------------------------------------------------------------------
-- 7. Monthly layoffs and rolling (cumulative) total
-- ---------------------------------------------------------------------

-- 7a. Layoffs per month
SELECT
    SUBSTRING(`date`, 1, 7) AS `MONTH`,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
GROUP BY `MONTH`
ORDER BY `MONTH` ASC;

-- 7b. Same result as a CTE, with a running total added via a window function
WITH Rolling_total AS
(
    SELECT
        SUBSTRING(`date`, 1, 7) AS `MONTH`,
        SUM(total_laid_off) AS total_off
    FROM layoffs_staging2
    WHERE SUBSTRING(`date`, 1, 7) IS NOT NULL
    GROUP BY `MONTH`
    ORDER BY `MONTH` ASC
)
SELECT
    `MONTH`,
    total_off,
    SUM(total_off) OVER (ORDER BY `MONTH`) AS rolling_total
FROM Rolling_total;


-- ---------------------------------------------------------------------
-- 8. Layoffs per company per year
-- ---------------------------------------------------------------------
SELECT
    company,
    YEAR(`date`) AS layoff_year,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company, YEAR(`date`)
ORDER BY total_laid_off DESC;


-- ---------------------------------------------------------------------
-- 9. Top 5 companies by layoffs in each year (CTEs + DENSE_RANK)
-- ---------------------------------------------------------------------
WITH Company_year (company, years, total_laid_off) AS
(
    SELECT
        company,
        YEAR(`date`),
        SUM(total_laid_off)
    FROM layoffs_staging2
    GROUP BY company, YEAR(`date`)
),
Company_Year_Rank AS
(
    SELECT
        *,
        DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
    FROM Company_year
    WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <= 5;
