<!-- src/views/AppLayout.vue -->
<template>
  <div class="container mx-auto px-4 py-8 max-w-6xl">
    <!-- AppHeader 元件包含了所有頂部表單和導航 -->
    <AppHeader
      v-model:dormZone="formState.dormZone"
      v-model:roomNumber="formState.roomNumber"
      v-model:checkType="formState.checkType"
      v-model:inspector="formState.inspector"
      :view="currentView"
      :progress="inspectionProgress"
      @navigate="navigateTo"
    />

    <!-- 根據路由顯示 檢查(Inspection) 或 後台(Admin) -->
    <!-- 使用 v-slot 將事件處理直接綁定 -->
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

// 將表單狀態提升到佈局層，以便 Header 和 Inspection 都能訪問
const formState = reactive({
  dormZone: '', // 儲存 zone.id
  roomNumber: '', // 儲存 room.id
  checkType: '', // 儲存 type.id
  // 檢查人員姓名預設帶入 Email (移除 @...)
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
      // 如果目前不在 admin 路徑下，則跳轉到儀表板
      if (!route.path.startsWith('/admin')) {
          router.push({ name: 'AdminDashboard' })
      }
  } else {
      // 如果目前不在檢查模式主頁，則跳轉
      if (route.name !== 'Inspection') {
         router.push({ name: 'Inspection' })
      }
  }
}

// 監聽來自 Inspection.vue 的進度更新
const updateInspectionProgress = (progress) => {
  // 添加檢查確保 progress 是有效物件
  if (progress && typeof progress.completed === 'number' && typeof progress.total === 'number' && typeof progress.percentage === 'number') {
      inspectionProgress.value = progress;
  } else {
      console.warn("Received invalid progress update:", progress);
      // 可以選擇重設為 0
      // inspectionProgress.value = { completed: 0, total: 0, percentage: 0 };
  }
}


// 監聽來自 Inspection.vue 的報告生成事件
const onReportGenerated = () => {
  // 清空檢查人員以外的表單 (保留 inspector)
  formState.dormZone = '';
  formState.roomNumber = '';
  formState.checkType = '';
  // 進度也應重設 (Inspection.vue 會自行清空 checkData)
  inspectionProgress.value = { completed: 0, total: 0, percentage: 0 }
}

// 當 user 狀態變化時 (例如登入後)，更新 inspector 預設值
watch(() => userStore.state.user, (newUser) => {
    if (newUser?.email && !formState.inspector) { // 只有在 inspector 為空時才更新
        formState.inspector = newUser.email.split('@')[0];
    }
}, { immediate: true });

</script>

