// youhog/ckack/ckack-10cc0a3bfb263ad24e91487d07fabdff03536175/src/views/admin/ManageUsers.vue
<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理使用者</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">檢視系統中的所有使用者並管理他們的角色。只有 `admin` 才能更改角色。</p>

    <div class="mb-6 p-4 bg-yellow-50 dark:bg-yellow-500/10 border-l-4 border-yellow-400 dark:border-yellow-600 text-yellow-800 dark:text-yellow-200 text-sm">
      <p><strong>注意：</strong>基於安全考量，刪除使用者功能應透過安全的後端 (例如 Supabase Edge Function) 或直接在 Supabase 儀表板操作。</p>
      <p class="mt-1">您**無法**透過前端修改自己的角色。</p>
    </div>

    <div v-if="loading" class="text-center text-slate-500 dark:text-slate-400 py-8">載入使用者列表中...</div>
    <div v-else-if="error" class="text-center text-red-500 py-8">{{ error }}</div>
    <div v-else-if="users.length === 0" class="text-center text-slate-500 dark:text-slate-400 py-8">
      找不到使用者。
    </div>
    <div v-else class="overflow-x-auto">
      <table class="min-w-full divide-y divide-slate-200 dark:divide-slate-700">
        <thead class="bg-slate-50 dark:bg-slate-900/50">
          <tr>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">Email</th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">註冊時間</th>
            <th scope="col" class="px-6 py-3 text-left text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">角色</th>
            <th scope="col" class="px-6 py-3 text-right text-xs font-medium text-slate-500 dark:text-slate-400 uppercase tracking-wider">操作</th>
          </tr>
        </thead>
        <tbody class="bg-white dark:bg-slate-800 divide-y divide-slate-200 dark:divide-slate-700">
          <tr v-for="user in users" :key="user.id" class="hover:bg-slate-50 dark:hover:bg-slate-700/50 transition-colors">
            <td data-label="Email" class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900 dark:text-slate-100">{{ user.email }}</td>
            <td data-label="註冊時間" class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">{{ new Date(user.created_at).toLocaleDateString('zh-TW') }}</td>
            <td data-label="角色" class="px-6 py-4 whitespace-nowrap text-sm">
              <select 
                v-model="user.newRole" 
                @change="user.isDirty = true"
                class="form-control py-1 px-3 w-auto"
                :disabled="!canEditRole(user) || isSaving[user.id]"
                :class="{ 'opacity-50 cursor-not-allowed': !canEditRole(user) }"
                title="更改角色"
              >
                <option 
                    v-for="role in availableRoles"
                    :key="role" 
                    :value="role"
                >
                    {{ role }}
                </option>
              </select>
              <span v-if="!canEditRole(user) && user.id === currentUserId" class="text-xs text-slate-400 italic ml-2">(自己)</span>
              <span v-else-if="!canEditRole(user) && user.currentRole === 'superadmin'" class="text-xs text-slate-400 italic ml-2">(Superadmin)</span>
            </td>
            <td data-label="操作" class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
               <button 
                @click="updateRole(user)" 
                class="btn-primary btn-sm" 
                v-if="user.isDirty && !isSaving[user.id]"
                :disabled="!canEditRole(user)"
               >
                 保存
               </button>
               <span v-if="isSaving[user.id]" class="text-xs text-slate-500 italic">保存中...</span>
               <span v-else-if="!user.isDirty" class="text-xs text-slate-400 italic">已保存</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive, computed } from 'vue'
import { supabase } from '@/services/supabase' 
import { userStore } from '@/store/user' 
import { configStore } from '@/store/config' 
import { showToast } from '@/utils' 

const loading = ref(true)
const error = ref(null)
const users = ref([]) 
const isSaving = reactive({}) 
const currentUserId = userStore.state.user?.id; 
const config = configStore.state; 

const availableRoles = computed(() => { 
    // MODIFIED: 確保 roles 被載入後才能使用
    return config.roles.length > 0 
        ? config.roles.map(r => r.name).sort() 
        : ['admin', 'inspector']; // Fallback
});

