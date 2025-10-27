import { reactive, readonly } from 'vue'

const state = reactive({
  session: null,
  user: null,
  role: null, // 'admin' 或 'inspector'
  loading: true // 初始為 true，直到 getSession() 完成
})

const setSession = (session) => {
  state.session = session
  state.user = session?.user ?? null
}

const setLoading = (loading) => {
  state.loading = loading
}

const setRole = (role) => {
  state.role = role
}

export const userStore = {
  state: readonly(state),
  setSession,
  setLoading,
  setRole,
}