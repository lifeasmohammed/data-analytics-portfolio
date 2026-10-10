# Data Cleaning: World Layoffs Dataset (MySQL)

## Overview

This project cleans a raw dataset of global tech layoffs so it's ready for exploratory analysis. The source data — pulled from Kaggle — had duplicate records, inconsistent text formatting, dates stored as text, and a mix of NULL and blank values across key columns.

The goal wasn't just to "fix" the data, but to do it in a way that's safe and repeatable: work on a copy, verify each change before committing to it, and leave a clear trail of what was done and why.

**Tools:** MySQL / MySQL Workbench
**Dataset:** [World Layoffs (Kaggle)](https://www.kaggle.com/datasets/swaptr/layoffs-2022)

---

## Process

1. [Staging the data](#1-staging-the-data)
2. [Removing duplicates](#2-removing-duplicates)
3. [Standardizing the data](#3-standardizing-the-data)
4. [Handling null and blank values](#4-handling-null-and-blank-values)
5. [Removing unneeded columns](#5-removing-unneeded-columns)

---

## 1. Staging the Data

Never clean the raw table directly — if something goes wrong, there's no way back. The first move is always to create a working copy.

```sql
CREATE TABLE layoffs_staging
LIKE layoffs;

INSERT layoffs_staging
SELECT * 
FROM layoffs;
```

`LIKE` copies the table structure (columns, data types) without the data, and `INSERT ... SELECT` populates it. `layoffs_staging` is now a safe sandbox — the original `layoffs` table stays untouched as a fallback.

---

## 2. Removing Duplicates

MySQL doesn't have a built-in "remove duplicate rows" command, so this takes a bit of engineering using a window function.

**Step 1 — Flag duplicates with `ROW_NUMBER()`**

```sql
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, `date`, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;
```

`PARTITION BY` groups rows that match across every meaningful column. Any row that's a true duplicate of another will get `row_num = 2` (or higher) instead of `1`.

**Step 2 — Confirm with a CTE**

```sql
WITH duplicate_cte AS (
    SELECT *,
        ROW_NUMBER() OVER(
            PARTITION BY company, location, industry, total_laid_off, 
                         percentage_laid_off, stage, country, `date`, funds_raised_millions
        ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
```

This surfaces the actual duplicate rows so they can be spot-checked before anything gets deleted — e.g. confirming that a company like Casper really does have identical duplicate entries, not just similar ones.

**Step 3 — Delete duplicates**

CTEs in MySQL aren't directly updatable/deletable, so the `row_num` gets materialized into a second staging table instead:

```sql
CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT layoffs_staging2
SELECT *,
    ROW_NUMBER() OVER(
        PARTITION BY company, location, industry, total_laid_off, 
                     percentage_laid_off, stage, country, `date`, funds_raised_millions
    ) AS row_num
FROM layoffs_staging;

DELETE
FROM layoffs_staging2
WHERE row_num > 1;
```

From here, all further cleaning happens on `layoffs_staging2`.

---

## 3. Standardizing the Data

With duplicates gone, the next issue is inconsistency — the same real-world value recorded in different ways.

**Trim stray whitespace:**

```sql
UPDATE layoffs_staging2
SET company = TRIM(company);
```

**Collapse inconsistent category names.** The `industry` column had multiple variants of "Crypto" (`Crypto`, `Crypto Currency`, `CryptoCurrency`) that all describe the same industry:

```sql
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
```

**Clean up trailing punctuation.** `country` had entries like `United States` and `United States.` being treated as distinct values:

```sql
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';
```

**Fix data types.** `date` was stored as text (`3/31/2020`), which blocks any real date math or sorting. `STR_TO_DATE()` converts it first so the result can be checked before committing to the schema change:

```sql
SELECT `date`, 
    STR_TO_DATE(`date`, '%m/%d/%Y') AS new_date
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

---

## 4. Handling Null and Blank Values

Nulls and blank strings aren't the same thing in SQL, and this dataset had both — so each needed its own check:

```sql
SELECT *
FROM layoffs_staging2
WHERE industry IS NULL
   OR industry = '';
```

Rather than guessing or deleting these rows, the fix was to recover the real value: if a company has multiple rows in the dataset, there's a good chance another row for the same company already has `industry` filled in. 

**Step 1 — Standardize blanks to NULL** (so a single, consistent check works going forward):

```sql
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
```

**Step 2 — Self-join the table to itself** on `company`, so each blank row can be matched against a non-blank row for the same company:

```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
    ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;
```

This recovered several rows that would otherwise have been lost — for example, Airbnb's `industry` was missing in one row but present in another, and the self-join filled it in correctly instead of discarding the data.

**Step 3 — Remove what's left.** Rows with no `total_laid_off` *and* no `percentage_laid_off` carry no usable signal for the kind of analysis this dataset is meant for, so they were dropped:

```sql
DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;
```

---

## 5. Removing Unneeded Columns

`row_num` was only ever a working column for the deduplication step — it has no place in the final dataset:

```sql
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
```

---

## Result

`layoffs_staging2` is now deduplicated, consistently formatted, free of blank/placeholder values where they could be recovered, and typed correctly — ready for exploratory analysis (trends by industry, country, company stage, etc.).

The original `layoffs` and intermediate `layoffs_staging` tables were left untouched throughout, so every step here is reproducible from scratch.
