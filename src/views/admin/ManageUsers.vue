// youhog/ckack/ckack-RBAC-creat/src/views/admin/ManageUsers.vue
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
            <td data-label="註冊時間" class="px-6 py-4 whitespace-nowrap text-sm text-slate-500 dark:text-slate-400">{{ user.created_at ? new Date(user.created_at).toLocaleDateString('zh-TW') : '未知' }}</td>
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
import { supabase } from '@/services/supabase' //
import { userStore } from '@/store/user' //
import { configStore } from '@/store/config' //
import { showToast } from '@/utils' //

const loading = ref(true) //
const error = ref(null) //
const users = ref([]) //
const isSaving = reactive({}) //
const currentUserId = userStore.state.user?.id; //
const config = configStore.state; //

const localAvailableRoles = ref([]); //

const availableRoles = computed(() => { //
    // 從 configStore.roles 獲取，因為它現在是權威來源
    return config.roles.map(r => r.name).sort(); //
});

const fetchUsers = async () => { //
    loading.value = true; //
    error.value = null; //

    // 確保 configStore 已經獲取了 roles
    if (config.roles.length === 0) { //
        await configStore.fetchConfig(); //
    }
    // 將 config.roles 賦值給 localAvailableRoles (雖然 template 直接用 computed 的 availableRoles)
    localAvailableRoles.value = config.roles; //

    console.log("ManageUsers: Fetching users with roles..."); //

    try {
        // 1. Fetch User Profiles
        // 注意: profiles.created_at 是 profile 記錄創建時間，可能與用戶註冊時間(auth.users.created_at)不同
        const { data: profilesData, error: profilesError } = await supabase //
            .from('profiles') //
            .select(`id, email, created_at`) // created_at here is from profiles table //
            .order('email', { ascending: true }); //

        if (profilesError) throw profilesError; //
        if (!profilesData) throw new Error("無法獲取使用者 Profile 資料。"); // 新增檢查

         // 2. Fetch all User Roles
        const { data: rolesData, error: rolesError } = await supabase //
            .from('user_roles') //
            .select(`user_id, role`); //

        if (rolesError) throw rolesError; //
        if (!rolesData) throw new Error("無法獲取使用者角色資料。"); // 新增檢查

        console.log("Fetched Profiles:", profilesData); //
        console.log("Fetched Roles:", rolesData); //

        // 3. Merge data
        const rolesMap = new Map((rolesData || []).map(r => [r.user_id, r.role])); //
        console.log("Created Roles Map:", rolesMap); //

        const mergedUsers = profilesData.map(p => { //
             const userRoleFromMap = rolesMap.get(p.id); //
             let determinedRole; //

             if (userRoleFromMap) { //
                 determinedRole = userRoleFromMap; //
             } else {
                 // Log specifically when a role is NOT found in the map
                 console.warn(`[ManageUsers] 警告：在 user_roles 表中找不到使用者 ${p.email} (ID: ${p.id}) 的角色記錄。將預設為 'inspector'。請檢查資料庫。`); //
                 determinedRole = 'inspector'; // Apply default //
             }

             // --- Specific log for the user in question ---
             if (p.email === 'demo@hyou.eu.org') { //
                  console.log(`[ManageUsers DEBUG] 正在處理 demo@hyou.eu.org (ID: ${p.id}): 從 Map 獲取的角色 = ${userRoleFromMap}, 最終判定的角色 = ${determinedRole}`); //
             }
             // --- End log ---

             return { //
                 id: p.id, //
                 email: p.email || 'N/A', //
                 created_at: p.created_at, // Using profiles.created_at (profile creation time)
                 currentRole: determinedRole, //
                 newRole: determinedRole, //
                 isDirty: false, //
             };
        });

        users.value = mergedUsers; //
        console.log(`[ManageUsers] 成功合併 ${users.value.length} 位使用者資料。`); //

    } catch (fetchError) {
        error.value = `載入使用者列表失敗: ${fetchError.message}`; //
        console.error("[ManageUsers] Fetch users error:", fetchError); //
        showToast(error.value, 'error'); //
    }

    loading.value = false; //
};


onMounted(() => { //
    fetchUsers(); //
});


