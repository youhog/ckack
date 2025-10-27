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
      class="btn btn-secondary" 
      @click="triggerFileInput" 
      :disabled="uploading"
      style="padding: 6px 12px; font-size: 12px;"
    >
      <span v-if="uploading">🔄 上傳中...</span>
      <span v-else>📷 拍照</span>
    </button>
    
    <img 
      v-if="photoPreviewUrl"
      :src="photoPreviewUrl" 
      class="photo-preview"
      :class="{ 'hidden': !photoPreviewUrl }" 
      @click="viewPhoto"
      alt="照片預覽"
    >
    
    <div v-if="errorMsg" class="text-red-500 text-sm">{{ errorMsg }}</div>

    <!-- 照片預覽彈窗 -->
    <dialog ref="photoDialog" id="photoModal" class="p-0 bg-transparent" @click.self="closePhotoDialog">
        <div class="relative max-w-4xl max-h-full p-4">
            <img :src="photoPreviewUrl" class="max-w-full max-h-[85vh] object-contain rounded-2xl" alt="照片全螢幕預覽">
            <button @click="photoDialog.close()" class="close-modal-btn absolute top-4 right-4 bg-white text-black rounded-full w-8 h-8 flex items-center justify-center">×</button>
        </div>
    </dialog>
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { supabase } from '../services/supabase'
import { userStore } from '../store/user'

const props = defineProps({
  itemId: String,
  existingPhotoUrl: String
})

const emit = defineEmits(['upload-success'])

const fileInput = ref(null)
const uploading = ref(false)
const errorMsg = ref(null)
const uploadedUrl = ref(null) // 儲存剛上傳的照片 URL

// 預覽 URL 優先顯示剛上傳的，其次是已儲存的
const photoPreviewUrl = computed(() => uploadedUrl.value || props.existingPhotoUrl)

const triggerFileInput = () => {
  fileInput.value.click()
}

const handleFileChange = async (event) => {
  const file = event.target.files[0]
  if (!file) return

  uploading.value = true
  errorMsg.value = null
  
  const user = userStore.state.user
  if (!user) {
    errorMsg.value = '錯誤：使用者未登入'
    uploading.value = false
    return
  }

  // 1. 建立唯一檔案路徑
  const fileExt = file.name.split('.').pop()
  const filePath = `${user.id}/${props.itemId}-${new Date().getTime()}.${fileExt}`

  // 2. 上傳到 Supabase Storage (Bucket: 'photos')
  const { error: uploadError } = await supabase.storage
    .from('photos')
    .upload(filePath, file, {
      cacheControl: '3600', // 1 小時
      upsert: false
    })

  if (uploadError) {
    errorMsg.value = `上傳失敗: ${uploadError.message}`
    uploading.value = false
    return
  }

  // 3. 獲取公開 URL
  const { data } = supabase.storage
    .from('photos')
    .getPublicUrl(filePath)

  if (data) {
    const publicUrl = data.publicUrl
    uploadedUrl.value = publicUrl
    // 4. 通知父元件
    emit('upload-success', publicUrl) 
  } else {
     errorMsg.value = '無法獲取照片 URL'
  }
  
  uploading.value = false
  fileInput.value.value = '' // 清空 input
}

// 預覽功能
const photoDialog = ref(null)
const viewPhoto = () => {
  if (photoPreviewUrl.value) {
    photoDialog.value?.showModal()
  }
}
const closePhotoDialog = (e) => {
  // 點擊背景時關閉
  if (e.target === photoDialog.value) {
    photoDialog.value?.close()
  }
}

// 當父元件傳入的 URL 變化時 (例如，報告提交後清空)
watch(() => props.existingPhotoUrl, (newUrl) => {
  if (!newUrl) {
    uploadedUrl.value = null // 清除本地上傳的 URL
  }
})
</script>
