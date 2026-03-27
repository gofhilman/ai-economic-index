---
title: AI Economic Index - Effectiveness and Efficiency in Work
sidebar_position: 3
---

<script>
	const formatPercent = (value, digits = 1) =>
		typeof value === 'number' ? `${(value * 100).toFixed(digits)}%` : 'n/a';

	const formatAutonomy = (value, digits = 2) =>
		typeof value === 'number' ? value.toFixed(digits) : 'n/a';

	let viewportWidth = 1280;

	function getPaddedDomain(rows, lowerKey, upperKey, fallbackMin, fallbackMax) {
		const bounds = rows
			.flatMap((row) => [row?.[lowerKey], row?.[upperKey]])
			.filter((value) => typeof value === 'number' && Number.isFinite(value));

		if (bounds.length === 0) {
			return {
				min: fallbackMin,
				max: fallbackMax
			};
		}

		const rawMin = Math.min(...bounds);
		const rawMax = Math.max(...bounds);
		const padding = Math.max(0.15, (rawMax - rawMin) * 0.08);

		return {
			min: Math.min(fallbackMin, rawMin - padding),
			max: Math.max(fallbackMax, rawMax + padding)
		};
	}

	function buildRangeChartConfig(rows, options) {
		const compactLayout = viewportWidth < 768;
		const labelWidth = compactLayout ? 96 : 180;
		const maxLabelLength = compactLayout ? 18 : 34;
		const formatAxisLabel = (value) =>
			value.length > maxLabelLength ? `${value.slice(0, maxLabelLength - 1)}...` : value;

		return {
			animationDuration: 400,
			grid: {
				left: compactLayout ? 8 : 24,
				right: compactLayout ? 16 : 28,
				top: 24,
				bottom: compactLayout ? 64 : 56,
				containLabel: true
			},
			tooltip: {
				trigger: 'item',
				formatter: (params) => {
					const datum = params.data;
					if (!datum) return '';
					return `
						<strong>${datum.label}</strong><br/>
						${options.tooltipLabel}: ${options.valueFormatter(datum.point)}<br/>
						95% CI: ${options.valueFormatter(datum.lower)} to ${options.valueFormatter(datum.upper)}
					`;
				}
			},
			xAxis: {
				type: 'value',
				min: options.xMin,
				max: options.xMax,
				name: options.xAxisName,
				nameLocation: 'middle',
				nameGap: compactLayout ? 28 : 34,
				nameTextStyle: {
					fontSize: compactLayout ? 11 : 12
				},
				axisLabel: {
					formatter: options.axisFormatter
				},
				splitLine: {
					show: true
				}
			},
			yAxis: {
				type: 'category',
				inverse: true,
				data: rows.map((row) => row.soc_group_display),
				axisLabel: {
					width: labelWidth,
					overflow: 'truncate',
					margin: compactLayout ? 8 : 12,
					formatter: formatAxisLabel
				}
			},
			series: [
				{
					type: 'custom',
					silent: true,
					data: rows.map((row, index) => [
						row[options.lowerKey],
						row[options.upperKey],
						index
					]),
					renderItem: (params, api) => {
						const start = api.coord([api.value(0), api.value(2)]);
						const end = api.coord([api.value(1), api.value(2)]);

						return {
							type: 'line',
							shape: {
								x1: start[0],
								y1: start[1],
								x2: end[0],
								y2: end[1]
							},
							style: {
								stroke: options.lineColor,
								lineWidth: 4,
								opacity: 0.55,
								lineCap: 'round'
							}
						};
					},
					z: 1
				},
				{
					type: 'scatter',
					symbolSize: 10,
					itemStyle: {
						color: options.pointColor
					},
					data: rows.map((row, index) => ({
						value: [row[options.valueKey], index],
						label: row.soc_group_display,
						point: row[options.valueKey],
						lower: row[options.lowerKey],
						upper: row[options.upperKey]
					})),
					z: 2
				}
			]
		};
	}

	$: page3AutonomyRows = Array.isArray(page3_ai_autonomy_rows)
		? Array.from(page3_ai_autonomy_rows)
		: [];

	$: page3TimeSavingsRows = Array.isArray(page3_time_savings_rows)
		? Array.from(page3_time_savings_rows)
		: [];

	$: page3TimeSavingsDomain = getPaddedDomain(
		page3TimeSavingsRows,
		'time_savings_ratio_ci_lower',
		'time_savings_ratio_ci_upper',
		-6,
		1
	);

	$: page3AutonomyConfig = buildRangeChartConfig(page3AutonomyRows, {
		valueKey: 'ai_autonomy_score',
		lowerKey: 'ai_autonomy_score_ci_lower',
		upperKey: 'ai_autonomy_score_ci_upper',
		xMin: 1,
		xMax: 5,
		xAxisName: 'AI autonomy score',
		tooltipLabel: 'AI autonomy score',
		axisFormatter: (value) => value.toFixed(1),
		valueFormatter: (value) => formatAutonomy(value),
		lineColor: '#93c5fd',
		pointColor: '#2563eb'
	});

	$: page3TimeSavingsConfig = buildRangeChartConfig(page3TimeSavingsRows, {
		valueKey: 'time_savings_ratio',
		lowerKey: 'time_savings_ratio_ci_lower',
		upperKey: 'time_savings_ratio_ci_upper',
		xMin: page3TimeSavingsDomain.min,
		xMax: page3TimeSavingsDomain.max,
		xAxisName: 'Time savings ratio',
		tooltipLabel: 'Time savings ratio',
		axisFormatter: (value) => `${Math.round(value * 100)}%`,
		valueFormatter: (value) => formatPercent(value),
		lineColor: '#f0abfc',
		pointColor: '#c2410c'
	});
