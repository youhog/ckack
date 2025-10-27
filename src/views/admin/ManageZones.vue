<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理宿舍區域</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">新增、刪除或編輯宿舍區域。</p>

    <form @submit.prevent="addZone" class="flex flex-col sm:flex-row gap-4 mb-6 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
      <input
        type="text"
        v-model="newZone.name"
        placeholder="新區域名稱 (例如: F區)"
        class="form-control flex-1"
        required
      >
      <input
        type="text"
        v-model="newZone.description"
        placeholder="描述 (選填)"
        class="form-control flex-1"
      >
      <button
        type="submit"
        class="btn-primary"
        :disabled="isSaving || !newZone.name"
      >
        <span v-if="isSaving">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
          新增中...
        </span>
        <span v-else>新增區域</span>
      </button>
    </form>

    <div v-if="config.loading" class="text-center text-slate-500 dark:text-slate-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-3">
      <div v-if="sortedZones.length === 0" class="text-center text-slate-500 dark:text-slate-400 py-8">
          目前沒有任何宿舍區域。請使用上方表單新增。
      </div>
      <div
        v-for="zone in sortedZones"
        :key="zone.id"
        class="flex flex-col sm:flex-row justify-between items-start sm:items-center bg-slate-50 dark:bg-slate-900/30 rounded-lg p-4 gap-4 border border-slate-200 dark:border-slate-700"
      >
        <div class="flex-1 w-full sm:w-auto">
           <input
            v-if="editingZone?.id === zone.id"
            v-model="editingZone.name"
            class="form-control font-semibold text-lg py-1 mb-1 w-full"
           />
          <strong v-else class="text-lg font-semibold text-slate-800 dark:text-slate-100">{{ zone.name }}</strong>

          <input
            v-if="editingZone?.id === zone.id"
            v-model="editingZone.description"
            class="form-control text-sm mt-1 w-full"
            placeholder="描述 (選填)"
          />
          <p v-else class="text-sm text-slate-500 dark:text-slate-400 mt-1">{{ zone.description || '沒有描述' }}</p>
        </div>
        <div class="flex gap-2 w-full sm:w-auto">
          <button v-if="editingZone?.id === zone.id" @click="updateZone" class="btn-primary flex-1 sm:flex-none" :disabled="isSaving || !editingZone?.name">儲存</button>
          <button v-if="editingZone?.id === zone.id" @click="cancelEdit" class="btn-secondary flex-1 sm:flex-none">取消</button>
          <button v-else @click="startEdit(zone)" class="btn-secondary flex-1 sm:flex-none">編輯</button>

          <button
            @click="prepareDeleteZone(zone)" class="btn-danger-secondary flex-1 sm:flex-none"
            :disabled="isSaving"
          >
            刪除
          </button>
        </div>
      </div>
    </div>

    <ConfirmModal
      v-model="showDeleteConfirm"
      title="確認刪除區域"
      :message="deleteConfirmMessage"
      confirm-text="確認刪除"
      confirm-variant="danger"
      @confirm="executeDeleteZone"
      @cancel="zoneToDelete = null" />
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase' //
import { configStore } from '@/store/config' //
import { showToast } from '@/utils' //
import ConfirmModal from '@/components/ConfirmModal.vue'; // <-- Import the modal component

const config = configStore.state //
const newZone = ref({ name: '', description: '' })
const editingZone = ref(null)
const isSaving = ref(false);

// --- State for Delete Confirmation ---
const showDeleteConfirm = ref(false);
const zoneToDelete = ref(null);
const deleteConfirmMessage = ref('');
// --- End State for Delete Confirmation ---

const sortedZones = computed(() => {
    return [...config.zones].sort((a,b) => a.name.localeCompare(b.name)); //
});

// --- (addZone function remains the same) ---
const addZone = async () => {
  const name = newZone.value.name.trim();
  if (!name || isSaving.value) return;
  isSaving.value = true;
  const { error } = await supabase.from('dorm_zones').insert({ //
      name: name,
      description: newZone.value.description || null
  });
  if (error) {
     if (error.code === '23505') {
        showToast('新增失敗: 已存在相同名稱的區域。', 'error') //
    } else {
        showToast(`新增失敗: ${error.message}`, 'error') //
    }
    console.error("Add zone error:", error);
  } else {
    newZone.value = { name: '', description: '' }
    showToast('區域新增成功', 'success'); //
    await configStore.fetchConfig() //
  }
   isSaving.value = false;
}

// --- *** Updated Delete Logic *** ---
// 1. Prepare for deletion (sets message and shows modal)
const prepareDeleteZone = (zone) => {
  if (isSaving.value) return;

  const hasRooms = config.rooms.some(room => room.zone_id === zone.id); //
  deleteConfirmMessage.value = hasRooms
      ? `確定要刪除區域 "${zone.name}" 嗎？\n其下的所有房間也將被刪除 (透過資料庫設定)，且相關報告連結會遺失！`
      : `確定要刪除區域 "${zone.name}" 嗎？`;

  zoneToDelete.value = zone; // Store the zone object to be deleted
  showDeleteConfirm.value = true; // Show the modal
}

// 2. Execute deletion (called when modal confirms)
const executeDeleteZone = async () => {
  if (!zoneToDelete.value || isSaving.value) return;

  isSaving.value = true;
  const idToDelete = zoneToDelete.value.id;
  const nameDeleted = zoneToDelete.value.name; // Store name for toast message

  const { error } = await supabase.from('dorm_zones').delete().eq('id', idToDelete) //
  if (error) {
    showToast(`刪除失敗: ${error.message}`, 'error') //
    console.error("Delete zone error:", error);
  } else {
    showToast(`區域 "${nameDeleted}" 已刪除`, 'success'); //
    await configStore.fetchConfig() //
  }
  isSaving.value = false;
  zoneToDelete.value = null; // Clear the stored zone
  // showDeleteConfirm will be set to false automatically by v-model
}
// --- *** End Updated Delete Logic *** ---


// --- (startEdit, cancelEdit, updateZone functions remain the same) ---
const startEdit = (zone) => {
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
  const { error } = await supabase //
    .from('dorm_zones') //
    .update({ name: nameTrimmed, description: description || null })
    .eq('id', id)

  if (error) {
     if (error.code === '23505') {
        showToast('更新失敗: 已存在相同名稱的區域。', 'error') //
    } else {
        showToast(`更新失敗: ${error.message}`, 'error') //
    }
    console.error("Update zone error:", error);
  } else {
    editingZone.value = null
    showToast('區域已更新', 'success'); //
    await configStore.fetchConfig() //
  }
  isSaving.value = false;
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
.btn-danger-secondary {
   @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-500/30 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>