// youhog/ckack/ckack-10cc0a3bfb263ad24e91487d07fabdff03536175/src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { userStore } from '../store/user'
import { watch } from 'vue'

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
import ManageAllocation from '../views/admin/ManageAllocation.vue' // ADDED: 引入床位分配管理
import KeyReturn from '../views/KeyReturn.vue' 

// routes 
const routes = [
  { path: '/login', name: 'Login', component: Login, meta: { title: '登入' } },
  {
    path: '/',
    component: AppLayout,
    meta: { requiresAuth: true },
    children: [
      { path: '', name: 'Inspection', component: Inspection, meta: { title: '檢查模式' } },
      { path: 'key-return', name: 'KeyReturn', component: KeyReturn, meta: { title: '鑰匙歸還' } },
      {
        path: 'admin',
        component: Admin,
        meta: { title: '後台管理', requiresAdmin: true },
        redirect: { name: 'AdminDashboard' },
        children: [
          { path: 'dashboard', name: 'AdminDashboard', component: AdminDashboard, meta: { title: '管理儀表板' } },
          { path: 'zones', name: 'ManageZones', component: ManageZones, meta: { title: '管理區域' } },
          { path: 'rooms', name: 'ManageRooms', component: ManageRooms, meta: { title: '管理房間' } },
          { path: 'types', name: 'ManageTypes', component: ManageTypes, meta: { title: '管理檢查類型' } },
          { path: 'checklist', name: 'ManageChecklist', component: ManageChecklist, meta: { title: '管理檢查項目' } },
          { path: 'allocation', name: 'ManageAllocation', component: ManageAllocation, meta: { title: '床位匯入' } }, // ADDED
          { path: 'users', name: 'ManageUsers', component: ManageUsers, meta: { title: '帳號管理' } }
        ]
      }
    ]
  },
]

// Create the router instance 
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes
})

// Navigation Guard: Checks authentication and authorization 
router.beforeEach(async (to, from, next) => {
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  const requiresAdmin = to.matched.some(record => record.meta.requiresAdmin);

  const waitForAuth = () => {
    return new Promise((resolve) => {
      // MODIFIED: 等待 isAuthReady 狀態確定，而不是 loading
      if (userStore.state.isAuthReady) { 
        resolve();
        return;
      }
      const unwatch = watch(() => userStore.state.isAuthReady, (isReady) => { 
        if (isReady) {
          unwatch(); 
          resolve();
        }
      });
      // REMOVED: 移除超時強制繼續
    });
  };

  await waitForAuth();
  console.log("路由守衛：Auth 狀態已載入。Session:", userStore.state.session ? '存在' : '不存在', "Role:", userStore.state.role); 


  const { session, role } = userStore.state; 

  if (requiresAuth && !session) {
    console.log("路由守衛：需要驗證，但未登入。重新導向到登入頁。");
    next({ name: 'Login', query: { redirect: to.fullPath } });
  } else if (requiresAdmin && role !== 'admin') {
    console.warn("路由守衛：需要 Admin 權限，但目前角色是:", role, "。重新導向到檢查頁。");
    alert('您沒有權限訪問此頁面。');
    next({ name: 'Inspection' }); 
  } else if (to.name === 'Login' && session) {
    console.log("路由守衛：已登入，但試圖訪問登入頁。重新導向到檢查頁。");
    next({ name: 'Inspection' });
  } else {
    console.log(`路由守衛：允許導航到 ${to.name || to.path}`);
    document.title = `${to.meta.title || '宿舍檢查'} - 系統`;
    next();
  }
});

export default router;