const canEditRole = (user) => { //
    // 檢查當前登入者是否為 'admin' 或 'superadmin' (理論上 superadmin 也應該能改，但題目要求 admin)
    // 根據 userStore.state.role 判斷
    const currentUserRole = userStore.state.role;
    if (currentUserRole !== 'admin' && currentUserRole !== 'superadmin') {
        // console.log(`[canEditRole] Denied: Current user role (${currentUserRole}) is not admin or superadmin.`);
        return false;
    }

    // 不能修改自己
    if (user.id === currentUserId) {
        // console.log(`[canEditRole] Denied: Cannot edit own role (User ID: ${user.id}).`);
        return false;
    }

    // 不能修改 superadmin (如果目標用戶是 superadmin)
    if (user.currentRole === 'superadmin') {
        // console.log(`[canEditRole] Denied: Cannot edit superadmin role (User ID: ${user.id}).`);
        return false;
    }

    // console.log(`[canEditRole] Allowed for user ${user.email}`);
    return true; //
};

const updateRole = async (user) => { //
    if (!canEditRole(user) || !user.isDirty) { //
        console.log(`[updateRole] Skipped for ${user.email}. Can edit: ${canEditRole(user)}, Is dirty: ${user.isDirty}`);
        return; //
    }

    const originalRole = user.currentRole; //

    // 彈出確認框
    if (confirm(`確定要將使用者 ${user.email} 的角色從 "${user.currentRole}" 更改為 "${user.newRole}" 嗎？`)) { //
        isSaving[user.id] = true; //
        error.value = null; //

        console.log(`[ManageUsers] Calling RPC update_user_role for user ${user.id} to role ${user.newRole}`); //

        const { error: rpcError } = await supabase.rpc('update_user_role', { //
            target_user_id: user.id, //
            new_role: user.newRole //
        });

        if (rpcError) { //
            error.value = `更新角色失敗: ${rpcError.message}`; //
            console.error("[ManageUsers] Update role RPC error:", rpcError); //
            showToast(error.value, 'error'); //

            // 恢復原始狀態
            user.newRole = originalRole; //
            user.isDirty = false; //

        } else {
            showToast(`使用者 ${user.email} 的角色已更新為 ${user.newRole}`, 'success'); //

            // 更新原始狀態和 dirty 標誌
            user.currentRole = user.newRole; //
            user.isDirty = false; //
             // 可能需要考慮是否重新 fetchUsers() 來確保完全同步，但通常這樣更新本地狀態即可
        }
        isSaving[user.id] = false; //
    } else {
        // 使用者取消，恢復 newRole 狀態
        console.log(`[ManageUsers] Role update for ${user.email} cancelled by user.`);
        user.newRole = originalRole; //
        user.isDirty = false; //
    }
};
</script>

<style scoped>
.form-control {
  @apply px-3 py-1.5 rounded-md border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm; /* */
  @apply focus:outline-none focus:border-blue-500 focus:ring-1 focus:ring-blue-500; /* */
  @apply disabled:opacity-60 disabled:cursor-not-allowed; /* */
}
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-md font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-sm hover:shadow disabled:opacity-60 disabled:cursor-not-allowed; /* */
}
.btn-sm {
  @apply px-3 py-1 text-xs; /* */
}

/* Responsive Table Styles (Optional but recommended) */
@media (max-width: 768px) {
  thead {
    display: none;
  }
  tbody tr {
    @apply block mb-4 border dark:border-slate-700 rounded-lg shadow-sm;
  }
  tbody td {
    @apply flex justify-between items-center px-4 py-3 border-b dark:border-slate-700;
    text-align: right;
  }
   tbody tr td:last-child {
      border-bottom: 0;
   }
  tbody td::before {
    content: attr(data-label);
    font-weight: bold;
    text-align: left;
    margin-right: 1rem;
    @apply text-slate-500 dark:text-slate-400 text-xs uppercase tracking-wider;
  }
  tbody td select {
     /* Adjust select width on mobile if needed */
     width: auto;
     max-width: 50%; /* Example */
  }
  tbody td span.italic {
     margin-left: 0.5rem; /* Adjust spacing */
  }
  tbody td button {
    /* Ensure button fits */
  }
}

</style>