WITH raw_genome_tags AS(
    SELECT * FROM movielens.raw.genome_tags_raw
)

SELECT 
    tagId as tag_id,
    tag
FROM raw_genome_tags;

