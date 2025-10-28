// src/views/AppLayout.vue
<template>
  <div class="container mx-auto px-4 py-8 max-w-7xl">
    <AppHeader
      v-model:dormZone="formState.dormZone"
      v-model:household="formState.household" v-model:roomNumber="formState.roomNumber"
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
          @update:dormZone="(val) => formState.dormZone = val"
          @update:household="(val) => formState.household = val" @update:roomNumber="(val) => formState.roomNumber = val"
        />
    </router-view>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { userStore } from '../store/user' //
import AppHeader from '../components/AppHeader.vue' //

const route = useRoute()
const router = useRouter()
const user = userStore.state.user

const formState = reactive({
  dormZone: '',
  household: '', // ****** 新增 household 狀態 ******
  roomNumber: '',
  checkType: '',
  inspector: user?.email ? user.email.split('@')[0] : '',
})

const inspectionProgress = ref({
  completed: 0,
  total: 0,
  percentage: 0
})

const currentView = computed(() => {
    if (route.path.startsWith('/admin')) return 'admin';
    if (route.name === 'KeyReturn') return 'key-return';
    return 'inspection';
})

const navigateTo = (view) => {
  if (view === 'admin') {
      if (!route.path.startsWith('/admin')) {
          router.push({ name: 'AdminDashboard' }) //
      }
  } else if (view === 'key-return') {
      if (route.name !== 'KeyReturn') { //
         router.push({ name: 'KeyReturn' }) //
      }
  } else { // 'inspection'
      if (route.name !== 'Inspection') { //
         router.push({ name: 'Inspection' }) //
      }
  }
}

const updateInspectionProgress = (progress) => {
  if (progress && typeof progress.completed === 'number' && typeof progress.total === 'number' && typeof progress.percentage === 'number') {
      inspectionProgress.value = progress;
  } else {
      console.warn("Received invalid progress update:", progress);
  }
}

const onReportGenerated = () => {
  formState.dormZone = '';
  formState.household = ''; // ****** 清空 household ******
  formState.roomNumber = '';
  formState.checkType = '';
  inspectionProgress.value = { completed: 0, total: 0, percentage: 0 }
}

watch(() => userStore.state.user, (newUser) => { //
    if (newUser?.email && !formState.inspector) {
        formState.inspector = newUser.email.split('@')[0];
    }
}, { immediate: true });

// ****** 修改 watch 邏輯 ******
watch(() => formState.dormZone, (newZone, oldZone) => {
    if (newZone !== oldZone) {
        formState.household = ''; // 清空戶別
        formState.roomNumber = ''; // 清空房號
    }
});
watch(() => formState.household, (newHousehold, oldHousehold) => {
    if (newHousehold !== oldHousehold) {
        formState.roomNumber = ''; // 改變戶別時清空房號
    }
});
// ****** 結束修改 ******

</script>