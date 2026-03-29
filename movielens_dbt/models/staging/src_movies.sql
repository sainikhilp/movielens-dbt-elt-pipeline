WITH raw_movies AS(
    SELECT * FROM movielens.raw.movies_raw
)

SELECT 
    movieId as movie_id,
    title,
    genres
FROM raw_movies;

