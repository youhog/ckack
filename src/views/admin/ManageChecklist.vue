<!-- src/views/admin/ManageChecklist.vue -->
<template>
  <div class="card p-6">
    <h3 class="text-xl font-semibold text-gray-800 mb-4">管理檢查項目</h3>
    <p class="text-sm text-gray-500 mb-6">在這裡新增、刪除或重新排序檢查分類和項目。變更將在下次重新載入設定時生效。</p>

    <!-- 新增分類 -->
    <form @submit.prevent="addCategory" class="flex flex-col sm:flex-row gap-4 mb-6 p-4 bg-gray-50 dark:bg-slate-700/50 rounded-lg border dark:border-slate-600">
      <input type="text" v-model="newCategory.icon" placeholder="圖示 (例如: 🛏️)" class="form-control" style="max-width: 100px;">
      <input type="text" v-model="newCategory.name" placeholder="新分類名稱 (例如: 寢具區域)" class="form-control flex-1" required>
      <button type="submit" class="btn btn-primary" :disabled="isSaving">
        {{ isSaving ? '新增中...' : '新增分類' }}
      </button>
    </form>

    <!-- 分類與項目列表 -->
    <div v-if="config.loading" class="text-center text-gray-500 dark:text-gray-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-6">

      <div v-if="categories.length === 0" class="text-center text-gray-500 dark:text-gray-400 py-8">
          目前沒有任何檢查分類。請使用上方表單新增。
      </div>

      <div v-for="(category, index) in categories" :key="category.id" class="card p-4 border border-gray-200 dark:border-slate-600">
        <!-- 分類標題 -->
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 gap-4">
          <div class="flex items-center gap-3 flex-1 w-full sm:w-auto">
            <input v-if="editingCategory?.id === category.id" v-model="editingCategory.icon" class="form-control w-16 text-2xl text-center" />
            <span v-else class="text-2xl min-w-[2rem] text-center">{{ category.icon }}</span>

            <input v-if="editingCategory?.id === category.id" v-model="editingCategory.name" @blur="updateCategory" @keyup.enter="updateCategory" class="form-control text-lg font-semibold flex-1" />
            <strong v-else class="text-lg font-semibold">{{ category.name }}</strong>
            <span class="text-xs text-gray-400">({{ category.items.length }} 項)</span>
          </div>
          <div class="flex gap-2 w-full sm:w-auto">
             <!-- 排序按鈕 (只有在非編輯模式且不只一個分類時顯示) -->
             <button v-if="!editingCategory && categories.length > 1 && index > 0" @click="moveCategory(index, 'up')" class="btn btn-secondary" style="padding: 8px;" title="上移">▲</button>
             <button v-if="!editingCategory && categories.length > 1 && index < categories.length - 1" @click="moveCategory(index, 'down')" class="btn btn-secondary" style="padding: 8px;" title="下移">▼</button>

            <button v-if="editingCategory?.id === category.id" @click="updateCategory" class="btn btn-primary flex-1 sm:flex-none" style="padding: 8px 12px;" :disabled="isSaving">儲存</button>
            <button v-if="editingCategory?.id === category.id" @click="cancelEditCategory" class="btn btn-secondary flex-1 sm:flex-none" style="padding: 8px 12px;">取消</button>
            <button v-else @click="startEditCategory(category)" class="btn btn-secondary flex-1 sm:flex-none" style="padding: 8px 12px;">編輯</button>

            <button @click="deleteCategory(category.id)" class="btn flex-1 sm:flex-none" :disabled="isSaving" style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 8px 12px;">
              刪除分類
            </button>
          </div>
        </div>

        <!-- 該分類下的項目列表 -->
        <div class="space-y-2 ml-4 md:ml-10">
          <div v-if="category.items.length === 0" class="text-sm text-gray-500 dark:text-gray-400 pl-4 italic">此分類下尚無項目。</div>
          <div v-for="(item, itemIndex) in category.items" :key="item.id" class="flex justify-between items-center group hover:bg-gray-50 dark:hover:bg-slate-700/50 rounded p-2 -mx-2">
            <span class="pl-2">{{ itemIndex + 1 }}. {{ item.name }}</span>
             <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                 <!-- 項目排序按鈕 -->
                 <button v-if="category.items.length > 1 && itemIndex > 0" @click="moveItem(category.id, itemIndex, 'up')" class="btn btn-secondary" style="padding: 4px;" title="上移">▲</button>
                 <button v-if="category.items.length > 1 && itemIndex < category.items.length - 1" @click="moveItem(category.id, itemIndex, 'down')" class="btn btn-secondary" style="padding: 4px;" title="下移">▼</button>
                 <!-- 刪除項目按鈕 -->
                 <button @click="deleteItem(item.id)" class="btn" style="background: rgba(239, 68, 68, 0.05); color: #ef4444; padding: 4px 8px; font-size: 12px;" title="刪除項目">
                   ✕
                 </button>
            </div>
          </div>
        </div>

        <!-- 新增項目到此分類 -->
        <form @submit.prevent="addItem(category.id)" class="flex gap-2 mt-4 ml-4 md:ml-10">
          <input type="text" v-model="newItemName[category.id]" placeholder="新項目名稱 (例如: 床架)" class="form-control form-control-sm flex-1" required>
          <button type="submit" class="btn btn-secondary" style="padding: 8px 12px;" :disabled="isSaving || !newItemName[category.id]">新增項目</button>
        </form>

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
const newCategory = ref({ name: '', icon: '📋' })
const editingCategory = ref(null)
const newItemName = ref({}) // { "category-id-1": "新項目名稱", ... }
const isSaving = ref(false); // 防止重複提交

