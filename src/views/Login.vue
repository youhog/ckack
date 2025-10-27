<template>
  <div class="container mx-auto max-w-lg py-8 min-h-screen flex items-center">
    <div class="bg-white shadow-lg rounded-2xl p-8 w-full border border-gray-200">
      <div class="flex items-center gap-4 mb-6 justify-center">
          <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white text-2xl shadow-lg">
              🏠
          </div>
          <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-800 to-gray-600 bg-clip-text text-transparent">
              宿舍檢查系統
          </h1>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-4">
        <div class="mb-4">
          <label for="email" class="block mb-2 text-sm font-medium text-gray-700">電子郵件 (檢查人員)</label>
          <input type="email" id="email" 
                 class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500" 
                 v-model="email" required placeholder="name@example.com">
        </div>
        <div class="mb-4">
          <label for="password" class="block mb-2 text-sm font-medium text-gray-700">密碼</label>
          <input type="password" id="password" 
                 class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500" 
                 v-model="password" required placeholder="••••••••">
        </div>

        <div v-if="errorMsg" class="text-red-600 text-center p-3 bg-red-100 rounded-lg text-sm">{{ errorMsg }}</div>
        <div v-if="successMsg" class="text-green-600 text-center p-3 bg-green-100 rounded-lg text-sm">{{ successMsg }}</div>

        <div class="flex flex-col sm:flex-row gap-4 pt-2">
          <button type="submit" 
                  class="w-full px-6 py-3 bg-indigo-600 text-white font-semibold rounded-lg shadow-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-opacity-75 disabled:opacity-50 disabled:cursor-not-allowed" 
                  :disabled="loading">
            {{ loading ? '登入中...' : '登入' }}
          </button>
          <button type="button" @click="handleSignUp" 
                  class="w-full px-6 py-3 bg-gray-200 text-gray-800 font-semibold rounded-lg shadow-sm hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-opacity-75 disabled:opacity-50 disabled:cursor-not-allowed" 
                  :disabled="loading">
            {{ loading ? '註冊中...' : '註冊新帳號' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
// Script 部分保持不變
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

  const { error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
  })
  if (error) {
    errorMsg.value = `註冊失敗: ${error.message}`
     console.error("Signup error:", error);
  } else {
    successMsg.value = '註冊成功！請直接使用此帳號密碼登入。'
    password.value = '';
  }
  loading.value = false
}
</script><template>
  <div class="container mx-auto max-w-lg py-8 min-h-screen flex items-center">
    <div class="bg-white shadow-lg rounded-2xl p-8 w-full border border-gray-200">
      <div class="flex items-center gap-4 mb-6 justify-center">
          <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white text-2xl shadow-lg">
              🏠
          </div>
          <h1 class="text-3xl font-bold bg-gradient-to-r from-gray-800 to-gray-600 bg-clip-text text-transparent">
              宿舍檢查系統
          </h1>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-4">
        <div class="mb-4">
          <label for="email" class="block mb-2 text-sm font-medium text-gray-700">電子郵件 (檢查人員)</label>
          <input type="email" id="email" 
                 class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500" 
                 v-model="email" required placeholder="name@example.com">
        </div>
        <div class="mb-4">
          <label for="password" class="block mb-2 text-sm font-medium text-gray-700">密碼</label>
          <input type="password" id="password" 
                 class="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-indigo-300 focus:border-indigo-500" 
                 v-model="password" required placeholder="••••••••">
        </div>

        <div v-if="errorMsg" class="text-red-600 text-center p-3 bg-red-100 rounded-lg text-sm">{{ errorMsg }}</div>
        <div v-if="successMsg" class="text-green-600 text-center p-3 bg-green-100 rounded-lg text-sm">{{ successMsg }}</div>

        <div class="flex flex-col sm:flex-row gap-4 pt-2">
          <button type="submit" 
                  class="w-full px-6 py-3 bg-indigo-600 text-white font-semibold rounded-lg shadow-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-400 focus:ring-opacity-75 disabled:opacity-50 disabled:cursor-not-allowed" 
                  :disabled="loading">
            {{ loading ? '登入中...' : '登入' }}
          </button>
          <button type="button" @click="handleSignUp" 
                  class="w-full px-6 py-3 bg-gray-200 text-gray-800 font-semibold rounded-lg shadow-sm hover:bg-gray-300 focus:outline-none focus:ring-2 focus:ring-gray-400 focus:ring-opacity-75 disabled:opacity-50 disabled:cursor-not-allowed" 
                  :disabled="loading">
            {{ loading ? '註冊中...' : '註冊新帳號' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>

<script setup>
// Script 部分保持不變
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

  const { error } = await supabase.auth.signUp({
    email: email.value,
    password: password.value,
  })
  if (error) {
    errorMsg.value = `註冊失敗: ${error.message}`
     console.error("Signup error:", error);
  } else {
    successMsg.value = '註冊成功！請直接使用此帳號密碼登入。'
    password.value = '';
  }
  loading.value = false
}
</script>