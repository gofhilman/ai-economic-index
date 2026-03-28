---
title: AI Economic Index - Usage Share Trends
sidebar_position: 2
---

<script>
	onMount(() => {
		const links = document.querySelectorAll('.custom-footer a');
		links.forEach((a) => {
			a.setAttribute('target', '_blank');
			a.setAttribute('rel', 'noopener noreferrer');
		});
	});

	const formatPercentPoints = (value, digits = 1) =>
		typeof value === 'number' ? `${Math.abs(value).toFixed(digits)}%` : 'n/a';

	let viewportWidth = 1280;

	$: page2SelectedSummary =
		Array.isArray(page2_selected_occupation_summary) && page2_selected_occupation_summary.length > 0
			? page2_selected_occupation_summary[0]
			: null;

	$: page2PieRows = Array.isArray(page2_release_occupation_mix)
		? Array.from(page2_release_occupation_mix)
		: [];

	$: page2OccupationPieConfig = {
		animationDuration: 400,
		tooltip: {
			trigger: 'item',
			formatter: (params) =>
				`${params.name}: ${typeof params.value === 'number' ? `${(params.value * 100).toFixed(1)}%` : 'n/a'}`
		},
		legend: {
			type: 'scroll',
			orient: viewportWidth < 768 ? 'horizontal' : 'vertical',
			right: viewportWidth < 768 ? undefined : 0,
			left: viewportWidth < 768 ? 'center' : undefined,
			top: viewportWidth < 768 ? undefined : 'middle',
			bottom: viewportWidth < 768 ? 0 : 16,
			itemWidth: viewportWidth < 768 ? 10 : 14,
			itemHeight: viewportWidth < 768 ? 10 : 14,
			textStyle: {
				padding: [0, 0, 0, 4],
				fontSize: viewportWidth < 768 ? 11 : 12
			}
		},
		series: [
			{
				name: 'Occupation Usage Share',
				type: 'pie',
				radius: viewportWidth < 768 ? '54%' : '68%',
				center: viewportWidth < 768 ? ['50%', '42%'] : ['34%', '50%'],
				itemStyle: {
					borderColor: '#ffffff',
					borderWidth: 2
				},
				label: {
					show: false
				},
				data: page2PieRows.map((row) => ({
					name: row.soc_group_display,
					value: row.share
				}))
			}
		]
	};
</script>

<svelte:window bind:innerWidth={viewportWidth} />

```sql page2_release_options
select distinct
    report_version,
    report_release_date,
    report_release_label,
    dense_rank() over (order by report_release_date desc) as sort_order
from bq.occupational_trends_long
order by report_release_date desc
```

```sql page2_occupation_options
select
    occupations.soc_group_display,
    coalesce(outcomes.work_use_case_pct, -1) as work_use_case_pct
from (
    select distinct soc_group_display
    from bq.occupational_trends_long
) as occupations
left join (
    select
        soc_group_display,
        work_use_case_pct
    from bq.work_soc_outcomes_display
) as outcomes
    using (soc_group_display)
order by work_use_case_pct desc, soc_group_display
```

```sql page2_selected_occupation_trend
select
    report_version,
    report_release_date,
    report_release_label,
    share
from bq.occupational_trends_long
where soc_group_display = coalesce(
    nullif('${inputs.page2_occupation.value}', 'undefined'),
    'Computer and Mathematical'
)
order by report_release_date
```

```sql page2_selected_occupation_summary
select
    soc_group_display,
    latest_vs_v1_diff_pp
from bq.occupational_trends_long
where soc_group_display = coalesce(
    nullif('${inputs.page2_occupation.value}', 'undefined'),
    'Computer and Mathematical'
)
limit 1
```

```sql page2_release_occupation_mix
select
    soc_group_display,
    share
from bq.occupational_trends_long
where report_version = coalesce(
    nullif('${inputs.page2_release.value}', 'undefined'),
    'v5'
)
order by share desc, soc_group_display
```

### Occupation Usage Share Trend by Release

<Dropdown
	data={page2_occupation_options}
	name=page2_occupation
	value=soc_group_display
	label=soc_group_display
	order=work_use_case_pct
	defaultValue="Computer and Mathematical"
	title="Occupation"
/>

<div class="space-y-8 mt-5">

<div>
<AreaChart
	data={page2_selected_occupation_trend}
	x=report_release_date
	y=share
	xFmt="mmmm yyyy"
	yFmt="pct1"
	line=true
	markers=true
	markerSize=8
/>
</div>

<div class="rounded-xl border border-base-300 bg-base-100 p-5 shadow-sm">
	<p class="mb-2 text-sm font-medium text-base-content-muted">Change since first release</p>
	{#if page2SelectedSummary}
		<p class="text-sm text-base-content">
			The usage share for <strong>{page2SelectedSummary.soc_group_display}</strong> is
			{page2SelectedSummary.latest_vs_v1_diff_pp >= 0 ? 'up' : 'down'} by
			{formatPercentPoints(page2SelectedSummary.latest_vs_v1_diff_pp)} from February 2025 to March 2026.
		</p>
	{/if}
</div>
</div>

### Occupation Usage Share for Selected Release

<div class="space-y-0">
<Dropdown
	data={page2_release_options}
	name=page2_release
	value=report_version
	label=report_release_label
	order=sort_order
	defaultValue="v5"
	title="Report release"
/>

<ECharts
	data={page2_release_occupation_mix}
	config={page2OccupationPieConfig}
	height={viewportWidth < 768 ? '360px' : '520px'}
/>
</div>


<div class="mt-5 flex flex-col sm:flex-row justify-between gap-4">
    <a href="/" class="font-medium hover:underline">
        &larr; Prev: Automation vs Augmentation Trends
    </a>
    <a href="/effectiveness-efficiency-in-work" class="font-medium hover:underline sm:text-right">
        Next: Effectiveness and Efficiency in Work &rarr;
    </a>
</div>

<hr style="margin-top: 20px; opacity: 0.3;"/>

<div class="custom-footer">

Created by [Hilman Fikry](https://github.com/gofhilman)  
The raw data is sourced from [The Anthropic Economic Index](https://huggingface.co/datasets/Anthropic/EconomicIndex)

</div>

<style>
  .custom-footer p {
    font-size: 0.8rem;
    line-height: 1.5;
    margin: 0;
  }
</style>
