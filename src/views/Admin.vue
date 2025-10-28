// youhog/ckack/ckack-RBAC-creat/src/views/Admin.vue
<template>
  <main id="adminContent" class="space-y-6">
    <AdminStats />

    <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
      <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-4">管理員控制台</h3>
      <div class="flex flex-wrap gap-3">
        <router-link
          v-for="link in adminLinks"
          :key="link.name"
          :to="{ name: link.name }"
          class="nav-link"
          active-class="nav-link-active"
        >
          <span class="flex items-center gap-2 justify-center">{{ link.icon }} {{ link.text }}</span>
        </router-link>
      </div>
       <p class="text-sm text-slate-500 dark:text-slate-400 mt-4">
         注意：只有 `admin` 可以訪問這些管理頁面。要將某人設為 Admin，請在下方「管理使用者」頁面操作，或直接在
         <a :href="supabaseDashboardUrl" target="_blank" class="text-blue-600 dark:text-blue-400 hover:underline">Supabase 儀表板</a>
         的 `user_roles` 表格中修改。
       </p>
    </div>

    <router-view v-slot="{ Component }">
      <keep-alive>
        <component :is="Component" :key="$route.fullPath" />
      </keep-alive>
    </router-view>
    </main>
</template>

<script setup>
import { computed } from 'vue'
import AdminStats from '@/components/AdminStats.vue'
import { configStore } from '@/store/config' // 引入 configStore 以獲取角色描述

const config = configStore.state

// 導航連結資料
const adminLinks = [
  { name: 'AdminDashboard', icon: '📊', text: '儀表板' },
  { name: 'ManageZones', icon: '🏢', text: '管理區域' },
  { name: 'ManageRooms', icon: '🚪', text: '管理房間' },
  { name: 'ManageTypes', icon: '📝', text: '管理類型' },
  { name: 'ManageChecklist', icon: '📋', text: '管理檢查項目' },
  { name: 'ManageAllocation', icon: '🛏️', text: '床位匯入' },
  { name: 'ManagePermissions', icon: '🔒', text: '權限管理' },
  { name: 'ManageUsers', icon: '👥', text: '管理使用者' }
];

// Supabase 儀表板連結
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const projectRef = computed(() => {
    try {
        if (!supabaseUrl) return null;
        const url = new URL(supabaseUrl);
        return url.hostname.split('.')[0];
    } catch (e) {
        console.error("無法解析 Supabase URL:", e);
        return null;
    }
});
const supabaseDashboardUrl = computed(() => {
    if (projectRef.value) {
        return `https://supabase.com/dashboard/project/${projectRef.value}/editor/table/user_roles?schema=public`;
    }
    return 'https://supabase.com/dashboard';
});

// 動態獲取角色描述的輔助函數 (已修改為動態)
const getRoleDescription = (roleName) => {
    const role = config.roles.find(r => r.name === roleName);
    return role?.description || '系統定義角色';
}

</script>

<style scoped>
/* 樣式保持不變 */
.nav-link {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-all duration-200 cursor-pointer flex-grow sm:flex-grow-0;
  @apply bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600;
}
.nav-link-active {
  @apply bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md border-transparent hover:shadow-lg dark:hover:bg-blue-600;
}

@media (max-width: 640px) {
    .flex-wrap > .nav-link {
        min-width: calc(50% - 0.375rem);
    }
}
</style>