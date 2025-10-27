<script setup>
import { ref, onMounted, reactive } from 'vue'
import { supabase } from '@/services/supabase' //
import { userStore } from '@/store/user' //
import { showToast } from '@/utils' //

const loading = ref(true)
const error = ref(null)
const users = ref([]) // { id, email, created_at, role }
const isSaving = reactive({}) // 儲存每個 user 的保存狀態 { userId: true/false }
const currentUserId = userStore.state.user?.id; // 當前登入管理員的 ID

const fetchUsers = async () => {
    loading.value = true;
    error.value = null;
    console.log("ManageUsers: Fetching users (from profiles)...");

    // --- 【重大修改】 ---
    // 從 profiles 開始查詢，並 join user_roles
    // RLS 確保只有 admin 能執行此查詢
    const { data, error: fetchError } = await supabase
        .from('profiles') // <--- 從 profiles 開始
        .select(`
            id,
            email,
            created_at,
            user_roles ( role ) 
        `) // <--- Join user_roles
        .order('created_at', { ascending: false }); // 按 profiles 的 created_at 排序

    if (fetchError) {
        // 檢查是否因為 user_roles 關聯失敗
         if (fetchError.code === 'PGRST200') {
             error.value = `載入使用者列表失敗: 無法關聯 user_roles 表格。請檢查資料庫外鍵 user_roles.user_id -> auth.users.id 是否存在。(${fetchError.message})`;
         } else {
             error.value = `載入使用者列表失敗: ${fetchError.message}`;
         }
        console.error("Fetch users error:", fetchError);
        showToast(error.value, 'error');
    } else {
        // --- 【修改】整理資料 ---
        // user_roles 現在是一個陣列 (可能為空)
        users.value = data.map(u => ({
            id: u.id,
            email: u.email || 'N/A',
            created_at: u.created_at,
            // 從 user_roles 陣列中獲取 role，如果不存在或為空，預設 inspector
            role: u.user_roles && u.user_roles.length > 0 ? u.user_roles[0].role : 'inspector'
        }));
         console.log(`Fetched ${users.value.length} users.`);
    }
    loading.value = false;
};

// 元件掛載時獲取使用者列表
onMounted(fetchUsers);

// 確認角色更改 (async)
const confirmRoleChange = async (user) => {
    const userInArray = users.value.find(u => u.id === user.id);
    if (!userInArray) return;

    let originalRole = userInArray.role;
    const newRole = user.role; // v-model 已經更新

    if (newRole === originalRole) {
        console.log("角色未改變");
        return;
    }

    if (confirm(`確定要將使用者 ${user.email} 的角色從 "${originalRole}" 更改為 "${newRole}" 嗎？`)) {
        await updateRole(user.id, newRole, originalRole);
    } else {
        console.log("使用者取消更改");
        user.role = originalRole; // 改回 select 顯示
        userInArray.role = originalRole; // 確保陣列資料一致
    }
};


// 更新角色 (呼叫 RPC 函數) (async)
const updateRole = async (userId, newRole, originalRole) => {
    if (userId === currentUserId) {
        showToast('無法更改自己的角色。', 'error');
        const user = users.value.find(u => u.id === userId);
        if (user) user.role = originalRole;
        return;
    }

    isSaving[userId] = true;
    error.value = null;

    console.log(`Calling RPC update_user_role for user ${userId} to role ${newRole}`);

    const { error: rpcError } = await supabase.rpc('update_user_role', {
        target_user_id: userId,
        new_role: newRole
    });

    if (rpcError) {
        error.value = `更新角色失敗: ${rpcError.message}`;
        console.error("Update role RPC error:", rpcError);
        showToast(error.value, 'error');
        // 失敗時改回原值
        const user = users.value.find(u => u.id === userId);
        if (user) user.role = originalRole;

    } else {
        showToast(`使用者 ${users.value.find(u=>u.id===userId)?.email || userId} 的角色已更新為 ${newRole}`, 'success');
        // 更新陣列資料
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