// 組合分類和它們各自的項目，並根據 display_order 排序
const categories = computed(() => {
  return config.checklistCategories
    .slice() // 創建副本以避免修改原始 store state
    .sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    .map(category => ({
      ...category,
      items: config.checklistItems
        .filter(item => item.category_id === category.id)
        .slice() // 創建副本
        .sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }));
});

// --- 分類 CRUD ---
const addCategory = async () => {
  if (!newCategory.value.name || isSaving.value) return
  isSaving.value = true;
  // 設置新分類的 display_order 為目前最大值 + 1
  const maxOrder = Math.max(0, ...config.checklistCategories.map(c => c.display_order || 0));
  const { error } = await supabase.from('checklist_categories').insert({
      name: newCategory.value.name,
      icon: newCategory.value.icon || '📋', // 提供預設圖示
      display_order: maxOrder + 1
  });
  if (error) {
    if (error.code === '23505') {
       showToast('新增分類失敗: 已存在相同名稱的分類。', 'error')
    } else {
       showToast(`新增分類失敗: ${error.message}`, 'error')
    }
    console.error("Add category error:", error);
  } else {
    newCategory.value = { name: '', icon: '📋' }
    showToast('分類新增成功', 'success');
    await configStore.fetchConfig() // 重新載入
  }
  isSaving.value = false;
}

const deleteCategory = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此分類嗎？其下的所有項目將全部被刪除！')) {
    isSaving.value = true;
    // RLS 確保只有 admin 能刪除，ON DELETE CASCADE 會處理 items
    const { error } = await supabase.from('checklist_categories').delete().eq('id', id)
    if (error) {
      showToast(`刪除分類失敗: ${error.message}`, 'error')
      console.error("Delete category error:", error);
    } else {
      showToast('分類已刪除', 'success');
      await configStore.fetchConfig() // 重新載入
    }
    isSaving.value = false;
  }
}

const startEditCategory = (category) => {
  // 深拷貝一份，避免直接修改 store state
  editingCategory.value = JSON.parse(JSON.stringify(category));
}
const cancelEditCategory = () => {
    editingCategory.value = null;
}

const updateCategory = async () => {
  if (!editingCategory.value || !editingCategory.value.name || isSaving.value) return;
  isSaving.value = true;
  const { id, name, icon, display_order } = editingCategory.value // 包含 display_order
  // 確保 display_order 是數字
  const order = typeof display_order === 'number' ? display_order : parseInt(display_order || '0');

  const { error } = await supabase
    .from('checklist_categories')
    .update({
        name,
        icon: icon || '📋', // 提供預設
        display_order: order
     })
    .eq('id', id)

  if (error) {
     if (error.code === '23505') {
       showToast('更新分類失敗: 已存在相同名稱的分類。', 'error')
    } else {
       showToast(`更新分類失敗: ${error.message}`, 'error')
    }
    console.error("Update category error:", error);
  } else {
    editingCategory.value = null
    showToast('分類已更新', 'success');
    await configStore.fetchConfig() // 重新載入
  }
  isSaving.value = false;
}

