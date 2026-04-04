import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/', name: 'Index', component: () => import('./pages/Index.vue') },
  { path: '/rank', name: 'Rank', component: () => import('./pages/Rank.vue') },
  { path: '/players', name: 'Players', component: () => import('./pages/Players.vue') },
  { path: '/player/:id', name: 'PlayerDetail', component: () => import('./pages/PlayerDetail.vue') },
  { path: '/links', name: 'Links', component: () => import('./pages/Links.vue') },
  { path: '/setting', name: 'Setting', component: () => import('./pages/Setting.vue') }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

export default router
