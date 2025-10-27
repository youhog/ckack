// src/store/config.js
import { reactive, readonly } from 'vue'
import { supabase } from '../services/supabase'

const state = reactive({
  zones: [],
  rooms: [], // 此陣列將保持為空，不再由 config 載入
  checkTypes: [],
  checklistCategories: [], 
  checklistItems: [],      
  loading: false,
  error: null
})

// 從 Supabase 獲取所有應用程式設定
const fetchConfig = async () => {
  state.loading = true
  state.error = null
  console.log("正在從 Supabase 載入設定 (已跳過 Rooms)..."); // 添加日誌
  
  try {
    // 【修改】移除 'roomsRes'
    const [zonesRes, typesRes, categoriesRes, itemsRes] = await Promise.all([
      supabase.from('dorm_zones').select('id, name, description').order('name'),
      // supabase.from('rooms').select('id, zone_id, room_number').order('room_number'), // <-- 已移除
      supabase.from('check_types').select('id, name, description').order('name'),
      supabase.from('checklist_categories').select('id, name, icon').order('display_order'),
      supabase.from('checklist_items').select('id, category_id, name').order('display_order')
    ])

    // 檢查是否有任何請求失敗
    if (zonesRes.error) throw new Error(`載入區域失敗: ${zonesRes.error.message}`);
    // if (roomsRes.error) throw new Error(`載入房間失敗: ${roomsRes.error.message}`); // <-- 已移除
    if (typesRes.error) throw new Error(`載入類型失敗: ${typesRes.error.message}`);
    if (categoriesRes.error) throw new Error(`載入分類失敗: ${categoriesRes.error.message}`);
    if (itemsRes.error) throw new Error(`載入項目失敗: ${itemsRes.error.message}`);

    // 更新狀態
    state.zones = zonesRes.data
    // state.rooms = roomsRes.data // <-- 已移除
    state.checkTypes = typesRes.data
    state.checklistCategories = categoriesRes.data 
    state.checklistItems = itemsRes.data       
    console.log("設定載入成功:", { 
        zones: state.zones.length, 
        rooms: '(未載入)', // <-- 已修改
        types: state.checkTypes.length,
        categories: state.checklistCategories.length,
        items: state.checklistItems.length 
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
  state.error = null;
}

// 導出 Store
export const configStore = {
  state: readonly(state), 
  fetchConfig,
  clearConfig
}