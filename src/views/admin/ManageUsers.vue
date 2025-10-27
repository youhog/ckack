<!-- src/views/admin/ManageUsers.vue -->
<template>
  <div class="card p-6">
    <h3 class="text-xl font-semibold text-gray-800 mb-4">管理使用者帳號</h3>
     <p class="text-sm text-gray-500 mb-6">查看所有已註冊的使用者並指派角色 (`admin` 或 `inspector`)。</p>

     <div v-if="loading" class="text-center text-gray-500 dark:text-gray-400 py-8">載入使用者列表中...</div>
     <div v-else-if="error" class="text-center text-red-500 py-8">載入失敗: {{ error }}</div>
     <div v-else class="overflow-x-auto">
        <table class="w-full text-left text-sm">
            <thead class="bg-gray-50 dark:bg-slate-700">
                <tr>
                    <th class="px-4 py-3 font-medium">電子郵件</th>
                    <th class="px-4 py-3 font-medium">註冊時間</th>
                    <th class="px-4 py-3 font-medium">角色</th>
                    <th class="px-4 py-3 font-medium text-right">操作</th>
                </tr>
            </thead>
            <tbody>
                <tr v-if="users.length === 0">
                    <td colspan="4" class="text-center text-gray-500 dark:text-gray-400 py-6">找不到使用者。</td>
                </tr>
                <tr v-for="user in users" :key="user.id" class="border-b dark:border-slate-600 hover:bg-gray-50 dark:hover:bg-slate-700/50">
                    <td class="px-4 py-3">{{ user.email }}</td>
                    <td class="px-4 py-3">{{ new Date(user.created_at).toLocaleDateString('zh-TW') }}</td>
                    <td class="px-4 py-3">
                        <select
                          v-model="user.role"
                          @change="confirmRoleChange(user)"
                          class="form-control form-control-sm py-1"
                          :disabled="isSaving[user.id] || user.id === currentUserId"
                          :title="user.id === currentUserId ? '無法更改自己的角色' : '更改使用者角色'"
                        >
                            <option value="inspector">Inspector (檢查員)</option>
                            <option value="admin">Admin (管理員)</option>
                            <!-- 注意：無法將人設為 superadmin，這應在資料庫層級控制 -->
                        </select>
                    </td>
                     <td class="px-4 py-3 text-right">
                         <span v-if="isSaving[user.id]" class="text-xs text-gray-500 italic animate-pulse">儲存中...</span>
                         <!-- 刪除按鈕 (提示) -->
                         <button
                           class="btn btn-sm ml-2"
                           style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 4px 8px;"
                           title="刪除使用者功能需透過 Supabase Edge Function 或後台操作"
                           @click="showDeleteWarning"
                          >
                            刪除
                         </button>
                     </td>
                </tr>
            </tbody>
        </table>
     </div>

     <p class="text-xs text-gray-500 dark:text-gray-400 mt-4 italic">
         * 提示：刪除使用者功能涉及敏感操作，建議透過安全的後端 (Supabase Edge Function) 或直接在 Supabase 儀表板中進行。
     </p>

  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import { supabase } from '@/services/supabase'
import { userStore } from '@/store/user'
import { showToast } from '@/utils'

const loading = ref(true)
const error = ref(null)
const users = ref([]) // { id, email, created_at, role }
const isSaving = reactive({}) // 儲存每個 user 的保存狀態 { userId: true/false }
const currentUserId = userStore.state.user?.id; // 當前登入管理員的 ID

const fetchUsers = async () => {
    loading.value = true;
    error.value = null;
    console.log("ManageUsers: Fetching users...");

    // RLS 確保只有 admin 能執行此查詢
    // 從 profiles 查詢，並 JOIN user_roles 以獲取角色
    const { data, error: fetchError } = await supabase
        .from('profiles') // 從 profiles 開始查
        .select(`
            id,
            email,
            created_at,
            user_roles ( role )
        `)
        .order('created_at', { ascending: false });

    if (fetchError) {
        error.value = `載入使用者列表失敗: ${fetchError.message}`;
        console.error("Fetch users error:", fetchError);
        showToast(error.value, 'error');
    } else {
        // 整理資料，如果 user_roles 不存在或為空，預設為 inspector
        users.value = data.map(u => ({
            id: u.id,
            email: u.email,
            created_at: u.created_at,
            // user_roles 可能是一個空陣列 [] 或包含一個物件 [{ role: 'admin' }]
            role: u.user_roles && u.user_roles.length > 0 ? u.user_roles[0].role : 'inspector'
        }));
         console.log(`Fetched ${users.value.length} users.`);
    }
    loading.value = false;
};

// 元件掛載時獲取使用者列表
onMounted(fetchUsers);

