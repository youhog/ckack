// src/store/config.js
import { reactive, readonly } from 'vue'
import { supabase } from '../services/supabase'
import { userStore } from './user' // 載入 userStore 以便在 helper 中使用

const state = reactive({
  zones: [],
  // rooms: [], // 已移除
  checkTypes: [],
  checklistCategories: [],
  checklistItems: [],
  roles: [], // 包含 { id, name, description }
  permissions: [], // 包含 { id, name, description }
  rolePermissionsMap: new Map(), // 新增: Map<role_name, Set<permission_name>>
  loading: false,
  error: null
})

// 從 Supabase 獲取所有應用程式設定
const fetchConfig = async () => {
  state.loading = true
  state.error = null
  console.log("正在從 Supabase 載入設定 (包含 RBAC)...");

  try {
    // 併發獲取所有需要的資料
    const [zonesRes, typesRes, categoriesRes, itemsRes, rolesRes, permsRes, rolePermsRes] = await Promise.all([
      supabase.from('dorm_zones').select('id, name, description').order('name'),
      supabase.from('check_types').select('id, name, description').order('name'),
      supabase.from('checklist_categories').select('id, name, icon, display_order').order('display_order'), // 包含 display_order
      supabase.from('checklist_items').select('id, category_id, name, display_order').order('display_order'), // 包含 display_order
      supabase.from('roles').select('id, name, description').order('name'),
      supabase.from('permissions').select('id, name, description').order('name'),
      supabase.from('role_permissions').select('role_id, permission_id') // 獲取角色權限關聯
    ]);

    // 統一檢查錯誤
    const checkError = (res, name) => {
        if (res.error) throw new Error(`載入 ${name} 失敗: ${res.error.message}`);
        return res.data || []; // 確保返回陣列
    };

    state.zones = checkError(zonesRes, '區域');
    state.checkTypes = checkError(typesRes, '類型');
    state.checklistCategories = checkError(categoriesRes, '分類');
    state.checklistItems = checkError(itemsRes, '項目');
    state.roles = checkError(rolesRes, '角色'); // 角色很重要
    state.permissions = checkError(permsRes, '權限'); // 權限很重要
    const rolePermLinks = checkError(rolePermsRes, '角色權限關聯'); // 關聯很重要

    // --- 建立 rolePermissionsMap ---
    state.rolePermissionsMap.clear();
    // 只有在 roles 和 permissions 成功載入後才建立 Map
    if (state.roles.length > 0 && state.permissions.length > 0) {
        const roleIdToName = new Map(state.roles.map(r => [r.id, r.name]));
        const permissionIdToName = new Map(state.permissions.map(p => [p.id, p.name]));

        rolePermLinks.forEach(link => {
            const roleName = roleIdToName.get(link.role_id);
            const permissionName = permissionIdToName.get(link.permission_id);

            if (roleName && permissionName) {
                if (!state.rolePermissionsMap.has(roleName)) {
                    state.rolePermissionsMap.set(roleName, new Set());
                }
                state.rolePermissionsMap.get(roleName).add(permissionName);
            }
        });
        console.log("Role Permissions Map 建立完成，包含", state.rolePermissionsMap.size, "個角色。");
    } else {
        console.warn("因角色或權限列表載入失敗，無法建立 Role Permissions Map。");
        // 可以考慮在此處設置一個錯誤狀態或拋出錯誤，取決於應用程式的容錯需求
        if (state.roles.length === 0) throw new Error("角色列表為空，無法繼續初始化權限。");
        if (state.permissions.length === 0) throw new Error("權限列表為空，無法繼續初始化權限。");
    }
    // --- Map 建立完成 ---


    console.log("設定載入成功:", {
        zones: state.zones.length,
        types: state.checkTypes.length,
        categories: state.checklistCategories.length,
        items: state.checklistItems.length,
        roles: state.roles.length,
        permissions: state.permissions.length,
        rolePermMapSize: state.rolePermissionsMap.size
    });

  } catch (error) {
    state.error = error.message
    console.error("載入設定時發生嚴重錯誤:", error);
    // 考慮是否需要清除部分狀態或顯示更嚴重的錯誤訊息
    state.rolePermissionsMap.clear(); // 清除可能不完整的 Map
  } finally {
    state.loading = false
  }
}

// 清空本地快取的設定
const clearConfig = () => {
  state.zones = [];
  state.checkTypes = [];
  state.checklistCategories = [];
  state.checklistItems = [];
  state.roles = [];
  state.permissions = [];
  state.rolePermissionsMap.clear(); // 清空 Map
  state.error = null;
}

// --- 權限檢查輔助函數 ---
const userHasPermission = (permissionName) => {
    // 1. 立即檢查 config 是否處於錯誤狀態
    if (state.error) {
        // console.error("Config store 處於錯誤狀態，無法檢查權限:", permissionName);
        return false;
    }
    // 2. 檢查 config 是否仍在載入中
    if (state.loading) {
        console.warn("嘗試在 config 載入中時檢查權限:", permissionName, " - 可能導致不準確的結果");
        // 返回 false 或 true 取決於您的安全策略，false 通常更安全
        return false;
    }
    // 3. 檢查 rolePermissionsMap 是否已建立 (防止在 fetchConfig 成功但 map 建立失敗時出錯)
    if (state.rolePermissionsMap.size === 0 && state.roles.length > 0) {
         console.warn("Role Permissions Map 為空，無法檢查權限 (可能在 fetchConfig 中建立失敗)。");
         return false;
    }


    const userRoleName = userStore.state.role; // 從 userStore 取得目前角色名稱
    if (!userRoleName) {
        // console.log("檢查權限失敗：使用者角色未設定");
        return false; // 沒有角色就沒有權限
    }

    // superadmin 總是擁有所有權限
    if (userRoleName === 'superadmin') {
        return true;
    }

    const permissionsForRole = state.rolePermissionsMap.get(userRoleName);
    const hasPerm = permissionsForRole ? permissionsForRole.has(permissionName) : false;
    // 為避免過多日誌，只在需要時取消註解下一行
    // console.log(`權限檢查: 角色='${userRoleName}', 權限='${permissionName}', 結果=${hasPerm}`);
    return hasPerm;
};
// --- 結束輔助函數 ---


// 導出 Store
export const configStore = {
  state: readonly(state),
  fetchConfig,
  clearConfig,
  userHasPermission // 將輔助函數也導出
}