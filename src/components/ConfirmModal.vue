<template>
  <dialog ref="dialogRef" class="p-0 rounded-2xl shadow-xl w-full max-w-md backdrop:bg-black/40 backdrop:backdrop-blur-sm" @close="handleClose">
    <div class="bg-white dark:bg-slate-800 rounded-2xl">
      <div class="px-6 py-4 border-b border-slate-200 dark:border-slate-700">
        <h3 class="text-lg font-semibold text-slate-800 dark:text-slate-100">{{ title }}</h3>
      </div>
      <div class="px-6 py-5">
        <p class="text-sm text-slate-600 dark:text-slate-300 whitespace-pre-wrap">{{ message }}</p>
      </div>
      <div class="px-6 py-4 bg-slate-50 dark:bg-slate-900/50 rounded-b-2xl flex justify-end gap-3">
        <button 
          @click="cancel" 
          class="btn-secondary"
          ref="cancelButtonRef"
        >
          {{ cancelText }}
        </button>
        <button 
          @click="confirm" 
          :class="confirmButtonClass"
          ref="confirmButtonRef"
        >
          {{ confirmText }}
        </button>
      </div>
    </div>
  </dialog>
</template>

<script setup>
import { ref, watch, computed, nextTick } from 'vue';

const props = defineProps({
  modelValue: Boolean, // Controls visibility using v-model
  title: {
    type: String,
    default: '確認操作',
  },
  message: {
    type: String,
    required: true,
  },
  confirmText: {
    type: String,
    default: '確定',
  },
  cancelText: {
    type: String,
    default: '取消',
  },
  confirmVariant: {
    type: String, // 'primary', 'danger', etc.
    default: 'primary',
  },
});

const emit = defineEmits(['update:modelValue', 'confirm', 'cancel']);

const dialogRef = ref(null);
const cancelButtonRef = ref(null);
const confirmButtonRef = ref(null);

// Control dialog visibility based on v-model
watch(() => props.modelValue, (newValue) => {
  if (newValue) {
    dialogRef.value?.showModal();
    // Auto-focus the cancel button for safety
    nextTick(() => {
        cancelButtonRef.value?.focus();
    });
  } else {
    dialogRef.value?.close();
  }
});

// Determine confirm button style
const confirmButtonClass = computed(() => {
  switch (props.confirmVariant) {
    case 'danger':
      return 'btn-danger'; // Requires .btn-danger definition
    default:
      return 'btn-primary';
  }
});

// Event handlers
const confirm = () => {
  emit('confirm');
  closeDialog();
};

const cancel = () => {
  emit('cancel');
  closeDialog();
};

const closeDialog = () => {
  emit('update:modelValue', false); // Update v-model
};

// Handle closing via ESC key or backdrop click
const handleClose = () => {
    // Check if the dialog is still supposed to be open (modelValue is true)
    // If yes, it means it was closed by ESC or backdrop, so emit cancel and update modelValue
    if (props.modelValue) {
        emit('cancel');
        emit('update:modelValue', false);
    }
};

</script>

<style scoped>
.btn-primary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-all duration-200 cursor-pointer bg-blue-600 hover:bg-blue-700 text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-secondary {
  @apply inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-300 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-60 disabled:cursor-not-allowed;
}
.btn-danger {
   @apply inline-flex items-center justify-center px-4 py-2 rounded-lg font-medium transition-all duration-200 cursor-pointer bg-red-600 hover:bg-red-700 text-white shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>