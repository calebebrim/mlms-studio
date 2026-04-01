<script setup lang="ts">
import * as d3 from 'd3'
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'
import type { JobHistoryPoint } from '../../stores/analyticsShell'

const props = defineProps<{
  points: JobHistoryPoint[]
}>()

const container = ref<HTMLDivElement | null>(null)

function render() {
  const el = container.value
  if (!el) return

  const width = el.clientWidth || 400
  const height = 200
  const margin = { top: 12, right: 12, bottom: 28, left: 44 }

  d3.select(el).selectAll('svg').remove()

  const svg = d3
    .select(el)
    .append('svg')
    .attr('width', width)
    .attr('height', height)
    .attr('role', 'img')
    .attr('aria-label', 'Linha do tempo de jobs')

  const innerW = width - margin.left - margin.right
  const innerH = height - margin.top - margin.bottom

  const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`)

  const data = props.points.map((p, i) => ({
    x: p.at,
    y: i + 1,
    ok: p.ok,
    stage: p.stage,
  }))

  if (data.length === 0) {
    g.append('text')
      .attr('x', innerW / 2)
      .attr('y', innerH / 2)
      .attr('text-anchor', 'middle')
      .attr('fill', 'currentColor')
      .attr('opacity', 0.5)
      .text('Nenhum job ainda — execute o stub')
    return
  }

  const times = data.map((d) => new Date(d.x))
  const [t0, t1] = d3.extent(times) as [Date, Date]
  const domain: [Date, Date] =
    t0.getTime() === t1.getTime()
      ? [new Date(t0.getTime() - 60_000), new Date(t1.getTime() + 60_000)]
      : [t0, t1]

  const x = d3.scaleTime().domain(domain).range([0, innerW])

  const y = d3.scaleLinear().domain([0, d3.max(data, (d) => d.y)! + 1]).range([innerH, 0])

  const line = d3
    .line<(typeof data)[0]>()
    .x((d) => x(new Date(d.x)))
    .y((d) => y(d.y))
    .curve(d3.curveMonotoneX)

  g.append('path')
    .datum(data)
    .attr('fill', 'none')
    .attr('stroke', 'var(--accent, #aa3bff)')
    .attr('stroke-width', 2)
    .attr('d', line)

  g.selectAll('circle.pt')
    .data(data)
    .join('circle')
    .attr('class', 'pt')
    .attr('cx', (d) => x(new Date(d.x)))
    .attr('cy', (d) => y(d.y))
    .attr('r', 5)
    .attr('fill', (d) => (d.ok ? 'var(--accent, #aa3bff)' : '#f87171'))

  const xAxis = d3.axisBottom(x).ticks(Math.min(5, data.length))
  const yAxis = d3.axisLeft(y).ticks(Math.min(6, data.length))

  g.append('g').attr('transform', `translate(0,${innerH})`).call(xAxis).attr('color', 'currentColor')

  g.append('g').call(yAxis).attr('color', 'currentColor')
}

let ro: ResizeObserver | null = null

onMounted(() => {
  render()
  if (container.value) {
    ro = new ResizeObserver(() => render())
    ro.observe(container.value)
  }
})

onBeforeUnmount(() => {
  ro?.disconnect()
})

watch(
  () => props.points,
  () => render(),
  { deep: true },
)
</script>

<template>
  <div ref="container" class="d3-job-timeline" />
</template>

<style scoped>
.d3-job-timeline {
  width: 100%;
  min-height: 200px;
  color: var(--shell-muted, #6b7280);
}
</style>
