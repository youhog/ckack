<template>
  <div class="p-5 rounded-xl transition-all duration-300 border-l-4 hover:shadow-md hover:-translate-y-0.5" :class="statusClass" :id="`item-${itemId}`">
      <div class="flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div class="flex-1">
              <div class="font-medium text-slate-800 dark:text-slate-100">{{ itemName }}</div>
              <div class="flex gap-2 mt-3">
                  <button 
                    class="status-btn px-4 py-1.5 text-xs font-medium rounded-full transition-all duration-200" 
                    :class="!isPerPerson && status === 'good' ? 'bg-green-600 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-600'"
                    @click="updateStatus('good')"
                  >
                      ✅ 良好
                  </button>
                  <button 
                    class="status-btn px-4 py-1.5 text-xs font-medium rounded-full transition-all duration-200" 
                    :class="baseStatusClicked === 'damaged' && hasIssues ? 'bg-red-600 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-600'"
                    @click="updateStatus('damaged')"
                  >
                      ❌ 損壞
                  </button>
                  <button 
                    class="status-btn px-4 py-1.5 text-xs font-medium rounded-full transition-all duration-200" 
                    :class="baseStatusClicked === 'missing' && hasIssues ? 'bg-yellow-500 text-white' : 'bg-slate-200 dark:bg-slate-700 text-slate-700 dark:text-slate-300 hover:bg-slate-300 dark:hover:bg-slate-600'"
                    @click="updateStatus('missing')"
                  >
                      ⚠️ 遺失
                  </button>
                  <span v-if="isPerPerson && hasIssues" class="px-2 py-1 text-xs font-medium rounded-full bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300 ml-2 cursor-pointer" @click="showOccupantModal = true">
                     👤 {{ issueCount }}/4 有問題
                  </span>
                  <span v-else-if="isPerPerson && status === 'good'" class="px-2 py-1 text-xs font-medium rounded-full bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-300 ml-2">
                     ✅ 良好 (4人)
                  </span>
                  <span v-else-if="status === 'pending'" class="px-2 py-1 text-xs font-medium rounded-full bg-slate-100 dark:bg-slate-700 text-slate-600 dark:text-slate-300 ml-2">
                     ⏳ 待檢查
                  </span>
              </div>
          </div>
          
          <PhotoUploader 
            :item-id="itemId"
            :existing-photo-url="photoUrl"
            @upload-success="onPhotoUpload"
          />

      </div>
      
      <div v-if="!isPerPerson" class="mt-3">
          <textarea 
            :value="notes"
            @input="$emit('update:notes', { itemId, notes: $event.target.value })"
            placeholder="請輸入備註說明..."
            class="form-control resize-none" 
            rows="2"
          ></textarea>
      </div>

      <OccupantIssueModal 
        v-if="isPerPerson"
        v-model="showOccupantModal"
        :item-id="itemId"
        :item-name="itemName"
        :base-status="baseStatusClicked"
        :initial-notes="notesObject"
        @save="handleOccupantSave"
      />
  </div>
</template>

<script setup>
import { computed, ref, watch } from 'vue'
import PhotoUploader from './PhotoUploader.vue' //
import OccupantIssueModal from './OccupantIssueModal.vue'; 

const props = defineProps({
  itemId: String, 
  itemName: String,
  isPerPerson: Boolean, 
  status: String, // 'good', 'damaged', 'missing', 'pending' (base status)
  notes: String, // Simple notes string for non-personal items
  notesObject: Object, // Complex notes object for personal items (used for isPerPerson=true)
  photoUrl: String
})

const emit = defineEmits(['update:status', 'update:notes', 'update:photo'])

const showOccupantModal = ref(false);
const baseStatusClicked = ref(props.status); 

// --- Computed Status/Notes ---

// 檢查此項目是否有任何問題 (共享項目看 status，個人項目看 notesObject)
const hasIssues = computed(() => {
    if (props.isPerPerson) {
        const occupants = props.notesObject?.occupantStatus || {};
        return Object.values(occupants).some(s => s !== 'good');
    }
    return props.status === 'damaged' || props.status === 'missing';
});

// 計算問題數量
const issueCount = computed(() => {
    if (!props.isPerPerson) return 0;
    const occupants = props.notesObject?.occupantStatus || {};
    return Object.values(occupants).filter(s => s !== 'good').length;
});

// 邊界顏色和背景
const statusClass = computed(() => {
  if (hasIssues.value) {
    return 'border-red-500 bg-red-50 dark:bg-red-500/10'
  }
  if (props.status === 'pending') {
      return 'border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-800'
  }
  return 'border-green-500 bg-green-50 dark:bg-green-500/10'
});

// --- Event Handlers ---

const onPhotoUpload = (url) => {
  emit('update:photo', { itemId: props.itemId, url })
}

const updateStatus = (newStatus) => {
    // 1. 如果點擊'良好'或非個人項目，直接更新狀態
    if (newStatus === 'good' || !props.isPerPerson) {
        emit('update:status', { itemId: props.itemId, status: newStatus });
        // 重設/清空個人項目狀態 (如果從有問題變回良好)
        if (props.isPerPerson && hasIssues.value) {
             emit('update:notes', { itemId: props.itemId, notes: {} }); // 清空 notes object
        }
        return;
    }
    
    // 2. 如果是個人項目且點擊了 'damaged' 或 'missing'，彈出 Modal
    if (props.isPerPerson && (newStatus === 'damaged' || newStatus === 'missing')) {
        baseStatusClicked.value = newStatus;
        showOccupantModal.value = true;
    }
}

const handleOccupantSave = ({ baseStatus, occupantStatus, occupantNotes }) => {
    // 1. Update checkData status based on modal result
    emit('update:status', { itemId: props.itemId, status: baseStatus });
    
    // 2. Update notesObject with the new complex data structure
    const newNotesObject = {
        occupantStatus: occupantStatus,
        occupantNotes: occupantNotes,
        // baseNotes: '', // For simplicity, we only store occupant details now
    };
    emit('update:notes', { itemId: props.itemId, notes: newNotesObject });
    
    showOccupantModal.value = false;
}

// 確保 baseStatusClicked 隨 status 變動 (例如從 Inspector.vue 的 initialize)
watch(() => props.status, (newStatus) => {
    if (newStatus !== baseStatusClicked.value) {
        baseStatusClicked.value = newStatus;
    }
});
</script>

<style scoped>
.form-control {
  @apply w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 transition-all duration-200 text-sm placeholder-slate-400 dark:placeholder-slate-500;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
</style>