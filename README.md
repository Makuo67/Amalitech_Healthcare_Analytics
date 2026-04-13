# Healthcare Analytics Lab – OLTP to Star Schema

## Overview

This project simulates a real-world data engineering workflow in the healthcare domain. The goal was to transform a normalized transactional (OLTP) database into an optimized star schema for analytics, enabling fast and efficient queries for healthcare insights.

The OLTP system modeled encounters, patients, providers, diagnoses, procedures, and billing, but analytics queries on this schema were slow due to multiple joins and aggregations.

This project demonstrates:

Star schema design based on Kimball methodology
ETL process to populate dimensions, fact tables, and bridge tables
Query optimization and performance improvement
Analytical insights (revenue, readmissions, diagnosis-procedure relationships)

Project Structure
File Description
query_analysis.txt Analysis of 4 original queries on normalized schema, including execution time, JOIN chain, and bottlenecks.
design_decisions.txt Documented design decisions for fact table grain, dimensions, pre-aggregated metrics, and bridge tables.
star_schema.sql Complete DDL for the star schema, including dimension tables, fact table, bridge tables, keys, and indexes.
star_schema_queries.txt Optimized versions of the 4 analytical queries on the star schema, with estimated execution times and improvement factors.
etl_design.txt ETL pseudocode/narrative describing how dimensions, fact, and bridge tables are populated, including refresh strategy and handling late-arriving data.
reflection.md Analysis and reflection on performance improvements, trade-offs, denormalization benefits, and bridge table design.
