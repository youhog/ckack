<template>
  <div class="relative min-h-screen overflow-hidden bg-gradient-to-br from-slate-900 via-indigo-900 to-purple-900">
    <div class="stars absolute top-0 left-0 w-full h-full pointer-events-none" id="stars"></div>

    <main class="min-h-screen flex items-center justify-center px-4 py-12 relative z-10">
      <div class="w-full max-w-md p-8 bg-white/10 dark:bg-black/20 backdrop-blur-lg border border-white/20 rounded-2xl shadow-xl">
        <div class="text-center mb-8">
          <div class="text-4xl mb-4">🌙</div>
          <h1 class="text-3xl font-bold text-white mb-2">宿舍檢查系統</h1>
          <p class="text-blue-200">歡迎回來</p>
        </div>

        <form @submit.prevent="handleLogin" class="space-y-6">
          <div>
            <label for="account" class="block text-sm font-medium text-blue-100 mb-2">
              帳號
            </label>
            <input
              type="text"
              id="account"
              name="account"
              required
              v-model="email" 
              class="w-full px-4 py-3 bg-white/10 border border-white/30 rounded-lg text-white placeholder-blue-200/70 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-500/50 transition-all duration-300"
              placeholder="請輸入帳號 (無需輸入 @網域)"
            />
          </div>

          <div>
            <label for="password" class="block text-sm font-medium text-blue-100 mb-2">
              密碼
            </label>
            <input
              type="password"
              id="password"
              name="password"
              required
              v-model="password"
              class="w-full px-4 py-3 bg-white/10 border border-white/30 rounded-lg text-white placeholder-blue-200/70 focus:outline-none focus:border-indigo-400 focus:ring-2 focus:ring-indigo-500/50 transition-all duration-300"
              placeholder="請輸入密碼"
            />
          </div>

          <div v-if="errorMsg" class="p-3 rounded-lg bg-red-500/20 border border-red-400 text-red-200 text-sm">
            {{ errorMsg }}
          </div>
          <div v-if="successMsg" class="p-3 rounded-lg bg-green-500/20 border border-green-400 text-green-200 text-sm">
            {{ successMsg }}
          </div>

          <button
            type="submit"
            :disabled="loading"
            class="w-full flex items-center justify-center bg-gradient-to-r from-indigo-600 to-purple-600 hover:from-indigo-700 hover:to-purple-700 text-white font-semibold py-3 px-4 rounded-lg transition-all duration-300 transform hover:scale-[1.02] focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-opacity-50 disabled:opacity-70 disabled:cursor-not-allowed"
          >
             <span v-if="loading" class="flex items-center">
                <svg class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                  <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                  <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                </svg>
                處理中...
              </span>
              <span v-else>立即登入</span>
          </button>
        </form>

        <div class="mt-6 text-center">
          <p class="text-blue-200 text-sm">
            還沒有帳號？
            <button 
              @click="handleSignUp" 
              :disabled="loading" 
              class="font-medium text-indigo-300 hover:text-indigo-100 transition-colors disabled:opacity-70 disabled:cursor-not-allowed"
            >
              立即註冊
            </button>
          </p>
        </div>

      </div>
    </main>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase' //
import { DEFAULT_EMAIL_DOMAIN } from '../utils/constants' //

// --- 星星動畫邏輯 (保持不變) ---
function createStars() {
  const starsContainer = document.getElementById('stars');
  if (!starsContainer) return;
  starsContainer.innerHTML = ''; // 清空舊星星
  const numberOfStars = 70; // 增加星星數量

  for (let i = 0; i < numberOfStars; i++) {
    const star = document.createElement('div');
    star.className = 'star'; // 使用 class 方便 CSS 控制
    // 使用 Tailwind classes 控制樣式
    star.classList.add('absolute', 'bg-white', 'rounded-full'); 
    star.style.left = Math.random() * 100 + '%';
    star.style.top = Math.random() * 100 + '%';
    const size = Math.random() * 2 + 0.5; // 調整大小範圍
    star.style.width = size + 'px';
    star.style.height = size + 'px';
    // 動畫參數
    star.style.animationName = 'twinkle';
    star.style.animationTimingFunction = 'ease-in-out';
    star.style.animationIterationCount = 'infinite';
    star.style.animationDelay = Math.random() * 3 + 's'; // 增加延遲變化
    star.style.animationDuration = (Math.random() * 4 + 3) + 's'; // 增加持續時間變化
    starsContainer.appendChild(star);
  }
}

// --- Vue 組件邏輯 (保持不變) ---
const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref(null)
const successMsg = ref(null)

onMounted(() => {
  createStars();
});

const formatEmail = (inputEmail) => {
  const domain = typeof DEFAULT_EMAIL_DOMAIN === 'string' ? DEFAULT_EMAIL_DOMAIN : '';
  if (inputEmail && !inputEmail.includes('@') && domain) {
    return inputEmail + domain; 
  }
  return inputEmail; 
};


const handleLogin = async () => {
  loading.value = true
  errorMsg.value = null
  successMsg.value = null
  const finalEmail = formatEmail(email.value);

  const { error } = await supabase.auth.signInWithPassword({ //
    email: finalEmail,
    password: password.value,
  })
  if (error) {
    errorMsg.value = `登入失敗: ${error.message}`
    console.error("Login error:", error);
  } else {
    router.push({ name: 'Inspection' }); //
  }
  loading.value = false
}

const handleSignUp = async () => {
  loading.value = true
  errorMsg.value = null
  successMsg.value = null
  const finalEmail = formatEmail(email.value);

  if (!finalEmail || !password.value) {
    errorMsg.value = '帳號和密碼不能為空。'
    loading.value = false
    return
  }

  if (password.value.length < 6) {
    errorMsg.value = '註冊失敗：密碼長度至少需要 6 個字元。'
    loading.value = false
    return
  }

  const { error } = await supabase.auth.signUp({ //
    email: finalEmail,
    password: password.value,
  })
  if (error) {
    errorMsg.value = `註冊失敗: ${error.message}`
     console.error("Signup error:", error);
  } else {
    // 【修改】提示用戶檢查信箱，不清空 email
    successMsg.value = '註冊請求已送出！請檢查您的電子郵件以完成驗證，然後即可登入。'
    password.value = ''; // 清空密碼欄位
  }
  loading.value = false
}
</script>

<style scoped>
/* Scoped styles specific to this component */
@keyframes twinkle {
  0%, 100% { opacity: 0.2; transform: scale(0.8); }
  50% { opacity: 1; transform: scale(1.1); }
}
/* 不需要 .star class，因為我們在 JS 中動態添加了 Tailwind classes */
</style>