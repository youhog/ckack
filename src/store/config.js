// youhog/ckack/ckack-10cc0a3bfb263ad24e91487d07fabdff03536175/src/store/config.js
import { reactive, readonly } from 'vue'
import { supabase } from '../services/supabase'

const state = reactive({
  zones: [],
  rooms: [], 
  checkTypes: [],
  checklistCategories: [], 
  checklistItems: [],
  roles: [], // ADDED: 新增 roles 狀態
  permissions: [], // ADDED: 新增 permissions 狀態
  loading: false,
  error: null
})

// 從 Supabase 獲取所有應用程式設定
const fetchConfig = async () => {
  state.loading = true
  state.error = null
  console.log("正在從 Supabase 載入設定 (已跳過 Rooms)..."); 
  
  try {
    // 【修改】新增獲取所有角色和權限的請求
    const [zonesRes, typesRes, categoriesRes, itemsRes, rolesRes, permsRes] = await Promise.all([
      supabase.from('dorm_zones').select('id, name, description').order('name'),
      supabase.from('check_types').select('id, name, description').order('name'),
      supabase.from('checklist_categories').select('id, name, icon').order('display_order'),
      supabase.from('checklist_items').select('id, category_id, name').order('display_order'),
      supabase.from('roles').select('id, name, description').order('name'), // MODIFIED: 從 roles 表獲取所有角色
      supabase.from('permissions').select('id, name, description').order('name'), // ADDED: 獲取所有權限
    ])

    // 檢查是否有任何請求失敗
    if (zonesRes.error) throw new Error(`載入區域失敗: ${zonesRes.error.message}`);
    if (typesRes.error) throw new Error(`載入類型失敗: ${typesRes.error.message}`);
    if (categoriesRes.error) throw new Error(`載入分類失敗: ${categoriesRes.error.message}`);
    if (itemsRes.error) throw new Error(`載入項目失敗: ${itemsRes.error.message}`);
    if (rolesRes.error) console.warn(`載入角色列表失敗 (非致命): ${rolesRes.error.message}`); 
    if (permsRes.error) console.warn(`載入權限列表失敗 (非致命): ${permsRes.error.message}`);


    // 更新狀態
    state.zones = zonesRes.data
    state.checkTypes = typesRes.data
    state.checklistCategories = categoriesRes.data 
    state.checklistItems = itemsRes.data       
    
    // 處理角色列表 (包含 id, name, description)
    state.roles = Array.isArray(rolesRes.data) ? rolesRes.data : [];
    
    state.permissions = Array.isArray(permsRes.data) ? permsRes.data : []; // ADDED

    console.log("設定載入成功:", { 
        zones: state.zones.length, 
        rooms: '(未載入)', 
        types: state.checkTypes.length,
        categories: state.checklistCategories.length,
        items: state.checklistItems.length,
        roles: state.roles.length,
        permissions: state.permissions.length
    });
    
  } catch (error) {
    state.error = error.message
    console.error("載入設定時發生錯誤:", error);
  } finally {
    state.loading = false
  }
}

// 清空本地快取的設定 (例如登出時)
const clearConfig = () => {
  state.zones = [];
  state.rooms = [];
  state.checkTypes = [];
  state.checklistCategories = [];
  state.checklistItems = [];
  state.roles = []; 
  state.permissions = []; 
  state.error = null;
}

// 導出 Store
export const configStore = {
  state: readonly(state), 
  fetchConfig,
  clearConfig
}