<template>
  <div class="card p-6 fade-in">
    <div class="flex items-center gap-3 mb-4">
        <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center text-white text-lg">
            {{ category.icon }}
        </div>
        <h3 class="text-xl font-semibold text-gray-800">{{ category.name }}</h3>
    </div>

    <div class="space-y-4">
      <ChecklistItem
        v-for="item in items"
        :key="item.id"
        :item-id="item.id"  
        :item-name="item.name"
        :status="checkData[item.id] || 'pending'"
        :notes="notesData[item.id] || ''"
        :photo-url="photoData[item.id] || null"
        @update:status="updateStatus"
        @update:notes="updateNotes"
        @update:photo="updatePhoto"
      />
    </div>
  </div>
</template>

<script setup>
import ChecklistItem from './ChecklistItem.vue'

const props = defineProps({
  category: Object,
  items: Array, // 傳入該分類的項目
  checkData: Object,
  notesData: Object,
  photoData: Object
})

const emit = defineEmits(['update:checkData', 'update:notesData', 'update:photoData'])

// 這裡的邏輯不變，因為 itemId 已經是 item.id
const updateStatus = ({ itemId, status }) => {
  const newCheckData = { ...props.checkData, [itemId]: status }
  emit('update:checkData', newCheckData)
}

const updateNotes = ({ itemId, notes }) => {
  const newNotesData = { ...props.notesData, [itemId]: notes }
  emit('update:notesData', newNotesData)
}

const updatePhoto = ({ itemId, url }) => {
  const newPhotoData = { ...props.photoData, [itemId]: url }
  emit('update:photoData', newPhotoData)
}
</script>
