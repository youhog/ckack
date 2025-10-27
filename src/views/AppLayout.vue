<template>
  <div class="container mx-auto px-4 py-8 max-w-7xl"> 
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
import { userStore } from '../store/user' //
import AppHeader from '../components/AppHeader.vue' //

// --- (所有 <script> 邏輯保持不變) ---
const route = useRoute()
const router = useRouter()
const user = userStore.state.user; //

const formState = reactive({
  dormZone: '', 
  roomNumber: '', 
  roomNumberInput: '', 
  checkType: '', 
  inspector: user?.email ? user.email.split('@')[0] : '',
})

const inspectionProgress = ref({
  completed: 0,
  total: 0,
  percentage: 0
})

const currentView = computed(() => route.path.startsWith('/admin') ? 'admin' : 'inspection')

const navigateTo = (view) => {
  if (view === 'admin') {
      if (!route.path.startsWith('/admin')) {
          router.push({ name: 'AdminDashboard' }) //
      }
  } else {
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
  formState.roomNumber = '';
  formState.roomNumberInput = ''; 
  formState.checkType = '';
  inspectionProgress.value = { completed: 0, total: 0, percentage: 0 }
}

watch(() => userStore.state.user, (newUser) => { //
    if (newUser?.email && !formState.inspector) {
        formState.inspector = newUser.email.split('@')[0];
    }
}, { immediate: true });

watch(() => formState.dormZone, (newZone, oldZone) => {
    if (newZone !== oldZone) {
        formState.roomNumber = '';
        formState.roomNumberInput = '';
    }
});

</script>