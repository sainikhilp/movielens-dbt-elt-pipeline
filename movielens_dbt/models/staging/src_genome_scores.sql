WITH raw_genome_scores AS(
    SELECT * FROM movielens.raw.genome_scores_raw
)

SELECT 
    movieId as movie_id,
    tagId as tag_id,
    relevance
FROM raw_genome_scores;

