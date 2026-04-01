import { createRouter, createWebHistory } from 'vue-router'
import AppShellLayout from '../layouts/AppShellLayout.vue'
import AnalyticsShellView from '../views/AnalyticsShellView.vue'
import DatasetsView from '../views/datasets/DatasetsView.vue'
import PipelineWizardView from '../views/pipeline/PipelineWizardView.vue'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes: [
    {
      path: '/',
      component: AppShellLayout,
      children: [
        { path: '', redirect: { name: 'datasets' } },
        { path: 'datasets', name: 'datasets', component: DatasetsView },
        { path: 'pipeline', name: 'pipeline', component: PipelineWizardView },
        { path: 'analytics', name: 'analytics', component: AnalyticsShellView },
      ],
    },
  ],
})

export default router
