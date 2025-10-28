// src/views/admin/ManagePermissions.vue
<template>
  <div class="p-6 bg-white dark:bg-slate-800 rounded-2xl shadow-lg">
    <h2 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-6">角色與權限管理</h2>

    <div v-if="config.loading" class="text-center py-8 text-slate-500 dark:text-slate-400">正在載入角色和權限配置...</div>

    <div v-else-if="config.error" class="text-center py-8 text-red-500 dark:text-red-400">
        <p>錯誤：無法載入權限設定。</p>
        <p class="text-sm text-slate-500 dark:text-slate-400 mt-2">{{ config.error }}</p>
    </div>

    <div v-else-if="config.roles.length === 0" class="text-center py-8 text-red-500 dark:text-red-400">
        <p>錯誤：無法從資料庫載入角色列表。請檢查 `roles` 表格中是否有數據。</p>
    </div>

    <div v-else class="flex flex-col md:flex-row gap-8">
      <div class="md:w-1/3">
        <h3 class="text-lg font-semibold mb-3 text-slate-700 dark:text-slate-300">角色列表 ({{ sortedRoles.length }} 個)</h3>
        <div class="space-y-2">
          <div
            v-for="role in sortedRoles"
            :key="role.id"  
            @click="selectRole(role)"
            :class="['p-3 rounded-lg cursor-pointer transition-all duration-200 border',
                     selectedRole?.id === role.id ? 'bg-indigo-100 dark:bg-indigo-900/50 border-indigo-500 shadow-md' : 'bg-slate-50 dark:bg-slate-700/50 hover:bg-slate-100 dark:hover:bg-slate-700 border-slate-200 dark:border-slate-700']"
          >
            <p class="font-bold text-slate-800 dark:text-slate-100">{{ role.name }}</p>
            <p class="text-xs text-slate-500 dark:text-slate-400">{{ role.description || '無描述' }}</p>
          </div>
        </div>
      </div>

      <div class="md:w-2/3">
        <div v-if="selectedRole">
          <h3 class="text-lg font-semibold mb-4 text-slate-700 dark:text-slate-300">
            編輯角色 <span class="font-bold text-blue-600 dark:text-blue-400">"{{ selectedRole.name }}"</span> 的權限
          </h3>
          <p v-if="isSuperAdmin" class="text-red-500 dark:text-red-400 font-medium mb-4">⚠️ Superadmin 擁有所有權限，無法修改。</p>

          <div v-if="fetchPermsLoading" class="text-center text-slate-500 dark:text-slate-400 py-4">正在載入角色權限...</div>
          <div v-else class="space-y-4 max-h-96 overflow-y-auto pr-3">
            <div v-for="(group, groupName) in groupedPermissions" :key="groupName" class="p-4 border rounded-lg bg-slate-50 dark:bg-slate-700/50 shadow-sm border-slate-200 dark:border-slate-700">
              <h4 class="font-semibold text-lg mb-3 text-slate-800 dark:text-slate-100 capitalize border-b dark:border-slate-600 pb-2">{{ groupName }}</h4>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <label v-for="permission in group" :key="permission.id" class="flex items-center space-x-3 p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700 cursor-pointer">
                  <input
                    type="checkbox"
                    :value="permission.id"
                    v-model="rolePermissionIds"
                    :disabled="isSaving || isSuperAdmin"
                    class="h-5 w-5 rounded text-indigo-600 focus:ring-indigo-500 border-gray-300 dark:border-slate-600 dark:bg-slate-900 dark:focus:ring-offset-slate-800"
                  >
                  <span class="text-slate-700 dark:text-slate-200 text-sm">{{ permission.description || permission.name }}</span>
                </label>
              </div>
            </div>
            <div v-if="config.permissions.length === 0" class="text-slate-500 dark:text-slate-400">
              系統中沒有定義任何權限。
            </div>
          </div>
           <div class="mt-6 flex justify-end">
            <button
              @click="updatePermissions"
              :disabled="isSaving || isSuperAdmin || fetchPermsLoading"
              class="btn-primary"
            >
              <span v-if="isSaving">
                <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                儲存中...
              </span>
              <span v-else>儲存變更</span>
            </button>
          </div>
        </div>
        <div v-else class="flex items-center justify-center h-full bg-slate-50 dark:bg-slate-900/50 rounded-lg p-8">
          <p class="text-slate-500 dark:text-slate-400 text-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="mx-auto h-12 w-12 text-slate-400 dark:text-slate-500" fill="none" viewBox="0 0 24 24" stroke="currentColor" stroke-width="2"><path stroke-linecap="round" stroke-linejoin="round" d="M11 17l-5-5m0 0l5-5m-5 5h12" /></svg>
            <span class="mt-2 block font-medium">請從左側選擇一個角色以編輯其權限。</span>
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, watch } from 'vue';
import { configStore } from '@/store/config';
import { showToast } from '@/utils';
import { supabase } from '@/services/supabase';
// 直接使用 supabase client 進行更新，因為 updatePermissionsForRole 輔助函數在此不再必要
// import { updatePermissionsForRole } from '@/services/api/permissions'; // 移除

const config = configStore.state;

// 狀態管理
const isSaving = ref(false);
const selectedRole = ref(null); // 儲存完整的 role 物件 { id, name, description }
const rolePermissionIds = ref([]); // 只儲存 selectedRole 擁有的 permission ID 陣列
const initialLoadDone = ref(false);
const fetchPermsLoading = ref(false); // 新增：用於載入特定角色權限的 loading 狀態

const isSuperAdmin = computed(() => selectedRole.value?.name === 'superadmin');

