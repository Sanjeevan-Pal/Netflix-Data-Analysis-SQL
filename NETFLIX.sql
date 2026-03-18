-- NETFLIX DATA ANALYSIS USING SQL --

-- PROJECT	: NETFLIX DATASET ANALYSIS
-- AUTHOR	: SANJEEVAN
-- DATE		: MARCH 2026
-- TOOL		: SQL/MSSQL

-- 1. SETTING UP THE DATABASE AND TABLE FOR DATA ANALYSIS

-- Creating a Database for the Netflix Dataset Data Analysis
CREATE DATABASE NETFLIX;
USE NETFLIX;

-- Creating the structure of the Table
CREATE TABLE netflix (
	show_id	VARCHAR(6),
	type VARCHAR(10),
	title VARCHAR(150),
	director NVARCHAR(MAX),
	cast NVARCHAR(MAX),
	country	VARCHAR(150),
	date_added	VARCHAR(50),
	release_year INT,
	rating	VARCHAR(10),
	duration VARCHAR(15),
	listed_in NVARCHAR(MAX),
	description NVARCHAR(MAX)
	);

-- Inserting the data into the Table
INSERT INTO netflix
SELECT *
FROM dbo.netflix_titles;

-- Viewing the Table
SELECT *
FROM netflix;

-- DATA CLEANING --

-- Checking for the NULL values --
-- PURPOSE: For proper analysis of the Dataset NULL values must be handled accordingly
SELECT 
	COUNT(*) - COUNT(show_id) 		AS [show_id NULL],
	COUNT(*) - COUNT(type) 			AS [type NULL],
	COUNT(*) - COUNT(title) 		AS [title NULL],
	COUNT(*) - COUNT(director) 		AS [director NULL],
	COUNT(*) - COUNT(cast) 			AS [cast NULL],
	COUNT(*) - COUNT(country) 		AS [country NULL],
	COUNT(*) - COUNT(date_added) 	AS [date_added NULL],
	COUNT(*) - COUNT(release_year) 	AS [release_year NULL],
	COUNT(*) - COUNT(rating) 		AS [rating NULL],
	COUNT(*) - COUNT(duration) 		AS [duration NULL],
	COUNT(*) - COUNT(listed_in) 	AS [listed_in NULL],
	COUNT(*) - COUNT(description) 	AS [description NULL]
FROM netflix;
-- FINDING: director(2634), cast(825), country(831) NULLs found

-- Deleting the NULL values where the counting of NULL values are low
DELETE FROM netflix
WHERE (
	date_added IS NULL
	OR 
	rating IS NULL
	OR 
	duration IS NULL
	);

-- Updating the NULL values with 'Unknown", where the NULL values can't be removed or dropped
UPDATE netflix
SET director='Unknown'
WHERE director IS NULL;

UPDATE netflix 
SET CAST = 'Unknown'
WHERE cast IS NULL;

UPDATE netflix 
SET country='Unknown'
WHERE country IS NULL;

-- Checking for the duplicate values
-- PURPOSE: Duplicate values may hamper the data-analysis since it will increase duplicacy 
SELECT *
FROM (
	SELECT *,
	ROW_NUMBER() OVER(
		PARTITION BY show_id
		ORDER BY show_id
		) AS row_num
	FROM netflix
	) AS T1
WHERE row_num>1;
-- FINDING: No duplicates are found

--DATA EXPLORATION--

-- Viewing the table for an overview
SELECT *
FROM netflix;

--Checking for the number of rows in the table
--PURPOSE: Helps in a better understanding of the Table
SELECT COUNT(*) AS [Total Content]
FROM netflix;
-- FINDING: There is a total of 8790 rows after data-cleaning

-- Checking for the different types of shows present on Netflix
-- PURPOSE: Helps us find out the categories present on Netflix
SELECT DISTINCT type AS [Type]
FROM netflix;
-- FINDING: There are 2 types of shows on Netflix

-- Checking for the number of columns 
-- PURPOSE: Helps in a better understanding of the Table
SELECT COUNT(*) AS [Total Columns]
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'netflix';
-- FINDING: There is a total of 12 columns

-- Checking for the number of directors
-- PURPOSE: Helps us to find all the directors
SELECT COUNT(DISTINCT director) AS [Total Directors]
FROM netflix
WHERE director!='Unknown' ;
-- FINDING: There is a total of 4524 directors

