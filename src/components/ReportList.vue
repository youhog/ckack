<template>
  <div id="reportsList" class="space-y-4 max-h-96 overflow-y-auto">
      <div v-if="!reports || reports.length === 0" class="text-center text-gray-500 py-8">
        尚無檢查報告
      </div>
      
      <div v-for="report in reports" :key="report.id" class="card p-4 fade-in">
          <div class="flex flex-col sm:flex-row justify-between sm:items-start">
              <div class="flex-1">
                  <div class="font-medium text-gray-800">
                    <!-- 'dorm_zone' 和 'room_number' 是 AdminDashboard 查詢時 join 過來的名稱 -->
                    {{ report.dorm_zone || '未知分區' }} - {{ report.room_number || '未知房間' }}
                  </div>
                  <div class="text-sm text-gray-600 mt-1">
                      檢查類型：{{ report.check_type_text || '未知' }} | 
                      檢查人員：{{ report.inspector_name || '未填寫' }} | 
                      時間：{{ new Date(report.created_at).toLocaleString('zh-TW') }}
                  </div>
                  <div class="flex flex-wrap gap-4 mt-2 text-sm">
                      <span class="status-indicator status-good">良好：{{ report.good_count || 0 }}</span>
                      <span class="status-indicator status-damaged">損壞：{{ report.damaged_count || 0 }}</span>
                      <span class="status-indicator status-missing">遺失：{{ report.missing_count || 0 }}</span>
                  </div>
              </div>
              <div class="flex gap-2 ml-0 sm:ml-4 mt-4 sm:mt-0">
                  <button 
                    @click="$emit('view', report)"
                    class="view-report-btn btn" 
                    style="background: rgba(59, 130, 246, 0.1); color: #3b82f6; padding: 8px 12px;">
                      查看
                  </button>
                  <button 
                    @click="$emit('delete', report.id)"
                    class="delete-report-btn btn" 
                    style="background: rgba(239, 68, 68, 0.1); color: #ef4444; padding: 8px 12px;">
                      刪除
                  </button>
              </div>
          </div>
      </div>
  </div>
</template>

<script setup>
defineProps({
  reports: Array
})

defineEmits(['view', 'delete'])
</script>
