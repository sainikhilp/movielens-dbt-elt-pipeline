# MovieLens DBT ELT Pipeline

![dbt](https://img.shields.io/badge/dbt-1.x-orange?logo=dbt)
![Databricks](https://img.shields.io/badge/platform-Databricks-red?logo=databricks)
![Python](https://img.shields.io/badge/python-%3E%3D3.12-blue?logo=python)
![License](https://img.shields.io/badge/license-MIT-green)

A production-style ELT pipeline built with **dbt** on **Databricks**, transforming the [MovieLens ml-20m](https://grouplens.org/datasets/movielens/) dataset into a clean, analytics-ready dimensional model.

---

## Table of Contents

- [Overview](#overview)
- [Dataset](#dataset)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Data Architecture](#data-architecture)
- [Models](#models)
- [Analyses](#analyses)
- [Getting Started](#getting-started)
- [Running the Pipeline](#running-the-pipeline)
- [Generating Documentation](#generating-documentation)
- [Testing](#testing)

---

## Overview

This project ingests raw MovieLens data from Databricks (`movielens.raw`), applies a layered transformation strategy (staging → dimensions & facts → marts), and exposes clean analytical tables ready for BI tooling or further analysis.

Key design principles:
- **Layered architecture**: raw → staging → dim/fct → mart
- **Dimensional modelling**: star-schema with reusable dimension and fact tables
- **Data quality**: dbt tests (not_null, relationships) on all key columns
- **Snapshot tracking**: SCD Type 2 snapshot on user tags via `dbt-utils` surrogate keys
- **Seed enrichment**: movie release dates loaded via a seed file

---

## Dataset

**Source**: [MovieLens ml-20m](https://grouplens.org/datasets/movielens/) — GroupLens Research, University of Minnesota

| File | Description |
|---|---|
| `movies.csv` | 27,278 movies with titles and genres |
| `ratings.csv` | 20,000,263 ratings (0.5–5 stars) by 138,493 users |
| `tags.csv` | 465,564 free-text tag applications |
| `genome-scores.csv` | Tag relevance scores per movie (0–1) |
| `genome-tags.csv` | 1,128 genome tag labels |
| `links.csv` | IMDB / TMDB cross-reference IDs |

> Data spans January 1995 – March 2015. Users are anonymised; no demographic data is included.

---

## Tech Stack

| Tool | Purpose |
|---|---|
| [dbt](https://www.getdbt.com/) | Transformation framework |
| [dbt-databricks](https://github.com/databricks/dbt-databricks) | Databricks adapter |
| [dbt_utils](https://github.com/dbt-labs/dbt-utils) | Surrogate keys & helper macros |
| Databricks | Cloud data platform / SQL warehouse |
| Python ≥ 3.12 | Runtime environment |

---

## Project Structure

```
MovieLensDBT/
├── data/                         # Raw CSV source files (ml-20m)
├── movielens_dbt/
│   ├── dbt_project.yml           # Project configuration
│   ├── packages.yml              # dbt package dependencies
│   ├── models/
│   │   ├── schema.yml            # Model descriptions & column tests
│   │   ├── staging/              # Thin wrappers over raw source tables
│   │   ├── dim/                  # Dimension tables (materialized as tables)
│   │   ├── fct/                  # Fact tables (materialized as tables)
│   │   └── mart/                 # Business-layer mart models
│   ├── analyses/
│   │   └── movie_analysis.sql    # Ad-hoc analytical queries
│   ├── seeds/
│   │   └── seed_movie_release_dates.csv
│   ├── snapshots/
│   │   └── snap_tags.sql         # SCD Type 2 snapshot on user tags
│   └── tests/                    # Custom data tests
└── pyproject.toml
```

---

## Data Architecture

```
Raw Layer (Databricks)
  movielens.raw.*
        │
        ▼
Staging Layer  (views)
  src_movies · src_ratings · src_tags
  src_genome_scores · src_genome_tags · src_links
        │
        ▼
Dimensional Layer  (tables)
  ┌─────────────────────────────────────────────┐
  │  dim_movies          dim_users              │
  │  dim_genome_tags     dim_movies_with_tags   │
  │  fct_ratings         fct_genome_scores      │
  └─────────────────────────────────────────────┘
        │
        ▼
Mart Layer  (table)
  mart_movie_releases
        │
        ▼
Seeds / Snapshots
  seed_movie_release_dates · snap_tags (SCD2)
```

---

## Models

### Staging (`views`)
Thin, renaming-only wrappers over raw Databricks source tables — no business logic applied here.

| Model | Source Table |
|---|---|
| `src_movies` | `movielens.raw.movies_raw` |
| `src_ratings` | `movielens.raw.ratings_raw` |
| `src_tags` | `movielens.raw.tags_raw` |
| `src_genome_scores` | `movielens.raw.genome_scores_raw` |
| `src_genome_tags` | `movielens.raw.genome_tags_raw` |
| `src_links` | `movielens.raw.links_raw` |

### Dimensions (`tables`)

| Model | Description |
|---|---|
| `dim_movies` | Cleaned movie metadata — standardised titles, genre arrays |
| `dim_users` | Deduplicated user IDs from ratings and tags |
| `dim_genome_tags` | Cleaned genome tag labels |
| `dim_movies_with_tags` | Movies enriched with genome tag scores |

### Facts (`tables`)

| Model | Description |
|---|---|
| `fct_ratings` | 20M+ user–movie ratings with timestamps |
| `fct_genome_scores` | Tag relevance scores (0–1) per movie–tag pair |

### Mart (`table`)

| Model | Description |
|---|---|
| `mart_movie_releases` | Ratings joined with seed release dates; flags known/unknown release info |

### Snapshot

| Snapshot | Strategy | Description |
|---|---|---|
| `snap_tags` | Timestamp (SCD Type 2) | Tracks historical changes to user tag applications using a `dbt_utils` surrogate key |

---

## Analyses

[`analyses/movie_analysis.sql`](movielens_dbt/analyses/movie_analysis.sql) contains ready-to-run analytical queries:

- **Top-rated movies** — movies with ≥ 100 ratings ranked by average score
- **Rating distribution by genre** — average rating and movie count per genre
- **User engagement** — top 20 most active users and their average given rating
- **Release trends over time** — movie count by release year
- **Tag relevance analysis** — top 20 most relevant genome tags across all movies

---

## Getting Started

### Prerequisites

- Python ≥ 3.12
- Access to a Databricks workspace with the `movielens` catalog loaded
- A Databricks personal access token

### 1. Install dependencies

```bash
pip install "dbt-databricks>=1.11.6"
```

### 2. Configure your dbt profile

Create `~/.dbt/profiles.yml` (or set `DBT_PROFILES_DIR` to the project folder):

```yaml
movielens_dbt:
  target: dev
  outputs:
    dev:
      type: databricks
      host: <your-databricks-host>          # e.g. adb-xxxx.azuredatabricks.net
      http_path: <your-sql-warehouse-path>  # e.g. /sql/1.0/warehouses/xxxx
      token: <your-personal-access-token>
      catalog: movielens
      schema: dev
      threads: 4
```

### 3. Install dbt packages

```bash
cd movielens_dbt
dbt deps
```

### 4. Verify connection

```bash
dbt debug
```

---

## Running the Pipeline

```bash
# Load seed data (release dates)
dbt seed

# Run all models
dbt run

# Run a specific layer only
dbt run --select staging
dbt run --select dim
dbt run --select fct

# Run snapshots
dbt snapshot

# Run everything end-to-end
dbt build
```

---

## Generating Documentation

```bash
# Generate the docs site
dbt docs generate

# Serve it locally (opens at http://localhost:8080)
dbt docs serve
```

The generated site includes a full interactive DAG (lineage graph), model descriptions, column-level metadata, and test results — all sourced from [`schema.yml`](movielens_dbt/models/schema.yml).

---

## Testing

```bash
# Run all data quality tests
dbt test

# Run tests for a specific model
dbt test --select dim_movies
```

Tests defined in `schema.yml` include:
- `not_null` — on all primary and foreign key columns
- `relationships` — `fct_ratings.movie_id` → `dim_movies.movie_id`

---

## Acknowledgements

Dataset provided by [GroupLens Research](https://grouplens.org/) at the University of Minnesota.

> F. Maxwell Harper and Joseph A. Konstan. 2015. *The MovieLens Datasets: History and Context.* ACM Transactions on Interactive Intelligent Systems (TiiS) 5, 4, Article 19. DOI: [10.1145/2827872](http://dx.doi.org/10.1145/2827872)
