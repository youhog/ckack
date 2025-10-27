<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理房間</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">新增或刪除指定區域下的房間號碼。房間數量過多，已啟用分頁載入。</p>

    <form @submit.prevent="addRoom" class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
      <select v-model="newRoom.zone_id" class="form-control" required title="選擇區域">
        <option value="">選擇區域</option>
        <option v-for="zone in sortedZones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
      </select>
      <input 
        type="text" 
        v-model="newRoom.room_number" 
        placeholder="新房間號碼 (例如: 101, A203)" 
        class="form-control" 
        required 
        title="輸入房間號碼"
      >
      <button 
        type="submit" 
        class="btn-primary" 
        :disabled="isSaving || !newRoom.zone_id || !newRoom.room_number"
      >
        <span v-if="isSaving">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
          新增中...
        </span>
        <span v-else>新增房間</span>
      </button>
    </form>

    <div v-if="config.loading" class="text-center text-slate-500 dark:text-slate-400 py-8">載入區域設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入區域失敗: {{ config.error }}</div>
    <div v-else class="space-y-6">

      <div v-if="sortedZones.length === 0" class="text-center text-slate-500 dark:text-slate-400 py-8">
          請先在「管理區域」頁面新增宿舍區域。
      </div>

      <div class="flex flex-col sm:flex-row gap-4">
        <select v-model="filterZone" @change="resetAndFetchRooms" class="form-control" title="篩選區域">
          <option value="">顯示所有區域</option>
          <option v-for="zone in sortedZones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
        </select>
        <input 
          type="text" 
          v-model="filterRoomNumber" 
          @input="debouncedFetchRooms" 
          placeholder="搜尋房號..." 
          class="form-control"
        >
      </div>

      <div v-if="loadingRooms" class="text-center text-slate-500 dark:text-slate-400 py-8">載入房間列表中...</div>
      <div v-else-if="loadError" class="text-center text-red-500 py-8">載入房間失敗: {{ loadError }}</div>
      
      <div v-else-if="rooms.length === 0" class="text-center text-slate-500 dark:text-slate-400 py-8">
          找不到符合條件的房間。
      </div>
      <div v-else class="space-y-4">
        <div class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-3">
          <div 
            v-for="room in rooms" 
            :key="room.id" 
            class="flex justify-between items-center bg-slate-50 dark:bg-slate-900/30 rounded-lg p-3 text-sm border border-slate-200 dark:border-slate-700"
          >
            <span class="truncate" :title="`${room.dorm_zones.name} - ${room.room_number}`">
              <span class="text-xs text-slate-500 dark:text-slate-400">{{ room.dorm_zones.name }}</span><br>
              <span class="font-medium text-slate-800 dark:text-slate-100">{{ room.room_number }}</span>
            </span>
            <button 
              @click="deleteRoom(room)" 
              class="inline-flex items-center justify-center p-1.5 rounded-md transition-all duration-200 cursor-pointer flex-shrink-0 ml-1 bg-red-100 dark:bg-red-500/20 text-red-600 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-500/30 disabled:opacity-60 disabled:cursor-not-allowed" 
              :disabled="isSaving" 
              title="刪除房間"
            >
              ✕
            </button>
          </div>
        </div>
        
        <div class="flex flex-col sm:flex-row justify-between items-center mt-6 gap-4">
            <span class="text-sm text-slate-600 dark:text-slate-400">
                總共 {{ totalRooms }} 筆 (第 {{ currentPage }} / {{ totalPages }} 頁)
            </span>
            <div class="flex gap-2">
                <button @click="prevPage" class="btn-secondary" :disabled="currentPage === 1">
                    上一頁
                </button>
                <button @click="nextPage" class="btn-secondary" :disabled="currentPage === totalPages || totalPages === 0">
                    下一頁
                </button>
            </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, watch } from 'vue'
import { supabase } from '@/services/supabase' //
import { configStore } from '@/store/config' //
import { showToast } from '@/utils' //