</script>

<svelte:window bind:innerWidth={viewportWidth} />

```sql page3_occupation_options
select
    soc_group_display,
    work_use_case_pct
from bq.work_soc_outcomes_display
order by work_use_case_pct desc, soc_group_display
```

```sql page3_task_success_data
select
    soc_group_display,
    task_success_rate
from bq.work_soc_outcomes_display
where task_success_rate is not null
order by work_use_case_pct desc, soc_group_display
```

```sql page3_ai_autonomy_rows
select
    soc_group_display,
    ai_autonomy_score,
    ai_autonomy_score_ci_lower,
    ai_autonomy_score_ci_upper
from bq.work_soc_outcomes_display
where ai_autonomy_score is not null
order by work_use_case_pct desc, soc_group_display
```

```sql page3_time_savings_rows
select
    soc_group_display,
    time_savings_ratio,
    time_savings_ratio_ci_lower,
    time_savings_ratio_ci_upper
from bq.work_soc_outcomes_display
where time_savings_ratio is not null
order by work_use_case_pct desc, soc_group_display
```

```sql page3_requires_ai_vs_human_only
with base as (
    select
        soc_group_display,
        work_use_case_pct,
        human_only_ability_requires_ai_rate,
        human_only_rate
    from bq.work_soc_outcomes_display
    where human_only_ability_requires_ai_rate is not null
      and human_only_rate is not null
)

select
    soc_group_display,
    work_use_case_pct,
    'Requires AI' as rate_label,
    human_only_ability_requires_ai_rate as share,
    1 as rate_sort
from base

union all

select
    soc_group_display,
    work_use_case_pct,
    'Human Only' as rate_label,
    human_only_rate as share,
    2 as rate_sort
from base

order by work_use_case_pct desc, soc_group_display, rate_sort
```

```sql page3_selected_top_tasks
select
    task_name as task,
    format('%.1f%%', onet_task_share * 100) as share
from bq.work_soc_top_tasks
where soc_group_display = coalesce(
    nullif('${inputs.page3_occupation.value}', 'undefined'),
    'Computer and Mathematical'
)
order by onet_task_share desc, task
limit 10
```

<div class="space-y-8">

<div>
<BarChart
	data={page3_task_success_data}
	x=soc_group_display
	y=task_success_rate
	swapXY=true
	sort=false
	title="Task Success Rate by Occupation"
	yFmt="pct1"
	chartAreaHeight={Math.max(480, (page3_task_success_data?.length ?? 0) * 28)}
/>
</div>

<div>
<ECharts
	data={page3_ai_autonomy_rows}
	config={page3AutonomyConfig}
	evidenceChartTitle="AI Autonomy Score With 95% Confidence Intervals"
	height={`${Math.max(480, (page3_ai_autonomy_rows?.length ?? 0) * 28)}px`}
/>
</div>

<div>
<ECharts
	data={page3_time_savings_rows}
	config={page3TimeSavingsConfig}
	evidenceChartTitle="Time Savings Ratio With 95% Confidence Intervals"
	height={`${Math.max(480, (page3_time_savings_rows?.length ?? 0) * 28)}px`}
/>
</div>

<div>
<BarChart
	data={page3_requires_ai_vs_human_only}
	x=soc_group_display
	y=share
	series=rate_label
	swapXY=true
	sort=false
	type="stacked100"
	title="Requires AI vs Human-Only by Occupation"
	yFmt="pct0"
	seriesOrder={['Requires AI', 'Human Only']}
	chartAreaHeight={Math.max(480, ((page3_requires_ai_vs_human_only?.length ?? 0) / 2) * 28)}
/>
</div>

<div class="space-y-2">
<Dropdown
	data={page3_occupation_options}
	name=page3_occupation
	value=soc_group_display
	label=soc_group_display
	order=work_use_case_pct
	defaultValue="Computer and Mathematical"
	title="Occupation"
/>

<DataTable data={page3_selected_top_tasks} title="Top 10 Tasks for Selected Occupation" />
</div>

<div class="grid gap-4 xl:grid-cols-2">
<Details title="Task success details">
<p>Did the Assistant complete the task provided by the User successfully? Choose from these options:</p>
<ul>
	<li>Yes: the Assistant completed the task provided by the User successfully</li>
	<li>No: the Assistant did not complete the task provided by the User successfully</li>
</ul>
</Details>

<Details title="AI autonomy score details">
<p>
	Estimate how much autonomy the Assistant had to make decisions in this conversation (a
	discrete number ranging from 1 - 5, where 1 is none and 5 is extreme).
</p>
</Details>

<Details title="Time savings ratio details">
<ul>
	<li>The ratio of human with AI time estimate to human time estimate</li>
	<li>
		Human time estimate: Estimate how many hours a competent professional would need to
		complete the tasks done by the Assistant. Assume they have the necessary domain
		knowledge and skills, all relevant context and background information, and access to
		required tools and resources.
	</li>
	<li>
		Human with AI time estimate: Estimate how many minutes the User spent completing the
		tasks in the prompt with the Assistant. Consider the number and complexity of User
		messages, time reading Assistant responses, no access to AI tools to assist with the
		work, realistic typing and reading speeds, time thinking and formulating questions, time
		reviewing outputs and iterating, and time implementing suggestions or running code
		outside of the conversation when directly relevant.
	</li>
</ul>
</Details>

<Details title="Human ability to complete task alone details">
<p>Could the User have completed this task by themselves? Choose from these options:</p>
<ul>
	<li>
		Yes: the User would have been able to complete the task without the Assistant, even if
		it would have taken more time
	</li>
	<li>
		No: the User would not have been able to complete the task without the Assistant, even
		with more time
	</li>
</ul>
</Details>
</div>

</div>
