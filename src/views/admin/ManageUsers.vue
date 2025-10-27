<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理使用者</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">檢視系統中的所有使用者並管理他們的角色。</p>

    <div class="mb-6 p-4 bg-yellow-50 dark:bg-yellow-500/10 border-l-4 border-yellow-400 dark:border-yellow-600 text-yellow-800 dark:text-yellow-200 text-sm">
      <p><strong>注意：</strong>基於安全考量，刪除使用者功能應透過安全的後端 (例如 Supabase Edge Function) 或直接在 Supabase 儀表板操作。前端直接刪除使用者 (特別是使用 admin 權限) 存在安全風險。</p>
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
            <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-slate-900 dark:text-slate-100">{{ user.email }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">{{ new Date(user.created_at).toLocaleDateString('zh-TW') }}</td>
            <td class="px-6 py-4 whitespace-nowrap text-sm">
              <select 
                v-model="user.role" 
                @change="confirmRoleChange(user)" 
                class="form-control py-1 px-3 w-auto"
                :disabled="user.id === currentUserId || isSaving[user.id]"
                :class="{ 'opacity-50 cursor-not-allowed': user.id === currentUserId }"
                title="更改角色"
              >
                <option value="inspector">Inspector</option>
                <option value="admin">Admin</option>
              </select>
            </td>
            <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
               <button 
                @click="updateRole(user.id, user.role, users.find(u => u.id === user.id)?.role)" 
                class="btn-primary btn-sm" 
                v-if="!isSaving[user.id]"
                :disabled="user.id === currentUserId"
               >
                 保存
               </button>
               <span v-if="isSaving[user.id]" class="text-xs text-slate-500 italic">保存中...</span>
               <span v-if="user.id === currentUserId" class="text-xs text-slate-400 italic ml-2">(自己)</span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import { supabase } from '@/services/supabase' //
import { userStore } from '@/store/user' //
import { showToast } from '@/utils' //

// --- (所有 <script> 邏輯保持不變) ---
const loading = ref(true)
const error = ref(null)
const users = ref([]) 
const isSaving = reactive({}) 
const currentUserId = userStore.state.user?.id; //

const fetchUsers = async () => {
    loading.value = true;
    error.value = null;
    console.log("ManageUsers: Fetching users (from profiles)...");

    const { data, error: fetchError } = await supabase //
        .from('profiles') //
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
        showToast(error.value, 'error'); //
    } else {
        users.value = data.map(u => ({
            id: u.id,
            email: u.email || 'N/A',
            created_at: u.created_at,
            role: u.user_roles && u.user_roles.length > 0 ? u.user_roles[0].role : 'inspector'
        }));
         console.log(`Fetched ${users.value.length} users.`);
    }
    loading.value = false;
};

onMounted(fetchUsers);

const confirmRoleChange = async (user) => {
    const userInArray = users.value.find(u => u.id === user.id);
    if (!userInArray) return;

    let originalRole = userInArray.role;
    const newRole = user.role; 

    if (newRole === originalRole) {
        console.log("角色未改變");
        return;
    }

    if (confirm(`確定要將使用者 ${user.email} 的角色從 "${originalRole}" 更改為 "${newRole}" 嗎？`)) {
        await updateRole(user.id, newRole, originalRole);
    } else {
        console.log("使用者取消更改");
        user.role = originalRole; 
        userInArray.role = originalRole; 
    }
};

const updateRole = async (userId, newRole, originalRole) => {
    if (userId === currentUserId) {
        showToast('無法更改自己的角色。', 'error'); //
        const user = users.value.find(u => u.id === userId);
        if (user) user.role = originalRole;
        return;
    }

    isSaving[userId] = true;
    error.value = null;

    console.log(`Calling RPC update_user_role for user ${userId} to role ${newRole}`);

    const { error: rpcError } = await supabase.rpc('update_user_role', { //
        target_user_id: userId,
        new_role: newRole
    });

    if (rpcError) {
        error.value = `更新角色失敗: ${rpcError.message}`;
        console.error("Update role RPC error:", rpcError);
        showToast(error.value, 'error'); //
        const user = users.value.find(u => u.id === userId);
        if (user) user.role = originalRole;

    } else {
        showToast(`使用者 ${users.value.find(u=>u.id===userId)?.email || userId} 的角色已更新為 ${newRole}`, 'success'); //
        const userInArray = users.value.find(u => u.id === userId);
        if (userInArray) userInArray.role = newRole;
    }
    isSaving[userId] = false;
};

const showDeleteWarning = () => {
    alert('基於安全考量，刪除使用者功能應透過安全的後端 (例如 Supabase Edge Function) 或直接在 Supabase 儀表板操作。\n\n前端直接刪除使用者 (特別是使用 admin 權限) 存在安全風險。');
}

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