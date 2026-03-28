/* @bruin

name: output_dataset.bruin_aei_task_changes
type: bq.sql
materialization:
  type: table

columns:
  - name: task_name
    type: STRING
    description: Normalized O*NET task label.
  - name: soc_group
    type: STRING
    description: SOC major-group title for the task when available.
  - name: v1_pct
    type: FLOAT64
    description: Task share in the 2025-02-10 report.
  - name: v2_pct
    type: FLOAT64
    description: Task share in the 2025-03-27 report.
  - name: v3_pct
    type: FLOAT64
    description: Task share in the 2025-09-15 report.
  - name: v4_pct
    type: FLOAT64
    description: Task share in the 2026-01-15 report.
  - name: v5_pct
    type: FLOAT64
    description: Task share in the 2026-03-24 report.
  - name: latest_vs_v1_diff_pp
    type: FLOAT64
    description: Percentage-point change between v5 and v1 task share.
  - name: latest_vs_v1_rel_change_pct
    type: FLOAT64
    description: Relative percentage change from v1 to v5 when a v1 baseline exists.
  - name: is_new_since_v1
    type: BOOL
    description: Whether the task had zero share in v1.
  - name: change_label
    type: STRING
    description: Presentation-oriented label for the v5 versus v1 change.

@bruin */

SELECT * FROM output_dataset.mart_aei_task_changes
