<!-- src/App.vue -->
<template>
  <!-- 只有在 session 載入中，或 session 已載入但設定仍在載入中時，才顯示載入畫面 -->
  <div v-if="userStore.state.loading || (userStore.state.session && configStore.state.loading)" class="loading-screen">
    <div class="card p-8 text-center">
      <h2 class="text-2xl font-semibold">
        宿舍檢查系統載入中...
      </h2>
      <p class="text-gray-500 mt-2">
        <span v-if="userStore.state.loading">正在驗證使用者...</span>
        <span v-else-if="configStore.state.loading">正在載入系統設定...</span>
      </p>
      <!-- 簡易 Spinner 動畫 -->
      <div class="spinner mt-4"></div>
    </div>
  </div>
  <!-- 載入完成後顯示路由內容 -->
  <router-view v-else />
</template>

<script setup>
import { userStore } from './store/user'
import { configStore } from './store/config'
</script>

<style>
/* Loading Screen 樣式 */
.loading-screen {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 100vh;
  /* 移除這裡的背景色，讓 body 的背景生效 */
  /* background: linear-gradient(135deg, #f0f4ff 0%, #e6f0ff 100%); */
}

/* 簡易 Spinner 動畫 */
.spinner {
  border: 4px solid rgba(0, 0, 0, 0.1);
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border-left-color: var(--primary); /* 使用 CSS 變數 */
  margin: auto; /* 置中 */
  animation: spin 1s ease infinite;
}

@keyframes spin {
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
}

/* 基本 body 樣式 */
body {
    /* 根據是否暗色模式設定背景 */
    background-color: #f0f4ff; /* 預設淺藍色背景 */
    color: #1e293b; /* 深藍灰色文字 */
    min-height: 100vh;
    transition: background-color 0.3s ease, color 0.3s ease; /* 平滑過渡 */
    margin: 0;
    padding: 0;
    font-family: 'Inter', sans-serif; /* 確保字體一致 */
}

/* 暗色模式下 body 的背景 */
body.dark-theme {
    background: #0f172a; /* 使用深色背景 */
    color: #e2e8f0; /* 亮灰色文字 */
}

/* 確保容器有左右邊距 */
.container {
    max-width: 1200px; /* 或者您希望的最大寬度 */
    margin-left: auto;
    margin-right: auto;
    padding-left: 1rem;  /* 16px */
    padding-right: 1rem; /* 16px */
}
/* 響應式邊距 */
@media (min-width: 640px) { /* sm breakpoint */
    .container {
        padding-left: 1.5rem; /* 24px */
        padding-right: 1.5rem; /* 24px */
    }
}
/* 修正 form-group 預設 margin */
.form-group {
    margin-bottom: 1rem; /* 保持一致的間距 */
}
</style>

