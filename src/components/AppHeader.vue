<template>
  <header class="card p-8 mb-8">
      <div class="flex flex-col lg:flex-row justify-between items-start lg:items-center gap-6 mb-8">
          <div class="flex items-center gap-4">
              <div class="w-14 h-14 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-2xl flex items-center justify-center text-white text-2xl shadow-lg">
                  🏠
              </div>
              <div>
                  <h1 class="text-3xl lg:text-4xl font-bold bg-gradient-to-r from-gray-800 to-gray-600 bg-clip-text text-transparent">
                      宿舍房間檢查系統
                  </h1>
                  <p class="text-gray-500 text-sm mt-1">
                    歡迎, {{ userEmail }} ({{ userRole }})
                  </p>
              </div>
          </div>
          <div class="flex gap-3 w-full lg:w-auto">
              <button @click="handleLogout" class="btn btn-secondary" title="登出">
                <span class="flex items-center gap-2">🚪 <span class="hidden sm:inline">登出</span></span>
              </button>
              <button 
                @click="$emit('navigate', 'inspection')" 
                :class="view === 'inspection' ? 'btn btn-primary' : 'btn-secondary'"
                class="flex-1 lg:flex-none">
                <span class="flex items-center gap-2">📋 <span>檢查模式</span></span>
              </button>
              <button 
                v-if="userRole === 'admin'"
                @click="$emit('navigate', 'admin')" 
                :class="view === 'admin' ? 'btn btn-primary' : 'btn-secondary'"
                class="flex-1 lg:flex-none">
                <span class="flex items-center gap-2">⚙️ <span>後台管理</span></span>
              </button>
          </div>
      </div>
      
      <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-6">
          <div class="form-group">
              <label for="dormZone" class="form-label flex items-center gap-2">
                  🏢 <span>宿舍分區</span>
              </label>
              <select id="dormZone" class="form-control" :value="dormZone" @input="$emit('update:dormZone', $event.target.value)">
                  <option value="">請選擇分區</option>
                  <option v-for="zone in config.zones" :key="zone.id" :value="zone.id">
                    {{ zone.name }}
                  </option>
              </select>
          </div>

          <div class="form-group">
              <label for="roomNumber" class="form-label flex items-center gap-2">
                  🚪 <span>房間號碼</span>
                  <span v-if="validationState === 'loading'" class="text-xs text-gray-500">驗證中...</span>
                  <span v-if="validationState === 'valid'" class="text-xs text-green-600">✅ 房號正確</span>
                  <span v-if="validationState === 'invalid'" class="text-xs text-red-500">❌ 查無此房號</span>
              </label>
              <input 
                type="text" 
                id="roomNumber" 
                class="form-control" 
                :class="{ 
                    'border-green-500 focus:border-green-500 focus:ring-green-100': validationState === 'valid', 
                    'border-red-500 focus:border-red-500 focus:ring-red-100': validationState === 'invalid' 
                }"
                :value="roomNumberInput"
                @input="$emit('update:roomNumberInput', $event.target.value)"
                @blur="validateRoom"
                :disabled="!dormZone"
                placeholder="請先選分區，再輸入房號"
              >
          </div>
          <div class="form-group">
              <label for="checkType" class="form-label flex items-center gap-2">
                  📝 <span>檢查類型</span>
              </label>
              <select id="checkType" class="form-control" :value="checkType" @input="$emit('update:checkType', $event.target.value)">
                 <option value="">請選擇類型</option>
                 <option v-for="type in config.checkTypes" :key="type.id" :value="type.id">
                  {{ type.name }}
                </option>
              </select>
          </div>
          <div class="form-group">
              <label for="inspector" class="form-label flex items-center gap-2">
                  👤 <span>檢查人員</span>
              </label>
              <input type="text" id="inspector" class="form-control" placeholder="請輸入姓名" :value="inspector" @input="$emit('update:inspector', $event.target.value)">
          </div>
      </div>
      
      <div id="inspectionMode" v-if="view === 'inspection'">
          <div class="card p-6 mb-6">
              <div class="flex justify-between items-center mb-4">
                  <div class="flex items-center gap-3">
                      <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center text-white text-lg">
                          📊
                      </div>
                      <span class="font-semibold text-gray-700">檢查進度</span>
                  </div>
                  <span id="progressText" class="status-indicator" :class="progressClass">
                    {{ progress.completed }}/{{ progress.total }} 完成 ({{ progress.percentage }}%)
                  </span>
              </div>
              <div class="progress-container">
                  <div id="progressBar" class="progress-bar" :style="{ width: `${progress.percentage}%` }"></div>
              </div>
          </div>
      </div>
  </header>