// --- 分類排序 ---
const moveCategory = async (index, direction) => {
    if (isSaving.value || !categories.value) return;

    const currentCategories = categories.value; // 使用計算屬性獲取已排序列表
    const categoryToMove = currentCategories[index];
    const swapIndex = direction === 'up' ? index - 1 : index + 1;

    // 邊界檢查
    if (swapIndex < 0 || swapIndex >= currentCategories.length) return;

    const categoryToSwap = currentCategories[swapIndex];

    if (!categoryToMove || !categoryToSwap) {
        console.error("無法移動分類，索引無效");
        return;
    }

    isSaving.value = true;
    console.log(`Moving category '${categoryToMove.name}' ${direction}... Swapping order with '${categoryToSwap.name}'`);

    // 交換 display_order
    const updates = [
        { id: categoryToMove.id, display_order: categoryToSwap.display_order },
        { id: categoryToSwap.id, display_order: categoryToMove.display_order }
    ];

    console.log("Upserting category order:", updates);
    const { error } = await supabase.from('checklist_categories').upsert(updates);

    if (error) {
        showToast(`移動分類失敗: ${error.message}`, 'error');
        console.error("Move category error:", error);
    } else {
        showToast('分類順序已更新', 'success');
        await configStore.fetchConfig(); // 重新載入以更新 UI
    }
    isSaving.value = false;
}


// --- 項目 CRUD ---
const addItem = async (categoryId) => {
  const name = newItemName.value[categoryId]?.trim(); // 去除頭尾空格
  if (!name || isSaving.value) return
  isSaving.value = true;

  // 設置新項目的 display_order
  const itemsInCategory = config.checklistItems.filter(i => i.category_id === categoryId);
  const maxOrder = Math.max(0, ...itemsInCategory.map(i => i.display_order || 0));

  const { error } = await supabase.from('checklist_items').insert({
    category_id: categoryId,
    name: name,
    display_order: maxOrder + 1
  })

  if (error) {
     if (error.code === '23505') {
       showToast('新增項目失敗: 此分類下已存在相同名稱的項目。', 'error')
    } else {
       showToast(`新增項目失敗: ${error.message}`, 'error')
    }
    console.error("Add item error:", error);
  } else {
    newItemName.value[categoryId] = '' // 清空輸入框
    showToast('項目新增成功', 'success');
    await configStore.fetchConfig() // 重新載入
  }
  isSaving.value = false;
}

const deleteItem = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此檢查項目嗎？')) {
    isSaving.value = true;
    const { error } = await supabase.from('checklist_items').delete().eq('id', id)
    if (error) {
      showToast(`刪除項目失敗: ${error.message}`, 'error')
      console.error("Delete item error:", error);
    } else {
      showToast('項目已刪除', 'success');
      await configStore.fetchConfig() // 重新載入
    }
    isSaving.value = false;
  }
}

// --- 項目排序 ---
const moveItem = async (categoryId, index, direction) => {
    if (isSaving.value || !categories.value) return;

    // 找到當前分類的所有項目，並已排序
    const category = categories.value.find(c => c.id === categoryId);
    if (!category || !category.items) return;
    const itemsInCategory = category.items;

    const itemToMove = itemsInCategory[index];
    const swapIndex = direction === 'up' ? index - 1 : index + 1;

    // 邊界檢查
    if (swapIndex < 0 || swapIndex >= itemsInCategory.length) return;

    const itemToSwap = itemsInCategory[swapIndex];

    if (!itemToMove || !itemToSwap) {
        console.error("無法移動項目，索引無效");
        return;
    }

    isSaving.value = true;
    console.log(`Moving item '${itemToMove.name}' ${direction}... Swapping order with '${itemToSwap.name}'`);

    // 交換 display_order
    const updates = [
        { id: itemToMove.id, display_order: itemToSwap.display_order },
        { id: itemToSwap.id, display_order: itemToMove.display_order }
    ];

     console.log("Upserting item order:", updates);
    const { error } = await supabase.from('checklist_items').upsert(updates);

    if (error) {
        showToast(`移動項目失敗: ${error.message}`, 'error');
        console.error("Move item error:", error);
    } else {
        showToast('項目順序已更新', 'success');
        await configStore.fetchConfig(); // 重新載入以更新 UI
    }
    isSaving.value = false;
}

</script>

<style scoped>
/* 使編輯輸入框樣式更一致 */
input.form-control.text-lg {
    padding-top: 0.5rem;
    padding-bottom: 0.5rem;
}
.group:hover .btn {
    opacity: 1;
}
.btn[disabled] {
    opacity: 0.6;
    cursor: not-allowed;
}
/* 調整新增項目的輸入框大小 */
.form-control-sm {
    padding: 0.5rem 0.75rem; /* 減少 padding */
    font-size: 0.875rem; /* text-sm */
}
/* 讓按鈕在小螢幕上可以稍微換行 */
@media (max-width: 640px) { /* sm breakpoint */
    .flex-wrap > .btn {
        min-width: calc(50% - 0.5rem); /* 減去 gap 的一半 */
    }
    .flex-col > .flex { /* 分類標題按鈕換行 */
        flex-direction: column;
        align-items: stretch;
    }
     .flex-col > .flex > .btn { /* 按鈕佔滿寬度 */
        width: 100%;
    }
}
</style>

