<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理檢查項目</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">在這裡新增、刪除或重新排序檢查分類和項目。變更將在下次重新載入設定時生效。</p>

    <form @submit.prevent="addCategory" class="flex flex-col sm:flex-row gap-4 mb-6 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
      <input 
        type="text" 
        v-model="newCategory.icon" 
        placeholder="圖示 (例如: 🛏️)" 
        class="form-control max-w-[100px]" 
      >
      <input 
        type="text" 
        v-model="newCategory.name" 
        placeholder="新分類名稱 (例如: 寢具區域)" 
        class="form-control flex-1" 
        required
      >
      <button 
        type="submit" 
        class="btn-primary" 
        :disabled="isSaving"
      >
        <span v-if="isSaving">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
          新增中...
        </span>
        <span v-else>新增分類</span>
      </button>
    </form>

    <div v-if="config.loading" class="text-center text-slate-500 dark:text-slate-400 py-8">載入設定中...</div>
    <div v-else-if="config.error" class="text-center text-red-500 py-8">載入設定失敗: {{ config.error }}</div>
    <div v-else class="space-y-6">

      <div v-if="categories.length === 0" class="text-center text-slate-500 dark:text-slate-400 py-8">
          目前沒有任何檢查分類。請使用上方表單新增。
      </div>

      <div 
        v-for="(category, index) in categories" 
        :key="category.id" 
        class="bg-slate-50 dark:bg-slate-900/30 rounded-lg p-4 border border-slate-200 dark:border-slate-700 transition-shadow hover:shadow-md"
      >
        <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-4 gap-4">
          <div class="flex items-center gap-3 flex-1 w-full sm:w-auto">
            <input 
              v-if="editingCategory?.id === category.id" 
              v-model="editingCategory.icon" 
              class="form-control w-16 text-2xl text-center py-1" 
            />
            <span v-else class="text-2xl min-w-[2rem] text-center">{{ category.icon }}</span>

            <input 
              v-if="editingCategory?.id === category.id" 
              v-model="editingCategory.name" 
              @blur="updateCategory" 
              @keyup.enter="updateCategory" 
              class="form-control text-lg font-semibold flex-1 py-1" 
            />
            <strong v-else class="text-lg font-semibold text-slate-800 dark:text-slate-100">{{ category.name }}</strong>
            <span class="text-xs text-slate-400 dark:text-slate-500">({{ category.items.length }} 項)</span>
          </div>
          <div class="flex gap-2 w-full sm:w-auto">
             <button v-if="!editingCategory && categories.length > 1 && index > 0" @click="moveCategory(index, 'up')" class="btn-icon-secondary" title="上移">▲</button>
             <button v-if="!editingCategory && categories.length > 1 && index < categories.length - 1" @click="moveCategory(index, 'down')" class="btn-icon-secondary" title="下移">▼</button>

            <button v-if="editingCategory?.id === category.id" @click="updateCategory" class="btn-primary flex-1 sm:flex-none" :disabled="isSaving">儲存</button>
            <button v-if="editingCategory?.id === category.id" @click="cancelEditCategory" class="btn-secondary flex-1 sm:flex-none">取消</button>
            <button v-else @click="startEditCategory(category)" class="btn-secondary flex-1 sm:flex-none">編輯</button>

            <button 
              @click="deleteCategory(category.id)" 
              class="btn-danger-secondary flex-1 sm:flex-none" 
              :disabled="isSaving"
            >
              刪除分類
            </button>
          </div>
        </div>

        <div class="space-y-2 ml-4 md:ml-10">
          <div v-if="category.items.length === 0" class="text-sm text-slate-500 dark:text-slate-400 pl-4 italic">此分類下尚無項目。</div>
          <div 
            v-for="(item, itemIndex) in category.items" 
            :key="item.id" 
            class="flex justify-between items-center group hover:bg-slate-100 dark:hover:bg-slate-700/50 rounded p-2 -mx-2"
          >
            <span class="pl-2 text-slate-700 dark:text-slate-200">{{ itemIndex + 1 }}. {{ item.name }}</span>
             <div class="flex gap-1 opacity-0 group-hover:opacity-100 transition-opacity">
                 <button v-if="category.items.length > 1 && itemIndex > 0" @click="moveItem(category.id, itemIndex, 'up')" class="btn-icon-secondary-sm" title="上移">▲</button>
                 <button v-if="category.items.length > 1 && itemIndex < category.items.length - 1" @click="moveItem(category.id, itemIndex, 'down')" class="btn-icon-secondary-sm" title="下移">▼</button>
                 <button 
                    @click="deleteItem(item.id)" 
                    class="btn-icon-danger-sm" 
                    title="刪除項目"
                 >
                   ✕
                 </button>
            </div>
          </div>
        </div>

        <form @submit.prevent="addItem(category.id)" class="flex gap-2 mt-4 ml-4 md:ml-10">
          <input 
            type="text" 
            v-model="newItemName[category.id]" 
            placeholder="新項目名稱 (例如: 床架)" 
            class="form-control form-control-sm flex-1" 
            required
          >
          <button 
            type="submit" 
            class="btn-secondary btn-sm" 
            :disabled="isSaving || !newItemName[category.id]"
          >
            新增項目
          </button>
        </form>

      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { supabase } from '@/services/supabase' //