// 排序角色 (保持不變)
const sortedRoles = computed(() => {
    return [...config.roles].sort((a, b) => {
        const order = { superadmin: 1, admin: 2, sdc: 3, sdsc: 4, inspector: 5 };
        const orderA = order[a.name] || 99;
        const orderB = order[b.name] || 99;
        if (orderA !== orderB) return orderA - orderB;
        return a.name.localeCompare(b.name);
    });
});

// 移除 userIsAdmin，由路由守衛處理

// 根據權限名稱分組 (保持不變)
const groupedPermissions = computed(() => {
  if (!config.permissions) return {};
  // 先按權限名稱排序
  const sortedPermissions = [...config.permissions].sort((a, b) => a.name.localeCompare(b.name));
  return sortedPermissions.reduce((acc, permission) => {
    // 嘗試用 ':' 分割，取第一部分作為組名，若無 ':' 則用 'general'
    const groupName = permission.name.includes(':') ? permission.name.split(':')[0] : 'general';
    if (!acc[groupName]) {
      acc[groupName] = [];
    }
    acc[groupName].push(permission);
    return acc;
  }, {});
});


// 移除 getRoleDescription，模板直接使用 role.description

// 獲取特定角色的權限 ID 列表 (保持不變)
const fetchPermissionsForRoleDirectly = async (roleId) => {
    if (!roleId) return [];
    const { data, error } = await supabase
        .from('role_permissions')
        .select('permission_id')
        .eq('role_id', roleId);

    if (error) {
        console.error("Failed to fetch role permissions:", error);
        throw error;
    }
    return data || [];
}


// --- 事件處理 ---

const selectRole = async (role) => {
  if (isSaving.value || fetchPermsLoading.value) return; // 防止重複點擊
  selectedRole.value = role; // 儲存完整的 role 物件
  rolePermissionIds.value = []; // 先清空

  if (role.name === 'superadmin') {
      // Superadmin 擁有所有權限 (直接從 config.permissions 獲取 ID)
      rolePermissionIds.value = config.permissions.map(p => p.id);
      return;
  }

  fetchPermsLoading.value = true; // 開始載入
  try {
      // 從數據庫獲取該角色的實際權限
      const permissionData = await fetchPermissionsForRoleDirectly(role.id);
      // 將返回的結構轉換為 ID 陣列
      rolePermissionIds.value = permissionData.map(p => p.permission_id);

  } catch (error) {
      showToast('讀取角色權限失敗，請稍後重試。', 'error');
      selectedRole.value = null; // 載入失敗時取消選中
  } finally {
      fetchPermsLoading.value = false; // 結束載入
  }
};

// 更新角色的權限列表 (使用 Upsert/Delete 策略) - 直接在此處實現
const updatePermissionsForRoleDirectly = async (roleId, permissionIds) => {
    // 1. 刪除該角色的所有現有權限
    const { error: deleteError } = await supabase
        .from('role_permissions')
        .delete()
        .eq('role_id', roleId);
    if (deleteError) throw deleteError;

    // 2. 插入新的權限列表 (如果有的話)
    if (permissionIds.length > 0) {
        const newLinks = permissionIds.map(pid => ({ role_id: roleId, permission_id: pid }));
        const { error: insertError } = await supabase
            .from('role_permissions')
            .insert(newLinks);
        if (insertError) throw insertError;
    }
    return true; // 表示成功
}


const updatePermissions = async () => {
  if (!selectedRole.value || isSuperAdmin.value || fetchPermsLoading.value) return;

  isSaving.value = true;
  try {
    const roleId = selectedRole.value.id;
    if (!roleId) {
        throw new Error('找不到角色 ID');
    }

    // 呼叫更新函數
    await updatePermissionsForRoleDirectly(roleId, rolePermissionIds.value);

    // 更新成功後，重新載入所有配置，確保權限更新反映在全域狀態中
    // 這裡 fetchConfig 會更新 configStore.state.rolePermissionsMap
    await configStore.fetchConfig();
    showToast(`角色 "${selectedRole.value.name}" 的權限已更新`, 'success');

  } catch (error) {
    showToast(`儲存權限失敗: ${error.message}`, 'error');
    // 儲存失敗，可以選擇重新載入當前角色的權限以顯示正確狀態
    if(selectedRole.value) {
        await selectRole(selectedRole.value); // 重新載入以回滾 UI 上的變更
    }
  } finally {
      isSaving.value = false;
  }
};


onMounted(async () => {
    // 確保 config (roles & permissions) 已載入
    const unwatch = watch(() => config.loading, (isLoading) => {
        if (!isLoading && config.roles.length > 0 && config.permissions.length > 0 && !initialLoadDone.value) {
            unwatch(); // 停止監聽
            // 預設選中排序後的第一個角色 (通常是 superadmin 或 admin)
            const defaultRole = sortedRoles.value[0];
            if (defaultRole) {
                selectRole(defaultRole);
            }
            initialLoadDone.value = true;
        } else if (!isLoading && (config.roles.length === 0 || config.permissions.length === 0)) {
            // 如果載入完成但缺少必要數據
            unwatch();
            initialLoadDone.value = true; // 標記完成，避免重複執行
            console.error("缺少角色或權限數據，無法預設選中角色。");
        }
    }, { immediate: true });
});
</script>

<style scoped>
.btn-primary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.max-h-96 {
    max-height: 24rem; /* 限制權限列表高度 */
}
/* 微調 checkbox 樣式 */
input[type="checkbox"] {
  @apply focus:ring-offset-0 focus:ring-2 dark:focus:ring-offset-slate-800;
}
</style>