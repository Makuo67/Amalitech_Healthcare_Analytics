# REFLECTION ON STAR SCHEMA DESIGN AND PERFORMANCE

## 1. Why Is the Star Schema Faster?

### Fewer Joins

The normalized OLTP schema requires deep join chains:

- encounters → providers → specialties
- billing → encounters
- encounters → encounter_diagnoses → diagnoses
- encounters → encounter_procedures → procedures

In contrast, the star schema reduces this to:

- fact_encounters → small dim tables (1 hop)
- bridge tables (indexed, compact)

This reduces CPU cost, I/O, and join complexity.

### Pre-Computation

The star schema stores metrics that originally required expensive runtime work:

- diagnosis_count
- procedure_count
- total_allowed_amount
- claim_count

Since these metrics are pre-aggregated once during ETL, analytical queries simply sum them—no scanning of billing or diagnosis tables.

### Denormalization Helps Analytics

Denormalized dimensions contain all descriptive attributes in one place:

- dim_provider includes provider, specialty, department info.
- dim_date includes all time attributes (month, quarter, etc.).

Analysts no longer compute:

- DATE_TRUNC
- Derived fields
- Joins to 3NF tables

This improves both simplicity and speed.

---

## 2. Trade-Offs:

### What We Gained

- **Massively faster analytical queries.**
- **Simpler SQL**: Queries become 5–10 lines instead of 20–30.
- **Predictable performance**: Star schemas are column-scan friendly.
- **Better index usage**: Fact table uses integer surrogate keys.
- **Pre-aggregated metrics reduce compute load.**

### What We Lost

- **Data duplication** across dimensions.
- **More complex ETL**, especially:
  - SCD handling
  - late-arriving facts/dimensions
  - pre-aggregation
- **More storage** (surrogate keys + replicated attributes).
- **ETL becomes the bottleneck instead of queries.**

### Was it worth it?

Yes — analytical systems prioritize performance and simplicity for BI workloads.  
ETL is run once per day; queries are run thousands of times per day.

The trade-off favors performance.

---

## 3. Bridge Tables:

### Why Keep Diagnoses/Procedures in Bridge Tables?

Diagnoses and procedures are many-to-many relationships:

- A single encounter can have 10+ diagnoses.
- A single diagnosis is reused by thousands of encounters.

Putting diagnosis/procedure fields directly in fact encounters would:

- Cause massive row explosion (Fact table × diagnoses).
- Create sparse columns.
- Increase fact size by 10–100×.

Bridge tables keep the fact table compact while preserving the M:N structure.

### Trade-Off

**Pros**

- Compact fact table.
- Flexible analytics (drill-down by dx, px).

**Cons**

- Additional joins required.
- ETL more complex.

### Would This Be Different in Production?

No — real hospital schemas (Epic, Cerner) use bridge tables.  
This is the industry-standard Kimball model for clinical data.

---

## 4. Performance Quantification

### Query 1 — Encounter volume by specialty & month

- Original: **0.316 ms**
- Star schema: **0.06 ms**
- Improvement: ** 5× faster**
- Reason: Integer joins + pre-modeled date dimension.

### Query 2 — Diagnosis × Procedure combinations

- Original: **6.374 ms**
- Star schema: **1.0 ms**
- Improvement: **6× faster**
- Reason: Bridge tables reduce row scans, dimensions are small.

### Summary

The star schema is significantly faster due to:

- fewer joins,
- pre-aggregation,
- denormalization,
- surrogate keys,
- optimized indexing,
- reduced table sizes.
