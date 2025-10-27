<!-- src/views/admin/ManageRooms.vue -->
<template>
  <div class="card p-6">
    <h3 class="text-xl font-semibold text-gray-800 mb-4">管理房間</h3>
    <p class="text-sm text-gray-500 mb-6">新增或刪除指定區域下的房間號碼。</p>

    <!-- 新增房間 -->
    <form @submit.prevent="addRoom" class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6 p-4 bg-gray-50 dark:bg-slate-700/50 rounded-lg border dark:border-slate-600">
      <select v-model="newRoom.zone_id" class="form-control" required title="選擇區域">
        <option value="">選擇區域</option>
        <option v-for="zone in sortedZones" :key="zone.id" :value="zone.id">{{ zone.name }}</option>
      </select>
      <input type="text" v-model="newRoom.room_number" placeholder="新房間號碼 (例如: 101, A203)" class="form-control" required title="輸入房間號碼">
      <button type="submit" class="btn btn-primary" :disabled="isSaving || !newRoom.zone_id || !newRoom.room_number">
        {{ isSaving ? '新增中...' : '新增房間' }}
      </button>
    </form>

    <!-- 房間列表 (分組) -->
    <div v-if="config.loading" class="text-center text-gray-500 dark:text-gray-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-6">

      <div v-if="sortedZones.length === 0" class="text-center text-gray-500 dark:text-gray-400 py-8">
          請先在「管理區域」頁面新增宿舍區域。
      </div>

      <div v-for="zone in sortedZones" :key="zone.id">
        <h4 class="text-lg font-semibold mb-2 p-2 bg-gray-50 dark:bg-slate-700 rounded">{{ zone.name }}</h4>
        <div v-if="roomsByZone(zone.id).length === 0" class="text-sm text-gray-500 dark:text-gray-400 pl-4 italic">
            此區域下尚無房間。
        </div>
        <div v-else class="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 lg:grid-cols-6 gap-2">
          <div v-for="room in roomsByZone(zone.id)" :key="room.id" class="flex justify-between items-center card p-3 text-sm">
            <span class="truncate" :title="room.room_number">{{ room.room_number }}</span>
            <button @click="deleteRoom(room.id)" class="btn flex-shrink-0 ml-1" :disabled="isSaving" style="background: rgba(239, 68, 68, 0.05); color: #ef4444; padding: 4px 8px; font-size: 12px;" title="刪除房間">
              ✕
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase'
import { configStore } from '@/store/config'
import { showToast } from '@/utils'

const config = configStore.state
const newRoom = ref({ zone_id: '', room_number: '' })
const isSaving = ref(false);

// 按區域名稱排序
const sortedZones = computed(() => {
    return [...config.zones].sort((a,b) => a.name.localeCompare(b.name));
});

// 按房間號碼排序（考慮數字和字母）
const roomsByZone = (zoneId) => {
  return config.rooms
    .filter(r => r.zone_id === zoneId)
    // 使用 localeCompare 進行自然排序 (例如 101 會在 20 之後)
    .sort((a,b) => a.room_number.localeCompare(b.room_number, undefined, { numeric: true, sensitivity: 'base' }))
}

const addRoom = async () => {
  if (!newRoom.value.zone_id || !newRoom.value.room_number || isSaving.value) return
  isSaving.value = true;
  // 去除房間號碼前後空格
  const roomNumberCleaned = newRoom.value.room_number.trim();
  if (!roomNumberCleaned) {
      showToast('房間號碼不能為空。', 'error');
      isSaving.value = false;
      return;
  }

  const { error } = await supabase.from('rooms').insert({
      zone_id: newRoom.value.zone_id,
      room_number: roomNumberCleaned
  })
  if (error) {
    // 檢查是否因為唯一性約束失敗
    if (error.code === '23505') { // PostgreSQL unique_violation code
        showToast('新增失敗: 此區域已存在相同房間號碼。', 'error')
    } else {
        showToast(`新增失敗: ${error.message}`, 'error')
    }
    console.error("Add room error:", error);
  } else {
    newRoom.value.room_number = '' // 清空房間號碼，保留區域，方便連續新增
    showToast('房間新增成功', 'success');
    await configStore.fetchConfig() // 重新載入
  }
  isSaving.value = false;
}

const deleteRoom = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此房間嗎？與此房間關聯的報告將會遺失連結。')) {
    isSaving.value = true;
    const { error } = await supabase.from('rooms').delete().eq('id', id)
    if (error) {
      showToast(`刪除失敗: ${error.message}`, 'error')
      console.error("Delete room error:", error);
    } else {
      showToast('房間已刪除', 'success');
      await configStore.fetchConfig() // 重新載入
    }
    isSaving.value = false;
  }
}
</script>

<style scoped>
.btn[disabled] {
    opacity: 0.6;
    cursor: not-allowed;
}
</style>

