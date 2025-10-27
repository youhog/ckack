// src/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import { userStore } from '../store/user' // Check path relative to router/

// Import Layouts and Views
import AppLayout from '../views/AppLayout.vue' // Check path relative to router/
import Login from '../views/Login.vue'       // Check path relative to router/
import Inspection from '../views/Inspection.vue' // Check path relative to router/
import Admin from '../views/Admin.vue'         // Check path relative to router/

// Import Admin Sub-views
import AdminDashboard from '../views/admin/AdminDashboard.vue' // Check path relative to router/
import ManageZones from '../views/admin/ManageZones.vue'     // Check path relative to router/
import ManageRooms from '../views/admin/ManageRooms.vue'     // Check path relative to router/
import ManageTypes from '../views/admin/ManageTypes.vue'     // Check path relative to router/
import ManageChecklist from '../views/admin/ManageChecklist.vue'// Check path relative to router/
import ManageUsers from '../views/admin/ManageUsers.vue'       // Check path relative to router/


const routes = [
  {
    path: '/login',
    name: 'Login',
    component: Login,
    meta: { title: '登入' }
  },
  {
    path: '/',
    component: AppLayout, // Layout for authenticated users
    meta: { requiresAuth: true }, // This route and children require login
    children: [
      {
        path: '', // Default child route for '/'
        name: 'Inspection',
        component: Inspection,
        meta: { title: '檢查模式' }
      },
      {
        path: 'admin',
        component: Admin, // Layout for admin section
        meta: { title: '後台管理', requiresAdmin: true }, // This route and children require admin role
        redirect: { name: 'AdminDashboard' }, // Default redirect for /admin
        children: [
          {
            path: 'dashboard', // Relative path, becomes /admin/dashboard
            name: 'AdminDashboard',
            component: AdminDashboard,
            meta: { title: '管理儀表板' }
          },
          {
            path: 'zones', // Becomes /admin/zones
            name: 'ManageZones',
            component: ManageZones,
            meta: { title: '管理區域' }
          },
          {
            path: 'rooms', // Becomes /admin/rooms
            name: 'ManageRooms',
            component: ManageRooms,
            meta: { title: '管理房間' }
          },
          {
            path: 'types', // Becomes /admin/types
            name: 'ManageTypes',
            component: ManageTypes,
            meta: { title: '管理檢查類型' }
          },
          {
            path: 'checklist', // Becomes /admin/checklist
            name: 'ManageChecklist',
            component: ManageChecklist,
            meta: { title: '管理檢查項目' }
          },
          {
            path: 'users', // Becomes /admin/users
            name: 'ManageUsers',
            component: ManageUsers,
            meta: { title: '帳號管理' }
          }
        ]
      }
    ]
  },
  // Catch-all 404 route - Optional
  // { path: '/:pathMatch(.*)*', name: 'NotFound', component: () => import('../views/NotFound.vue') }
]

// Create the router instance
const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL), // Use BASE_URL from Vite config if needed
  routes
})

// Navigation Guard: Checks authentication and authorization
router.beforeEach(async (to, from, next) => {
  let { session, loading, role } = userStore.state; // Get current state

  // If the user store is still loading initial auth state, wait for it
  if (loading) {
    console.log("Router guard waiting for auth state...");
    await new Promise(resolve => {
        const interval = setInterval(() => {
            if (!userStore.state.loading) { // Check if loading is complete
                clearInterval(interval);
                session = userStore.state.session; // Re-fetch session state
                role = userStore.state.role;       // Re-fetch role state
                console.log("Auth state loaded, proceeding.", { session, role });
                resolve();
            }
        }, 50); // Check every 50ms
    });
  }

  // Determine if the target route requires authentication or admin privileges
  const requiresAuth = to.matched.some(record => record.meta.requiresAuth);
  const requiresAdmin = to.matched.some(record => record.meta.requiresAdmin);

  // --- Logic ---
  if (requiresAuth && !session) {
    // 1. Target route requires login, but user is not logged in
    console.log("Guard: Requires auth, not logged in. Redirecting to Login.");
    next({ name: 'Login', query: { redirect: to.fullPath } }); // Redirect to login, maybe pass redirect query
  } else if (requiresAdmin && role !== 'admin') {
    // 2. Target route requires admin, but user is not an admin
    console.warn("Guard: Requires admin, user is not admin. Redirecting to Inspection.");
    alert('您沒有權限訪問此頁面。'); // Or use a less intrusive notification
    next({ name: 'Inspection' }); // Redirect to a default safe page
  } else if (to.name === 'Login' && session) {
    // 3. User is logged in but trying to access the login page
    console.log("Guard: Logged in, trying to access Login. Redirecting to Inspection.");
    next({ name: 'Inspection' }); // Redirect to the main page
  } else {
    // 4. All checks passed, allow navigation
    console.log(`Guard: Allowing navigation to ${to.name || to.path}`);
    document.title = `${to.meta.title || '宿舍檢查'} - 系統`;
    next(); // Proceed to the route
  }
});

// VERY IMPORTANT: Export the router instance as the default export
export default router;

