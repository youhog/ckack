// vite.config.js
import { fileURLToPath, URL } from 'node:url'

import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    vue(),
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  },
  // --- 加入 server 設定 ---
  server: {
    port: 3000, // 您可以改成 5174, 8080 或其他您知道可用的 port
    // (可選) 如果希望伺服器啟動時自動開啟瀏覽器
    // open: true
  },
  // --- 加入 build 設定 ---
  build: {
    minify: 'esbuild', // 確保使用 esbuild 壓縮 (Vite 5 預設)
    // 設定 esbuild 選項移除 console 和 debugger
    esbuild: {
      drop: ['console', 'debugger'], // 在生產建置中移除 console.* 和 debugger 語句
    }
  }
  // --- 結束 build 設定 ---
})