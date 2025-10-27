<!-- src/views/Login.vue -->
<template>
  <div class="container mx-auto max-w-lg py-8" style="min-height: 100vh; display: flex; align-items: center;">
    <div class="card p-8 w-full">
      <div class="flex items-center gap-4 mb-6 justify-center">
          <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white text-2xl shadow-lg">
              🏠
          </div>
          <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-800 to-gray-600 bg-clip-text text-transparent">
              宿舍檢查系統
          </h1>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-4">
        <div class="form-group mb-0">
          <label for="email" class="form-label">電子郵件 (檢查人員)</label>
          <input type="email" id="email" class="form-control" v-model="email" required placeholder="name@example.com">
        </div>
        <div class="form-group mb-0">
          <label for="password" class="form-label">密碼</label>
          <input type="password" id="password" class="form-control" v-model="password" required placeholder="••••••••">
        </div>

        <div v-if="errorMsg" class="text-red-500 text-center p-3 bg-red-50 rounded-lg">{{ errorMsg }}</div>
        <div v-if="successMsg" class="text-green-500 text-center p-3 bg-green-50 rounded-lg">{{ successMsg }}</div>

        <div class="flex flex-col sm:flex-row gap-4 pt-2">
          <button type="submit" class="btn btn-primary w-full" :disabled="loading">
            {{ loading ? '登入中...' : '登入' }}
          </button>
          <button type="button" @click="handleSignUp" class="btn btn-secondary w-full" :disabled="loading">
            {{ loading ? '註冊中...' : '註冊新帳號' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase'

const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref(null)
const successMsg = ref(null)

const handleLogin = async () => {
  loading.value = true
  errorMsg.value = null
  successMsg.value = null
  const { error } = await supabase.auth.signInWithPassword({
    email: email.value,
    password: password.value,
  })
  if (error) {
    errorMsg.value = `登入失敗: ${error.message}`
    console.error("Login error:", error);
  } else {
    // 登入成功後，路由守衛會處理跳轉
    // 等待 onAuthStateChange 觸發並載入角色/設定
    // 不需要手動 router.push
  }
  loading.value = false
}

const handleSignUp = async () => {
  loading.value = true
  errorMsg.value = null
  successMsg.value = null

  if (password.value.length < 6) {
    errorMsg.value = '註冊失敗：密碼長度至少需要 6 個字元。'
    loading.value = false
    return
  }

  // Supabase signUp 預設會發送驗證信（如果開啟的話）
  // 並且觸發器 handle_new_user 會自動新增 user_roles 記錄 (預設 inspector)
  const { error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
  })
  if (error) {
    errorMsg.value = `註冊失敗: ${error.message}`
     console.error("Signup error:", error);
  } else {
    successMsg.value = '註冊成功！請直接使用此帳號密碼登入。'
    // 清空密碼欄位，保留 email
    password.value = '';
  }
  loading.value = false
}
</script>

