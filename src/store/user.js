// youhog/ckack/ckack-10cc0a3bfb263ad24e91487d07fabdff03536175/src/store/user.js
import { reactive, readonly } from 'vue'

const state = reactive({
  session: null,  // Supabase Auth session object
  user: null,     // Supabase Auth user object
  role: null,     // 'admin' 或 'inspector'
  loading: true,   // 初始為 true，直到 getSession() 和 get_my_role() 完成
  isAuthReady: false // ADDED: 初始為 false，直到 Auth 狀態確定完成 (不論是否載入 config)
})

// 設定 Session 和 User 狀態
const setSession = (session) => {
  state.session = session
  state.user = session?.user ?? null
}

// 設定載入狀態
const setLoading = (loading) => {
  state.loading = loading
}

// ADDED: 設定 Auth 準備完成狀態
const setAuthReady = (status) => {
    state.isAuthReady = status
}
// END ADDED

// 設定使用者角色
const setRole = (role) => {
  // 確保角色是 'admin' 或 'inspector'，否則設為 null 或預設值
  if (role === 'admin' || role === 'inspector') {
      state.role = role
  } else {
      console.warn(`嘗試設定無效的角色: ${role}, 將設為 null`);
      state.role = null; 
  }
}

// 清除所有使用者狀態 (例如登出時)
const clearUser = () => {
    state.session = null;
    state.user = null;
    state.role = null;
    state.loading = false; // 登出後設為 false
    state.isAuthReady = true; // ADDED: 登出後 Auth 狀態也視為確定
}

// 導出 Store
export const userStore = {
  state: readonly(state), // 使 state 唯讀
  setSession,
  setLoading,
  setRole,
  setAuthReady, // ADDED
  clearUser             // 導出清除函數
}