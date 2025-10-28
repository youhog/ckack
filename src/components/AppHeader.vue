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
             <button @click="handleLogout" title="登出" class="btn-secondary">
                <span class="flex items-center gap-2">🚪 <span class="hidden sm:inline">登出</span></span>
              </button>
              <button @click="$emit('navigate', 'inspection')" :class="view === 'inspection' ? 'btn-primary' : 'btn-secondary'" class="flex-1 lg:flex-none">
                <span class="flex items-center gap-2">📋 <span>檢查模式</span></span>
              </button>
              <button @click="$emit('navigate', 'key-return')" :class="view === 'key-return' ? 'btn-primary' : 'btn-secondary'" class="flex-1 lg:flex-none">
                <span class="flex items-center gap-2">🔑 <span>歸還模式</span></span>
              </button>
              <button v-if="canAccessAdminArea" @click="$emit('navigate', 'admin')" :class="view === 'admin' ? 'btn-primary' : 'btn-secondary'" class="flex-1 lg:flex-none">
                <span class="flex items-center gap-2">⚙️ <span>後台管理</span></span>
              </button>
          </div>
      </div>

      <div class="grid grid-cols-1 md:grid-cols-3 lg:grid-cols-5 gap-6 mb-6">
          <div class="lg:col-span-1">
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

          <div class="lg:col-span-1">
               <label for="household" class="form-label">
                  <span class="flex items-center gap-1">🏘️ <span>戶別</span></span>
              </label>
              <select
                id="household"
                class="form-control"
                :value="household"
                @change="onHouseholdChange($event.target.value)"
                :disabled="!dormZone || availableHouseholds.length === 0 || loadingRooms"
              >
                 <option value="">{{ householdSelectPlaceholder }}</option>
                 <option v-for="hh in availableHouseholds" :key="hh" :value="hh">
                  {{ hh }} 戶
                </option>
              </select>
          </div>

          <div class="lg:col-span-1">
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
                :disabled="!dormZone || (hasHouseholds && !household) || availableRooms.length === 0 || loadingRooms"
              >
                 <option value="">請選擇房號</option>
                 <option v-for="room in availableRooms" :key="room.id" :value="room.id">
                  {{ room.floor }}樓 {{ room.room_number }} </option>
              </select>
          </div>

          <div class="lg:col-span-1">
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
          <div class="lg:col-span-1">
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
import { computed, ref, watch, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase' //
import { userStore } from '../store/user' //
import { configStore } from '../store/config' //
import ConfirmModal from './ConfirmModal.vue'; //
import { showToast } from '@/utils'; //

// ****** 修改 Props 和 Emits ******
const props = defineProps({
  dormZone: String,
  household: String, // 新增 household prop
  roomNumber: String,
  checkType: String,
  inspector: String,
  view: String,
  progress: Object
})
const emit = defineEmits(['update:dormZone', 'update:household', 'update:roomNumber', 'update:checkType', 'update:inspector', 'navigate'])
// ****** 結束修改 ******

const router = useRouter()
const user = userStore.state.user
const userEmail = computed(() => user?.email || '訪客')
const userRole = computed(() => userStore.state.role)
const config = configStore.state

const showLogoutConfirm = ref(false);
const allRooms = ref([]);
const loadingRooms = ref(false);

const canAccessAdminArea = computed(() => {
    // ... (判斷邏輯不變) ...
    const adminAreaPermissions = [
        'read_all_reports',
        'manage_zones',
        'manage_rooms',
        'manage_types',
        'manage_checklist',
        'manage_allocations',
        'manage_permissions',
        'manage_users'
    ];
    return adminAreaPermissions.some(permission => configStore.userHasPermission(permission));
});

const fetchAllRooms = async () => {
    loadingRooms.value = true;
    try {
        // 查詢保持不變，包含 floor 和 household
        const { data, error } = await supabase
            .from('rooms') //
            .select('id, zone_id, room_number, floor, household')
            .order('floor', { ascending: true })
            .order('household', { ascending: true, nullsFirst: true })
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

onMounted(fetchAllRooms);

// ****** 新增計算屬性 ******
// 取得目前分區下所有不重複的 household 值 (排除 null 或空字串)
const availableHouseholds = computed(() => {
    if (!props.dormZone) return [];
    const households = allRooms.value
        .filter(room => room.zone_id === props.dormZone && room.household) // 過濾掉 household 為 null 或空字串
        .map(room => room.household);
    return [...new Set(households)].sort(); // 去重並排序
});

// 判斷當前選中分區是否有戶別資訊
const hasHouseholds = computed(() => availableHouseholds.value.length > 0);

// 戶別下拉選單的 placeholder
const householdSelectPlaceholder = computed(() => {
    if (!props.dormZone) return '請先選分區';
    if (loadingRooms.value) return '載入中...';
    if (hasHouseholds.value) return '請選擇戶別';
    return '此區無戶別';
});
// ****** 結束新增 ******


// ****** 修改 availableRooms 計算屬性 ******
const availableRooms = computed(() => {
    if (!props.dormZone) return [];

    let filtered = allRooms.value.filter(room => room.zone_id === props.dormZone);

    // 如果該分區有戶別，且使用者已選擇戶別，則進一步篩選
    if (hasHouseholds.value && props.household) {
        filtered = filtered.filter(room => room.household === props.household);
    }
    // 如果該分區有戶別，但使用者尚未選擇戶別，則不顯示任何房間 (等待戶別選擇)
    else if (hasHouseholds.value && !props.household) {
       return [];
    }
    // 如果該分區沒有戶別，則直接使用分區篩選結果

    // 排序已在 fetchAllRooms 完成
    return filtered;
});
// ****** 結束修改 ******

// ****** 修改 onZoneChange ******
const onZoneChange = (newZoneId) => {
    emit('update:dormZone', newZoneId);
    emit('update:household', ''); // 清空戶別
    emit('update:roomNumber', ''); // 清空房號
}
// ****** 結束修改 ******

// ****** 新增 onHouseholdChange ******
const onHouseholdChange = (newHousehold) => {
    emit('update:household', newHousehold);
    emit('update:roomNumber', ''); // 改變戶別時清空房號
}
// ****** 結束新增 ******

const handleLogout = () => {
  showLogoutConfirm.value = true;
}

const executeLogout = async () => {
  const { error } = await supabase.auth.signOut()
  if (!error) {
    router.push({ name: 'Login' }) //
  } else {
    showToast(`登出失敗: ${error.message}`, 'error');
    console.error("登出失敗:", error);
  }
}

const progressClass = computed(() => {
  // ... (進度條樣式邏輯不變) ...
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
  @apply w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-700/50 transition-all duration-200 text-sm placeholder-slate-400 dark:placeholder-slate-500 text-slate-800 dark:text-slate-200;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
.form-control:disabled {
  @apply bg-slate-100 dark:bg-slate-700/80 text-slate-500 dark:text-slate-400 cursor-not-allowed border-slate-200 dark:border-slate-600;
}
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>