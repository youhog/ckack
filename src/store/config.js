import { reactive, readonly } from 'vue'
import { supabase } from '../services/supabase'

const state = reactive({
  zones: [],
  rooms: [],
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
  console.log("正在從 Supabase 載入設定..."); // 添加日誌
  
  try {
    // 平行獲取所有設定，並按名稱或顯示順序排序
    const [zonesRes, roomsRes, typesRes, categoriesRes, itemsRes] = await Promise.all([
      supabase.from('dorm_zones').select('id, name, description').order('name'),
      supabase.from('rooms').select('id, zone_id, room_number').order('room_number'),
      supabase.from('check_types').select('id, name, description').order('name'),
      supabase.from('checklist_categories').select('id, name, icon').order('display_order'),
      supabase.from('checklist_items').select('id, category_id, name').order('display_order')
    ])

    // 檢查是否有任何請求失敗
    if (zonesRes.error) throw new Error(`載入區域失敗: ${zonesRes.error.message}`);
    if (roomsRes.error) throw new Error(`載入房間失敗: ${roomsRes.error.message}`);
    if (typesRes.error) throw new Error(`載入類型失敗: ${typesRes.error.message}`);
    if (categoriesRes.error) throw new Error(`載入分類失敗: ${categoriesRes.error.message}`);
    if (itemsRes.error) throw new Error(`載入項目失敗: ${itemsRes.error.message}`);

    // 更新狀態
    state.zones = zonesRes.data
    state.rooms = roomsRes.data
    state.checkTypes = typesRes.data
    state.checklistCategories = categoriesRes.data 
    state.checklistItems = itemsRes.data       
    console.log("設定載入成功:", { 
        zones: state.zones.length, 
        rooms: state.rooms.length, 
        types: state.checkTypes.length,
        categories: state.checklistCategories.length,
        items: state.checklistItems.length 
    });
    
  } catch (error) {
    state.error = error.message // 儲存錯誤訊息
    console.error("載入設定時發生錯誤:", error);
    // 可以在 UI 中顯示錯誤訊息給使用者
  } finally {
    state.loading = false // 無論成功或失敗，都結束載入狀態
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
  state: readonly(state), // 使 state 唯讀，防止外部直接修改
  fetchConfig,           // 導出獲取設定的函數
  clearConfig            // 導出清空設定的函數
}
