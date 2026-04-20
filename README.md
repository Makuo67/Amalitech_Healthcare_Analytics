# Amalitech Healthcare Analytics Lab: OLTP to Star Schema Transformation

## Table of Contents

- [Overview](#overview)
- [Problem Statement](#problem-statement)
- [Solution Architecture](#solution-architecture)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [ETL Process](#etl-process)
- [Key Queries and Performance](#key-queries-and-performance)
- [Design Decisions](#design-decisions)
- [Performance Reflections](#performance-reflections)
- [Future Enhancements](#future-enhancements)
- [License](#license)

## Overview

This project demonstrates a complete data engineering workflow for healthcare analytics. It transforms a normalized transactional (OLTP) database—modeling encounters, patients, providers, diagnoses, procedures, and billing—into an optimized star schema for analytical workloads.

The star schema follows Kimball dimensional modeling principles, enabling efficient querying for insights such as:

- Monthly encounters by specialty and type
- Top diagnosis-procedure combinations
- 30-day readmission rates by specialty
- Revenue trends by specialty and month

The transformation achieves significant performance gains through denormalization, pre-aggregation, surrogate keys, and bridge tables for many-to-many relationships.

**Technologies**: PostgreSQL, SQL (DDL, DML, ETL scripts).

## Problem Statement

The original OLTP schema suffers from:

- Deep join chains (3-4 tables per query)
- Runtime computations (DATE_TRUNC, COUNT(DISTINCT), SUM over billing)
- Many-to-many joins exploding row counts
- Non-index-friendly operations in GROUP BY

Queries on small datasets take 0.3-1.4 ms but scale poorly; at production volumes (millions of encounters), they would timeout.

Detailed analysis in [query_analysis.txt](query_analysis.txt).

## Solution Architecture

```
OLTP Schema (normalized)
  ↓ ETL (dimensions → fact → bridges)
Star Schema
  ├── Dimensions: dim_patient, dim_provider, dim_date, dim_diagnosis, dim_procedure
  ├── Fact: fact_encounter (grain: 1 row per encounter, pre-aggregated metrics)
  └── Bridges: fact_encounter_diagnosis, fact_encounter_procedure
  ↓ Analytical Queries (simple joins, fast aggregation)
BI Dashboards / Reports
```

- **Fact Grain**: One row per encounter (optimal for queries).
- **Pre-aggregates**: diagnosis_count, procedure_count, total_allowed_amount, length_of_stay.
- **SCD Handling**: Type 1 (overwrite) for simplicity.
- **Indexes**: On FKs (date_key, patient_key, etc.) for fast joins.

DDL in [star_schema.sql](star_schema.sql).

## Project Structure

| File                                               | Description                                                          |
| -------------------------------------------------- | -------------------------------------------------------------------- |
| [design_decisions.txt](design_decisions.txt)       | Rationale for fact grain, dimensions, pre-aggregates, bridge tables. |
| [etl_design.txt](etl_design.txt)                   | Narrative ETL logic, SCD, refresh strategy, late-arriving data.      |
| [etl.sql](etl.sql)                                 | Executable ETL scripts (dimensions, fact, bridges).                  |
| [query_analysis.txt](query_analysis.txt)           | Original OLTP queries with EXPLAIN ANALYZE, bottlenecks.             |
| [README.md](README.md)                             | This file.                                                           |
| [reflection.md](reflection.md)                     | Trade-offs, performance quantification, lessons.                     |
| [star_schema_queries.txt](star_schema_queries.txt) | Optimized star schema queries with est. times.                       |
| [star_schema.sql](star_schema.sql)                 | Complete DDL for all tables, constraints, indexes.                   |
| star_schema/                                       | Virtual environment directory (ignore for usage).                    |
| .gitignore                                         | Git ignores.                                                         |

## Prerequisites

- PostgreSQL 13+.
- Access to sample OLTP database (assumed populated with `patients`, `encounters`, `providers`, etc.).
- SQL client (psql, pgAdmin, DBeaver).

No additional dependencies.

## Quick Start

1. **Create database**:

   ```
   CREATE DATABASE healthcare_analytics;
   \c healthcare_analytics;
   ```

2. **(Optional) Setup OLTP sample data** in source schema.

3. **Create star schema**:

   ```
   \i star_schema.sql
   ```

4. **Run ETL**:

   ```
   \i etl.sql
   ```

5. **Run sample queries** (see [star_schema_queries.txt](star_schema_queries.txt)).

Example: Monthly encounters:

```sql
SELECT d.year || '-' || LPAD(d.month::TEXT, 2, '0') AS encounter_month,
       s.specialty_name,
       COUNT(f.encounter_key) AS total_encounters
FROM fact_encounter f
JOIN dim_date d ON f.encounter_date_key = d.date_key
JOIN dim_provider prov ON f.provider_key = prov.provider_key
JOIN dim_specialty s ON prov.specialty_key = s.specialty_key  -- Note: from design
GROUP BY 1, 2
ORDER BY 1, 2;
```

## ETL Process

Detailed in [etl_design.txt](etl_design.txt).

**Sequence**:

1. **Dimensions**: dim_date (generated), dim_patient (w/ age_group), dim_provider (joined), dim_diagnosis/procedure (lookup).
2. **Fact**: fact_encounter – lookup keys, compute pre-aggregates (SUM(allowed_amount), COUNT(diagnoses)).
3. **Bridges**: fact_encounter_diagnosis/procedure – post-fact lookups.

**Refresh**: Daily incremental; Type 1 SCD; handle NULLs as 0/'Unknown'.

Scripts auto-generate dim_date (2024-2025).

## Key Queries and Performance

| Query                           | OLTP Time                  | Star Time (est.) | Improvement          | Bottleneck Fixed                                   |
| ------------------------------- | -------------------------- | ---------------- | -------------------- | -------------------------------------------------- |
| Monthly encounters by specialty | 0.316 ms                   | 0.1 ms           | 3x                   | Date_TRUNC → dim_date; COUNT(DISTINCT) pre-handled |
| Top diagnosis-procedure pairs   | 0.316 ms (scales to 6+ ms) | 1.1 ms           | 6x                   | Many-to-many joins → bridges                       |
| 30-day readmissions             | 1.355 ms                   | 1.3 ms           | 1x (better at scale) | Self-join → surrogate keys                         |
| Revenue by specialty/month      | 0.353 ms                   | 0.1 ms           | 3x                   | SUM(billing) → pre-aggregated                      |

Full OLTP: [query_analysis.txt](query_analysis.txt).  
Optimized: [star_schema_queries.txt](star_schema_queries.txt).

## Design Decisions

From [design_decisions.txt](design_decisions.txt):

- **Grain**: Encounter-level (avoids explosion).
- **Dimensions**: Separate specialty/dept; pre-bucketed age_group.
- **Pre-aggregates**: Shift compute to ETL.
- **Bridges**: Essential for M:N (diagnoses/procedures).

## Performance Reflections

From [reflection.md](reflection.md):

- **Gains**: Fewer joins, integer FKs, no runtime aggs → 3-6x faster.
- **Trade-offs**: ETL complexity, storage duplication → Worth it for analytics.
- **Industry Standard**: Matches Epic/Cerner patterns.

## Future Enhancements

- Partition fact by date_key.
- Materialized views for readmissions.
- Incremental ETL w/ MERGE.
- Add fact_claim for billing grain.
- Python Airflow orchestration.

## License

MIT License. See LICENSE (or add one).

---

_Project for Amalitech Healthcare Analytics Lab. Author: Okeke Makuochukwu. Last updated: 20/04/2026._
