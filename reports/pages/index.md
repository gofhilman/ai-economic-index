---
title: AI Economic Index - Automation vs Augmentation Trends
sidebar_position: 1
---

<script>
	const formatPercent = (value, digits = 1) =>
		typeof value === 'number' ? `${(value * 100).toFixed(digits)}%` : 'n/a';

	let viewportWidth = 1280;

	$: page1PieRows = Array.isArray(page1_release_pattern_mix) ? Array.from(page1_release_pattern_mix) : [];

	$: page1InteractionPieConfig = {
		animationDuration: 400,
		tooltip: {
			trigger: 'item',
			formatter: (params) => `${params.name}: ${formatPercent(params.value)}`
		},
		legend: {
			type: viewportWidth < 768 ? 'scroll' : 'plain',
			orient: viewportWidth < 768 ? 'horizontal' : 'vertical',
			right: viewportWidth < 768 ? undefined : 0,
			left: viewportWidth < 768 ? 'center' : undefined,
			top: viewportWidth < 768 ? undefined : 'middle',
			bottom: viewportWidth < 768 ? 0 : undefined,
			itemWidth: viewportWidth < 768 ? 10 : 14,
			itemHeight: viewportWidth < 768 ? 10 : 14,
			textStyle: {
				padding: [0, 0, 0, 4],
				fontSize: viewportWidth < 768 ? 11 : 12
			}
		},
		series: [
			{
				name: 'Interaction Pattern',
				type: 'pie',
				radius: viewportWidth < 768 ? '54%' : '68%',
				center: viewportWidth < 768 ? ['50%', '42%'] : ['38%', '50%'],
				itemStyle: {
					borderColor: '#ffffff',
					borderWidth: 2
				},
				label: {
					formatter: (params) => `${params.name}\n${formatPercent(params.value)}`
				},
				data: page1PieRows.map((row) => ({
					name: row.interaction_label,
					value: row.share
				}))
			}
		]
	};
</script>

<svelte:window bind:innerWidth={viewportWidth} />

```sql page1_automation_trends
select *
from bq.automation_trends
order by report_release_date
```

```sql page1_release_options
select distinct
    report_version,
    report_release_date,
    report_release_label,
    dense_rank() over (order by report_release_date desc) as sort_order
from bq.automation_trends
order by report_release_date desc
```

```sql page1_automation_totals_long
select
    report_release_date,
    report_release_label,
    'Automation' as total_type,
    automation_total_share as share
from bq.automation_trends

union all

select
    report_release_date,
    report_release_label,
    'Augmentation' as total_type,
    augmentation_total_share as share
from bq.automation_trends
```

```sql page1_interaction_filter_options
select 'all' as value, 'Automation and Augmentation' as label, 1 as sort_order
union all
select 'automation' as value, 'Automation Only' as label, 2 as sort_order
union all
select 'augmentation' as value, 'Augmentation Only' as label, 3 as sort_order
```

```sql page1_filtered_patterns
select
    report_release_date,
    report_release_label,
    interaction_label,
    share
from bq.automation_patterns_long
where interaction_filter_group = coalesce(
    nullif(nullif('${inputs.page1_interaction_filter}', 'undefined'), 'null'),
    'all'
)
order by report_release_date, interaction_label
```

```sql page1_release_pattern_mix
select
    interaction_label,
    share
from bq.automation_patterns_long
where report_version = coalesce(
    nullif('${inputs.page1_release.value}', 'undefined'),
    'v5'
)
  and interaction_filter_group = 'all'
order by share desc, interaction_label
```

<div class="space-y-8">

<div>
<LineChart
	data={page1_automation_totals_long}
	x=report_release_date
	y=share
	series=total_type
	title="Automation vs Augmentation Share by Release"
	xFmt="mmmm yyyy"
	yFmt="pct1"
	seriesOrder={['Automation', 'Augmentation']}
	legend=true
	markers=true
	markerSize=8
/>
</div>

<div class="space-y-3">
<ButtonGroup
	data={page1_interaction_filter_options}
	name=page1_interaction_filter
	value=value
	label=label
	order=sort_order
	defaultValue="all"
	display="tabs"
/>

<LineChart
	data={page1_filtered_patterns}
	x=report_release_date
	y=share
	series=interaction_label
	title="Interaction Pattern Shares by Release"
	xFmt="mmmm yyyy"
	yFmt="pct1"
	seriesOrder={['Directive', 'Feedback Loop', 'Validation', 'Task Iteration', 'Learning']}
	legend=true
	markers=true
	markerSize=8
/>
</div>

<div class="space-y-0">
<Dropdown
	data={page1_release_options}
	name=page1_release
	value=report_version
	label=report_release_label
	order=sort_order
	defaultValue="v5"
	title="Report release"
/>

<ECharts
	data={page1_release_pattern_mix}
	config={page1InteractionPieConfig}
	evidenceChartTitle="Interaction Pattern Composition for Selected Release"
	height={viewportWidth < 768 ? '340px' : '420px'}
/>
</div>

<div class="grid gap-6 xl:grid-cols-2">
<Details title="Automation details">
<p>Automation encompasses interaction patterns focused on task completion:</p>
<ul>
	<li>Directive: Users give Claude a task and it completes it with minimal back-and-forth</li>
	<li>Feedback Loops: Users automate tasks and provide feedback to Claude as needed</li>
</ul>
</Details>

<Details title="Augmentation details">
<p>Augmentation focuses on collaborative interaction patterns:</p>
<ul>
	<li>Learning: Users ask Claude for information or explanations about various topics</li>
	<li>Task Iteration: Users iterate on tasks collaboratively with Claude</li>
	<li>Validation: Users ask Claude for feedback on their work</li>
</ul>
</Details>
</div>

</div>
