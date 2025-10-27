<template>
  <div class="p-5 rounded-xl transition-all duration-300 border-l-4" :class="statusClass" :id="`item-${itemId}`">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
              <div class="font-medium text-slate-800 dark:text-slate-100">{{ itemName }}</div>
              <div class="flex gap-2 mt-3">
                  <button 
                    class="px-4 py-1.5 text-xs font-medium rounded-full transition-all duration-200" 
                    :class="status === 'good' ? 'bg-green-600 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-600'"
                    @click="$emit('update:status', { itemId, status: 'good' })"
                  >
                      ✅ 良好
                  </button>
                  <button 
                    class="px-4 py-1.5 text-xs font-medium rounded-full transition-all duration-200" 
                    :class="status === 'damaged' ? 'bg-red-600 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-600'"
                    @click="$emit('update:status', { itemId, status: 'damaged' })"
                  >
                      ❌ 損壞
                  </button>
                  <button 
                    class="px-4 py-1.5 text-xs font-medium rounded-full transition-all duration-200" 
                    :class="status === 'missing' ? 'bg-yellow-500 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-600'"
                    @click="$emit('update:status', { itemId, status: 'missing' })"
                  >
                      ⚠️ 遺失
                  </button>
              </div>
          </div>
          
          <PhotoUploader 
            :item-id="itemId"
            :existing-photo-url="photoUrl"
            @upload-success="onPhotoUpload"
          />

      </div>
      <div class="mt-3">
          <textarea 
            :value="notes" 
            @input="$emit('update:notes', { itemId, notes: $event.target.value })" 
            placeholder="請輸入備註說明..." 
            class="w-full px-4 py-2 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm resize-none focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20" 
            rows="2"
          ></textarea>
      </div>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import PhotoUploader from './PhotoUploader.vue'

const props = defineProps({
  itemId: String,
  itemName: String,
  status: String,
  notes: String,
  photoUrl: String
})

const emit = defineEmits(['update:status', 'update:notes', 'update:photo'])

const onPhotoUpload = (url) => {
  emit('update:photo', { itemId: props.itemId, url })
}

// 【新增】computed class
const statusClass = computed(() => {
  switch (props.status) {
    case 'good':
      return 'border-green-500 bg-green-50 dark:bg-green-500/10'
    case 'damaged':
      return 'border-red-500 bg-red-50 dark:bg-red-500/10'
    case 'missing':
      return 'border-yellow-500 bg-yellow-50 dark:bg-yellow-500/10'
    default:
      return 'border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800'
  }
})
</script>