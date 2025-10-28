// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { userStore } from '../store/user'
// 載入 configStore 以使用權限檢查函數
import { configStore } from '../store/config'
import { watch } from 'vue' // 確保 watch 已引入
import { showToast } from '@/utils'; // 引入 showToast
import { supabase } from '../services/supabase' // 引入 supabase 以便登出 (如果需要)

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
          { path: 'dashboard', name: 'AdminDashboard', component: AdminDashboard, meta: { title: '管理儀表板', requiresPermission: 'read_all_reports' } },
          { path: 'zones', name: 'ManageZones', component: ManageZones, meta: { title: '管理區域', requiresPermission: 'manage_zones' } },
          { path: 'rooms', name: 'ManageRooms', component: ManageRooms, meta: { title: '管理房間', requiresPermission: 'manage_rooms' } },
          { path: 'types', name: 'ManageTypes', component: ManageTypes, meta: { title: '管理檢查類型', requiresPermission: 'manage_types' } },
          { path: 'checklist', name: 'ManageChecklist', component: ManageChecklist, meta: { title: '管理檢查項目', requiresPermission: 'manage_checklist' } },
          { path: 'allocation', name: 'ManageAllocation', component: ManageAllocation, meta: { title: '床位匯入', requiresPermission: 'manage_allocations' } },
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
  const requiredPermission = to.meta.requiresPermission;

  // Function to wait until authentication and ROLE are ready
  const waitForAuthAndRole = () => {
    return new Promise((resolve) => {
      // Check if auth is ready AND (either no session OR role is set)
      const checkCompletion = () => {
        if (userStore.state.isAuthReady && (!userStore.state.session || userStore.state.role)) {
          resolve();
        }
      };

      // If already complete, resolve immediately
      if (userStore.state.isAuthReady && (!userStore.state.session || userStore.state.role)) {
        resolve();
        return;
      }

      // Watch for changes in isAuthReady and role
      const unwatch = watch(
        () => [userStore.state.isAuthReady, userStore.state.role, userStore.state.session],
        ([isAuthReady, role, session]) => {
          if (isAuthReady && (!session || role)) {
            unwatch(); // Stop watching once condition met
            resolve();
          }
        },
        { immediate: false } // Don't run immediately, wait for change
      );
    });
  };


  // Wait for auth state AND role to be determined
  await waitForAuthAndRole();

  const { session } = userStore.state;

  // Check 1: Authentication required?
  if (requiresAuth && !session) {
    console.log("路由守衛：需要驗證，但未登入。重新導向到登入頁。");
    next({ name: 'Login', query: { redirect: to.fullPath } });

  // Check 2: Permission required? (NOW check role and permission)
  } else if (requiredPermission) {
      // Ensure role is actually loaded before checking permission
      if (!userStore.state.role && session) {
           console.error(`路由守衛：嚴重錯誤！已登入但角色為空，無法檢查權限 "${requiredPermission}"。可能 get_my_role() 或設定有問題。`);
           showToast('無法驗證您的使用者角色，請重新登入。', 'error');
           // Consider signing the user out here or redirect to login
           // await supabase.auth.signOut(); // Example sign out
           next({ name: 'Login' }); // Redirect to login
      } else if (session && !configStore.userHasPermission(requiredPermission)) {
           console.warn(`路由守衛：存取 ${to.path} 需要權限 "${requiredPermission}"，但目前角色 (${userStore.state.role}) 沒有。重新導向到檢查頁。`);
           showToast('您沒有權限訪問此頁面。', 'error');
           if (from.name !== 'Inspection') {
               next({ name: 'Inspection' });
           } else {
               next(false); // Stay if already on Inspection page
           }
      } else {
           // Has permission or no session required (allow public pages if any)
           document.title = `${to.meta.title || '宿舍檢查'} - 系統`;
           next();
      }

  // Check 3: Trying to access login page while already logged in?
  } else if (to.name === 'Login' && session) {
    console.log("路由守衛：已登入，但試圖訪問登入頁。重新導向到檢查頁。");
    next({ name: 'Inspection' }); // Redirect logged-in users away from login

  // All checks passed, allow navigation
  } else {
    document.title = `${to.meta.title || '宿舍檢查'} - 系統`;
    next();
  }
});

export default router;