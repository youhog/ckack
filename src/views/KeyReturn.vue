<template>
  <main class="space-y-6">
    <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 md:p-8">
      <div class="flex items-center gap-3 mb-6 border-b border-slate-200 dark:border-slate-700 pb-4">
          <div class="w-12 h-12 bg-gradient-to-r from-yellow-500 to-orange-500 rounded-2xl flex items-center justify-center text-white text-xl">
              🔑
          </div>
          <h3 class="text-2xl font-bold text-slate-800 dark:text-slate-100">鑰匙歸還記錄</h3>
      </div>
      
      <p class="text-slate-500 dark:text-slate-400 mb-6">
          請在上方選單選擇「宿舍分區」和「房間號碼」，或輸入學生學號自動帶入。
      </p>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
          <div class="col-span-4">
              <label for="studentId" class="form-label">
                  👤 <span>學生學號 (選填)</span>
              </label>
              <input 
                type="text" 
                id="studentId" 
                class="form-control" 
                placeholder="請輸入學號自動帶入房間資訊"
                v-model="studentId" 
              >
              <p v-if="lookupError" class="text-sm text-red-500 dark:text-red-400 mt-1">{{ lookupError }}</p>
          </div>

          <div class="col-span-2">
              <label for="currentZone" class="form-label flex items-center gap-1">
                  🏢 <span>所選區域</span>
              </label>
              <input 
                type="text" 
                id="currentZone" 
                class="form-control" 
                :value="currentZoneName" 
                disabled 
              >
              <p v-if="!formState.dormZone" class="text-sm text-red-500 dark:text-red-400 mt-1">請在上方選單選擇分區。</p>
          </div>
          <div class="col-span-2">
               <label for="currentRoom" class="form-label">
                    🚪 <span>所選房間號碼</span>
              </label>
              <input 
                type="text" 
                id="currentRoom" 
                class="form-control" 
                :value="currentRoomNumber" 
                disabled 
              >
              <p v-if="!formState.roomNumber" class="text-sm text-red-500 dark:text-red-400 mt-1">請在上方選單選擇房號。</p>
          </div>

          <div>
              <label for="bedNumber" class="form-label">
                  🛏️ <span>床位號碼 (選填)</span>
              </label>
              <select 
                id="bedNumber" 
                class="form-control" 
                v-model="bedNumber"
                :disabled="lookupLoading"
              >
                 <option value="">未選擇</option>
                 <option value="1">1 號床</option>
                 <option value="2">2 號床</option>
                 <option value="3">3 號床</option>
                 <option value="4">4 號床</option>
              </select>
          </div>
      </div>

      <div class="mb-6">
          <label for="returnNotes" class="form-label">
              💭 <span>歸還備註</span>
          </label>
          <textarea 
            id="returnNotes" 
            rows="4" 
            class="form-control resize-none" 
            placeholder="請輸入鑰匙或房內其他情況的備註..." 
            v-model="returnNotes"
          ></textarea>
      </div>
      
      <button 
        @click="logKeyReturn"
        :disabled="isLogging || isLogDisabled"
        class="w-full py-3 text-lg font-semibold text-white bg-gradient-to-r from-orange-500 to-yellow-600 rounded-xl shadow-md transition-all duration-300 transform hover:shadow-lg hover:-translate-y-0.5 focus:outline-none focus:ring-4 focus:ring-orange-500/30 disabled:opacity-60 disabled:cursor-not-allowed"
      >
        <span class="flex items-center justify-center gap-3">
            <span v-if="isLogging">
              <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            </span>
            <span v-else>✅</span>
            <span v-if="isLogging">記錄歸還中...</span>
            <span v-else>記錄鑰匙歸還 ({{ currentRoomNumber }})</span>
        </span>
      </button>
      <p v-if="missingInfoReason" class="text-sm text-red-500 dark:text-red-400 mt-3 text-center">
          {{ missingInfoReason }}
      </p>

    </div>
  </main>
</template>

<script setup>
import { ref, computed, onMounted, watch, nextTick } from 'vue' // nextTick 已引入
import { supabase } from '@/services/supabase' 
import { configStore } from '@/store/config' 
import { userStore } from '@/store/user'
import { showToast } from '@/utils' 

