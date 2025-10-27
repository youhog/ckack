<!-- src/views/admin/ManageZones.vue -->
<template>
  <div class="card p-6">
    <h3 class="text-xl font-semibold text-gray-800 mb-4">管理宿舍區域</h3>
    <p class="text-sm text-gray-500 mb-6">新增、刪除或編輯宿舍區域。</p>

    <!-- 新增區域 -->
    <form @submit.prevent="addZone" class="flex flex-col sm:flex-row gap-4 mb-6 p-4 bg-gray-50 dark:bg-slate-700/50 rounded-lg border dark:border-slate-600">
      <input type="text" v-model="newZone.name" placeholder="新區域名稱 (例如: F區)" class="form-control flex-1" required>
      <input type="text" v-model="newZone.description" placeholder="描述 (選填)" class="form-control flex-1">
      <button type="submit" class="btn btn-primary" :disabled="isSaving || !newZone.name">
        {{ isSaving ? '新增中...' : '新增區域' }}
      </button>
    </form>

    <!-- 區域列表 -->
    <div v-if="config.loading" class="text-center text-gray-500 dark:text-gray-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-3">
      <div v-if="sortedZones.length === 0" class="text-center text-gray-500 dark:text-gray-400 py-8">
          目前沒有任何宿舍區域。請使用上方表單新增。
      </div>
      <div v-for="zone in sortedZones" :key="zone.id" class="flex flex-col sm:flex-row justify-between items-start sm:items-center card p-4 gap-4">
        <div class="flex-1 w-full sm:w-auto">
           <input v-if="editingZone?.id === zone.id" v-model="editingZone.name" class="form-control font-semibold text-lg" />
          <strong v-else class="text-lg font-semibold">{{ zone.name }}</strong>

          <input v-if="editingZone?.id === zone.id" v-model="editingZone.description" class="form-control text-sm mt-1" placeholder="描述 (選填)" />
          <p v-else class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ zone.description || '沒有描述' }}</p>
        </div>
        <div class="flex gap-2 w-full sm:w-auto">
          <button v-if="editingZone?.id === zone.id" @click="updateZone" class="btn btn-primary flex-1 sm:flex-none" style="padding: 8px 12px;" :disabled="isSaving || !editingZone?.name">儲存</button>
          <button v-if="editingZone?.id === zone.id" @click="cancelEdit" class="btn btn-secondary flex-1 sm:flex-none" style="padding: 8px 12px;">取消</button>
          <button v-else @click="startEdit(zone)" class="btn btn-secondary flex-1 sm:flex-none" style="padding: 8px 12px;">編輯</button>

          <button @click="deleteZone(zone.id)" class="btn flex-1 sm:flex-none" :disabled="isSaving" style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 8px 12px;">
            刪除
          </button>
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
const newZone = ref({ name: '', description: '' })
const editingZone = ref(null) // 儲存正在編輯的區域物件
const isSaving = ref(false); // 防止重複提交

// 按名稱排序
const sortedZones = computed(() => {
    // 創建副本再排序
    return [...config.zones].sort((a,b) => a.name.localeCompare(b.name));
});


const addZone = async () => {
  const name = newZone.value.name.trim();
  if (!name || isSaving.value) return;
  isSaving.value = true;
  const { error } = await supabase.from('dorm_zones').insert({
      name: name,
      description: newZone.value.description || null
  });
  if (error) {
     if (error.code === '23505') { // unique_violation
        showToast('新增失敗: 已存在相同名稱的區域。', 'error')
    } else {
        showToast(`新增失敗: ${error.message}`, 'error')
    }
    console.error("Add zone error:", error);
  } else {
    newZone.value = { name: '', description: '' }
    showToast('區域新增成功', 'success');
    await configStore.fetchConfig() // 重新載入
  }
   isSaving.value = false;
}

const deleteZone = async (id) => {
  if (isSaving.value) return;
  // 檢查是否有房間關聯到此區域
  const hasRooms = config.rooms.some(room => room.zone_id === id);
  const confirmMessage = hasRooms
      ? '確定要刪除此區域嗎？其下的所有房間也將被刪除 (透過資料庫設定)，且相關報告連結會遺失！'
      : '確定要刪除此區域嗎？';

  if (confirm(confirmMessage)) {
    isSaving.value = true;
    // RLS 確保只有 admin 能刪除，且資料庫的 ON DELETE CASCADE 會處理房間
    const { error } = await supabase.from('dorm_zones').delete().eq('id', id)
    if (error) {
      showToast(`刪除失敗: ${error.message}`, 'error')
      console.error("Delete zone error:", error);
    } else {
      showToast('區域已刪除', 'success');
      await configStore.fetchConfig() // 重新載入
    }
     isSaving.value = false;
  }
}

const startEdit = (zone) => {
  // 深拷貝一份，避免直接修改 store state
  editingZone.value = JSON.parse(JSON.stringify(zone));
}

const cancelEdit = () => {
    editingZone.value = null;
}

const updateZone = async () => {
  if (!editingZone.value || !editingZone.value.name.trim() || isSaving.value) return;
   isSaving.value = true;
  const { id, name, description } = editingZone.value;
  const nameTrimmed = name.trim();
  const { error } = await supabase
    .from('dorm_zones')
    .update({ name: nameTrimmed, description: description || null }) // 空字串存為 null
    .eq('id', id)

  if (error) {
     if (error.code === '23505') {
        showToast('更新失敗: 已存在相同名稱的區域。', 'error')
    } else {
        showToast(`更新失敗: ${error.message}`, 'error')
    }
    console.error("Update zone error:", error);
  } else {
    editingZone.value = null
    showToast('區域已更新', 'success');
    await configStore.fetchConfig() // 重新載入
  }
  isSaving.value = false;
}
</script>

<style scoped>
.btn[disabled] {
    opacity: 0.6;
    cursor: not-allowed;
}
input.form-control.text-lg {
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
}
</style>

