// youhog/ckack/ckack-RBAC-creat/src/main.js
import { createApp } from 'vue'
import App from './App.vue'
import router from './router'
import { supabase } from './services/supabase'
import { userStore } from './store/user'
import { configStore } from './store/config'

// Import your global CSS
import './index.css'

console.log("應用程式初始化開始...");

const app = createApp(App)

app.use(router)
app.mount('#app')

// Function to fetch role and config data
const getRoleAndConfig = async () => {
  console.log("getRoleAndConfig: 正在獲取系統設定和使用者角色..."); // 修改日誌訊息

  // 1. 【修改】先獲取系統設定 (包含角色列表)
  console.log("getRoleAndConfig: Fetching config data (including roles)...");
  try {
      await configStore.fetchConfig(); // 等待設定載入完成
      if (configStore.state.error) {
          console.error("Error fetching config:", configStore.state.error);
          // 即使設定載入失敗，仍然嘗試獲取角色，但 setRole 可能會失敗
      } else {
          console.log("getRoleAndConfig: Config data fetched.");
      }
  } catch (configError) {
      console.error("Exception during config fetch:", configError);
      // 同上，繼續嘗試獲取角色
  }
  // 此時 configStore.state.roles 應該有數據了 (除非 fetchConfig 失敗)

  // 2. 【修改】再獲取使用者角色
  let role = 'inspector'; // Default role
  try {
      console.log("getRoleAndConfig: Fetching user role...");
      const { data: roleData, error: roleError } = await supabase.rpc('get_my_role');
      if (roleError) {
          console.error("Error fetching user role:", roleError);
          // 發生錯誤，保持預設 'inspector' (或者可以設為 null)
      } else {
          console.log("getRoleAndConfig: Role fetched:", roleData);
          role = roleData; // 賦值獲取到的角色
      }
  } catch (rpcError) {
      console.error("Exception during RPC call (get_my_role):", rpcError);
      // 異常情況，保持預設
  }

  // 3. 【修改】最後設定角色 (此時 configStore.state.roles 應該已載入)
  userStore.setRole(role);
  // configStore.fetchConfig() 內部會自行管理 configStore.state.loading
  // 所以這裡不需要再手動設置 config loading
};

// --- Authentication State Management ---
// (後續程式碼保持不變)
let authListener = null;

const setupAuthListener = () => {
    console.log("正在設定新的 Auth 狀態監聽器...");
    if (authListener) {
        console.log("正在取消訂閱舊的 Auth 監聽器...");
        authListener.unsubscribe();
        authListener = null;
    }

    const { data } = supabase.auth.onAuthStateChange((event, session) => {
        console.log("Auth 狀態改變:", event, "Session:", session ? "存在" : "不存在");

        userStore.setSession(session);

        if (event === 'INITIAL_SESSION') {
            console.log("Auth 監聽器: 收到 INITIAL_SESSION 事件。");
            if (session) {
                console.log("Auth 監聽器: 初始 Session 存在。觸發設定/角色載入...");
                getRoleAndConfig(); // 觸發背景載入 (現在會先載 config)
            } else {
                console.log("Auth 監聽器: 初始 Session 為 null (未登入)。");
                userStore.setRole(null);
                // 【重要】未登入也需要標記 Auth Ready
                userStore.setLoading(false);
                userStore.setAuthReady(true);
            }
            // 【關鍵修改】：將 setLoading 和 setAuthReady 移到 getRoleAndConfig 內部或其完成後處理
            // 我們讓 getRoleAndConfig 處理完後再標記 AuthReady，或者依賴 App.vue 的 config loading
            // 這裡暫時移除，避免過早標記 Ready
            // userStore.setLoading(false); // 移到 getRoleAndConfig 內部處理或依賴 App.vue
            // userStore.setAuthReady(true); // 移到 getRoleAndConfig 內部處理或依賴 App.vue
        }
        else if (event === 'SIGNED_IN') {
             console.log("Auth 監聽器: 偵測到登入。觸發設定/角色載入...");
             getRoleAndConfig(); // 觸發背景載入 (現在會先載 config)
             // 登入後 Auth 狀態穩定
             userStore.setLoading(false);
             userStore.setAuthReady(true);
        }
        else if (event === 'SIGNED_OUT') {
             console.log("Auth 監聽器: 偵測到登出。");
             userStore.clearUser(); // 使用 clearUser 清理狀態
             configStore.clearConfig();

            if (router.currentRoute.value.name !== 'Login') {
                 console.log("Auth 監聽器: 正在重新導向到登入頁面...");
                 router.replace({ name: 'Login' });
            }
        }

        // --- 新增: 監聽 getRoleAndConfig 完成後才設置 AuthReady ---
        // (這部分比較複雜，可以先依賴 App.vue 的 config loading 畫面)
        //  simpler approach: rely on App.vue checks for userStore.isAuthReady AND configStore.loading
        // Make sure INITIAL_SESSION *always* sets AuthReady after getRoleAndConfig or if no session
        if (event === 'INITIAL_SESSION') {
             const checkCompletion = async () => {
                 await getRoleAndConfig(); // 等待 getRoleAndConfig 完成
                 console.log("INITIAL_SESSION: getRoleAndConfig completed.");
                 userStore.setLoading(false); // Auth 流程完成
                 userStore.setAuthReady(true); // Auth 狀態確定
             };
             if(session) {
                checkCompletion();
             }
             // else case handled above
        }
    });
    authListener = data.subscription;
    console.log("Auth 監聽器已設定。");
};


// --- Initialize App ---
const initializeApp = async () => {
    userStore.setLoading(true);
    userStore.setAuthReady(false);
    console.log("initializeApp: 開始應用程式初始化流程...");

    if (!authListener) {
        setupAuthListener();
    }

    console.log("initializeApp: 呼叫 getSession() 以觸發 INITIAL_SESSION...");
    supabase.auth.getSession();
};

// Initialize the app
initializeApp();

console.log("main.js 執行完畢 (非同步操作可能仍在進行中)。");