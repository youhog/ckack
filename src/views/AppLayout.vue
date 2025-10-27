<template>
  <div class="container mx-auto px-4 py-8 max-w-6xl">
    <AppHeader
      v-model:dormZone="formState.dormZone"
      v-model:roomNumber="formState.roomNumber"
      v-model:roomNumberInput="formState.roomNumberInput"
      v-model:checkType="formState.checkType"
      v-model:inspector="formState.inspector"
      :view="currentView"
      :progress="inspectionProgress"
      @navigate="navigateTo"
    />

    <router-view v-slot="{ Component }">
       <component
          :is="Component"
          :formState="formState"
          :progress="inspectionProgress"
          @report-generated="onReportGenerated"
          @checklist-updated="updateInspectionProgress"
        />
    </router-view>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { userStore } from '../store/user'
import AppHeader from '../components/AppHeader.vue'

const route = useRoute()
const router = useRouter()
const user = userStore.state.user

// 【修改】將表單狀態提升到佈局層
const formState = reactive({
  dormZone: '', // 儲存 zone.id
  roomNumber: '', // 儲存驗證後的 room.id
  roomNumberInput: '', // 【新增】儲存房號的文字輸入
  checkType: '', // 儲存 type.id
  inspector: user?.email ? user.email.split('@')[0] : '',
})

// 檢查進度狀態
const inspectionProgress = ref({
  completed: 0,
  total: 0,
  percentage: 0
})

// 當前視圖 (檢查或管理)
const currentView = computed(() => route.path.startsWith('/admin') ? 'admin' : 'inspection')

// 導航到不同視圖
const navigateTo = (view) => {
  if (view === 'admin') {
      if (!route.path.startsWith('/admin')) {
          router.push({ name: 'AdminDashboard' })
      }
  } else {
      if (route.name !== 'Inspection') {
         router.push({ name: 'Inspection' })
      }
  }
}

// 監聽來自 Inspection.vue 的進度更新
const updateInspectionProgress = (progress) => {
  if (progress && typeof progress.completed === 'number' && typeof progress.total === 'number' && typeof progress.percentage === 'number') {
      inspectionProgress.value = progress;
  } else {
      console.warn("Received invalid progress update:", progress);
  }
}


// 監聽來自 Inspection.vue 的報告生成事件
const onReportGenerated = () => {
  // 【修改】清空檢查人員以外的表單
  formState.dormZone = '';
  formState.roomNumber = '';
  formState.roomNumberInput = ''; // <-- 新增
  formState.checkType = '';
  inspectionProgress.value = { completed: 0, total: 0, percentage: 0 }
}

// 當 user 狀態變化時 (例如登入後)，更新 inspector 預設值
watch(() => userStore.state.user, (newUser) => {
    if (newUser?.email && !formState.inspector) {
        formState.inspector = newUser.email.split('@')[0];
    }
}, { immediate: true });

// 【新增】當區域改變時，清空房號相關欄位
watch(() => formState.dormZone, (newZone, oldZone) => {
    if (newZone !== oldZone) {
        formState.roomNumber = '';
        formState.roomNumberInput = '';
    }
});

</script>