</template>

<script setup>
import { computed, ref, watch } from 'vue' // <-- 【新增】 ref, watch
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase' // <-- 【新增】 supabase
import { userStore } from '../store/user'
import { configStore } from '../store/config' 

const props = defineProps({
  dormZone: String,    // zone.id
  roomNumber: String,  // 【修改】這仍然是 room.id
  roomNumberInput: String, // 【新增】這是輸入框的文字
  checkType: String,   // type.id
  inspector: String,
  view: String,
  progress: Object
})

// 【修改】新增 'update:roomNumberInput'
const emit = defineEmits(['update:dormZone', 'update:roomNumber', 'update:roomNumberInput', 'update:checkType', 'update:inspector', 'navigate'])

const router = useRouter()
const user = userStore.state.user
const userEmail = computed(() => user?.email || '訪客')
const userRole = computed(() => userStore.state.role)

const config = configStore.state

const handleLogout = async () => {
  if (confirm('確定要登出嗎？')) {
    const { error } = await supabase.auth.signOut()
    if (!error) {
      router.push({ name: 'Login' })
    }
  }
}

// 【移除】 availableRooms (不再需要)
// const availableRooms = computed(() => { ... })

// 【新增】房號驗證邏輯
const validationState = ref('idle'); // 'idle', 'loading', 'valid', 'invalid'

// 當區域改變時，重設驗證狀態
watch(() => props.dormZone, () => {
    validationState.value = 'idle';
    // AppLayout 會自動清空 ID 和 Input
});

// 當使用者重新輸入時，重設狀態
watch(() => props.roomNumberInput, (newInput) => {
    if (validationState.value !== 'idle') {
        validationState.value = 'idle';
    }
    // 同時清除已驗證的 ID，因為輸入變了
    if (props.roomNumber) {
        emit('update:roomNumber', '');
    }
});

// 當使用者輸入框失焦時 (on-blur)，執行驗證
const validateRoom = async () => {
    const zoneId = props.dormZone;
    const roomInput = props.roomNumberInput ? props.roomNumberInput.trim() : '';

    // 如果沒選區域或沒輸入房號，不執行
    if (!zoneId || !roomInput) {
        validationState.value = 'idle';
        emit('update:roomNumber', ''); // 確保 ID 是空的
        return;
    }

    validationState.value = 'loading';
    
    try {
        const { data, error } = await supabase
            .from('rooms')
            .select('id') // 只需要 ID
            .eq('zone_id', zoneId)
            .eq('room_number', roomInput) // 嚴格比對房號文字
            .single(); // 預期只找到一筆

        if (error || !data) {
            console.warn("房號驗證失敗:", error?.message || '找不到房號');
            validationState.value = 'invalid';
            emit('update:roomNumber', ''); // 傳送空 ID
        } else {
            // 找到了！
            validationState.value = 'valid';
            emit('update:roomNumber', data.id); // 傳送驗證通過的 room.id
        }
    } catch (e) {
        console.error("驗證房號時發生例外:", e);
        validationState.value = 'invalid';
        emit('update:roomNumber', '');
    }
}


const progressClass = computed(() => {
  if (!props.progress) return 'status-pending'
  const p = props.progress.percentage
  if (p === 100) return 'status-good'
  if (props.progress.completed > 0) return 'status-missing'
  return 'status-pending'
})
</script>

<style scoped>
.form-control.border-green-500 {
    border-color: #22c55e;
}
.form-control:focus.border-green-500 {
    box-shadow: 0 0 0 3px rgba(34, 197, 94, 0.1);
    border-color: #22c55e;
}
.form-control.border-red-500 {
    border-color: #ef4444;
}
.form-control:focus.border-red-500 {
    box-shadow: 0 0 0 3px rgba(239, 68, 68, 0.1);
    border-color: #ef4444;
}
</style>