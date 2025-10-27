<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 animate-fade-in">
    <div class="flex items-center gap-3 mb-6">
        <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center text-white text-lg shadow">
            {{ category.icon }}
        </div>
        <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100">{{ category.name }}</h3>
    </div>

    <div class="space-y-4">
      <ChecklistItem
        v-for="item in items"
        :key="item.id"
        :item-id="item.id"
        :item-name="item.name"
        :is-per-person="isPerPerson" :status="checkData[item.id] || 'pending'"
        :notes-object="notesData[item.id]" :photo-url="photoData[item.id] || null"
        @update:status="updateStatus"
        @update:notes="updateNotes"
        @update:photo="updatePhoto"
      />
    </div>
  </div>
</template>

<script setup>
import ChecklistItem from './ChecklistItem.vue' //

const props = defineProps({
  category: Object,
  items: Array,
  isPerPerson: Boolean, // *** NEW PROP ***
  checkData: Object,
  notesData: Object,
  photoData: Object
})

const emit = defineEmits(['update:checkData', 'update:notesData', 'update:photoData'])

// 狀態更新 (簡單覆蓋)
const updateStatus = ({ itemId, status }) => {
  const newCheckData = { ...props.checkData, [itemId]: status }
  emit('update:checkData', newCheckData)
}

// 備註更新 (傳遞複雜物件，適用於個人項目)
const updateNotes = ({ itemId, notes }) => {
  const newNotesData = { ...props.notesData, [itemId]: notes }
  emit('update:notesData', newNotesData)
}

// 照片更新 (簡單覆蓋)
const updatePhoto = ({ itemId, url }) => {
  const newPhotoData = { ...props.photoData, [itemId]: url }
  emit('update:photoData', newPhotoData)
}
</script>

<style scoped>
@keyframes fadeIn {
  from { opacity: 0; transform: translateY(10px); }
  to { opacity: 1; transform: translateY(0); }
}
.animate-fade-in {
  animation: fadeIn 0.3s ease-out;
}
</style>