-- CHECKING FOR THE NUMBER OF COUNTRIES
-- PURPOSE: Helps us to find the number of countries producing films
SELECT COUNT(DISTINCT TRIM(value)) AS [Total Countries]
FROM netflix
CROSS APPLY STRING_SPLIT(country, ',')
WHERE TRIM(value) != 'Unknown';;
-- FINDING: There are only 123 countries producing films, which is 63% of the total countries

-- DATA ANALYSIS AND BUSINESS ANALYSIS

-- Q1. Count of Movies vs TV Shows
-- PURPOSE: HELPS IN FIGURING OUT THE DISTRIBUTION OF THE SHOWS IN NETFLIX
SELECT 
	type AS [Type], 
	COUNT(*) AS [Total Counts]
FROM netflix
GROUP BY type;
-- FINDING: Movies dominate Netflix with approximately 3x more content than TV Shows

-- Q2. Most Common Rating for Movies and TV Shows
-- PURPOSE: Helps us to find out the most used ratings 
SELECT *
FROM (
	SELECT 
		type AS [Type],
		rating AS [Rating],
		--COUNT(*) AS [Total Count],
		RANK() OVER(
			PARTITION BY type
			ORDER BY COUNT(*) DESC
			) AS [Rank]
	FROM netflix
	GROUP BY 
		type,
		rating
	) AS T1
WHERE Rank=1;
-- FINDING: TV-MA is the most common rating for both Movies and TV Shows on Netflix

-- Q3. Movies Released Per Year
-- PURPOSE: Find how many movies got released each year
SELECT release_year AS [Release Year], COUNT(*) AS [Total Count]
FROM netflix
GROUP BY release_year
ORDER BY release_year;
-- FINDING: The number of movies released per year has been gradually increasing over time

-- Q4. Top 5 Countries with the most content on Netflix
-- PURPOSE: Identify which countries produce the most content
SELECT TOP 5
	TRIM(value) AS [Country],
	COUNT(*) AS [Total Movies]
FROM netflix
CROSS APPLY STRING_SPLIT(country, ',')
GROUP BY TRIM(value)
HAVING TRIM(value) != 'Unknown'
ORDER BY COUNT(*) DESC;
-- FINDING: United States leads by a large margin, followed by India, United Kingdom, Canada, and France

-- Q5. Identify the Longest Movie
-- PURPOSE: Find the movie with the highest duration
SELECT top 1 
	title AS [MOVIE],
	CAST(REPLACE(duration,'min','') AS INT) AS [Duration]
FROM netflix
WHERE type = 'movie'
ORDER BY CAST(REPLACE(duration,'min','') AS INT) DESC;
-- FINDING: 'Black Mirror: Bandersnatch' is the longest movie on Netflix

-- Q6. Content Released Between 2017 and 2021
-- PURPOSE: Find content released in a specific time range
SELECT *
FROM netflix
WHERE release_year BETWEEN 2017 AND 2021
ORDER BY release_year;

-- Q7. All Movies Directed by Rajiv Chilaka
-- PURPOSE: Find all movies directed by a specific director
SELECT 
	title AS [MOVIE NAME]
FROM netflix
CROSS APPLY STRING_SPLIT(director,',')
WHERE 
	TRIM(value) = 'Rajiv Chilaka'
	AND 
	type = 'Movie';
-- FINDING: Rajiv Chilaka has directed 19 movies on Netflix

-- Q8. TV Shows with More Than 5 Seasons
-- PURPOSE: Find long-running series with extensive storylines
SELECT title AS [Series Name]
FROM NETFLIX
WHERE 
	type = 'TV Show'
	AND 
	CAST(TRIM(REPLACE(REPLACE(duration,'Seasons',''),'Season','')) AS INT) > 5
ORDER BY duration DESC;
-- FINDING: 96 TV Shows have more than 5 seasons on Netflix

-- Q9. Content Count by Genre
-- PURPOSE: Figure out which genre has the most content
SELECT
	TRIM(value) AS [Genre],
	COUNT(*) AS [Total Content]
FROM netflix
CROSS APPLY STRING_SPLIT(listed_in,',')
GROUP BY TRIM(value)
ORDER BY COUNT(*) DESC;
-- International Movies is the genre with the highest number of content on Netflix

