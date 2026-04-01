<script setup lang="ts">
import * as d3 from 'd3'
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'

const props = defineProps<{
  mz: number[]
  intensity: number[]
}>()

const container = ref<HTMLDivElement | null>(null)

function render() {
  const el = container.value
  if (!el) return

  const width = el.clientWidth || 400
  const height = 220
  const margin = { top: 12, right: 12, bottom: 32, left: 52 }

  d3.select(el).selectAll('svg').remove()

  const svg = d3
    .select(el)
    .append('svg')
    .attr('width', width)
    .attr('height', height)
    .attr('role', 'img')
    .attr('aria-label', 'Pré-visualização do espectro')

  const innerW = width - margin.left - margin.right
  const innerH = height - margin.top - margin.bottom

  const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`)

  const mz = props.mz
  const yv = props.intensity
  const n = Math.min(mz.length, yv.length)

  if (n === 0) {
    g.append('text')
      .attr('x', innerW / 2)
      .attr('y', innerH / 2)
      .attr('text-anchor', 'middle')
      .attr('fill', 'currentColor')
      .attr('opacity', 0.5)
      .text('Selecione uma amostra ou carregue dados demo')
    return
  }

  const data = Array.from({ length: n }, (_, i) => ({
    x: mz[i]!,
    y: yv[i]!,
    i,
  }))

  const useMzAxis = n === mz.length && n === yv.length && mz.length > 1
  const xDomain: [number, number] = useMzAxis
    ? (d3.extent(data, (d) => d.x) as [number, number])
    : [0, n - 1]

  const x = d3
    .scaleLinear()
    .domain(
      xDomain[0] === xDomain[1]
        ? [xDomain[0] - 1, xDomain[1] + 1]
        : [xDomain[0], xDomain[1]],
    )
    .range([0, innerW])

  const yMin = d3.min(data, (d) => d.y) ?? 0
  const yMax = d3.max(data, (d) => d.y) ?? 1
  const pad = (yMax - yMin) * 0.06 || 0.05
  const y = d3
    .scaleLinear()
    .domain([Math.max(0, yMin - pad), yMax + pad])
    .range([innerH, 0])

  const line = d3
    .line<(typeof data)[0]>()
    .x((d) => (useMzAxis ? x(d.x) : x(d.i)))
    .y((d) => y(d.y))
    .curve(d3.curveMonotoneX)

  g.append('path')
    .datum(data)
    .attr('fill', 'none')
    .attr('stroke', 'var(--accent, #aa3bff)')
    .attr('stroke-width', 1.75)
    .attr('d', line)

  const xAxis = d3
    .axisBottom(x)
    .ticks(Math.min(8, n))
    .tickFormat(useMzAxis ? (v) => String(Number(v).toFixed(1)) : d3.format('d'))

  const yAxis = d3.axisLeft(y).ticks(5)

  g.append('g').attr('transform', `translate(0,${innerH})`).call(xAxis).attr('color', 'currentColor')

  g.append('g').call(yAxis).attr('color', 'currentColor')

  g.append('text')
    .attr('x', innerW / 2)
    .attr('y', innerH + 26)
    .attr('text-anchor', 'middle')
    .attr('fill', 'currentColor')
    .attr('font-size', '11px')
    .attr('opacity', 0.65)
    .text(useMzAxis ? 'm/z' : 'Índice')
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
  () => [props.mz, props.intensity],
  () => render(),
  { deep: true },
)
</script>

<template>
  <div ref="container" class="d3-spectrum-preview" />
</template>

<style scoped>
.d3-spectrum-preview {
  width: 100%;
  min-height: 220px;
  color: var(--shell-muted, #6b7280);
}
</style>
