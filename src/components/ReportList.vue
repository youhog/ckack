<template>
  <div id="reportsList" class="space-y-4 max-h-[60vh] overflow-y-auto pr-2">
      <div v-if="!reports || reports.length === 0" class="text-center text-slate-500 py-8">
        尚無檢查報告
      </div>
      
      <div 
        v-for="report in reports" 
        :key="report.id" 
        class="bg-white dark:bg-slate-800/50 rounded-xl shadow p-4 transition-all duration-200 hover:shadow-md hover:bg-slate-50 dark:hover:bg-slate-700/50"
      >
          <div class="flex flex-col sm:flex-row justify-between sm:items-start">
              <div class="flex-1">
                  <div class="font-medium text-slate-800 dark:text-slate-100">
                    {{ report.dorm_zone || '未知分區' }} - {{ report.room_number || '未知房間' }}
                  </div>
                  <div class="text-sm text-slate-500 dark:text-slate-400 mt-1">
                      檢查類型：{{ report.check_type_text || '未知' }} | 
                      檢查人員：{{ report.inspector_name || '未填寫' }} | 
                      時間：{{ new Date(report.created_at).toLocaleString('zh-TW') }}
                  </div>
                  <div class="flex flex-wrap gap-x-4 gap-y-2 mt-3 text-sm">
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-300">
                        良好：{{ report.good_count || 0 }}
                      </span>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300">
                        損壞：{{ report.damaged_count || 0 }}
                      </span>
                      <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-yellow-100 dark:bg-yellow-500/20 text-yellow-700 dark:text-yellow-300">
                        遺失：{{ report.missing_count || 0 }}
                      </span>
                  </div>
              </div>
              <div class="flex gap-2 ml-0 sm:ml-4 mt-4 sm:mt-0">
                  <button 
                    @click="$emit('view', report)"
                    class="inline-flex items-center justify-center px-3 py-1.5 text-sm font-medium rounded-md transition-all duration-200 cursor-pointer bg-blue-100 dark:bg-blue-500/20 text-blue-700 dark:text-blue-300 hover:bg-blue-200 dark:hover:bg-blue-500/30"
                  >
                      查看
                  </button>
                  <button 
                    @click="$emit('delete', report.id)"
                    class="inline-flex items-center justify-center px-3 py-1.5 text-sm font-medium rounded-md transition-all duration-200 cursor-pointer bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-500/30"
                  >
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