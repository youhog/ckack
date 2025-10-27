import { reactive, readonly } from 'vue'

const state = reactive({
  session: null,  // Supabase Auth session object
  user: null,     // Supabase Auth user object
  role: null,     // 'admin' 或 'inspector'
  loading: true   // 初始為 true，直到 getSession() 和 get_my_role() 完成
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
}

// 導出 Store
export const userStore = {
  state: readonly(state), // 使 state 唯讀
  setSession,
  setLoading,
  setRole,
  clearUser             // 導出清除函數
}
