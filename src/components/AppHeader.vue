<template>
  <header class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 md:p-8 mb-8">
      <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 mb-8">
          <div class="flex items-center gap-4">
              <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white text-2xl shadow-lg">
                  🏠
              </div>
              <div>
                   <h1 class="text-3xl lg:text-4xl font-bold bg-gradient-to-r from-gray-800 to-gray-600 dark:from-gray-100 dark:to-gray-300 bg-clip-text text-transparent">
                      宿舍房間檢查系統
                  </h1>
                  <p class="text-slate-500 dark:text-slate-400 text-sm mt-1">
                    歡迎, {{ userEmail }} ({{ userRole }})
                  </p>
              </div>
          </div>
          <div class="flex gap-3 w-full lg:w-auto">
              <button
                @click="handleLogout" 
                title="登出"
                class="btn-secondary"
              >
                <span class="flex items-center gap-2">🚪 <span class="hidden sm:inline">登出</span></span>
              </button>

              <button
                @click="$emit('navigate', 'inspection')"
                :class="view === 'inspection' ? 'btn-primary' : 'btn-secondary'"
                class="flex-1 lg:flex-none"
              >
                <span class="flex items-center gap-2">📋 <span>檢查模式</span></span>
              </button>

              <button
                v-if="userRole === 'admin'"
                @click="$emit('navigate', 'admin')"
                :class="view === 'admin' ? 'btn-primary' : 'btn-secondary'"
                class="flex-1 lg:flex-none"
              >
                <span class="flex items-center gap-2">⚙️ <span>後台管理</span></span>
              </button>
          </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <div>
              <label for="dormZone" class="form-label flex items-center gap-1">
                  🏢 <span>宿舍分區</span>
              </label>
              <select
                id="dormZone"
                class="form-control"
                :value="dormZone"
                @change="onZoneChange($event.target.value)"
              >
                  <option value="">請選擇分區</option>
                  <option v-for="zone in config.zones" :key="zone.id" :value="zone.id">
                    {{ zone.name }}
                  </option>
              </select>
          </div>

          <div>
               <label for="roomNumber" class="form-label">
                  <div class="flex justify-between items-center w-full">
                    <span class="flex items-center gap-1">🚪 <span>房間號碼</span></span>
                    <span v-if="loadingRooms" class="text-xs text-slate-500 dark:text-slate-400">載入中...</span>
                    </div>
              </label>
              <select
                id="roomNumber"
                class="form-control"
                :value="roomNumber"
                @change="$emit('update:roomNumber', $event.target.value)"
                :disabled="!dormZone || availableRooms.length === 0 || loadingRooms"
              >
                 <option value="">請選擇房號</option>
                 <option v-for="room in availableRooms" :key="room.id" :value="room.id">
                  {{ room.room_number }}
                </option>
              </select>
              <input type="hidden" :value="roomNumberInput" @input="$emit('update:roomNumberInput', $event.target.value)">
          </div>
          <div>
              <label for="checkType" class="form-label flex items-center gap-1">
                  📝 <span>檢查類型</span>
              </label>
              <select
                id="checkType"
                class="form-control"
                :value="checkType"
                @change="$emit('update:checkType', $event.target.value)"
              >
                 <option value="">請選擇類型</option>
                 <option v-for="type in config.checkTypes" :key="type.id" :value="type.id">
                  {{ type.name }}
                </option>
              </select>
          </div>
          <div>
              <label for="inspector" class="form-label flex items-center gap-1">
                  👤 <span>檢查人員</span>
              </label>
              <input
                type="text"
                id="inspector"
                class="form-control"
                placeholder="請輸入姓名"
                :value="inspector"
                @input="$emit('update:inspector', $event.target.value)"
                readonly
                disabled
              >
          </div>
      </div>

      <div id="inspectionMode" v-if="view === 'inspection'">
          <div class="bg-slate-50 dark:bg-slate-700/50 rounded-xl p-5">
              <div class="flex justify-between items-center mb-3">
                  <div class="flex items-center gap-3">
                      <div class="w-10 h-10 bg-gradient-to-r from-cyan-500 to-blue-500 rounded-xl flex items-center justify-center text-white text-lg shadow">
                           📊
                      </div>
                      <span class="font-semibold text-slate-700 dark:text-slate-300">檢查進度</span>
                  </div>
                  <span
                    class="inline-flex items-center px-3 py-1 rounded-full text-xs font-medium"
                    :class="progressClass"
                  >
                    {{ progress.completed }}/{{ progress.total }} 完成 ({{ progress.percentage }}%)
                  </span>
              </div>
              <div class="w-full h-2 bg-slate-200 dark:bg-slate-600 rounded-full overflow-hidden">
                  <div
                    class="h-full bg-gradient-to-r from-cyan-500 to-blue-500 rounded-full transition-all duration-500 ease-in-out"
                    :style="{ width: `${progress.percentage}%` }">
                  </div>
              </div>
          </div>
      </div>
      <ConfirmModal
        v-model="showLogoutConfirm"
        title="確認登出"
        message="您確定要登出系統嗎？"
        confirm-text="登出"
        confirm-variant="danger"
        @confirm="executeLogout"
      />
  </header>
