<!-- src/views/Admin.vue -->
<template>
  <main id="adminContent" class="space-y-6">
    <!-- Admin 統計 -->
    <AdminStats />

    <!-- Admin 導航 -->
    <div class="card p-6">
      <h3 class="text-xl font-semibold text-gray-800 mb-4">管理員控制台</h3>
      <!-- 使用 flex-wrap 允許換行 -->
      <div class="flex flex-wrap gap-4">
        <router-link :to="{ name: 'AdminDashboard' }" class="btn btn-secondary flex-grow sm:flex-grow-0" active-class="btn-primary">
          <span class="flex items-center gap-2 justify-center">📊 儀表板</span>
        </router-link>
        <router-link :to="{ name: 'ManageZones' }" class="btn btn-secondary flex-grow sm:flex-grow-0" active-class="btn-primary">
          <span class="flex items-center gap-2 justify-center">🏢 管理區域</span>
        </router-link>
        <router-link :to="{ name: 'ManageRooms' }" class="btn btn-secondary flex-grow sm:flex-grow-0" active-class="btn-primary">
           <span class="flex items-center gap-2 justify-center">🚪 管理房間</span>
        </router-link>
        <router-link :to="{ name: 'ManageTypes' }" class="btn btn-secondary flex-grow sm:flex-grow-0" active-class="btn-primary">
           <span class="flex items-center gap-2 justify-center">📝 管理類型</span>
        </router-link>
        <router-link :to="{ name: 'ManageChecklist' }" class="btn btn-secondary flex-grow sm:flex-grow-0" active-class="btn-primary">
          <span class="flex items-center gap-2 justify-center">📋 管理檢查項目</span>
        </router-link>
        <router-link :to="{ name: 'ManageUsers' }" class="btn btn-secondary flex-grow sm:flex-grow-0" active-class="btn-primary">
          <span class="flex items-center gap-2 justify-center">👥 管理使用者</span>
        </router-link>
      </div>
       <p class="text-sm text-gray-500 mt-4">
         注意：只有 `admin` 可以訪問這些管理頁面。要將某人設為 Admin，請在下方「管理使用者」頁面操作，或直接在
         <a :href="supabaseDashboardUrl" target="_blank" class="text-blue-600 hover:underline">Supabase 儀表板</a>
         的 `user_roles` 表格中修改。
       </p>
    </div>

    <!-- 子路由將顯示在這裡 -->
    <router-view />
  </main>
</template>

<script setup>
import { computed } from 'vue'
import AdminStats from '@/components/AdminStats.vue'

// 從環境變數獲取 Supabase URL 以建立儀表板連結
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
const projectRef = computed(() => {
    try {
        if (!supabaseUrl) return null;
        const url = new URL(supabaseUrl);
        // 通常是 `projectref.supabase.co` 或 `projectref.supabase.in`
        return url.hostname.split('.')[0];
    } catch (e) {
        console.error("無法解析 Supabase URL:", e);
        return null;
    }
});
// 建立指向 user_roles 表格的儀表板連結
const supabaseDashboardUrl = computed(() => {
    if (projectRef.value) {
        // 使用 Supabase Studio 的新路徑格式
        return `https://supabase.com/dashboard/project/${projectRef.value}/editor/table/user_roles?schema=public`;
    }
    // 如果無法解析，提供一個通用連結
    return 'https://supabase.com/dashboard';
});

</script>

<style scoped>
/* 確保按鈕在高亮時有正確樣式 */
.router-link-active.btn-secondary {
  background: linear-gradient(135deg, var(--primary), var(--primary-dark));
  color: white;
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3);
}
/* 讓按鈕在小螢幕上可以稍微換行 */
@media (max-width: 640px) { /* sm breakpoint */
    .flex-wrap > .btn {
        min-width: calc(50% - 0.5rem); /* 減去 gap 的一半 */
    }
}
</style>

