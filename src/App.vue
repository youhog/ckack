// youhog/ckack/ckack-10cc0a3bfb263ad24e91487d07fabdff03536175/src/App.vue
<template>
  <div v-if="!userStore.state.isAuthReady" class="loading-screen">
    <div class="bg-white dark:bg-slate-800 p-8 rounded-2xl shadow-xl text-center">
      <h2 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
        宿舍檢查系統載入中...
      </h2>
      <p class="text-slate-500 dark:text-slate-400 mt-2">
        <span>正在驗證使用者...</span>
      </p>
      <div class="spinner mt-6"></div>
    </div>
  </div>
  <div v-else-if="userStore.state.session && configStore.state.loading" class="loading-screen">
      <div class="bg-white dark:bg-slate-800 p-8 rounded-2xl shadow-xl text-center">
          <h2 class="text-2xl font-semibold text-slate-800 dark:text-slate-100">
            宿舍檢查系統載入中...
          </h2>
          <p class="text-slate-500 dark:text-slate-400 mt-2">
            <span>正在載入系統設定...</span>
          </p>
          <div class="spinner mt-6"></div>
      </div>
  </div>
  <router-view v-else />
</template>

<script setup>
import { onMounted } from 'vue'
import { userStore } from './store/user'
import { configStore } from './store/config'

// 【新增】深色模式自動偵測
onMounted(() => {
  // 檢查 localStorage 中是否有儲存的偏好
  if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
    document.documentElement.classList.add('dark')
  } else {
    document.documentElement.classList.remove('dark')
  }

  // (可選) 監聽系統變化
  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', e => {
    if (e.matches) {
      document.documentElement.classList.add('dark')
      localStorage.theme = 'dark'
    } else {
      document.documentElement.classList.remove('dark')
      localStorage.theme = 'light'
    }
  });
})
</script>

<style>
/* 我們將 loading-screen 和 spinner 樣式移到這裡，
  因為它們只在這個全域檔案中使用。
  我們使用 @apply 來應用 Tailwind classes。
*/
.loading-screen {
  @apply flex items-center justify-center min-h-screen;
}

.spinner {
  @apply w-10 h-10 border-4 border-slate-200 dark:border-slate-700 border-t-blue-500 dark:border-t-blue-500 rounded-full animate-spin mx-auto;
}

/* 所有 .card, .btn 等樣式都已從 src/index.css 移除。
  body 樣式由 src/index.css @layer base 提供。
*/
</style>