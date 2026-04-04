import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import './style.css'
import { registerSW } from 'virtual:pwa-register'

const updateSW = registerSW({
  onNeedRefresh() {},
  onOfflineReady() {},
})

const app = createApp(App)

app.use(router)

app.mount('#app')
