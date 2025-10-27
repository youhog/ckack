<template>
  <div class="p-6 bg-white dark:bg-slate-800 rounded-2xl shadow-lg">
    <h2 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-6">角色與權限管理</h2>
    
    <div v-if="!userIsAdmin" class="text-center py-8 text-red-500 dark:text-red-400">
      <p>❌ 權限不足：您必須具備 'admin' 角色才能訪問此頁面。</p>
      <p class="text-sm text-slate-500 dark:text-slate-400 mt-2">請聯繫系統管理員。</p>
    </div>

    <div v-else-if="config.loading" class="text-center py-8 text-slate-500 dark:text-slate-400">正在載入角色和權限配置...</div>

    <div v-else-if="config.roles.length === 0" class="text-center py-8 text-red-500 dark:text-red-400">
        <p>錯誤：無法從資料庫載入角色列表。請檢查 `roles` 表格中是否有數據。</p>
    </div>

    <div v-else class="flex flex-col md:flex-row gap-8">
      <div class="md:w-1/3">
        <h3 class="text-lg font-semibold mb-3 text-slate-700 dark:text-slate-300">角色列表 ({{ sortedRoles.length }} 個)</h3>
        <div class="space-y-2">
          <div 
            v-for="role in sortedRoles" 
            :key="role.name"
            @click="selectRole(role)"
            :class="['p-3 rounded-lg cursor-pointer transition-all duration-200 border', 
                     selectedRole?.name === role.name ? 'bg-indigo-100 dark:bg-indigo-900/50 border-indigo-500 shadow-md' : 'bg-slate-50 dark:bg-slate-700/50 hover:bg-slate-100 dark:hover:bg-slate-700 border-slate-200 dark:border-slate-700']"
          >
            <p class="font-bold text-slate-800 dark:text-slate-100">{{ role.name }}</p>
            <p class="text-xs text-slate-500 dark:text-slate-400">{{ getRoleDescription(role.name) }}</p>
          </div>
        </div>
      </div>

      <div class="md:w-2/3">
        <div v-if="selectedRole">
          <h3 class="text-lg font-semibold mb-4 text-slate-700 dark:text-slate-300">
            編輯角色 <span class="font-bold text-blue-600 dark:text-blue-400">"{{ selectedRole.name }}"</span> 的權限
          </h3>
          <p v-if="isSuperAdmin" class="text-red-500 dark:text-red-400 font-medium mb-4">⚠️ Superadmin 擁有所有權限，無法修改。</p>

          <div class="space-y-4 max-h-96 overflow-y-auto pr-3">
            <div v-for="(group, groupName) in groupedPermissions" :key="groupName" class="p-4 border rounded-lg bg-slate-50 dark:bg-slate-700/50 shadow-sm border-slate-200 dark:border-slate-700">
              <h4 class="font-semibold text-lg mb-3 text-slate-800 dark:text-slate-100 capitalize border-b dark:border-slate-600 pb-2">{{ groupName }}</h4>
              <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
                <label v-for="permission in group" :key="permission.id" class="flex items-center space-x-3 p-2 rounded-md hover:bg-slate-100 dark:hover:bg-slate-700 cursor-pointer">
                  <input 
                    type="checkbox"
                    :value="permission.id"
                    v-model="rolePermissionIds"
                    :disabled="isSaving || isSuperAdmin"
                    class="h-5 w-5 rounded text-indigo-600 focus:ring-indigo-500 border-gray-300"
                  >
                  <span class="text-slate-700 dark:text-slate-200 text-sm">{{ permission.description || permission.name }}</span>
                </label>
              </div>
            </div>
          </div>
           <div class="mt-6 flex justify-end">
            <button 
              @click="updatePermissions" 
              :disabled="isSaving || isSuperAdmin"
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
import { updatePermissionsForRole } from '@/services/api/permissions'; 
import { userStore } from '@/store/user'; // ADDED: 引入 userStore

const config = configStore.state; 

// 狀態管理
const isSaving = ref(false);
const selectedRole = ref(null);
const rolePermissionIds = ref([]); // 只儲存 selectedRole 擁有的 permission ID 陣列
const initialLoadDone = ref(false);