const fetchUsers = async () => {
    loading.value = true;
    error.value = null;
    
    // MODIFIED: 確保角色列表已載入
    if (config.roles.length === 0) {
        await fetchAllRoles(); 
    }

    console.log("ManageUsers: Fetching users (from profiles)...");

    const { data, error: fetchError } = await supabase
        .from('profiles')
        .select(`
            id,
            email,
            created_at,
            user_roles ( role ) 
        `) 
        .order('created_at', { ascending: false }); 

    if (fetchError) {
         if (fetchError.code === 'PGRST200') {
             error.value = `載入使用者列表失敗: 無法關聯 user_roles 表格。請檢查資料庫外鍵 user_roles.user_id -> auth.users.id 是否存在。(${fetchError.message})`;
         } else {
             error.value = `載入使用者列表失敗: ${fetchError.message}`;
         }
        console.error("Fetch users error:", fetchError);
        showToast(error.value, 'error'); 
    } else {
        users.value = data.map(u => ({
            id: u.id,
            email: u.email || 'N/A',
            created_at: u.created_at,
            currentRole: u.user_roles && u.user_roles.length > 0 ? u.user_roles[0].role : 'inspector',
            newRole: u.user_roles && u.user_roles.length > 0 ? u.user_roles[0].role : 'inspector',
            isDirty: false,
        }));
         console.log(`Fetched ${users.value.length} users.`);
    }
    loading.value = false;
};

// ADDED: 輔助函式，從 DB 載入所有角色 (因為 configStore 預設只載入 Checklist 和 Zones)
const fetchAllRoles = async () => {
    try {
        const { data, error } = await supabase.from('user_roles').select('role');
        if (error) throw error;
        // 提取所有不重複的角色名稱
        const uniqueRoles = [...new Set(data.map(r => r.role))].map(role => ({ name: role }));
        config.roles = uniqueRoles; 
    } catch (e) {
        console.error("Failed to load roles for select box:", e);
    }
};

onMounted(() => {
    // 確保 config.roles 在 mounted 時被載入，即使 configStore 沒有預載入
    if (config.roles.length === 0) {
        fetchAllRoles(); 
    }
    fetchUsers();
});


const canEditRole = (user) => {
    // 檢查當前登入者是否為 'admin'
    if (userStore.state.role !== 'admin') {
        return false;
    }
    
    // admin 不能修改自己
    if (user.id === currentUserId) {
        return false;
    }
    
    // admin 不能修改 superadmin (如果您的 DB 有 superadmin 角色)
    if (user.currentRole === 'superadmin') {
        return false;
    }

    return true;
};

const updateRole = async (user) => {
    if (!canEditRole(user) || !user.isDirty) {
        return;
    }

    const originalRole = user.currentRole;

    if (confirm(`確定要將使用者 ${user.email} 的角色從 "${user.currentRole}" 更改為 "${user.newRole}" 嗎？`)) {
        isSaving[user.id] = true;
        error.value = null;

        console.log(`Calling RPC update_user_role for user ${user.id} to role ${user.newRole}`);

        const { error: rpcError } = await supabase.rpc('update_user_role', { 
            target_user_id: user.id,
            new_role: user.newRole
        });

        if (rpcError) {
            error.value = `更新角色失敗: ${rpcError.message}`;
            console.error("Update role RPC error:", rpcError);
            showToast(error.value, 'error'); 
            
            // 恢復原始狀態
            user.newRole = originalRole;
            user.isDirty = false;

        } else {
            showToast(`使用者 ${user.email} 的角色已更新為 ${user.newRole}`, 'success'); 
            
            // 更新原始狀態和 dirty 標誌
            user.currentRole = user.newRole;
            user.isDirty = false;
        }
        isSaving[user.id] = false;
    } else {
        // 使用者取消，恢復 newRole 狀態
        user.newRole = originalRole;
        user.isDirty = false;
    }
};
</script>

<style scoped>
.form-control {
  @apply px-3 py-1.5 rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500;
  @apply disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-md font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-sm hover:shadow disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-sm {
  @apply px-3 py-1 text-xs;
}
</style>