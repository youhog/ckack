<template>
  <dialog ref="dialogRef" class="p-0 rounded-2xl shadow-xl w-full max-w-lg backdrop:bg-black/40 backdrop:backdrop-blur-sm" @close="$emit('update:modelValue', false)">
      <div class="bg-white dark:bg-slate-800 rounded-2xl">
          <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
              <h3 class="text-lg font-semibold text-slate-800 dark:text-slate-100">標記異常: {{ itemName }}</h3>
              <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">請標記哪個床位有問題 (共 4 個床位)。</p>
          </div>
          <div class="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
              <div 
                  v-for="(label, index) in OCCUPANT_LABELS" 
                  :key="label" 
                  class="p-4 rounded-lg border transition-all duration-200" 
                  :class="occupantStatusClass(index)"
              >
                  <div class="flex justify-between items-center mb-2">
                      <strong class="text-slate-800 dark:text-slate-100">{{ label }}</strong>
                      <select 
                        :value="tempOccupantsStatus[SUFFIXES[index]] || 'good'" 
                        @change="updateTempStatus(index, $event.target.value)"
                        class="form-control w-auto py-1"
                      >
                          <option value="good">良好 ✅</option>
                          <option value="damaged">損壞 ❌</option>
                          <option value="missing">遺失 ⚠️</option>
                      </select>
                  </div>
                  <textarea 
                    :value="tempOccupantsNotes[SUFFIXES[index]] || ''"
                    @input="updateTempNotes(index, $event.target.value)"
                    :placeholder="`${label}的具體備註 (選填)`" 
                    class="form-control resize-none mt-2 text-sm" 
                    :class="{ 'dark:placeholder-slate-400': true }"
                    rows="1"
                  ></textarea>
              </div>
          </div>
          <div class="px-6 py-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-2xl flex justify-end gap-3">
              <button @click="$emit('update:modelValue', false)" class="btn-secondary">取消</button>
              <button @click="saveIssues" class="btn-primary">保存問題</button>
          </div>
      </div>
  </dialog>
</template>

<script setup>
import { ref, watch, nextTick, computed } from 'vue';

const props = defineProps({
  modelValue: Boolean, 
  itemId: String,
  itemName: String,
  baseStatus: String, 
  initialNotes: Object, 
});

const emit = defineEmits(['update:modelValue', 'save']);

const dialogRef = ref(null);
const SUFFIXES = ['-A', '-B', '-C', '-D']; 
const OCCUPANT_LABELS = ['A 床', 'B 床', 'C 床', 'D 床'];

const tempOccupantsStatus = ref({}); 
const tempOccupantsNotes = ref({});  

// Watch modelValue to control dialog visibility
watch(() => props.modelValue, (newValue) => {
    if (newValue) {
        const occupants = props.initialNotes?.occupantStatus || {};
        const occupantNotes = props.initialNotes?.occupantNotes || {};

        // 1. Load Status
        SUFFIXES.forEach(suffix => {
            // *** 核心修改：始終從 'good' 開始，除非狀態已存在 ***
            const existingStatus = occupants[suffix];
            tempOccupantsStatus.value[suffix] = existingStatus || 'good'; // 預設為 'good'
        });

        // 2. Load Notes
        SUFFIXES.forEach(suffix => {
            tempOccupantsNotes.value[suffix] = occupantNotes[suffix] || '';
        });
        
        nextTick(() => dialogRef.value?.showModal());
    } else {
        dialogRef.value?.close();
    }
}, { immediate: true }); // Use immediate: true for initial state sync

// --- Handlers ---
const updateTempStatus = (index, newStatus) => {
    const suffix = SUFFIXES[index];
    tempOccupantsStatus.value = { ...tempOccupantsStatus.value, [suffix]: newStatus };
};

const updateTempNotes = (index, newNote) => {
    const suffix = SUFFIXES[index];
    tempOccupantsNotes.value = { ...tempOccupantsNotes.value, [suffix]: newNote };
};

const saveIssues = () => {
    let newOccupants = {};
    let newOccupantNotes = {};
    let hasIssue = false;
    let worstBaseStatus = 'good'; // 決定 Item 的基本狀態 (如果至少有一個不是 good)

    // Process all 4 occupants
    SUFFIXES.forEach(suffix => {
        const status = tempOccupantsStatus.value[suffix] || 'good';
        const notes = tempOccupantsNotes.value[suffix] ? tempOccupantsNotes.value[suffix].trim() : '';

        if (status !== 'good') {
            hasIssue = true;
            newOccupants[suffix] = status;

            // 確定最差的狀態作為 Item 的基本狀態
            if (worstBaseStatus === 'good') {
                worstBaseStatus = status;
            } else if (worstBaseStatus === 'damaged' && status === 'missing') {
                worstBaseStatus = 'missing'; 
            } else if (worstBaseStatus === 'missing' && status === 'damaged') {
                 // 保持 missing
                 worstBaseStatus = 'missing'; 
            }
        }
        if (notes) {
            newOccupantNotes[suffix] = notes;
        }
    });

    // Final base status reflects the worst case found, or is 'good' if no issues were found.
    const finalBaseStatus = hasIssue ? worstBaseStatus : 'good';
    
    // Emit the complex data structure back to ChecklistItem
    emit('save', {
        baseStatus: finalBaseStatus,
        occupantStatus: newOccupants,
        occupantNotes: newOccupantNotes,
    });
};

// --- Utilities ---
const occupantStatusClass = (index) => {
    const status = tempOccupantsStatus.value[SUFFIXES[index]] || 'good';
    switch (status) {
        case 'damaged': return 'border-red-500 bg-red-500/5 dark:bg-red-500/10';
        case 'missing': return 'border-yellow-500 bg-yellow-500/5 dark:bg-yellow-500/10';
        default: return 'border-slate-300 dark:border-slate-700 bg-slate-50 dark:bg-slate-700/30';
    }
}
</script>

<style scoped>
/* 修正 2: 確保深色模式下的 Form Control 樣式 */
.form-control {
  @apply w-full px-3 py-2 rounded-lg border border-slate-300 dark:border-slate-600 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
  /* 修正 2: 確保文字和 placeholder 有足夠的對比 */
  @apply text-slate-800 dark:text-slate-200 placeholder-slate-400 dark:placeholder-slate-500; 
}
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-blue-600 hover:bg-blue-700 text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>