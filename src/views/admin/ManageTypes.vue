<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理檢查類型</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">新增、刪除或編輯用於報告的檢查類型。</p>

    <form @submit.prevent="addType" class="flex flex-col sm:flex-row gap-4 mb-6 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
      <input 
        type="text" 
        v-model="newType.name" 
        placeholder="新類型名稱 (例如: 寒假檢查)" 
        class="form-control flex-1" 
        required
      >
      <input 
        type="text" 
        v-model="newType.description" 
        placeholder="描述 (選填)" 
        class="form-control flex-1"
      >
      <button 
        type="submit" 
        class="btn-primary" 
        :disabled="isSaving || !newType.name"
      >
         <span v-if="isSaving">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
          新增中...
        </span>
        <span v-else>新增類型</span>
      </button>
    </form>

    <div v-if="config.loading" class="text-center text-slate-500 dark:text-slate-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-3">
       <div v-if="sortedTypes.length === 0" class="text-center text-slate-500 dark:text-slate-400 py-8">
          目前沒有任何檢查類型。請使用上方表單新增。
      </div>
      <div v-for="type in sortedTypes" :key="type.id" class="flex flex-col sm:flex-row justify-between items-start sm:items-center bg-slate-50 dark:bg-slate-900/30 rounded-lg p-4 gap-4 border border-slate-200 dark:border-slate-700">
        <div class="flex-1 w-full sm:w-auto">
          <input 
            v-if="editingType?.id === type.id" 
            v-model="editingType.name" 
            class="form-control font-semibold text-lg py-1 mb-1 w-full" 
          />
          <strong v-else class="text-lg font-semibold text-slate-800 dark:text-slate-100">{{ type.name }}</strong>

          <input 
            v-if="editingType?.id === type.id" 
            v-model="editingType.description" 
            class="form-control text-sm mt-1 w-full" 
            placeholder="描述 (選填)" 
          />
          <p v-else class="text-sm text-slate-500 dark:text-slate-400 mt-1">{{ type.description || '沒有描述' }}</p>
        </div>
        <div class="flex gap-2 w-full sm:w-auto">
          <button v-if="editingType?.id === type.id" @click="updateType" class="btn-primary flex-1 sm:flex-none" :disabled="isSaving || !editingType?.name">儲存</button>
          <button v-if="editingType?.id === type.id" @click="cancelEdit" class="btn-secondary flex-1 sm:flex-none">取消</button>
          <button v-else @click="startEdit(type)" class="btn-secondary flex-1 sm:flex-none">編輯</button>

          <button 
            @click="deleteType(type.id)" 
            class="btn-danger-secondary flex-1 sm:flex-none" 
            :disabled="isSaving"
          >
            刪除
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase' //
import { configStore } from '@/store/config' //
import { showToast } from '@/utils' //

const config = configStore.state //
const newType = ref({ name: '', description: '' })
const editingType = ref(null) 
const isSaving = ref(false);

const sortedTypes = computed(() => {
    return [...config.checkTypes].sort((a,b) => a.name.localeCompare(b.name)); //
});

const addType = async () => {
  const name = newType.value.name.trim();
  if (!name || isSaving.value) return;
  isSaving.value = true;
  const { error } = await supabase.from('check_types').insert({ //
      name: name,
      description: newType.value.description || null
  });
  if (error) {
    if (error.code === '23505') { 
        showToast('新增失敗: 已存在相同名稱的檢查類型。', 'error') //
    } else {
        showToast(`新增失敗: ${error.message}`, 'error') //
    }
    console.error("Add type error:", error);
  } else {
    newType.value = { name: '', description: '' }
    showToast('檢查類型新增成功', 'success'); //
    await configStore.fetchConfig() //
  }
  isSaving.value = false;
}

const deleteType = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此檢查類型嗎？與此類型關聯的報告將會遺失連結。')) {
    isSaving.value = true;
    const { error } = await supabase.from('check_types').delete().eq('id', id) //
    if (error) {
      showToast(`刪除失敗: ${error.message}`, 'error') //
      console.error("Delete type error:", error);
    } else {
      showToast('檢查類型已刪除', 'success'); //
      await configStore.fetchConfig() //
    }
     isSaving.value = false;
  }
}

const startEdit = (type) => {
  editingType.value = JSON.parse(JSON.stringify(type));
}

const cancelEdit = () => {
    editingType.value = null;
}

const updateType = async () => {
  if (!editingType.value || !editingType.value.name.trim() || isSaving.value) return;
  isSaving.value = true;
  const { id, name, description } = editingType.value;
  const nameTrimmed = name.trim();
  const { error } = await supabase //
    .from('check_types') //
    .update({ name: nameTrimmed, description: description || null }) 
    .eq('id', id)

  if (error) {
     if (error.code === '23505') {
        showToast('更新失敗: 已存在相同名稱的檢查類型。', 'error') //
    } else {
        showToast(`更新失敗: ${error.message}`, 'error') //
    }
    console.error("Update type error:", error);
  } else {
    editingType.value = null
    showToast('檢查類型已更新', 'success'); //
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