const props = defineProps({
  formState: Object,
})
const emit = defineEmits(['update:dormZone', 'update:roomNumber'])

const isLogging = ref(false)
const returnNotes = ref('')
const studentId = ref('') 
const bedNumber = ref('') 
const lookupLoading = ref(false);
const lookupError = ref(null);

const config = configStore.state
const user = userStore.state.user

const allRoomsCache = ref([]); 
const isRoomCacheLoading = ref(true);

const fetchAllRoomsCache = async () => {
    isRoomCacheLoading.value = true;
    console.log("KeyReturn: 正在載入 rooms/zones 快取...");
    try {
        const [{ data: roomsData, error: roomError }, { data: zonesData, error: zoneError }] = await Promise.all([
             supabase.from('rooms').select('id, room_number, zone_id'),
             supabase.from('dorm_zones').select('id, name')
        ]);

        if (roomError) throw roomError;
        if (zoneError) throw zoneError;

        allRoomsCache.value = roomsData || [];
        allRoomsCache.value = allRoomsCache.value.map(r => ({
            ...r,
            zone_name: zonesData.find(z => z.id === r.zone_id)?.name
        }));
        console.log(`KeyReturn: rooms 快取載入成功，共 ${allRoomsCache.value.length} 筆資料。`);
    } catch (e) {
        console.error("KeyReturn: 載入所有房間快取失敗:", e);
        showToast('載入房間列表快取失敗！', 'error');
    } finally {
        isRoomCacheLoading.value = false;
    }
}

onMounted(fetchAllRoomsCache);

// --- Student ID Lookup Logic (Updated to query student_allocations) ---
let lookupDebounce = null;
watch(studentId, (newId) => {
    lookupError.value = null;
    if (newId.trim().length === 0) {
        // 清空學號時，清空床位號
        bedNumber.value = '';
        return;
    }
    
    clearTimeout(lookupDebounce);
    lookupLoading.value = true;
    lookupDebounce = setTimeout(() => {
        performStudentLookup(newId);
    }, 500); 
});

const performStudentLookup = async (id) => {
    id = id.trim();
    console.log(`KeyReturn: 正在查詢學號 ${id} 的分配記錄...`);
    if (isRoomCacheLoading.value) {
        lookupError.value = '房間資訊尚未載入，請稍候。';
        lookupLoading.value = false;
        return;
    }
    
    // 1. Query the student_allocations table
    const { data: allocationData, error: allocationError } = await supabase
        .from('student_allocations')
        .select(`
            room_id, 
            zone_id, 
            bed_number
        `)
        .eq('student_id', id)
        .maybeSingle();

    if (allocationError) {
        console.error("KeyReturn: Allocation lookup error:", allocationError);
        lookupError.value = `查詢失敗: ${allocationError.message}`;
        lookupLoading.value = false;
        return;
    }

    if (allocationData) {
        console.log("KeyReturn: 找到分配記錄。Room ID:", allocationData.room_id, "Zone ID:", allocationData.zone_id);
        const roomMatch = allRoomsCache.value.find(r => r.id === allocationData.room_id);

        if (roomMatch) {
            console.log("KeyReturn: 房間 ID 在快取中匹配成功。房號:", roomMatch.room_number);
            
            // 步驟 1: 先更新 dormZone (這會在 AppLayout 觸發 roomNumber 的清空)
            emit('update:dormZone', allocationData.zone_id); // MODIFIED
            console.log("KeyReturn: Step 1 (Zone) emitted. Waiting for nextTick to set Room ID..."); // ADDED
            
            // 步驟 2: 在下一個微任務中，再更新正確的 roomNumber
            nextTick(() => { // MODIFIED: 使用 nextTick
                emit('update:roomNumber', allocationData.room_id); // MODIFIED
                console.log("KeyReturn: Step 2 (Room) emitted in nextTick."); // ADDED
                
                // 再次 nextTick 檢查最終狀態
                nextTick(() => { // ADDED: 額外的 nextTick 檢查
                    console.log("KeyReturn: Final nextTick check. Current Room ID in formState should be:", props.formState.roomNumber); // ADDED
                    console.log("KeyReturn: Final nextTick check. Current Room Number should be:", currentRoomNumber.value); // ADDED
                });
            });
            
            // 2. Update local bedNumber
            bedNumber.value = allocationData.bed_number;
            lookupError.value = null;
            showToast(`學號 ${id} 的房間資訊已自動帶入！`, 'success');
        } else {
            // 查到分配紀錄，但房間 ID 無效 (資料不一致)
            console.warn(`KeyReturn: 找到分配記錄 (Room ID: ${allocationData.room_id})，但在本地 rooms 快取中查無對應房號。`);
            lookupError.value = `找到分配記錄，但查無對應房號資訊。`;
            resetRoomInfo();
        }
    } else {
        console.log("KeyReturn: 查無學號分配記錄。");
        lookupError.value = `查無學號 ${id} 的床位分配資訊。`;
        // 清空床位號，但不清除房間選擇（保留使用者手動選擇的狀態）
        bedNumber.value = ''; 
    }
    lookupLoading.value = false;
};

