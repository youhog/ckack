<template>
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="stat-card" style="background: linear-gradient(135deg, rgba(59, 130, 246, 0.1), rgba(139, 92, 246, 0.1))">
          <div class="stat-icon" style="background: linear-gradient(135deg, #3b82f6, #8b5cf6); color: white;">
              📋
          </div>
          <div class="stat-value text-blue-600" id="totalReports">{{ stats.totalReports }}</div>
          <div class="stat-label">總檢查報告 (全部)</div>
      </div>
      <div class="stat-card" style="background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), rgba(5, 150, 105, 0.1))">
          <div class="stat-icon" style="background: linear-gradient(135deg, #10b981, #059669); color: white;">
              ✅
          </div>
          <div class="stat-value text-green-600" id="completedToday">{{ stats.completedToday }}</div>
          <div class="stat-label">今日完成 (全部)</div>
      </div>
      <div class="stat-card" style="background: linear-gradient(135deg, rgba(239, 68, 68, 0.1), rgba(220, 38, 38, 0.1))">
          <div class="stat-icon" style="background: linear-gradient(135deg, #ef4444, #dc2626); color: white;">
              ⚠️
          </div>
          <div class="stat-value text-red-600" id="issuesFound">{{ stats.issuesFound }}</div>
          <div class="stat-label">累計發現問題 (全部)</div>
      </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../services/supabase'

const stats = ref({
  totalReports: 0,
  completedToday: 0,
  issuesFound: 0
})

const fetchAdminStats = async () => {
  // 由於這是 Admin 元件，RLS 策略 (get_my_role() = 'admin') 
  // 會確保我們能查詢所有報告
  const { data, error, count } = await supabase
    .from('reports')
    .select('*', { count: 'exact' }) // 獲取總數
  
  if (error) {
    console.error("載入管理統計失敗:", error)
    return
  }

  const today = new Date().toDateString();
  const todayReports = data.filter(report => 
      new Date(report.created_at).toDateString() === today
  );
  
  const issuesCount = data.reduce((count, report) => 
      count + (report.damaged_count || 0) + (report.missing_count || 0), 0
  );

  stats.value = {
    totalReports: count || 0,
    completedToday: todayReports.length,
    issuesFound: issuesCount
  }
}

// 元件掛載時，獲取最新統計數據
onMounted(fetchAdminStats)
</script>
