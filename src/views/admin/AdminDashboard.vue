<template>
  <div class="card p-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
        <h3 class="text-xl font-semibold text-gray-800">📊 檢查報告管理 (所有使用者)</h3>
        <div class="flex gap-2 w-full sm:w-auto">
             <button @click="exportAllReports" class="btn btn-primary w-1/2 sm:w-auto" :disabled="reports.length === 0">
                📤 匯出 (目前頁面)
            </button>
            <button @click="clearFilteredReports" class="btn w-1/2 sm:w-auto" :disabled="reports.length === 0" style="background: rgba(239, 68, 68, 0.1); color: #ef4444;">
                🗑️ 刪除 (篩選後)
            </button>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-6">
        <select class="form-control" v-model="filters.zone_id" @change="applyFilters">
            <option value="">所有分區</option>
            <option v-for="zone in config.zones" :key="zone.id" :value="zone.id">
              {{ zone.name }}
            </option>
        </select>
        <select class="form-control" v-model="filters.check_type_id" @change="applyFilters">
            <option value="">所有類型</option>
            <option v-for="type in config.checkTypes" :key="type.id" :value="type.id">
              {{ type.name }}
            </option>
        </select>
        <input type="date" class="form-control" v-model="filters.date" @change="applyFilters">
        <input type="text" placeholder="房間號碼" class="form-control" v-model="filters.room_number" @input="applyFiltersDebounced">
    </div>
    <div class="mb-6">
        <input type="text" placeholder="檢查人員 Email 或姓名" class="form-control" v-model="filters.inspector" @input="applyFiltersDebounced">
    </div>

    <div v-if="loading" class="text-center text-gray-500 py-8">載入報告中...</div>
    <div v-else-if="error" class="text-center text-red-500 py-8">{{ error }}</div>
    <ReportList
      v-else
      :reports="reports"
      @view="handleViewReport"
      @delete="handleDeleteReport"
    />

    <div class="flex justify-between items-center mt-6">
        <span class="text-sm text-gray-600">
            總共 {{ totalReports }} 筆報告 (第 {{ currentPage }} / {{ totalPages }} 頁)
        </span>
        <div class="flex gap-2">
            <button @click="prevPage" class="btn btn-secondary" :disabled="currentPage === 1">
                上一頁
            </button>
            <button @click="nextPage" class="btn btn-secondary" :disabled="currentPage === totalPages || totalPages === 0">
                下一頁
            </button>
        </div>
    </div>


    <dialog ref="reportDialog" class="card p-0 max-w-4xl w-full">
       <div class="dialog-header flex justify-between items-center sticky top-0">
          <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center text-white text-xl">
                  📋
              </div>
              <h3 class="text-2xl font-bold text-gray-800">檢查報告詳情</h3>
          </div>
          <button @click="closeReportDialog" class="close-modal-btn w-10 h-10 bg-gray-100 hover:bg-gray-200 rounded-xl flex items-center justify-center text-gray-500 hover:text-gray-700 transition-all duration-200">
              ✕
          </button>
      </div>
      <div class="dialog-content-wrapper overflow-y-auto max-h-[75vh]">
          <div class="dialog-body space-y-2 text-sm report-preview-content p-6" v-if="viewingReport" v-html="viewingReport.report_content_html"></div>
      </div>
    </dialog>
  </div>
</template>

<script setup>
import { ref, onMounted, computed, reactive, watch } from 'vue'
import { supabase } from '@/services/supabase'
import { configStore } from '@/store/config'
import ReportList from '@/components/ReportList.vue'

// --- State ---
const loading = ref(true)
const error = ref(null)
const reports = ref([]) // 只儲存目前頁面的報告
const reportDialog = ref(null)
const viewingReport = ref(null)
const config = configStore.state

// --- 分頁狀態 ---
const currentPage = ref(1)
const rowsPerPage = ref(20) // 每頁顯示 20 筆
const totalReports = ref(0) // 總報告數
let filterTimeout = null;

const filters = reactive({
  zone_id: '',
  check_type_id: '',
  date: '',
  room_number: '',
  inspector: ''
})