import { configStore } from '@/store/config' //
import { showToast } from '@/utils' //

// --- (所有 <script> 邏輯保持不變) ---
const config = configStore.state; //
const newCategory = ref({ name: '', icon: '📋' })
const editingCategory = ref(null)
const newItemName = ref({}) 
const isSaving = ref(false); 

const categories = computed(() => {
  return config.checklistCategories //
    .slice() 
    .sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    .map(category => ({
      ...category,
      items: config.checklistItems //
        .filter(item => item.category_id === category.id)
        .slice() 
        .sort((a, b) => (a.display_order || 0) - (b.display_order || 0))
    }));
});

const addCategory = async () => {
  if (!newCategory.value.name || isSaving.value) return
  isSaving.value = true;
  const maxOrder = Math.max(0, ...config.checklistCategories.map(c => c.display_order || 0)); //
  const { error } = await supabase.from('checklist_categories').insert({ //
      name: newCategory.value.name,
      icon: newCategory.value.icon || '📋',
      display_order: maxOrder + 1
  });
  if (error) {
    if (error.code === '23505') {
       showToast('新增分類失敗: 已存在相同名稱的分類。', 'error') //
    } else {
       showToast(`新增分類失敗: ${error.message}`, 'error') //
    }
    console.error("Add category error:", error);
  } else {
    newCategory.value = { name: '', icon: '📋' }
    showToast('分類新增成功', 'success'); //
    await configStore.fetchConfig() //
  }
  isSaving.value = false;
}

const deleteCategory = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此分類嗎？其下的所有項目將全部被刪除！')) {
    isSaving.value = true;
    const { error } = await supabase.from('checklist_categories').delete().eq('id', id) //
    if (error) {
      showToast(`刪除分類失敗: ${error.message}`, 'error') //
      console.error("Delete category error:", error);
    } else {
      showToast('分類已刪除', 'success'); //
      await configStore.fetchConfig() //
    }
    isSaving.value = false;
  }
}

const startEditCategory = (category) => {
  editingCategory.value = JSON.parse(JSON.stringify(category));
}
const cancelEditCategory = () => {
    editingCategory.value = null;
}

const updateCategory = async () => {
  if (!editingCategory.value || !editingCategory.value.name || isSaving.value) return;
  isSaving.value = true;
  const { id, name, icon, display_order } = editingCategory.value 
  const order = typeof display_order === 'number' ? display_order : parseInt(display_order || '0');

  const { error } = await supabase //
    .from('checklist_categories') //
    .update({
        name,
        icon: icon || '📋',
        display_order: order
     })
    .eq('id', id)

  if (error) {
     if (error.code === '23505') {
       showToast('更新分類失敗: 已存在相同名稱的分類。', 'error') //
    } else {
       showToast(`更新分類失敗: ${error.message}`, 'error') //
    }
    console.error("Update category error:", error);
  } else {
    editingCategory.value = null
    showToast('分類已更新', 'success'); //
    await configStore.fetchConfig() //
  }
  isSaving.value = false;
}

