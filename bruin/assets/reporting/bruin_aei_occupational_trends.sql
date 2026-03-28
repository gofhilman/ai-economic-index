/* @bruin

name: output_dataset.bruin_aei_occupational_trends
type: bq.sql
materialization:
  type: table

columns:
  - name: soc_group
    type: STRING
    description: SOC major-group title.
  - name: v1_pct
    type: FLOAT64
    description: Occupational share for the 2025-02-10 report.
  - name: v2_pct
    type: FLOAT64
    description: Occupational share for the 2025-03-27 report.
  - name: v3_pct
    type: FLOAT64
    description: Occupational share for the 2025-09-15 report.
  - name: v4_pct
    type: FLOAT64
    description: Occupational share for the 2026-01-15 report.
  - name: v5_pct
    type: FLOAT64
    description: Occupational share for the 2026-03-24 report.
  - name: latest_vs_v1_diff_pp
    type: FLOAT64
    description: Percentage-point change between v5 and v1 occupational share.

@bruin */

SELECT * FROM output_dataset.mart_aei_occupational_trends
