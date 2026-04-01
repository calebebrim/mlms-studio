<script setup lang="ts">
import { RouterLink, RouterView } from 'vue-router'

const nav = [
  { to: '/datasets', label: 'Datasets' },
  { to: '/pipeline', label: 'Pipeline' },
  { to: '/analytics', label: 'Analytics' },
] as const
</script>

<template>
  <div class="app-shell">
    <aside class="app-shell__sidebar" aria-label="Navegação principal">
      <div class="app-shell__brand">
        <span class="app-shell__title">MLMS Studio</span>
        <span class="app-shell__sub">Vue 3 · Vite</span>
      </div>
      <nav class="app-shell__nav">
        <RouterLink
          v-for="item in nav"
          :key="item.to"
          :to="item.to"
          class="app-shell__link"
          active-class="app-shell__link--active"
        >
          {{ item.label }}
        </RouterLink>
      </nav>
    </aside>
    <div class="app-shell__main">
      <RouterView />
    </div>
  </div>
</template>

<style scoped>
.app-shell {
  min-height: 100vh;
  display: flex;
  background: var(--shell-bg, #0b0c10);
  color: var(--shell-fg, #e5e7eb);
}

.app-shell__sidebar {
  width: 220px;
  flex-shrink: 0;
  display: flex;
  flex-direction: column;
  gap: 20px;
  padding: 20px 16px;
  border-right: 1px solid var(--shell-border, #27272f);
  background: #08090c;
}

.app-shell__brand {
  display: flex;
  flex-direction: column;
  gap: 4px;
  padding-bottom: 8px;
  border-bottom: 1px solid var(--shell-border, #27272f);
}

.app-shell__title {
  font-weight: 600;
  font-size: 1.05rem;
  letter-spacing: -0.02em;
}

.app-shell__sub {
  font-size: 0.75rem;
  opacity: 0.55;
}

.app-shell__nav {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.app-shell__link {
  display: block;
  padding: 10px 12px;
  border-radius: 8px;
  font-size: 0.875rem;
  font-weight: 500;
  color: var(--shell-muted, #9ca3af);
  text-decoration: none;
  transition: background 0.15s ease, color 0.15s ease;
}

.app-shell__link:hover {
  background: #1f2937;
  color: var(--shell-fg, #e5e7eb);
}

.app-shell__link--active {
  background: linear-gradient(135deg, rgba(124, 58, 237, 0.25), rgba(168, 85, 247, 0.15));
  color: #e9d5ff;
  border: 1px solid rgba(168, 85, 247, 0.35);
}

.app-shell__main {
  flex: 1;
  min-width: 0;
  min-height: 0;
  display: flex;
  flex-direction: column;
}

@media (max-width: 640px) {
  .app-shell {
    flex-direction: column;
  }

  .app-shell__sidebar {
    width: 100%;
    flex-direction: row;
    flex-wrap: wrap;
    align-items: center;
    gap: 12px;
    padding: 12px 16px;
  }

  .app-shell__brand {
    border-bottom: none;
    padding-bottom: 0;
    flex: 1 1 auto;
    min-width: 140px;
  }

  .app-shell__nav {
    flex-direction: row;
    flex-wrap: wrap;
    flex: 1 1 100%;
  }

  .app-shell__link {
    padding: 8px 12px;
  }
}
</style>
