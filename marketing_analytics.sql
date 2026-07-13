-- SQL statement to join dim_customers with dim_geography to enrich customer data with geographic information
SELECT
    c.CustomerID,
    c.CustomerName,
    c.Email,
    c.Gender, 
    c.Age,  
    g.Country,  
    g.City 
FROM 
    dbo.customers as c
LEFT JOIN 
    dbo.geography as g
ON
    c.GeographyID = g.GeographyID;



-- SQL Query to categorize products based on their price
SELECT 
   ProductID,
   ProductName,
   Price,
   CASE
       WHEN Price< 50 THEN 'Low'
       WHEN Price BETWEEN 50 and 200 THEN 'Medium'
       Else 'High'
    END as PriceCategory
FROM
   dbo.products;



-- Query to clean whitespace issues in the ReviewText column
SELECT 
   ReviewID,
   CustomerID,
   ProductID,
   ReviewDate,
   Rating,
   REPLACE(ReviewText,'  ',' ') as ReviewText
FROM
   dbo.customer_reviews;



-- Query to clean and normalize the engagement_data table
SELECT
   EngagementID,
   ContentID,
   CampaignID,
   ProductID,
   UPPER( REPLACE(ContentType,'Socialmedia', 'Social Media') ) as ContentType,
   LEFT(ViewsClicksCombined, CHARINDEX('-', ViewsClicksCombined) - 1) AS Views,
   RIGHT(ViewsClicksCombined,LEN(ViewsClicksCombined) - CHARINDEX('-', ViewsClicksCombined)) AS Clicks,
   Likes,
   FORMAT( CONVERT( DATE, EngagementDate),'dd.mm.yyyy') as EngagementDate
FROM
   dbo.engagement_data
WHERE
   ContentType != 'Newsletter';



-- Common Table Expression (CTE) to identify and tag duplicate records

WITH DuplicateRecords AS (
   SELECT 
      JourneyID,
      CustomerID,
      ProductID,
      VisitDate,
      Stage,
      Action,
      Duration,
      ROW_NUMBER() OVER(
            PARTITION BY CustomerID, ProductID, VisitDate, Stage, Action  
            ORDER BY JourneyID  
        ) AS row_num 
    FROM 
      dbo.customer_journey 
)

-- Select all records from the CTE where row_num > 1, which indicates duplicate entries 
SELECT *
FROM DuplicateRecords
ORDER BY JourneyID
SELECT 
    JourneyID,  
    CustomerID,  
    ProductID,  
    VisitDate,  
    Stage,  
    Action, 
    COALESCE(Duration, avg_duration) AS Duration  
FROM 
    (
        SELECT 
            JourneyID, 
            CustomerID,  
            ProductID,  
            VisitDate,  
            UPPER(Stage) AS Stage,  
            Action,  
            Duration, 
            AVG(Duration) OVER (PARTITION BY VisitDate) AS avg_duration,  
            ROW_NUMBER() OVER (
                PARTITION BY CustomerID, ProductID, VisitDate, UPPER(Stage), Action  
                ORDER BY JourneyID  
            ) AS row_num  
        FROM 
            dbo.customer_journey  
    ) AS subquery  
WHERE 
    row_num = 1;  

