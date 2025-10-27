<template>
  <div class="check-item" :class="`check-item-${status}`" :id="`item-${itemId}`">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
              <div class="font-medium text-gray-800">{{ itemName }}</div>
              <div class="flex gap-2 mt-2">
                  <button 
                    class="status-btn btn" 
                    :class="status === 'good' ? 'btn-primary' : 'btn-secondary'" 
                    @click="$emit('update:status', { itemId, status: 'good' })"
                    style="padding: 6px 12px; font-size: 12px;">
                      ✅ 良好
                  </button>
                  <button 
                    class="status-btn btn" 
                    :class="status === 'damaged' ? 'btn-primary' : 'btn-secondary'" 
                    @click="$emit('update:status', { itemId, status: 'damaged' })"
                    :style="status === 'damaged' ? 'background: #ef4444; color: white; padding: 6px 12px; font-size: 12px;' : 'padding: 6px 12px; font-size: 12px;'">
                      ❌ 損壞
                  </button>
                  <button 
                    class="status-btn btn" 
                    :class="status === 'missing' ? 'btn-primary' : 'btn-secondary'" 
                    @click="$emit('update:status', { itemId, status: 'missing' })"
                    :style="status === 'missing' ? 'background: #f59e0b; color: white; padding: 6px 12px; font-size: 12px;' : 'padding: 6px 12px; font-size: 12px;'">
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
            class="form-control resize-none" 
            rows="2"
          ></textarea>
      </div>
  </div>
</template>

<script setup>
import PhotoUploader from './PhotoUploader.vue'

const props = defineProps({
  itemId: String, // 這是 "uuid-..."
  itemName: String,
  status: String,
  notes: String,
  photoUrl: String
})

const emit = defineEmits(['update:status', 'update:notes', 'update:photo'])

const onPhotoUpload = (url) => {
  emit('update:photo', { itemId: props.itemId, url })
}
</script>
