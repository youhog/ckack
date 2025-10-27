<template>
  <div class="flex gap-2 items-center">
    <input 
      type="file" 
      class="hidden" 
      accept="image/*" 
      ref="fileInput" 
      @change="handleFileChange"
      :disabled="uploading"
    >
    <button 
      class="inline-flex items-center justify-center px-3 py-1.5 text-xs font-medium rounded-md transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed" 
      @click="triggerFileInput" 
      :disabled="uploading"
    >
      <span v-if="uploading" class="flex items-center">
        <svg class="animate-spin -ml-0.5 mr-1.5 h-3 w-3" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
        上傳中...
      </span>
      <span v-else class="flex items-center gap-1">📷 拍照</span>
    </button>
    
    <img 
      v-if="photoPreviewUrl"
      :src="photoPreviewUrl" 
      class="w-10 h-10 object-cover rounded-md border border-slate-200 dark:border-slate-700 cursor-pointer hover:opacity-80 transition-opacity"
      @click="viewPhoto"
      alt="照片預覽"
    >
    
    <div v-if="errorMsg" class="text-red-500 text-xs">{{ errorMsg }}</div>

    <dialog ref="photoDialog" id="photoModal" class="p-0 bg-transparent shadow-none border-none max-w-4xl max-h-[90vh]" @click.self="closePhotoDialog">
        <div class="relative max-w-4xl max-h-full p-4">
            <img :src="photoPreviewUrl" class="max-w-full max-h-[85vh] object-contain rounded-2xl" alt="照片全螢幕預覽">
            <button 
              @click="photoDialog.close()" 
              class="absolute top-4 right-4 bg-white/70 dark:bg-black/70 text-black dark:text-white rounded-full w-8 h-8 flex items-center justify-center backdrop-blur-sm hover:bg-white dark:hover:bg-black transition-colors"
            >
              ✕
            </button>
        </div>
    </dialog>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { supabase } from '../services/supabase' //
import { userStore } from '../store/user' //

// --- (所有 <script> 邏輯保持不變) ---
const props = defineProps({
  itemId: String,
  existingPhotoUrl: String
})

const emit = defineEmits(['upload-success'])

const fileInput = ref(null)
const uploading = ref(false)
const errorMsg = ref(null)
const uploadedUrl = ref(null)

const photoPreviewUrl = computed(() => uploadedUrl.value || props.existingPhotoUrl)

const triggerFileInput = () => {
  fileInput.value.click()
}

const handleFileChange = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  uploading.value = true
  errorMsg.value = null
  
  const user = userStore.state.user; //
  if (!user) {
    errorMsg.value = '錯誤：使用者未登入'
    uploading.value = false
    return
  }

  const fileExt = file.name.split('.').pop()
  const filePath = `${user.id}/${props.itemId}-${new Date().getTime()}.${fileExt}`

  const { error: uploadError } = await supabase.storage //
    .from('photos') //
    .upload(filePath, file, {
      cacheControl: '3600', 
      upsert: false
    })

  if (uploadError) {
    errorMsg.value = `上傳失敗: ${uploadError.message}`
    uploading.value = false
    return
  }

  const { data } = supabase.storage //
    .from('photos') //
    .getPublicUrl(filePath)

  if (data) {
    const publicUrl = data.publicUrl
    uploadedUrl.value = publicUrl
    emit('upload-success', publicUrl) 
  } else {
     errorMsg.value = '無法獲取照片 URL'
  }
  
  uploading.value = false
  fileInput.value.value = '' 
}

const photoDialog = ref(null)
const viewPhoto = () => {
  if (photoPreviewUrl.value) {
    photoDialog.value?.showModal()
  }
}
const closePhotoDialog = (e) => {
  if (e.target === photoDialog.value) {
    photoDialog.value?.close()
  }
}

watch(() => props.existingPhotoUrl, (newUrl) => {
  if (!newUrl) {
    uploadedUrl.value = null 
  }
})
</script>