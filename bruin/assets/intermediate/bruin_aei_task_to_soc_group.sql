/* @bruin

name: output_dataset.bruin_aei_task_to_soc_group
type: bq.sql
materialization:
  type: table

columns:
  - name: task_name
    type: STRING
    description: Lowercased and trimmed O*NET task label.
  - name: soc_group
    type: STRING
    description: SOC major-group title associated with the task.

@bruin */

SELECT * FROM output_dataset.int_aei_task_to_soc_group