const resetRoomInfo = () => {
    emit('update:dormZone', '');
    emit('update:roomNumber', '');
}
// --- End Student ID Lookup Logic ---


const currentZoneName = computed(() => {
    return config.zones.find(z => z.id === props.formState.dormZone)?.name || '未選擇';
});

const currentRoomNumber = computed(() => {
    if (isRoomCacheLoading.value) return '載入中...';
    
    const room = allRoomsCache.value.find(r => r.id === props.formState.roomNumber);
    
    if (room && room.room_number) {
        // console.log("Computed: Room ID 匹配成功。顯示房號:", room.room_number); // REMOVED: 避免過多日誌
        return room.room_number;
    }
    
    // 如果 room ID 存在，但房號不存在，可能是資料問題，提供除錯訊息
    if (props.formState.roomNumber) {
        console.warn("Computed: Room ID 存在，但 rooms 快取中查無或 room_number 為空。Form ID:", props.formState.roomNumber);
    }
    
    return '未選擇';
});

const missingInfoReason = computed(() => {
    if (!props.formState.dormZone) return '請在上方選單選擇宿舍分區。';
    if (!props.formState.roomNumber) return '請在上方選單選擇房間號碼。';
    return null;
});

const isLogDisabled = computed(() => {
    return isLogging.value || isRoomCacheLoading.value || lookupLoading.value || !!missingInfoReason.value;
});

const logKeyReturn = async () => {
    if (isLogDisabled.value) {
        showToast(missingInfoReason.value || '系統仍在載入中，請稍候。', 'warning');
        return;
    }
    
    const sId = studentId.value.trim();
    const bNum = bedNumber.value.trim();

    // Secondary check if student/bed info is missing
    if (!sId && !bNum) {
        if (!confirm(`您沒有輸入學號或床位號碼。確定要繼續記錄 ${currentRoomNumber.value} 的歸還嗎？`)) {
            return;
        }
    }
    
    isLogging.value = true;
    
    const record = {
        user_id: user.id,
        zone_id: props.formState.dormZone,
        room_id: props.formState.roomNumber,
        student_id: sId || null, 
        bed_number: bNum || null, 
        return_notes: returnNotes.value || null,
        is_returned: true
    };
    
    const { error } = await supabase
        .from('key_returns')
        .insert(record);

    if (error) {
        showToast(`記錄歸還失敗: ${error.message}`, 'error');
        console.error("Log key return error:", error);
    } else {
        showToast(`${currentRoomNumber.value} 鑰匙歸還記錄成功！`, 'success');
        
        // 清空表單
        returnNotes.value = '';
        studentId.value = '';
        bedNumber.value = '';
        lookupError.value = null; 
        resetRoomInfo(); // 清空上方選單
    }
    
    isLogging.value = false;
};
</script>

<style scoped>
.form-label {
  @apply block mb-1.5 text-sm font-medium text-slate-700 dark:text-slate-300;
}
.form-control {
  @apply w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 transition-all duration-200 text-sm placeholder-slate-400 dark:placeholder-slate-500 text-slate-800 dark:text-slate-200;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
.form-control[disabled] {
  @apply bg-slate-100 dark:bg-slate-700 disabled:opacity-100 dark:text-slate-400; 
}
</style>