// 確認角色更改
const confirmRoleChange = (user) => {
    // 從 users 陣列中找到原始 user object 以獲取更改前的角色
    const userInArray = users.value.find(u => u.id === user.id);
    if (!userInArray) return; // 防禦性檢查
    // 我們需要一個獨立變數儲存原始角色，因為 user.role 會被 v-model 立即更新
    let originalRole = 'inspector'; // 預設值
     const { data: currentRoleData, error: roleError } = supabase
        .from('user_roles')
        .select('role')
        .eq('user_id', user.id)
        .single()
        .then(({data, error}) => {
            if (!error && data) {
                originalRole = data.role;
            } else if (error && error.code !== 'PGRST116') { // PGRST116 = no rows found
                 console.error("獲取原始角色失敗:", error);
                 // 也可以顯示錯誤訊息
            }
            // 獲取到原始角色後再執行後續邏輯

            // 獲取 select 元素當前選擇的新角色
            const newRole = user.role; // v-model 已經更新了 user 物件上的 role

            // 如果角色沒有實際變化，則不執行任何操作
            if (newRole === originalRole) {
                console.log("角色未改變");
                return;
            }

            // 彈出確認框
            if (confirm(`確定要將使用者 ${user.email} 的角色從 "${originalRole}" 更改為 "${newRole}" 嗎？`)) {
                updateRole(user.id, newRole, originalRole); // 將 originalRole 傳遞下去以便回滾
            } else {
                // 使用者取消，將 user 物件上的 role 改回原來的角色，以同步 select 顯示
                console.log("使用者取消更改");
                user.role = originalRole;
                // 更新 users 陣列中的對應物件 (雖然 v-model 可能已經改了 user，但為了明確起見)
                userInArray.role = originalRole;
            }
        });
};


// 更新角色 (呼叫 RPC 函數)
const updateRole = async (userId, newRole, originalRole) => {
    // 再次檢查是否更改自己的角色
    if (userId === currentUserId) {
        showToast('無法更改自己的角色。', 'error');
        // 將 select 改回原始值
        const user = users.value.find(u => u.id === userId);
        if (user) user.role = originalRole; // 改回傳入的原始角色
        return;
    }

    isSaving[userId] = true;
    error.value = null; // 清除之前的錯誤訊息

    console.log(`Calling RPC update_user_role for user ${userId} to role ${newRole}`);

    const { error: rpcError } = await supabase.rpc('update_user_role', {
        target_user_id: userId,
        new_role: newRole
    });

    if (rpcError) {
        error.value = `更新角色失敗: ${rpcError.message}`;
        console.error("Update role RPC error:", rpcError);
        showToast(error.value, 'error');
        // 失敗時，將 select 的值改回原來的角色
        const user = users.value.find(u => u.id === userId);
        if (user) user.role = originalRole; // 改回傳入的原始角色

    } else {
        showToast(`使用者 ${users.value.find(u=>u.id===userId)?.email || userId} 的角色已更新為 ${newRole}`, 'success');
        // 成功後不需要手動改 user.role，因為 select 已經更新了
        // 更新 users 陣列中的角色以保持數據一致性
        const userInArray = users.value.find(u => u.id === userId);
        if (userInArray) userInArray.role = newRole;
    }
    isSaving[userId] = false;
};

// 顯示刪除警告
const showDeleteWarning = () => {
    alert('基於安全考量，刪除使用者功能應透過安全的後端 (例如 Supabase Edge Function) 或直接在 Supabase 儀表板操作。\n\n前端直接刪除使用者 (特別是使用 admin 權限) 存在安全風險。');
}

</script>

<style scoped>
/* 讓表格在小螢幕上可以滾動 */
.overflow-x-auto {
    overflow-x: auto;
}
table {
    min-width: 600px; /* 設定最小寬度以觸發滾動 */
}
/* 調整下拉選單樣式 */
select.form-control-sm {
    padding-top: 0.25rem;    /* 4px */
    padding-bottom: 0.25rem; /* 4px */
    padding-left: 0.5rem;   /* 8px */
    padding-right: 2rem;    /* 為下拉箭頭留出空間 */
    font-size: 0.875rem;    /* text-sm */
    min-width: 150px;       /* 讓下拉選單寬一點 */
    background-position: right 0.5rem center; /* 調整箭頭位置 */
    background-size: 16px 12px;
}
select:disabled {
    cursor: not-allowed;
    opacity: 0.7;
    background-color: #f3f4f6; /* light gray background */
}
.dark-theme select:disabled {
     background-color: #374151; /* darker gray for dark theme */
     color: #9ca3af; /* lighter text color */
}

/* 儲存中動畫 */
.animate-pulse {
  animation: pulse 1.5s cubic-bezier(0.4, 0, 0.6, 1) infinite;
}
@keyframes pulse {
  0%, 100% {
    opacity: 1;
  }
  50% {
    opacity: .5;
  }
}
</style>

