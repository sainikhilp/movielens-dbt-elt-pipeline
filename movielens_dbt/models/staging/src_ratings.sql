WITH raw_ratings AS(
    SELECT * FROM movielens.raw.ratings_raw
)

SELECT 
    userId as user_id,
    movieId as movie_id,
    rating,
    TO_TIMESTAMP_LTZ(timestamp) AS rating_timestamp
FROM raw_ratings;

