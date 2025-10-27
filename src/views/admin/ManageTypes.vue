<!-- src/views/admin/ManageTypes.vue -->
<template>
  <div class="card p-6">
    <h3 class="text-xl font-semibold text-gray-800 mb-4">管理檢查類型</h3>
    <p class="text-sm text-gray-500 mb-6">新增、刪除或編輯用於報告的檢查類型。</p>

    <!-- 新增類型 -->
    <form @submit.prevent="addType" class="flex flex-col sm:flex-row gap-4 mb-6 p-4 bg-gray-50 dark:bg-slate-700/50 rounded-lg border dark:border-slate-600">
      <input type="text" v-model="newType.name" placeholder="新類型名稱 (例如: 寒假檢查)" class="form-control flex-1" required>
      <input type="text" v-model="newType.description" placeholder="描述 (選填)" class="form-control flex-1">
      <button type="submit" class="btn btn-primary" :disabled="isSaving || !newType.name">
        {{ isSaving ? '新增中...' : '新增類型' }}
      </button>
    </form>

    <!-- 類型列表 -->
    <div v-if="config.loading" class="text-center text-gray-500 dark:text-gray-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-3">
       <div v-if="sortedTypes.length === 0" class="text-center text-gray-500 dark:text-gray-400 py-8">
          目前沒有任何檢查類型。請使用上方表單新增。
      </div>
      <div v-for="type in sortedTypes" :key="type.id" class="flex flex-col sm:flex-row justify-between items-start sm:items-center card p-4 gap-4">
        <div class="flex-1 w-full sm:w-auto">
          <input v-if="editingType?.id === type.id" v-model="editingType.name" class="form-control font-semibold text-lg" />
          <strong v-else class="text-lg font-semibold">{{ type.name }}</strong>

          <input v-if="editingType?.id === type.id" v-model="editingType.description" class="form-control text-sm mt-1" placeholder="描述 (選填)" />
          <p v-else class="text-sm text-gray-500 dark:text-gray-400 mt-1">{{ type.description || '沒有描述' }}</p>
        </div>
        <div class="flex gap-2 w-full sm:w-auto">
          <button v-if="editingType?.id === type.id" @click="updateType" class="btn btn-primary flex-1 sm:flex-none" style="padding: 8px 12px;" :disabled="isSaving || !editingType?.name">儲存</button>
          <button v-if="editingType?.id === type.id" @click="cancelEdit" class="btn btn-secondary flex-1 sm:flex-none" style="padding: 8px 12px;">取消</button>
          <button v-else @click="startEdit(type)" class="btn btn-secondary flex-1 sm:flex-none" style="padding: 8px 12px;">編輯</button>

          <button @click="deleteType(type.id)" class="btn flex-1 sm:flex-none" :disabled="isSaving" style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 8px 12px;">
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
const newType = ref({ name: '', description: '' })
const editingType = ref(null) // 儲存正在編輯的類型物件
const isSaving = ref(false);

// 按名稱排序
const sortedTypes = computed(() => {
    // 創建副本再排序
    return [...config.checkTypes].sort((a,b) => a.name.localeCompare(b.name));
});

const addType = async () => {
  const name = newType.value.name.trim();
  if (!name || isSaving.value) return;
  isSaving.value = true;
  const { error } = await supabase.from('check_types').insert({
      name: name,
      description: newType.value.description || null
  });
  if (error) {
    // 檢查是否唯一性約束錯誤
    if (error.code === '23505') { // PostgreSQL unique_violation code
        showToast('新增失敗: 已存在相同名稱的檢查類型。', 'error')
    } else {
        showToast(`新增失敗: ${error.message}`, 'error')
    }
    console.error("Add type error:", error);
  } else {
    newType.value = { name: '', description: '' }
    showToast('檢查類型新增成功', 'success');
    await configStore.fetchConfig() // 重新載入
  }
  isSaving.value = false;
}

const deleteType = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此檢查類型嗎？與此類型關聯的報告將會遺失連結。')) {
    isSaving.value = true;
    const { error } = await supabase.from('check_types').delete().eq('id', id)
    if (error) {
      showToast(`刪除失敗: ${error.message}`, 'error')
      console.error("Delete type error:", error);
    } else {
      showToast('檢查類型已刪除', 'success');
      await configStore.fetchConfig() // 重新載入
    }
     isSaving.value = false;
  }
}

const startEdit = (type) => {
  // 深拷貝一份，避免直接修改 store state
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
  const { error } = await supabase
    .from('check_types')
    .update({ name: nameTrimmed, description: description || null }) // 如果 description 為空字串，存為 null
    .eq('id', id)

  if (error) {
     if (error.code === '23505') {
        showToast('更新失敗: 已存在相同名稱的檢查類型。', 'error')
    } else {
        showToast(`更新失敗: ${error.message}`, 'error')
    }
    console.error("Update type error:", error);
  } else {
    editingType.value = null
    showToast('檢查類型已更新', 'success');
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

