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
          請在上方選單選擇「宿舍分區」和「房間號碼」，然後填寫下方歸還資訊。
      </p>

      <div class="grid grid-cols-2 md:grid-cols-4 gap-6 mb-8">
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
          </div>

          <div>
              <label for="studentId" class="form-label">
                  👤 <span>學生學號 (選填)</span>
              </label>
              <input 
                type="text" 
                id="studentId" 
                class="form-control" 
                placeholder="請輸入學號"
                v-model="studentId" 
              >
          </div>
          <div>
              <label for="bedNumber" class="form-label">
                  🛏️ <span>床位號碼 (選填)</span>
              </label>
              <select 
                id="bedNumber" 
                class="form-control" 
                v-model="bedNumber"
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
import { ref, computed, onMounted } from 'vue'
import { supabase } from '@/services/supabase' 
import { configStore } from '@/store/config' 
import { userStore } from '@/store/user'
import { showToast } from '@/utils' 

const props = defineProps({
  formState: Object,
})

const isLogging = ref(false)
const returnNotes = ref('')
const studentId = ref('') 
const bedNumber = ref('') 

const config = configStore.state
const user = userStore.state.user

const allRoomsCache = ref([]); 
const isRoomCacheLoading = ref(true);

const fetchAllRoomsCache = async () => {
    isRoomCacheLoading.value = true;
    try {
        const { data, error } = await supabase
            .from('rooms')
            .select('id, room_number');

        if (error) throw error;
        allRoomsCache.value = data || [];
    } catch (e) {
        console.error("載入所有房間快取失敗:", e);
        showToast('載入房間列表快取失敗！', 'error');
    } finally {
        isRoomCacheLoading.value = false;
    }
}

onMounted(fetchAllRoomsCache);

const currentZoneName = computed(() => {
    return config.zones.find(z => z.id === props.formState.dormZone)?.name || '未選擇';
});

const currentRoomNumber = computed(() => {
    if (isRoomCacheLoading.value) return '載入中...';
    return allRoomsCache.value.find(r => r.id === props.formState.roomNumber)?.room_number || '未選擇';
});

const missingInfoReason = computed(() => {
    if (!props.formState.dormZone) return '請在上方選單選擇宿舍分區。';
    if (!props.formState.roomNumber) return '請在上方選單選擇房間號碼。';
    return null;
});

const isLogDisabled = computed(() => {
    return isLogging.value || isRoomCacheLoading.value || !!missingInfoReason.value;
});

const logKeyReturn = async () => {
    if (isLogDisabled.value) {
        showToast(missingInfoReason.value || '系統仍在載入中，請稍候。', 'warning');
        return;
    }
    
    const sId = studentId.value.trim();
    const bNum = bedNumber.value.trim();

    // 提示：若未填寫學號或床位，讓使用者確認
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
    }
    
    isLogging.value = false;
};
</script>

<style scoped>
.form-label {
  display: block;
  margin-bottom: 0.375rem;
  font-size: 0.875rem;
  font-weight: 500;
  color: #334155; /* dark:text-slate-300 */
}
.form-control {
  width: 100%;
  padding: 0.5rem 1rem;
  border-radius: 0.5rem;
  border-width: 1px;
  border-color: #cbd5e1; /* dark:border-slate-600 */
  background-color: #ffffff; /* dark:bg-slate-700/50 */
  transition: all 0.2s ease;
  font-size: 0.875rem;
  color: #1e293b; /* dark:text-slate-200 */
  box-shadow: none;
}
.form-control:focus {
  outline: none;
  border-color: #3b82f6; /* focus:border-blue-500 */
  box-shadow: 0 0 0 2px rgba(59, 130, 246, 0.2); /* focus:ring-2 focus:ring-blue-500/20 */
}
.form-control.disabled, .form-control[disabled] {
  background-color: #f1f5f9; /* disabled:bg-slate-100 */
  opacity: 0.7; /* disabled:opacity-70 */
  cursor: not-allowed;
}
</style>