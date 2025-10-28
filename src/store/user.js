// youhog/ckack/ckack-RBAC-creat/src/store/user.js
import { reactive, readonly } from 'vue'
// 【新增】引入 configStore 以讀取有效角色列表
import { configStore } from './config' // 確保路徑正確

const state = reactive({
  session: null,  // Supabase Auth session object
  user: null,     // Supabase Auth user object
  role: null,     // 'admin', 'inspector', 'sdc', 'sdsc', 'superadmin' 等
  loading: true,   // 初始為 true，直到 getSession() 和 get_my_role() 完成
  isAuthReady: false // 初始為 false，直到 Auth 狀態確定完成
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

// 設定 Auth 準備完成狀態
const setAuthReady = (status) => {
    state.isAuthReady = status
}

// 設定使用者角色
// 【修改】動態檢查角色有效性
const setRole = (role) => {
  // 從 configStore 獲取有效角色名稱列表
  const validRoles = configStore.state.roles.map(r => r.name);

  // 檢查傳入的角色是否存在於有效列表中
  if (role && validRoles.includes(role)) {
      state.role = role
      console.log(`User role set to: ${role}`); // 添加日誌確認
  } else {
      console.warn(`嘗試設定無效的角色: ${role} (有效角色: ${validRoles.join(', ')}), 將設為 null`);
      state.role = null; // 或者可以設為一個預設的 'guest' 或 'inspector' 角色
  }
}

// 清除所有使用者狀態 (例如登出時)
const clearUser = () => {
    state.session = null;
    state.user = null;
    state.role = null;
    state.loading = false;
    state.isAuthReady = true;
}

// 導出 Store
export const userStore = {
  state: readonly(state),
  setSession,
  setLoading,
  setRole,
  setAuthReady,
  clearUser
}