</template>

<script setup>
import { computed, ref, watch } from 'vue' //
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase' //
import { userStore } from '../store/user' //
import { configStore } from '../store/config' //
import ConfirmModal from './ConfirmModal.vue'; 
import { showToast } from '@/utils'; // 引入 showToast

const props = defineProps({
  dormZone: String,
  roomNumber: String, // 這是 room.id
  roomNumberInput: String, // 這是輸入框的文字 (現在是隱藏的)
  checkType: String,
  inspector: String,
  view: String,
  progress: Object
})
const emit = defineEmits(['update:dormZone', 'update:roomNumber', 'update:roomNumberInput', 'update:checkType', 'update:inspector', 'navigate'])
const router = useRouter()
const user = userStore.state.user //
const userEmail = computed(() => user?.email || '訪客')
const userRole = computed(() => userStore.state.role) //
const config = configStore.state //

const showLogoutConfirm = ref(false); 
const allRooms = ref([]); // 所有房間的本地快取
const loadingRooms = ref(false);

// *** 新增: 獲取所有房間列表 (一次性載入) ***
const fetchAllRooms = async () => {
    loadingRooms.value = true;
    try {
        // 從資料庫獲取所有房間資料
        const { data, error } = await supabase //
            .from('rooms') //
            .select('id, zone_id, room_number')
            .order('room_number', { ascending: true });

        if (error) throw error;
        allRooms.value = data || [];
    } catch (e) {
        console.error("載入所有房間失敗:", e);
        showToast('載入房間列表失敗！', 'error');
    } finally {
        loadingRooms.value = false;
    }
}
// 應用程式啟動時載入房間
fetchAllRooms();


// *** 修改 1.1: 根據選擇的區域篩選房間列表 ***
const availableRooms = computed(() => {
    if (!props.dormZone) return [];
    return allRooms.value
        .filter(room => room.zone_id === props.dormZone)
        .sort((a, b) => a.room_number.localeCompare(b.room_number)); // 確保排序
});

// *** 修改 1.2: 處理區域變化並重設房號 ***
const onZoneChange = (newZoneId) => {
    emit('update:dormZone', newZoneId);
    // 重設 roomNumber 和 roomNumberInput (AppLayout.vue 也有類似邏輯，但這裡確保立即反應)
    emit('update:roomNumber', '');
    emit('update:roomNumberInput', ''); 
}


// --- 登出邏輯 (使用 Modal) ---
const handleLogout = () => {
  showLogoutConfirm.value = true;
}

const executeLogout = async () => {
  const { error } = await supabase.auth.signOut() //
  if (!error) {
    router.push({ name: 'Login' }) //
  } else {
    console.error("登出失敗:", error);
  }
}

// --- Progress class logic ---
const progressClass = computed(() => {
  if (!props.progress) return 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
  const p = props.progress.percentage
  if (p === 100) return 'bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-300'
  if (props.progress.completed > 0) return 'bg-yellow-100 dark:bg-yellow-500/20 text-yellow-700 dark:text-yellow-300'
  return 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
})
</script>

<style scoped>
/* Define reusable styles using @apply */
.form-label {
  @apply block mb-1.5 text-sm font-medium text-slate-700 dark:text-slate-300;
}
.form-control {
  @apply w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700/50 transition-all duration-200 text-sm placeholder-slate-400 dark:placeholder-slate-500;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
  /* 針對 readonly/disabled 欄位，確保視覺上是不可編輯的 */
  @apply disabled:bg-slate-100 disabled:opacity-70 dark:disabled:bg-slate-700 dark:disabled:text-slate-400 dark:disabled:opacity-100; 
}
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>