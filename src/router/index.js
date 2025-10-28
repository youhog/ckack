// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { userStore } from '../store/user'
// 載入 configStore 以使用權限檢查函數
import { configStore } from '../store/config'
import { watch } from 'vue'
import { showToast } from '@/utils'; // 引入 showToast

// Import Layouts and Views
import AppLayout from '../views/AppLayout.vue'
import Login from '../views/Login.vue'
import Inspection from '../views/Inspection.vue'
import Admin from '../views/Admin.vue'
import AdminDashboard from '../views/admin/AdminDashboard.vue'
import ManageZones from '../views/admin/ManageZones.vue'
import ManageRooms from '../views/admin/ManageRooms.vue'
import ManageTypes from '../views/admin/ManageTypes.vue'
import ManageChecklist from '../views/admin/ManageChecklist.vue'
import ManageUsers from '../views/admin/ManageUsers.vue'
import ManageAllocation from '../views/admin/ManageAllocation.vue'
import ManagePermissions from '../views/admin/ManagePermissions.vue'
import KeyReturn from '../views/KeyReturn.vue'

// routes
const routes = [
  { path: '/login', name: 'Login', component: Login, meta: { title: '登入' } },
  {
    path: '/',
    component: AppLayout,
    meta: { requiresAuth: true }, // 所有子路由都需要登入
    children: [
      { path: '', name: 'Inspection', component: Inspection, meta: { title: '檢查模式' } },
      { path: 'key-return', name: 'KeyReturn', component: KeyReturn, meta: { title: '鑰匙歸還' } },
      {
        path: 'admin',
        component: Admin,
        meta: { requiresAuth: true }, // 父路由確保已登入
        redirect: { name: 'AdminDashboard' }, // 預設跳轉到儀表板
        children: [
          // --- 為每個管理頁面添加 requiresPermission ---
          // 儀表板通常需要讀取報告的權限
          { path: 'dashboard', name: 'AdminDashboard', component: AdminDashboard, meta: { title: '管理儀表板', requiresPermission: 'read_all_reports' } },
          { path: 'zones', name: 'ManageZones', component: ManageZones, meta: { title: '管理區域', requiresPermission: 'manage_zones' } },
          { path: 'rooms', name: 'ManageRooms', component: ManageRooms, meta: { title: '管理房間', requiresPermission: 'manage_rooms' } },
          { path: 'types', name: 'ManageTypes', component: ManageTypes, meta: { title: '管理檢查類型', requiresPermission: 'manage_types' } },
          { path: 'checklist', name: 'ManageChecklist', component: ManageChecklist, meta: { title: '管理檢查項目', requiresPermission: 'manage_checklist' } },
          { path: 'allocation', name: 'ManageAllocation', component: ManageAllocation, meta: { title: '床位匯入', requiresPermission: 'manage_allocations' } }, // <-- 指定床位匯入權限
          { path: 'permissions', name: 'ManagePermissions', component: ManagePermissions, meta: { title: '權限管理', requiresPermission: 'manage_permissions' } },
          { path: 'users', name: 'ManageUsers', component: ManageUsers, meta: { title: '帳號管理', requiresPermission: 'manage_users' } }
          // --- 結束 ---
        ]
      }
    ]
  },
  // 可以加入 404 頁面等
]

// Create the router instance
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// Navigation Guard: Checks authentication and authorization
router.beforeEach(async (to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  // --- 修改：取得需要的權限名稱 (從最深的匹配路由獲取) ---
  const requiredPermission = to.meta.requiresPermission;
  // --- 結束修改 ---

  // Function to wait until authentication and config (roles, permissions, map) are ready
  const waitForAuthAndConfig = () => {
    return new Promise((resolve) => {
        // 先確保 Auth 狀態已就緒
        const ensureAuthReady = () => {
            if (userStore.state.isAuthReady) {
                ensureConfigReady(); // Auth 好了，檢查 Config
            } else {
                // 持續監聽 Auth 狀態
                const unwatchAuth = watch(() => userStore.state.isAuthReady, (isReady) => {
                    if (isReady) {
                        unwatchAuth();
                        ensureConfigReady();
                    }
                });
            }
        };

        // 確保 Config 載入完成且 Map 已建立
        const ensureConfigReady = () => {
             // 如果 config 正在載入，則監聽 loading 狀態
            if (configStore.state.loading) {
                 const unwatchConfig = watch(() => configStore.state.loading, (isLoading) => {
                    if (!isLoading) {
                        unwatchConfig();
                        // 載入完成後檢查 Map 是否建立 (防止 config 載入成功但 Map 建立失敗)
                        if (configStore.state.rolePermissionsMap.size > 0 || configStore.state.roles.length === 0 || configStore.state.error) {
                             resolve(); // Map 建立成功 或 確定無法建立 (roles 空或有 error)
                        } else {
                             // 理論上不太會發生，但作為防禦
                             console.error("Config loaded but Role Permissions Map is empty!");
                             resolve(); // 仍然 resolve，讓後續權限檢查失敗
                        }
                    }
                });
            } else {
                 // 如果 config 沒有在載入，直接檢查 Map 是否建立 或 是否有錯誤
                 if (configStore.state.rolePermissionsMap.size > 0 || configStore.state.roles.length === 0 || configStore.state.error) {
                      resolve();
                 } else {
                      // 如果 Map 是空的但沒有 loading 且 roles 不是空的，表示可能有問題
                      console.warn("Config not loading, but Role Permissions Map is empty. Potential issue?");
                      resolve(); // 仍然 resolve
                 }
            }
        };

        ensureAuthReady(); // 啟動檢查流程
    });
  };

  await waitForAuthAndConfig(); // 等待使用者角色和權限設定載入
  // console.log("路由守衛：Auth & Config 狀態已就緒。Role:", userStore.state.role); // 減少日誌

  const { session } = userStore.state;

  // Check 1: Authentication required?
  if (requiresAuth && !session) {
    console.log("路由守衛：需要驗證，但未登入。重新導向到登入頁。");
    next({ name: 'Login', query: { redirect: to.fullPath } });

  // --- 修改：檢查特定權限 ---
  } else if (requiredPermission && !configStore.userHasPermission(requiredPermission)) {
     console.warn(`路由守衛：存取 ${to.path} 需要權限 "${requiredPermission}"，但目前角色 (${userStore.state.role}) 沒有。重新導向到檢查頁。`);
     showToast('您沒有權限訪問此頁面。', 'error'); // 使用 showToast 提示
     // 如果使用者已登入但無權限，導回檢查頁
     if (session) {
        // 避免從檢查頁無限重導回檢查頁
        if (from.name !== 'Inspection') {
            next({ name: 'Inspection' });
        } else {
            // 如果來源就是檢查頁，表示使用者可能剛登入但沒有任何管理權限，停留在原地即可
            // 或者可以考慮導向一個特定的 "無權限" 頁面
            next(false); // 取消導航
        }
     } else {
         // 理論上不會執行到這裡，因為 requiresAuth 會先攔截
         next({ name: 'Login' });
     }
  // --- 結束修改 ---

  // Check 3: Trying to access login page while already logged in?
  } else if (to.name === 'Login' && session) {
    console.log("路由守衛：已登入，但試圖訪問登入頁。重新導向到檢查頁。");
    next({ name: 'Inspection' }); // Redirect logged-in users away from login

  // All checks passed, allow navigation
  } else {
    // console.log(`路由守衛：允許導航到 ${to.name || to.path}`); // 減少日誌
    document.title = `${to.meta.title || '宿舍檢查'} - 系統`;
    next();
  }
});

export default router;