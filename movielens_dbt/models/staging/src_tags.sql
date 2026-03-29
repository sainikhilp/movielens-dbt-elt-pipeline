WITH raw_tags AS(
    SELECT * FROM movielens.raw.tags_raw
)

SELECT 
    userId as user_id,
    movieId as movie_id,
    tag,
    TO_TIMESTAMP_LTZ(timestamp) AS tag_timestamp
FROM raw_tags;