// --- Computed ---
// 計算總頁數
const totalPages = computed(() => {
    if (totalReports.value === 0) return 1;
    return Math.ceil(totalReports.value / rowsPerPage.value)
})

// --- Methods ---

// fetchReports 會處理篩選和分頁
const fetchReports = async () => {
  loading.value = true
  error.value = null
  console.log(`AdminDashboard: Fetching reports... Page: ${currentPage.value}`);

  // 1. 計算分頁範圍
  const from = (currentPage.value - 1) * rowsPerPage.value;
  const to = from + rowsPerPage.value - 1;

  // 2. 建立查詢 (假設 'reports' 已與 'profiles' 建立外鍵)
  let query = supabase
    .from('reports')
    .select(`
      id, created_at, user_id, zone_id, room_id, check_type_id,
      inspector_name, additional_notes,
      good_count, damaged_count, missing_count, report_content_html,
      dorm_zones ( name ),
      rooms ( room_number ),
      check_types ( name ),
      profiles ( email )
    `, { count: 'exact' }) // { count: 'exact' } 會回傳總數
    .order('created_at', { ascending: false });

  // 3. 應用伺服器端篩選
  if (filters.zone_id) {
      query = query.eq('zone_id', filters.zone_id);
  }
  if (filters.check_type_id) {
      query = query.eq('check_type_id', filters.check_type_id);
  }
  if (filters.date) {
      // 篩選一整天
      query = query.gte('created_at', `${filters.date}T00:00:00.000Z`);
      query = query.lte('created_at', `${filters.date}T23:59:59.999Z`);
  }
  if (filters.room_number) {
      // 關聯篩選 (需要 'rooms' 外鍵)
      query = query.ilike('rooms.room_number', `%${filters.room_number}%`);
  }
  if (filters.inspector) {
      // 多欄位模糊搜尋 (使用 or)
      const inspectorLower = `%${filters.inspector.toLowerCase()}%`;
      query = query.or(
          `inspector_name.ilike.${inspectorLower},profiles.email.ilike.${inspectorLower}`,
          { foreignTable: 'profiles' } // 指定關聯表
      );
  }
  
  // 4. 執行分頁查詢
  query = query.range(from, to);
  
  const { data, error: fetchError, count } = await query;

  if (fetchError) {
    // 檢查是否因為 profiles 連結失敗 (如果是，就執行不含 profiles 的備用查詢)
    if (fetchError.code === 'PGRST200') {
        console.warn("關聯 profiles 失敗，嘗試備用查詢... (請檢查 RLS 與外鍵)");
        await fetchReportsFallback(from, to); // 呼叫備用函數
        return; // 結束此函數
    }
    error.value = `載入報告失敗: ${fetchError.message}`
    console.error("Fetch Error:", fetchError)
  } else {
    // 格式化報告
    reports.value = data.map(r => ({
      ...r,
      dorm_zone: r.dorm_zones?.name || '未知區域',
      room_number: r.rooms?.room_number || '未知房間',
      check_type_text: r.check_types?.name || '未知類型',
      user_email: r.profiles?.email || '未知使用者'
    }))
    totalReports.value = count || 0; // 更新總數
    console.log(`Reports loaded: ${reports.value.length} of ${count}`);
  }
  loading.value = false
}

// 備用 fetchReports (不查詢 profiles)
const fetchReportsFallback = async (from, to) => {
    let query = supabase
        .from('reports')
        .select(`
          id, created_at, user_id, zone_id, room_id, check_type_id,
          inspector_name, additional_notes,
          good_count, damaged_count, missing_count, report_content_html,
          dorm_zones ( name ),
          rooms ( room_number ),
          check_types ( name )
        `, { count: 'exact' })
        .order('created_at', { ascending: false });

    // 應用篩選 (不含 inspector email)
    if (filters.zone_id) query = query.eq('zone_id', filters.zone_id);
    if (filters.check_type_id) query = query.eq('check_type_id', filters.check_type_id);
    if (filters.date) {
        query = query.gte('created_at', `${filters.date}T00:00:00.000Z`);
        query = query.lte('created_at', `${filters.date}T23:59:59.999Z`);
    }
    if (filters.room_number) query = query.ilike('rooms.room_number', `%${filters.room_number}%`);
    if (filters.inspector) {
        query = query.ilike('inspector_name', `%${filters.inspector}%`);
    }
    
    query = query.range(from, to);
    const { data, error: fetchError, count } = await query;

    if (fetchError) {
        error.value = `載入報告失敗 (Fallback): ${fetchError.message}`
        console.error("Fetch Error (Fallback):", fetchError)
    } else {
        reports.value = data.map(r => ({
          ...r,
          dorm_zone: r.dorm_zones?.name || '未知區域',
          room_number: r.rooms?.room_number || '未知房間',
          check_type_text: r.check_types?.name || '未知類型',
          user_email: 'N/A (備用模式)'
        }))
        totalReports.value = count || 0;
    }
    loading.value = false;
}


