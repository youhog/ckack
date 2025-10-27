<template>
  <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <div class="rounded-2xl p-6 text-center bg-gradient-to-br from-blue-50 dark:from-blue-900/50 to-indigo-100 dark:to-indigo-900/30 shadow hover:shadow-md transition-shadow">
          <div class="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-4 bg-gradient-to-r from-blue-500 to-indigo-500 text-white text-2xl shadow-lg">
              📋
          </div>
          <div class="text-3xl font-bold text-blue-600 dark:text-blue-400 mb-2" id="totalReports">{{ stats.totalReports }}</div>
          <div class="text-sm text-slate-600 dark:text-slate-400">總檢查報告 (全部)</div>
      </div>
      <div class="rounded-2xl p-6 text-center bg-gradient-to-br from-green-50 dark:from-green-900/50 to-emerald-100 dark:to-emerald-900/30 shadow hover:shadow-md transition-shadow">
          <div class="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-4 bg-gradient-to-r from-green-500 to-emerald-500 text-white text-2xl shadow-lg">
              ✅
          </div>
          <div class="text-3xl font-bold text-green-600 dark:text-green-400 mb-2" id="completedToday">{{ stats.completedToday }}</div>
          <div class="text-sm text-slate-600 dark:text-slate-400">今日完成 (全部)</div>
      </div>
      <div class="rounded-2xl p-6 text-center bg-gradient-to-br from-red-50 dark:from-red-900/50 to-rose-100 dark:to-rose-900/30 shadow hover:shadow-md transition-shadow">
          <div class="w-14 h-14 rounded-2xl flex items-center justify-center mx-auto mb-4 bg-gradient-to-r from-red-500 to-rose-500 text-white text-2xl shadow-lg">
              ⚠️
          </div>
          <div class="text-3xl font-bold text-red-600 dark:text-red-400 mb-2" id="issuesFound">{{ stats.issuesFound }}</div>
          <div class="text-sm text-slate-600 dark:text-slate-400">累計發現問題 (全部)</div>
      </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '../services/supabase' //

// --- (所有 <script> 邏輯保持不變) ---
const stats = ref({
  totalReports: 0,
  completedToday: 0,
  issuesFound: 0
})

const fetchAdminStats = async () => {
  const { data, error, count } = await supabase //
    .from('reports') //
    .select('*', { count: 'exact' }) 
  
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

onMounted(fetchAdminStats)
</script>