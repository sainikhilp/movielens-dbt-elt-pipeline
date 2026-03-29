WITH raw_links AS(
    SELECT * FROM movielens.raw.links_raw
)

SELECT 
    movieId as movie_id,
    imdbId as imb_id,
    tmdbId as tmb_id
FROM raw_links;