const moveCategory = async (index, direction) => {
    if (isSaving.value || !categories.value) return;

    const currentCategories = categories.value;
    const categoryToMove = currentCategories[index];
    const swapIndex = direction === 'up' ? index - 1 : index + 1;

    if (swapIndex < 0 || swapIndex >= currentCategories.length) return;

    const categoryToSwap = currentCategories[swapIndex];

    if (!categoryToMove || !categoryToSwap) {
        console.error("無法移動分類，索引無效");
        return;
    }

    isSaving.value = true;
    console.log(`Moving category '${categoryToMove.name}' ${direction}... Swapping order with '${categoryToSwap.name}'`);

    const updates = [
        { id: categoryToMove.id, display_order: categoryToSwap.display_order },
        { id: categoryToSwap.id, display_order: categoryToMove.display_order }
    ];

    console.log("Upserting category order:", updates);
    const { error } = await supabase.from('checklist_categories').upsert(updates); //

    if (error) {
        showToast(`移動分類失敗: ${error.message}`, 'error'); //
        console.error("Move category error:", error);
    } else {
        showToast('分類順序已更新', 'success'); //
        await configStore.fetchConfig(); //
    }
    isSaving.value = false;
}


const addItem = async (categoryId) => {
  const name = newItemName.value[categoryId]?.trim(); 
  if (!name || isSaving.value) return
  isSaving.value = true;

  const itemsInCategory = config.checklistItems.filter(i => i.category_id === categoryId); //
  const maxOrder = Math.max(0, ...itemsInCategory.map(i => i.display_order || 0));

  const { error } = await supabase.from('checklist_items').insert({ //
    category_id: categoryId,
    name: name,
    display_order: maxOrder + 1
  })

  if (error) {
     if (error.code === '23505') {
       showToast('新增項目失敗: 此分類下已存在相同名稱的項目。', 'error') //
    } else {
       showToast(`新增項目失敗: ${error.message}`, 'error') //
    }
    console.error("Add item error:", error);
  } else {
    newItemName.value[categoryId] = '' 
    showToast('項目新增成功', 'success'); //
    await configStore.fetchConfig() //
  }
  isSaving.value = false;
}

const deleteItem = async (id) => {
  if (isSaving.value) return;
  if (confirm('確定要刪除此檢查項目嗎？')) {
    isSaving.value = true;
    const { error } = await supabase.from('checklist_items').delete().eq('id', id) //
    if (error) {
      showToast(`刪除項目失敗: ${error.message}`, 'error') //
      console.error("Delete item error:", error);
    } else {
      showToast('項目已刪除', 'success'); //
      await configStore.fetchConfig() //
    }
    isSaving.value = false;
  }
}

const moveItem = async (categoryId, index, direction) => {
    if (isSaving.value || !categories.value) return;

    const category = categories.value.find(c => c.id === categoryId);
    if (!category || !category.items) return;
    const itemsInCategory = category.items;

    const itemToMove = itemsInCategory[index];
    const swapIndex = direction === 'up' ? index - 1 : index + 1;

    if (swapIndex < 0 || swapIndex >= itemsInCategory.length) return;

    const itemToSwap = itemsInCategory[swapIndex];

    if (!itemToMove || !itemToSwap) {
        console.error("無法移動項目，索引無效");
        return;
    }

    isSaving.value = true;
    console.log(`Moving item '${itemToMove.name}' ${direction}... Swapping order with '${itemToSwap.name}'`);

    const updates = [
        { id: itemToMove.id, display_order: itemToSwap.display_order },
        { id: itemToSwap.id, display_order: itemToMove.display_order }
    ];

     console.log("Upserting item order:", updates);
    const { error } = await supabase.from('checklist_items').upsert(updates); //

    if (error) {
        showToast(`移動項目失敗: ${error.message}`, 'error'); //
        console.error("Move item error:", error);
    } else {
        showToast('項目順序已更新', 'success'); //
        await configStore.fetchConfig(); //
    }
    isSaving.value = false;
}

</script>

<style scoped>
.form-control {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
.form-control-sm {
  @apply py-2 px-3 text-sm;
}
.btn-primary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-sm {
  @apply px-4 py-2 text-sm;
}
.btn-danger-secondary {
   @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-500/30 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-icon-secondary {
  @apply inline-flex items-center justify-center p-2 rounded-md font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-600 dark:text-slate-300 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-icon-secondary-sm {
  @apply inline-flex items-center justify-center p-1 rounded font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-600 border border-slate-900/10 dark:border-slate-500 text-slate-500 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-500 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-icon-danger-sm {
   @apply inline-flex items-center justify-center p-1 rounded font-medium transition-all duration-200 cursor-pointer bg-red-100 dark:bg-red-500/20 text-red-600 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-500/30 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>