// 篩選器改變時，重設頁碼並重新獲取
const applyFilters = () => {
    clearTimeout(filterTimeout);
    currentPage.value = 1; // 重設到第一頁
    fetchReports();
}
const applyFiltersDebounced = () => {
    clearTimeout(filterTimeout);
    filterTimeout = setTimeout(() => {
        currentPage.value = 1; // 重設到第一頁
        fetchReports();
    }, 300); // 延遲 300 毫秒
}

// 分頁函數
const nextPage = () => {
    if (currentPage.value < totalPages.value) {
        currentPage.value++;
        fetchReports();
    }
}
const prevPage = () => {
    if (currentPage.value > 1) {
        currentPage.value--;
        fetchReports();
    }
}

// 監聽篩選器
watch(filters, applyFiltersDebounced, { deep: true });


const handleViewReport = (report) => {
  const fullReport = reports.value.find(r => r.id === report.id);
  if (fullReport) {
    viewingReport.value = fullReport;
    reportDialog.value?.showModal();
  } else {
    alert("無法載入報告詳情。");
  }
}

const closeReportDialog = () => {
    reportDialog.value?.close();
    viewingReport.value = null; 
}


const handleDeleteReport = async (reportId) => {
  if (!confirm('管理員權限：確定要刪除此報告嗎？此操作無法復原。')) return

  const { error: deleteError } = await supabase
    .from('reports')
    .delete()
    .eq('id', reportId) 

  if (deleteError) {
    alert(`刪除失敗: ${deleteError.message}`)
  } else {
    alert('報告已刪除')
    // 重新載入目前頁面
    fetchReports();
  }
}

const exportAllReports = () => {
    // 只匯出目前頁面
    if (reports.value.length === 0) {
        alert('目前頁面沒有報告可以匯出');
        return;
    }

    const dataToExport = reports.value.map(({ report_content_html, dorm_zones, rooms, check_types, profiles, ...rest }) => ({
        ...rest,
        dorm_zone_name: rest.dorm_zone, 
        room_number_val: rest.room_number,
        check_type_name: rest.check_type_text,
        user_email: rest.user_email
    }));

    const dataStr = JSON.stringify(dataToExport, null, 2);
    const blob = new Blob([dataStr], { type: 'application/json;charset=utf-8' }); 
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.download = `宿舍檢查報告(P${currentPage.value})_${new Date().toISOString().split('T')[0]}.json`;
    a.href = url;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

const clearFilteredReports = async () => {
    alert('基於安全和效能考量，「刪除篩選後」功能在此分頁模式下已停用。請逐一刪除。');
    return; 
}


// --- Lifecycle ---
onMounted(fetchReports)

</script>

<style scoped>
/* (樣式不變) */
.dialog-content-wrapper {
  scrollbar-width: thin;
}
.dialog-content-wrapper::-webkit-scrollbar {
  width: 8px;
}
.dialog-content-wrapper::-webkit-scrollbar-track {
  background: #f1f1f1;
  border-radius: 10px;
}
.dialog-content-wrapper::-webkit-scrollbar-thumb {
  background: #ccc;
  border-radius: 10px;
}
.dialog-content-wrapper::-webkit-scrollbar-thumb:hover {
  background: #aaa;
}
.report-preview-content :deep(div) {
    word-break: break-word;
}
.btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
}
</style>