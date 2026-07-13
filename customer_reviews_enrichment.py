import pandas as pd
import pyodbc
import nltk
from nltk.sentiment.vader import SentimentIntensityAnalyzer

# Download the VADER lexicon for sentiment analysis if not already present.
nltk.download('vader_lexicon')

def fetch_data_from_sql():
    
    conn_str = (
        "Driver={ODBC Driver 17 for SQL Server};"  
        "Server=LAPTOP-QEVPDR9Q\SQLEXPRESS ;"
        "Database=PortfolioProject_MarketingAnalytics;"  
        "Trusted_Connection=yes;"  
    )
    
    conn = pyodbc.connect(conn_str)
    
    query = "SELECT ReviewID, CustomerID, ProductID, ReviewDate, Rating, REPLACE(ReviewText, '  ', ' ') AS ReviewText FROM dbo.customer_reviews;"
    df = pd.read_sql(query, conn)
    
    conn.close()
    return df

customer_reviews_df = fetch_data_from_sql()

sia = SentimentIntensityAnalyzer()

# Define a function to calculate sentiment scores using VADER
def calculate_sentiment(review):
    sentiment = sia.polarity_scores(review)
    return sentiment['compound']


def categorize_sentiment(score, rating):
    
    if score > 0.05:  # Positive sentiment score
        if rating >= 4:
            return 'Positive'  # High rating and positive sentiment
        elif rating == 3:
            return 'Mixed Positive'  # Neutral rating but positive sentiment
        else:
            return 'Mixed Negative'  # Low rating but positive sentiment
    elif score < -0.05:  # Negative sentiment score
        if rating <= 2:
            return 'Negative'  # Low rating and negative sentiment
        elif rating == 3:
            return 'Mixed Negative'  # Neutral rating but negative sentiment
        else:
            return 'Mixed Positive'  # High rating but negative sentiment
    else:  # Neutral sentiment score
        if rating >= 4:
            return 'Positive'  # High rating with neutral sentiment
        elif rating <= 2:
            return 'Negative'  # Low rating with neutral sentiment
        else:
            return 'Neutral'  # Neutral rating and neutral sentiment


def sentiment_bucket(score):
    if score >= 0.5:
        return '0.5 to 1.0'  # Strongly positive sentiment
    elif 0.0 <= score < 0.5:
        return '0.0 to 0.49'  # Mildly positive sentiment
    elif -0.5 <= score < 0.0:
        return '-0.49 to 0.0'  # Mildly negative sentiment
    else:
        return '-1.0 to -0.5'  # Strongly negative sentiment


customer_reviews_df['SentimentScore'] = customer_reviews_df['ReviewText'].apply(calculate_sentiment)

customer_reviews_df['SentimentCategory'] = customer_reviews_df.apply(
    lambda row: categorize_sentiment(row['SentimentScore'], row['Rating']), axis=1)

customer_reviews_df['SentimentBucket'] = customer_reviews_df['SentimentScore'].apply(sentiment_bucket)

print(customer_reviews_df.head())

# Save the DataFrame to a new CSV file
customer_reviews_df.to_csv('customer_reviews_with_sentiment.csv', index=False)

