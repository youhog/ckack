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
              <!-- 只有 Admin 看得到後台管理按鈕 -->
              <button 
                v-if="userRole === 'admin'"
                @click="$emit('navigate', 'admin')" 
                :class="view === 'admin' ? 'btn btn-primary' : 'btn-secondary'"
                class="flex-1 lg:flex-none">
                <span class="flex items-center gap-2">⚙️ <span>後台管理</span></span>
              </button>
          </div>
      </div>
      
      <!-- 基本資訊 (從 Store 載入) -->
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
              </label>
              <select id="roomNumber" class="form-control" :value="roomNumber" @input="$emit('update:roomNumber', $event.target.value)" :disabled="!dormZone">
                  <option value="">請先選擇分區</option>
                  <option v-for="room in availableRooms" :key="room.id" :value="room.id">
                    {{ room.room_number }}
                  </option>
              </select>
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
      
      <!-- 檢查模式內容 -->
      <div id="inspectionMode" v-if="view === 'inspection'">
          <!-- 進度條 -->
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

      <!-- 後台管理內容 -->
      <div id="adminMode" v-if="view === 'admin'">
          <!-- AdminStats 現在移到 Admin.vue 佈局中 -->
      </div>
  </header>
</template>

<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { supabase } from '../services/supabase'
import { userStore } from '../store/user'
import { configStore } from '../store/config' // 匯入 config store

const props = defineProps({
  dormZone: String,    // 現在是 zone.id
  roomNumber: String,  // 現在是 room.id
  checkType: String,   // 現在是 type.id
  inspector: String,
  view: String,
  progress: Object // { completed, total, percentage }
})

defineEmits(['update:dormZone', 'update:roomNumber', 'update:checkType', 'update:inspector', 'navigate'])

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

// 根據所選 Zone ID 過濾房間
const availableRooms = computed(() => {
  if (!props.dormZone) return []
  return config.rooms
    .filter(room => room.zone_id === props.dormZone)
    .sort((a,b) => a.room_number.localeCompare(b.room_number))
})

const progressClass = computed(() => {
  if (!props.progress) return 'status-pending'
  const p = props.progress.percentage
  if (p === 100) return 'status-good'
  if (props.progress.completed > 0) return 'status-missing'
  return 'status-pending'
})
</script>
