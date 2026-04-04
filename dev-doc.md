# NBA赛事数据助手（PWA）技术开发文档
```markdown
# NBA赛事数据助手（PWA）技术开发文档

## 一、文档概述
### 1.1 文档用途
本文档为 **NBA赛事资讯数据可视化PWA应用** 完整技术实现说明，用于指导前端开发、接口对接、PWA配置、iOS适配与项目部署，全程无后端、无数据库、无侵权逻辑，仅面向个人自用场景。

### 1.2 适用环境
- 运行平台：iOS Safari 浏览器
- 应用形态：PWA 渐进式网页应用（添加至主屏幕全屏运行）
- 开发环境：Node.js ≥ 16.0.0
- 部署环境：Vercel / GitHub Pages（免费 HTTPS）

---

## 二、技术栈选型
### 2.1 核心技术
- 构建工具：Vite 5.x
- 前端框架：Vue 3 (Composition API)
- 样式方案：Tailwind CSS v3
- 数据可视化：ECharts 5
- 网络请求：Axios
- PWA 支持：Vite Plugin PWA
- 数据来源：BallDontLie 免费公开NBA API

### 2.2 技术优势
- 轻量打包体积小，iOS 加载极快
- 无需苹果开发者账号、无需上架
- 纯前端实现，无需服务器与数据库
- 支持离线缓存、下拉刷新、数据持久化

---

## 三、项目目录结构
```
nba-pwa/
├── public/
│   ├── icons/              # PWA桌面图标（iOS适配尺寸）
│   ├── manifest.json       # PWA配置文件
│   └── sw.js               # ServiceWorker 离线缓存
├── src/
│   ├── api/
│   │   └── nba.js          # NBA接口统一封装
│   ├── components/         # 公共组件（赛程卡片、排行榜、图表等）
│   ├── pages/
│   │   ├── Index.vue        # 首页
│   │   ├── Rank.vue         # 球队排名
│   │   ├── Players.vue      # 球员榜单
│   │   ├── PlayerDetail.vue # 球员详情页
│   │   ├── Links.vue        # 自用观赛链接管理
│   │   └── Setting.vue      # 设置页
│   ├── utils/
│   │   ├── storage.js       # localStorage工具
│   │   ├── date.js          # 日期格式化
│   │   └── cache.js         # 接口数据缓存
│   ├── App.vue
│   ├── router.js            # 路由配置
│   └── main.js
├── vite.config.js
└── package.json
```

---

## 四、API 接口设计
### 4.1 接口基础信息
- 基础域名：`https://www.balldontlie.io/api/v1`
- 无需密钥、无需登录
- 支持：赛程、球队、球员、赛季数据

### 4.2 接口封装（src/api/nba.js）
```javascript
import axios from 'axios'

const api = axios.create({
  baseURL: 'https://www.balldontlie.io/api/v1',
  timeout: 10000
})

// 获取指定日期赛程
export const getGamesByDate = (date) => {
  return api.get('/games', { params: { 'dates[]': date } })
}

// 获取所有球队
export const getTeams = () => {
  return api.get('/teams')
}

// 获取球员列表
export const getPlayers = (page = 0, per_page = 25) => {
  return api.get('/players', { params: { page, per_page } })
}

// 获取赛季场均数据
export const getSeasonAverages = () => {
  return api.get('/season_averages')
}
```

### 4.3 缓存策略
- 接口数据缓存 2 小时
- 无网络时自动读取本地缓存
- 下拉刷新可强制更新数据

---

## 五、页面与功能实现
### 5.1 首页（Index.vue）
- 展示今日全部NBA赛程
- 比赛状态：未开始 / 进行中 / 已结束
- 横向滚动赛程卡片
- 快捷自用观赛入口
- 支持下拉刷新

### 5.2 球队排名页（Rank.vue）
- 东部/西部联盟切换
- 球队胜率柱状图（ECharts）
- 排名表格：胜场、负场、胜率、连胜/连败
- 点击球队可进入详情

### 5.3 球员榜单页（Players.vue）
- 数据分类：得分 / 篮板 / 助攻 / 抢断 / 盖帽
- 联盟 TOP20 球员排序
- 点击进入球员详情

### 5.4 球员详情页（PlayerDetail.vue）
- 基础信息：姓名、球队、位置、号码
- 赛季场均数据
- 球员能力雷达图（ECharts）
  - 维度：得分、篮板、助攻、抢断、盖帽

### 5.5 观赛链接管理（Links.vue）
- 本地新增/编辑/删除观赛链接
- 数据存储在 localStorage
- 点击跳转外部Safari浏览
- 不上传云端、不对外分享

### 5.6 设置页（Setting.vue）
- 深色/浅色模式切换
- iOS添加到主屏幕教程
- 清理本地缓存
- 版本信息

---

## 六、PWA 配置
### 6.1 manifest.json
```json
{
  "name": "NBA赛事数据助手",
  "short_name": "NBA数据",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#121212",
  "theme_color": "#E03A3E",
  "icons": [
    {
      "src": "/icons/192x192.png",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "/icons/512x512.png",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
```

### 6.2 ServiceWorker 缓存规则
- 静态资源（JS/CSS/IMG）：缓存优先
- 接口数据：网络优先，离线降级
- 页面路由：预缓存首页、排名、球员页

### 6.3 iOS 专属适配
- 禁用双击缩放
- 全屏 standalone 模式
- 隐藏地址栏与工具栏
- 适配iPhone刘海屏安全区域

---

## 七、路由配置（src/router.js）
```javascript
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
```

---

## 八、UI 设计规范
### 8.1 色彩系统
- 主色红：#E03A3E
- 主色蓝：#17408B
- 背景深色：#121212
- 卡片背景：rgba(30,30,30,0.8)
- 文字：#fff / #eee / #999

### 8.2 布局规范
- 适配iPhone竖屏：375px~430px宽度
- 卡片圆角：12px
- 列表间距：10px~16px
- 字体：iOS 系统 SF 字体

---

## 九、数据持久化
所有用户数据仅保存在本地 localStorage，不上传云端：
- 自定义观赛链接
- 收藏球队/球员
- 深色/浅色模式设置
- 接口缓存数据

---

## 十、部署方案
### 10.1 Vercel 部署（推荐）
1. 项目上传至 GitHub
2. Vercel 导入仓库
3. 自动构建，生成 HTTPS 域名
4. PWA 可直接被 iOS 识别

### 10.2 GitHub Pages 部署
1. 配置 vite.config.js  base path
2. 执行 `npm run build`
3. 推送 dist 目录至 gh-pages 分支

---

## 十一、性能优化
- 路由懒加载
- 接口防抖与缓存
- ECharts 按需引入
- 图片压缩与懒加载
- 静态资源缓存策略

---

## 十二、安全与合规要求
1. 不提供任何盗版直播内容
2. 不存储、不分发、不聚合盗播链接
3. 不爬取腾讯体育、咪咕等版权平台数据
4. 不收集用户隐私、不上传数据
5. 仅限个人自用，禁止公开传播

---

## 十三、开发与测试流程
1. 环境安装：node install
2. 开发运行：npm run dev
3. 生产构建：npm run build
4. iOS 真机测试：Safari 打开本地/部署地址
5. 添加至主屏幕验证全屏效果
6. 离线模式验证缓存功能
```