-- Q10. Top 5 Years — Average Content Released by India
-- PURPOSE: Find years when India added the most content
SELECT TOP 5
	YEAR(CAST(date_added AS DATE)) AS [Year Released],
	COUNT(*) AS [Total Content],
	ROUND(COUNT(*)*100.0/
		(
			(
				SELECT COUNT(*) 
				FROM netflix 
				CROSS APPLY STRING_SPLIT(country,',') 
				WHERE TRIM(value)='India'
			)
		)
	,2
	) AS [Percentage]
FROM netflix
CROSS APPLY STRING_SPLIT(country,',')
WHERE TRIM(value) = 'India'
GROUP BY YEAR(CAST(date_added AS DATE))
ORDER BY COUNT(*) DESC;
-- FINDING: The pre-COVID period was when India produced the most content on Netflix

-- Q11. LIST ALL THE MOVIES THAT ARE LISTED IN DOCUMENTARIES
-- HELPS TO FIGURE OUT THE MOVIES WHICH ARE ORIGINALLY A DOCUMENTRY
SELECT * 
FROM netflix
CROSS APPLY STRING_SPLIT(listed_in,',')
WHERE TRIM(Value) = 'Documentaries';
-- SO, WE CAN SEE THAT THERE ARE TOTAL OF 869 CONTENTS WHICH ARE DOCUMENTARIES

-- Q12. FIND ALL CONTENT DIRECTORS WITHOUT ANY DIRECTOR
-- HELPS US TO FIND ROWS WITH UNKNOWN DIRECTORS
SELECT *
FROM netflix
WHERE director = 'Unknown';

-- Q13. FIND HOW MANY MOVIES ACTOR ' SALMAN KHAN' APPEARED IN LAST 10 YEARS
SELECT 
	TRIM(Value) AS [Actor],
	COUNT(*) AS [Appearances]
FROM netflix
CROSS APPLY STRING_SPLIT(cast,',')
WHERE	
	TRIM(Value) = 'Salman Khan'
	AND 
	release_year BETWEEN 2012 AND 2021
GROUP BY TRIM(Value);
-- WE CAN SEE THAT SALMAN KHAN HAD ONLY APPEARNCE IN 3 MOVIES IN LAST 10 YEARS

-- Q14. FIND THE TOP 10 ACTORS WHO HAVE APPEARED IN THE HIGHEST NUMBER OF MOVIES PRODUCED IN INDIA
-- HELPS TO FIND OUT THE ACTOR WHO IS MOST ACTIVE IN THE MOVIE-INDUSTRY OF INDIA
SELECT TOP 10
	TRIM(a.Value) AS [Actor],
	COUNT(*) AS [Appearances]
FROM netflix
CROSS APPLY STRING_SPLIT(cast,',') a
CROSS APPLY STRING_SPLIT(country,',') b
WHERE	
	TRIM(b.Value) = 'India'
	AND 
	TRIM(a.Value) != 'Unknown'
	AND 
	type = 'Movie'
GROUP BY TRIM(a.Value)
ORDER BY COUNT(*) DESC;
-- HERE WE CAN SEE THAT ANUPAM KHER HAS THE MOST APPEARANCES IN THE INDIAN-MOVIES, FOLLOWED BY SHAH RUKH KHAN AND HENCE THE LIST CONTINUES

-- Q15. CATEGORIZE THE CONTENT BASED ON THE PRESENCE OF THE KEYWORDS 'KILL' AND 'VIOLENCE' IN THE DESCRIPTION FIELD. LABEL CONTENT CONTAINING THESE KEYWORDS AS 'BAD' AND ALL OTHER CONTENT AS 'GOOD'. COUNT HOW MANY ITEMS FALL INTO EACH CATEGORY.
-- HELPS US TO DIFFERENTIATE BETWEEN MOVIES WHICH HAS VIOLENCE AND WHICH DOESN'T
WITH CategoryCTE AS (
	SELECT DISTINCT show_id, title,
	CASE	
		WHEN 
			description LIKE '%kill%' 
			OR 
			description LIKE '%Violence%'
		THEN 'Bad'
		ELSE 'Good'
		END AS [Keyword]
	FROM netflix
	)
SELECT
	Keyword,
	COUNT(*) AS [Total Content]
FROM CategoryCTE
GROUP BY Keyword;
-- HERE WE CAN SEE THAT THERE ARE NEARLY 96.00% GOOD MOVIES AND ONLY 4.00% MOVIES CONTAIN VIOLENCE


-- END OF THE PROJECT --
