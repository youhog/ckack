// src/components/AppHeader.vue
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
                @click="$emit('navigate', 'key-return')"
                :class="view === 'key-return' ? 'btn-primary' : 'btn-secondary'"
                class="flex-1 lg:flex-none"
              >
                <span class="flex items-center gap-2">🔑 <span>歸還模式</span></span>
              </button>

              <button
                v-if="canAccessAdminArea"
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
                :disabled="view === 'key-return'"
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
import { computed, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase'
import { userStore } from '../store/user'
import { configStore } from '../store/config' // 載入 configStore
import ConfirmModal from './ConfirmModal.vue';
import { showToast } from '@/utils';
import { onMounted } from 'vue'; // <--- **加入這一行**

const props = defineProps({
  dormZone: String,
  roomNumber: String,
  // roomNumberInput: String, // 移除
  checkType: String,
  inspector: String,
  view: String,
  progress: Object
})
const emit = defineEmits(['update:dormZone', 'update:roomNumber', /*'update:roomNumberInput',*/ 'update:checkType', 'update:inspector', 'navigate']) // 移除 roomNumberInput
const router = useRouter()
const user = userStore.state.user
const userEmail = computed(() => user?.email || '訪客')
const userRole = computed(() => userStore.state.role)
const config = configStore.state

const showLogoutConfirm = ref(false);
const allRooms = ref([]);
const loadingRooms = ref(false);

// --- 判斷是否顯示 "後台管理" 按鈕 ---
// 邏輯：只要使用者擁有任一管理相關的權限，就顯示按鈕
const canAccessAdminArea = computed(() => {
    // 列出所有可能進入 Admin 區塊的權限
    const adminAreaPermissions = [
        'read_all_reports', // For Dashboard
        'manage_zones',
        'manage_rooms',
        'manage_types',
        'manage_checklist',
        'manage_allocations',
        'manage_permissions',
        'manage_users'
    ];
    // 使用 some 檢查是否至少有一個權限符合
    return adminAreaPermissions.some(permission => configStore.userHasPermission(permission));
});
// --- 結束判斷 ---

const fetchAllRooms = async () => {
    loadingRooms.value = true;
    try {
        const { data, error } = await supabase
            .from('rooms')
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
// 只有在元件掛載後才載入房間列表，避免不必要的請求
onMounted(fetchAllRooms);


const availableRooms = computed(() => {
    if (!props.dormZone) return [];
    // 直接使用已載入的 allRooms 進行過濾和排序
    return allRooms.value
        .filter(room => room.zone_id === props.dormZone)
        // 確保 room_number 存在且為字串再排序
        .sort((a, b) => (a.room_number || '').localeCompare(b.room_number || '', undefined, { numeric: true, sensitivity: 'base' }));
});


const onZoneChange = (newZoneId) => {
    emit('update:dormZone', newZoneId);
    emit('update:roomNumber', ''); // 清空 roomNumber (ID)
    // emit('update:roomNumberInput', ''); // 移除
}


const handleLogout = () => {
  showLogoutConfirm.value = true;
}

const executeLogout = async () => {
  const { error } = await supabase.auth.signOut()
  if (!error) {
    // 登出後，userStore 和 configStore 應被清除 (在 main.js 的監聽器中處理)
    router.push({ name: 'Login' })
  } else {
    showToast(`登出失敗: ${error.message}`, 'error');
    console.error("登出失敗:", error);
  }
}

const progressClass = computed(() => {
  if (!props.progress) return 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
  const p = props.progress.percentage
  if (p === 100) return 'bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-300'
  // 即使只完成一部分也顯示黃色
  if (props.progress.completed > 0) return 'bg-yellow-100 dark:bg-yellow-500/20 text-yellow-700 dark:text-yellow-300'
  // 預設 (0 完成)
  return 'bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300'
})
</script>

<style scoped>
/* Define reusable styles using @apply */
.form-label {
  @apply block mb-1.5 text-sm font-medium text-slate-700 dark:text-slate-300;
}
.form-control {
  @apply w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700/50 transition-all duration-200 text-sm placeholder-slate-400 dark:placeholder-slate-500 text-slate-800 dark:text-slate-200;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
  /* 針對 readonly/disabled 欄位，優化深色模式下的對比度 */
  @apply disabled:bg-slate-100 disabled:opacity-100 dark:disabled:bg-slate-700 dark:disabled:text-slate-400;
}
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>