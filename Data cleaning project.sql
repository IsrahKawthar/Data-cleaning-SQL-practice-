-- Project- Data cleaning 

-- Download your database and put it in your folder
-- Go on SQL and create a new schema (the 4th icon after the new sql sheet)- click apply 
-- it should now be under schemas, double click on it (i named it world layoffs) and right under it it should say tables- right click and table data import wizard


-- make sure to double click on world layoffs before selecting everything so you have right data
SELECT * 
FROM layoffs;
-- layoffs was named soemthing else so under tables under schemas, i pressed the wrench icon and renamed it.


-- We're going to:
-- 1. Remove duplicates 
-- 2. Standardize the data (so sorting out issues with the data with spellings for exmaple)
-- 3. Null values or blank values
-- 4. remove any columns (if they arent relevant)


CREATE TABLE layoffs_staging
LIKE layoffs; 

SELECT * 
FROM layoffs_staging;
-- So now we have the same columns (not the data) and just have to insert data

INSERT layoffs_staging
SELECT *
FROM layoffs; 

SELECT * 
FROM layoffs_staging;
-- now we have the data too
-- We basically made a copy of the dataset because we want a copy of the raw database ust in case we make mistakes or change a lot and need to see it


-- Now to remove duplicates

SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;
-- now theres a column called row num and everthing with the number 1 is good but anything else would be a duplicate
-- the table you can see below doesnt show the whole table as itd be so big and we limit how many rows we can see to 1000

WITH duplicate_cte AS
(
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num > 1;
-- Now we select which numbers are more than 1 as theyre duplicates 
-- just realised the dataset i imported only had 500 rows whereas it was supposed to have 2000 so i changed it from csv to json file (cos this keeps all rows) and deleted wolrd layoffs from schemas, copy and pasted all the code into a new sheet (tho idk if i needed a new sheet) and then imported the dataset again as json and just kept my copy and pasted queries and executed them
-- Tho my point about limit to 1000 rows still stands 


SELECT *
FROM layoffs_staging
WHERE company = 'Casper';
-- just checking an example of the duplicates
-- this shows 3 caspers but one of them has some clumns which are different like date, so that ones isnt a duplicate. a duplicate is only if every columnis identical

-- to remove these duplicates do this:
-- right click layoffs_staging under schemas and copy to clipboard- create statement and paste 

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` text,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` text,
  `row_num` INT 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
-- ^ all these was copied but just add a 2 to layoff_staging so layoff_staging2 on first line. also added the row_num in back ticks and INT. Now execute.

SELECT *
FROM layoffs_staging2; 
-- now we have columns

INSERT INTO layoffs_staging2
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, 'date', 
stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;
-- now we have values

SELECT *
FROM layoffs_staging2
WHERE row_num > 1; 
-- ^ we picked the duplicates

DELETE 
FROM layoffs_staging2
WHERE row_num > 1; 
-- we delete them
-- cant delete cos in safe mode so go on MYSQLWORKBENCH (next to file)- settings- SQL editoer- scroll to bottom, untick safe updates. Might have to reset my SQL first for it to work or just go to query at the top - reconnect to server and then try deleting

SELECT *
FROM layoffs_staging2;



-- Standardizing data 
SELECT company, TRIM(company)
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company) ;

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;
-- distinct stops it from being repeated
-- crypto and crypto currency however are the same thing but distinct sees them as diff so do the followimg


SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';


UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';
-- this puts all crypto currency as crypto

SELECT DISTINCT industry
FROM layoffs_staging2;
-- now crypto is just crypto and theres no other like cryptocurrency


SELECT DISTINCT country
FROM layoffs_staging2
ORDER BY 1;
-- some unhelpful person put united states with a fullstop so now theres two diff united states

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;
-- Trim is done to stop duplicates that have more whitespaces- may look the same to human eye, but not SQL
-- Trim can also be used to trim characters or fullstops etc..
-- TRAILING means stuff trailing at the end of a string like for example SELECT TRIM(TRAILING 'x' FROM 'Helloxxx');


UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging2
ORDER BY 1;

SELECT 'date',
STR_TO_DATE( `date`, '%m/%d/%Y')
FROM layoffs_staging2;
-- STR_TO_DATE turns text date into date format. SQL date looks like 2023-01-27. We must write it as %m lower case m %d lower case d %Y upper case Y for month day year.


UPDATE layoffs_staging2
SET `date` = STR_TO_DATE( `date`, '%m/%d/%Y');
-- sadly this worked for alex but not me cos i have a NULL thats ruining everything

SELECT DISTINCT `date`
FROM layoffs_staging2
WHERE `date` IS NOT NULL
  AND `date` != ''
  AND STR_TO_DATE(`date`, '%m/%d/%Y') IS NULL;
  -- this is to see the null
  
 UPDATE layoffs_staging2
SET `date` = CASE
    WHEN `date` LIKE '%/%/%' THEN STR_TO_DATE(`date`, '%m/%d/%Y')
    ELSE `date`
END;
-- This is a better way to UPDATE as it says if there's a date like %/%/% but not NULLS or emptys change that so it ignores nulls and empty


ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
-- ughhhh doesnt work 

SELECT `date`
FROM layoffs_staging2
WHERE `date` IS NOT NULL
  AND STR_TO_DATE(`date`, '%Y-%m-%d') IS NULL;
  -- this value is the issue 
  
UPDATE layoffs_staging2
SET `date` = NULL
WHERE `date` IN ('N/A', 'TBD', '', 'null', 'NULL');
-- do this to change text NULL to date NULL so sql can actually read it

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
-- now it works yayy 
-- on the left under schemas, object info, it says column: date
-- next time when youre importing data from wizard got to date date instead of text date to avoid this hassle before you click apply


SELECT *
FROM layoffs_staging2;



-- Dealing with null and blank values
SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;

UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
-- change blanks to nulls first!!

SELECT DISTINCT industry
FROM layoffs_staging2
WHERE industry IS NULL
OR industry = '';
-- i didnt get same values as Alex the analyst so i think i may have not imported all the data properly but its okay ill just continue for now, next time check you have all he data in excel first by counting rows there and make sure all is imported to sql properly



SELECT *
FROM layoffs_staging2
WHERE company = 'Airbnb';
-- one of the airbnb says travel and the other is blank, we want the blank one to say travel



SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
	ON t1. company = t2. company
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2. industry IS NOT NULL;
-- we want to join where the company is same but industry has null or blank to ones where it isnt null/blank. (But just went back and changed blanks to nulls) Just called it t1 for table 1 and t2 for table 2.

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2. company
SET t1. industry = t2. industry
WHERE t1.industry IS NULL AND t2.industry IS NOT NULL;
-- now airbnb null says travel too


SELECT *
FROM layoffs_staging2
WHERE company LIKE 'Bally%';
-- Since this null one only had one row, we couldnt join it to another 


SELECT *
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;
-- for some reason this is showing nothing but for Alex's it shows like a whole load of rows that have lots of nulls, we can delete these (tho be careful when deleting data and only be sure you can delete it). maybe its not showing it cos id already deleted it


DELETE
FROM layoffs_staging2
WHERE total_laid_off IS NULL 
AND percentage_laid_off IS NULL;
-- just deleted it


SELECT *
FROM layoffs_staging2;
-- now imma remove a column (we dont need it i think)


ALTER TABLE layoffs_staging2
DROP COLUMN row_num;
-- now row num is gone



