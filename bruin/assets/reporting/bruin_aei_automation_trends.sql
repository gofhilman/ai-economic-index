/* @bruin

name: output_dataset.bruin_aei_automation_trends
type: bq.sql
materialization:
  type: table

columns:
  - name: report_version
    type: STRING
    description: AEI report version label from v1 through v5.
  - name: report_release_date
    type: DATE
    description: Public release date for the AEI report.
  - name: automation_total_pct
    type: FLOAT64
    description: Sum of directive and feedback_loop shares.
  - name: augmentation_total_pct
    type: FLOAT64
    description: Sum of validation, task_iteration, and learning shares.
  - name: directive_pct
    type: FLOAT64
    description: Directive collaboration share.
  - name: feedback_loop_pct
    type: FLOAT64
    description: Feedback-loop collaboration share.
  - name: validation_pct
    type: FLOAT64
    description: Validation collaboration share.
  - name: task_iteration_pct
    type: FLOAT64
    description: Task-iteration collaboration share.
  - name: learning_pct
    type: FLOAT64
    description: Learning collaboration share.

@bruin */

SELECT * FROM output_dataset.mart_aei_automation_trends
