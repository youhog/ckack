// src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { supabase } from './services/supabase'
import { userStore } from './store/user'
import { configStore } from './store/config'

// Import your global CSS (!!! 確保這裡是 index.css !!!)
import './index.css'

console.log("應用程式初始化開始...");

const app = createApp(App)

app.use(router)
app.mount('#app')

// Function to fetch role and config data
const getRoleAndConfig = async () => {
  console.log("getRoleAndConfig: 正在獲取使用者角色和系統設定...");
  
  // configStore.fetchConfig() 內部會自行管理 configStore.state.loading
  
  let role = 'inspector'; // Default role
  try {
      // 1. 獲取角色
      console.log("getRoleAndConfig: Fetching user role...");
      const { data: roleData, error: roleError } = await supabase.rpc('get_my_role');
      if (roleError) {
          console.error("Error fetching user role:", roleError);
          // 發生錯誤，保持預設 'inspector'
      } else {
          console.log("getRoleAndConfig: Role fetched:", roleData);
          role = roleData; // 賦值獲取到的角色
      }
  } catch (rpcError) {
      console.error("Exception during RPC call (get_my_role):", rpcError);
  }
  // 立即設定角色
  userStore.setRole(role); 

  // 2. 獲取系統設定 (configStore.fetchConfig 會處理自己的 loading 狀態)
  console.log("getRoleAndConfig: Fetching config data...");
  try {
      await configStore.fetchConfig();
      if (configStore.state.error) {
          console.error("Error fetching config:", configStore.state.error);
      } else {
          console.log("getRoleAndConfig: Config data fetched.");
      }
  } catch (configError) {
      console.error("Exception during config fetch:", configError);
  }
  // 此時 configStore.state.loading 會變為 false
};

// --- Authentication State Management ---

let authListener = null; // Variable to hold the listener

const setupAuthListener = () => {
    console.log("正在設定新的 Auth 狀態監聽器...");
    if (authListener) {
        console.log("正在取消訂閱舊的 Auth 監聽器...");
        authListener.unsubscribe();
        authListener = null;
    }

    const { data } = supabase.auth.onAuthStateChange((event, session) => {
        console.log("Auth 狀態改變:", event, "Session:", session ? "存在" : "不存在");
        userStore.setSession(session); // Update session state *immediately*

        // userStore.loading 只追蹤「驗證狀態」是否已確認
        // 它不應該等待 config 載入

        if (event === 'INITIAL_SESSION') {
            console.log("Auth 監聽器: 收到 INITIAL_SESSION 事件。");
            if (session) {
                // 驗證通過，有使用者
                console.log("Auth 監聽器: 初始 Session 存在。觸發角色/設定載入...");
                getRoleAndConfig(); // 觸發背景載入，**不使用 await**
            } else {
                // 驗證通過，無使用者
                console.log("Auth 監聽器: 初始 Session 為 null (未登入)。");
                userStore.setRole(null);
            }
            // 【關鍵修復】: 無論是否有 session，驗證流程已完成
            userStore.setLoading(false); 
        }
        else if (event === 'SIGNED_IN') {
             // 使用者剛登入
             console.log("Auth 監聽器: 偵測到登入。觸發角色/設定載入...");
             // 確保 configStore 是 loading 狀態，以便 App.vue 顯示 "載入系統設定"
             if (!configStore.state.loading) {
                configStore.fetchConfig(); // 觸發背景載入
             } else {
                console.log("Config 仍在載入中，不重複觸發");
             }
             // 登入後，驗證狀態也是穩定的
             if (userStore.state.loading) {
                userStore.setLoading(false);
             }
        }
        else if (event === 'SIGNED_OUT') {
             // 使用者剛登出
             console.log("Auth 監聽器: 偵測到登出。");
             userStore.setRole(null);
             configStore.clearConfig(); // 登出時清除快取的設定檔
             userStore.setLoading(false); // 驗證狀態穩定

            // 重新導向到登入頁面
            if (router.currentRoute.value.name !== 'Login') {
                 console.log("Auth 監聽器: 正在重新導向到登入頁面...");
                 router.replace({ name: 'Login' });
            }
        }
        // 其他事件 (如 TOKEN_REFRESHED) 不需要變更 loading 狀態
    });
    authListener = data.subscription; // Store the subscription
    console.log("Auth 監聽器已設定。");
};


// --- Initialize App ---
const initializeApp = async () => {
    // 應用程式啟動時，立即將驗證狀態設為 loading
    // router guard 會等待這個狀態
    userStore.setLoading(true); 
    console.log("initializeApp: 開始應用程式初始化流程...");

    // 立即設定監聽器
    if (!authListener) {
        setupAuthListener();
    }

    // 呼叫 getSession() 只是為了觸發監聽器儘快回傳 INITIAL_SESSION
    console.log("initializeApp: 呼叫 getSession() 以觸發 INITIAL_SESSION...");
    await supabase.auth.getSession();
    
    // onAuthStateChange 監聽器將會處理後續所有邏輯
    
    // 添加一個安全超時
    setTimeout(() => {
        if (userStore.state.loading) {
            console.error("Auth Timeout: 5秒後仍在載入 Auth 狀態。強制解除鎖定。");
            console.error("請檢查您的 Supabase 連線或 .env 檔案是否正確。");
            userStore.setLoading(false); // 強制解除鎖定，避免無限卡住
        }
    }, 5000); // 5 秒超時
};

// Initialize the app
initializeApp();

console.log("main.js 執行完畢 (非同步操作可能仍在進行中)。");