const isSuperAdmin = computed(() => selectedRole.value?.name === 'superadmin');
const sortedRoles = computed(() => {
    // 排序角色，讓 admin 和 inspector 靠前
    return [...config.roles].sort((a, b) => {
        if (a.name === 'admin') return -1;
        if (b.name === 'admin') return 1;
        if (a.name === 'inspector') return -1;
        if (b.name === 'inspector') return 1;
        return a.name.localeCompare(b.name);
    });
});

// ADDED: 檢查用戶是否是管理員 (用於模板層的防護)
const userIsAdmin = computed(() => userStore.state.role === 'admin');

// 根據權限名稱分組 (例如 'reports:view' -> 'reports')
const groupedPermissions = computed(() => {
  if (!config.permissions) return {};
  return config.permissions.reduce((acc, permission) => {
    const groupName = permission.name.split(':')[0];
    if (!acc[groupName]) {
      acc[groupName] = [];
    }
    acc[groupName].push(permission);
    return acc;
  }, {});
});

// 獲取角色描述的輔助函數 
const getRoleDescription = (roleName) => {
    // 這是硬編碼的範例描述，因為 config.roles 只有 name
    switch(roleName) {
        case 'superadmin': return '超級管理員，擁有所有權限且不可修改';
        case 'admin': return '擁有所有管理權限';
        case 'inspector': return '檢查員，只能進行檢查和查看自己的報告';
        case 'sdc': return '宿委會，中等管理權限';
        case 'sdsc': return '宿服，僅供查看權限';
        default: return '系統定義角色';
    }
}

// 獲取特定角色的權限 ID 列表
const fetchPermissionsForRole = async (roleName) => {
    // 1. 查找角色的 UUID
    const role = config.roles.find(r => r.name === roleName);
    if (!role) {
         return [];
    }
    const roleId = role.id;

    // 2. 獲取該角色的權限
    const { data: permsData, error: permsError } = await supabase
        .from('role_permissions')
        .select('permission_id')
        .eq('role_id', roleId);
        
    if (permsError) {
        console.error("Failed to fetch role permissions:", permsError);
        throw permsError;
    }
    return permsData;
}


// --- 事件處理 ---

const selectRole = async (role) => {
  if (isSaving.value) return;
  selectedRole.value = role;
  
  if (role.name === 'superadmin') {
      // Superadmin 擁有所有權限
      rolePermissionIds.value = config.permissions.map(p => p.id);
      return;
  }
  
  isSaving.value = true;
  try {
      // 從數據庫獲取該角色的實際權限
      const permissionData = await fetchPermissionsForRole(role.name);
      // MODIFIED: 將返回的結構轉換為 ID 陣列
      rolePermissionIds.value = permissionData.map(p => p.permission_id);
      
  } catch (error) {
      showToast('讀取權限失敗，請檢查資料庫。', 'error');
  } finally {
      isSaving.value = false;
  }
};

const updatePermissions = async () => {
  if (!selectedRole.value || isSuperAdmin.value) return;

  isSaving.value = true;
  try {
    // 查找角色 ID
    const role = config.roles.find(r => r.name === selectedRole.value.name); 
    
    if (!role) {
        throw new Error('找不到角色 ID');
    }
    const roleId = role.id;

    // 呼叫 API 函數進行更新
    await updatePermissionsForRole(roleId, rolePermissionIds.value); 

    // 重新載入所有配置，確保權限更新反映在全域狀態中
    await configStore.fetchConfig(); 
    showToast(`角色 "${selectedRole.value.name}" 的權限已更新`, 'success');
  } catch (error) {
    showToast(`儲存權限失敗: ${error.message}`, 'error');
    // 儲存失敗，重新獲取一次資料庫狀態來覆蓋當前錯誤狀態
    await selectRole(selectedRole.value); 
  } finally {
      isSaving.value = false;
  }
};


onMounted(async () => {
  // 等待 config.roles 載入後，預設選中第一個角色
  watch(() => config.roles, (newRoles) => {
      if (newRoles.length > 0 && !initialLoadDone.value) {
          // 確保 config.permissions 也已載入
          if (config.permissions.length === 0) return; 

          // 預設選中 'admin' 或 'inspector'
          const defaultRole = newRoles.find(r => r.name === 'admin' || r.name === 'inspector') || newRoles[0];
          selectRole(defaultRole);
          initialLoadDone.value = true;
      }
  }, { immediate: true });
});
</script>

<style scoped>
.btn-primary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.max-h-96 {
    max-height: 24rem;
}
</style>