// --- (所有 <script> 邏輯保持不變) ---
const config = configStore.state; //
const newRoom = ref({ zone_id: '', room_number: '' })
const isSaving = ref(false);

const loadingRooms = ref(true);
const loadError = ref(null);
const rooms = ref([]);
const currentPage = ref(1);
const rowsPerPage = ref(30);
const totalRooms = ref(0);

const filterZone = ref('');
const filterRoomNumber = ref('');
let debounceTimer = null;

const sortedZones = computed(() => {
    return [...config.zones].sort((a,b) => a.name.localeCompare(b.name)); //
});

const totalPages = computed(() => {
    if (totalRooms.value === 0) return 1;
    return Math.ceil(totalRooms.value / rowsPerPage.value)
});

const fetchRooms = async () => {
    loadingRooms.value = true;
    loadError.value = null;

    const from = (currentPage.value - 1) * rowsPerPage.value;
    const to = from + rowsPerPage.value - 1;

    let query = supabase //
        .from('rooms') //
        .select(`
            id, 
            room_number,
            dorm_zones ( name )
        `, { count: 'exact' })
        .order('room_number', { ascending: true, nullsFirst: false }); 

    if (filterZone.value) {
        query = query.eq('zone_id', filterZone.value);
    }
    if (filterRoomNumber.value) {
        query = query.ilike('room_number', `%${filterRoomNumber.value}%`);
    }

    query = query.range(from, to);

    const { data, error, count } = await query;

    if (error) {
        loadError.value = error.message;
        showToast(`載入房間失敗: ${error.message}`, 'error'); //
        console.error("Fetch rooms error:", error);
    } else {
        rooms.value = data;
        totalRooms.value = count || 0;
    }
    loadingRooms.value = false;
}

const nextPage = () => {
    if (currentPage.value < totalPages.value) {
        currentPage.value++;
        fetchRooms();
    }
}
const prevPage = () => {
    if (currentPage.value > 1) {
        currentPage.value--;
        fetchRooms();
    }
}

const resetAndFetchRooms = () => {
    currentPage.value = 1;
    fetchRooms();
}

const debouncedFetchRooms = () => {
    clearTimeout(debounceTimer);
    debounceTimer = setTimeout(() => {
        resetAndFetchRooms();
    }, 300);
}

onMounted(fetchRooms);

watch(filterZone, resetAndFetchRooms);

const addRoom = async () => {
  if (!newRoom.value.zone_id || !newRoom.value.room_number || isSaving.value) return
  isSaving.value = true;
  const roomNumberCleaned = newRoom.value.room_number.trim();
  if (!roomNumberCleaned) {
      showToast('房間號碼不能為空。', 'error'); //
      isSaving.value = false;
      return;
  }

  const { error } = await supabase.from('rooms').insert({ //
      zone_id: newRoom.value.zone_id,
      room_number: roomNumberCleaned
  })
  if (error) {
    if (error.code === '23505') { 
        showToast('新增失敗: 此區域已存在相同房間號碼。', 'error') //
    } else {
        showToast(`新增失敗: ${error.message}`, 'error') //
    }
    console.error("Add room error:", error);
  } else {
    newRoom.value.room_number = '' 
    showToast('房間新增成功', 'success'); //
    fetchRooms();
  }
  isSaving.value = false;
}

const deleteRoom = async (room) => {
  if (isSaving.value) return;
  if (confirm(`確定要刪除房間 ${room.dorm_zones.name} - ${room.room_number} 嗎？\n與此房間關聯的報告將會遺失連結。`)) {
    isSaving.value = true;
    const { error } = await supabase.from('rooms').delete().eq('id', room.id) //
    if (error) {
      showToast(`刪除失敗: ${error.message}`, 'error') //
      console.error("Delete room error:", error);
    } else {
      showToast('房間已刪除', 'success'); //
      fetchRooms();
    }
    isSaving.value = false;
  }
}
</script>

<style scoped>
.form-control {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
.btn-primary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>