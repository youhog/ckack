<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <div class="flex flex-col sm:flex-row justify-between items-start sm:items-center mb-6 gap-4">
        <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100">📊 檢查報告管理 (所有使用者)</h3>
        <div class="flex gap-2 w-full sm:w-auto">
             <button
                @click="exportReports"
                class="inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer w-1/2 sm:w-auto bg-gradient-to-r from-green-500 to-emerald-600 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed"
                :disabled="isExporting"
             >
                <span v-if="isExporting">
                  <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                  匯出中...
                </span>
                <span v-else>📤 匯出 CSV</span>
            </button>
            <button
              @click="clearFilteredReports"
              class="inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer w-1/2 sm:w-auto bg-red-100 dark:bg-red-500/20 text-red-700 dark:text-red-300 hover:bg-red-200 dark:hover:bg-red-500/30 disabled:opacity-60 disabled:cursor-not-allowed"
              :disabled="reports.length === 0 || loading"
            >
                🗑️ 刪除 (篩選後)
            </button>
        </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-5 gap-4 mb-6">
        <select class="form-control" v-model="filters.zone_id" @change="onZoneChange">
            <option value="">選擇區域</option>
            <option v-for="zone in config.zones" :key="zone.id" :value="zone.id">
              {{ zone.name }}
            </option>
        </select>
        <select class="form-control" v-model="filters.floor" @change="onFloorChange" :disabled="!filters.zone_id || floorsLoading">
            <option value="">選擇樓層</option>
            <option v-if="floorsLoading" value="" disabled>載入樓層中...</option>
            <option v-for="floor in availableFloors" :key="floor" :value="floor">
              {{ floor }}
            </option>
        </select>
        <select class="form-control" v-model="filters.room_id" @change="applyFilters" :disabled="!filters.floor || roomsLoading">
             <option value="">選擇房間</option>
             <option v-if="roomsLoading" value="" disabled>載入房間中...</option>
             <option v-for="room in availableRooms" :key="room.id" :value="room.id">
               {{ room.room_number }}
             </option>
        </select>
        <select class="form-control" v-model="filters.check_type_id" @change="applyFilters">
            <option value="">所有類型</option>
            <option v-for="type in config.checkTypes" :key="type.id" :value="type.id">
              {{ type.name }}
            </option>
        </select>
        <input type="date" class="form-control" v-model="filters.date" @change="applyFilters">
    </div>
    <div class="mb-6">
        <input type="text" placeholder="檢查人員姓名" class="form-control" v-model="filters.inspector" @input="applyFiltersDebounced">
    </div>
     <div v-if="loading" class="text-center text-slate-500 py-8">載入報告中...</div>
    <div v-else-if="error" class="text-center text-red-500 py-8">{{ error }}</div>
    <ReportList
      v-else
      :reports="reports"
      @view="handleViewReport"
      @delete="handleDeleteReport"
    />

    <div class="flex justify-between items-center mt-6">
        <span class="text-sm text-slate-600 dark:text-slate-400">
            總共 {{ totalReports }} 筆報告 (第 {{ currentPage }} / {{ totalPages }} 頁)
        </span>
        <div class="flex gap-2">
            <button
              @click="prevPage"
              class="inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed"
              :disabled="currentPage === 1"
            >
                上一頁
            </button>
            <button
              @click="nextPage"
              class="inline-flex items-center justify-center px-4 py-2 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600 disabled:opacity-60 disabled:cursor-not-allowed"
              :disabled="currentPage === totalPages || totalPages === 0"
            >
                下一頁
            </button>
        </div>
    </div>

    <dialog ref="reportDialog" class="p-0 max-w-4xl w-full">
       <div class="sticky top-0 bg-white/90 dark:bg-slate-800/90 backdrop-blur-md border-b border-slate-200 dark:border-slate-700 p-6 flex justify-between items-center z-10">
          <div class="flex items-center gap-3">
              <div class="w-10 h-10 bg-gradient-to-r from-blue-500 to-indigo-500 rounded-xl flex items-center justify-center text-white text-xl">
                  📋
              </div>
              <h3 class="text-2xl font-bold text-slate-800 dark:text-slate-100">檢查報告詳情</h3>
          </div>
          <button @click="closeReportDialog" class="w-10 h-10 bg-slate-100 hover:bg-slate-200 dark:bg-slate-700 dark:hover:bg-slate-600 rounded-xl flex items-center justify-center text-slate-500 dark:text-slate-300 hover:text-slate-700 dark:hover:text-slate-100 transition-all duration-200">
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
import Papa from 'papaparse';
import { showToast } from '@/utils';

const loading = ref(true)
const error = ref(null)
const reports = ref([])
const reportDialog = ref(null)
const viewingReport = ref(null)
const config = configStore.state

const currentPage = ref(1)
const rowsPerPage = ref(20) // 每頁顯示數量
const totalReports = ref(0)
let filterTimeout = null;

const filters = reactive({
  zone_id: '',
  floor: '',
  room_id: '',
  check_type_id: '',
  date: '',
  inspector: '' // 只用於 inspector_name
})

const availableFloors = ref([]);
const floorsLoading = ref(false);
const availableRooms = ref([]);
const roomsLoading = ref(false);

const isExporting = ref(false);

const totalPages = computed(() => {
    if (totalReports.value === 0) return 1;
    return Math.ceil(totalReports.value / rowsPerPage.value)
})

const fetchFloorsForZone = async () => {
    if (!filters.zone_id) {
        availableFloors.value = [];
        filters.floor = ''; // 清空樓層
        filters.room_id = ''; // 清空房間
        availableRooms.value = []; // 清空房間列表
        applyFilters(); // 觸發查詢
        return;
    }
    floorsLoading.value = true;
    availableFloors.value = [];
    filters.floor = '';
    filters.room_id = '';
    availableRooms.value = [];
    try {
        const { data, error } = await supabase
            .from('rooms')
            .select('floor')
            .eq('zone_id', filters.zone_id)
            .order('floor');

        if (error) throw error;
        availableFloors.value = [...new Set(data.map(item => item.floor))].sort((a, b) => a.localeCompare(b, undefined, { numeric: true }));
    } catch (e) {
        console.error("載入樓層失敗:", e);
        showToast(`載入樓層失敗: ${e.message}`, 'error');
    } finally {
        floorsLoading.value = false;
        applyFilters();
    }
}

const fetchRoomsForFloor = async () => {
     if (!filters.zone_id || !filters.floor) {
        availableRooms.value = [];
        filters.room_id = ''; // 清空房間選擇
        applyFilters(); // 觸發查詢
        return;
    }
    roomsLoading.value = true;
    availableRooms.value = [];
    filters.room_id = '';
    try {
        const { data, error } = await supabase
            .from('rooms')
            .select('id, room_number')
            .eq('zone_id', filters.zone_id)
            .eq('floor', filters.floor)
            .order('room_number');

        if (error) throw error;
        availableRooms.value = data;
    } catch (e) {
        console.error("載入房間失敗:", e);
        showToast(`載入房間失敗: ${e.message}`, 'error');
    } finally {
        roomsLoading.value = false;
        applyFilters();
    }
}

const onZoneChange = () => {
    fetchFloorsForZone();
}
const onFloorChange = () => {
    fetchRoomsForFloor();
}

// *** fetchReports 修改 ***
const fetchReports = async (isExport = false, exportLimit = 1000) => {
    if (!isExport) {
      loading.value = true;
    }
    error.value = null;
    console.log(`AdminDashboard: Fetching reports... Page: ${currentPage.value}, Export: ${isExport}`);

    const from = isExport ? 0 : (currentPage.value - 1) * rowsPerPage.value;
    const to = isExport ? exportLimit -1 : from + rowsPerPage.value - 1;

    // --- 修改 Query: 移除 student_allocations(...) ---
    let query = supabase
        .from('reports')
        .select(`
          id, created_at, user_id, zone_id, room_id, check_type_id,
          inspector_name, additional_notes,
          good_count, damaged_count, missing_count, report_content_html,
          dorm_zones ( name ),
          rooms ( room_number, floor, household ),
          check_types ( name )
        `, { count: 'exact' }) // 移除 student_allocations(...)
        .order('created_at', { ascending: false });
    // --- 結束修改 ---


    // --- Filter Logic ---
    if (filters.zone_id) query = query.eq('zone_id', filters.zone_id);
    // --- 新增：樓層篩選 (如果只選了樓層) ---
    if (filters.floor && !filters.room_id) {
        // 需要先找出該樓層的所有 room_id
        const { data: roomIdsData, error: roomIdsError } = await supabase
            .from('rooms')
            .select('id')
            .eq('zone_id', filters.zone_id)
            .eq('floor', filters.floor);

        if (roomIdsError) {
            console.error("Error fetching room IDs for floor filter:", roomIdsError);
            // 根據需求決定是否要中斷查詢或忽略樓層篩選
        } else if (roomIdsData && roomIdsData.length > 0) {
            query = query.in('room_id', roomIdsData.map(r => r.id));
        } else {
            // 該樓層沒有房間，查詢結果會是空的
             query = query.eq('room_id', '00000000-0000-0000-0000-000000000000'); // 用一個不存在的 UUID 確保沒結果
        }
    } else if (filters.room_id) {
        // 如果選了房間，則直接用 room_id 篩選
        query = query.eq('room_id', filters.room_id);
    }
    // --- 結束樓層篩選 ---
    if (filters.check_type_id) query = query.eq('check_type_id', filters.check_type_id);
    if (filters.date) {
        query = query.gte('created_at', `${filters.date}T00:00:00.000Z`);
        query = query.lte('created_at', `${filters.date}T23:59:59.999Z`);
    }
    if (filters.inspector) {
        const inspectorLower = `%${filters.inspector.toLowerCase()}%`;
        query = query.ilike('inspector_name', inspectorLower);
    }
    // --- 結束 Filter Logic ---

    // Apply range/limit
    query = query.range(from, to);

    const { data, error: fetchError, count } = await query;

    if (fetchError) {
        // 錯誤處理保持不變
        if (fetchError.message.includes('Could not find a relationship')) {
             error.value = `載入報告失敗：資料庫關聯查詢設定錯誤。(${fetchError.message})`;
             console.error("Fetch Error (Relationship):", fetchError);
        } else {
            error.value = `載入報告失敗: ${fetchError.message}`;
            console.error("Fetch Error:", fetchError);
        }
        if (!isExport) loading.value = false;
        if (isExport) throw fetchError;
    } else {
        // --- 修改資料處理: 移除 student_id 和 bed_number ---
        const processedData = data.map(r => ({
            ...r,
            dorm_zone: r.dorm_zones?.name || '未知區域',
            floor: r.rooms?.floor || '未知樓層',
            household: r.rooms?.household || '',
            room_number: r.rooms?.room_number || '未知房間',
            check_type_text: r.check_types?.name || '未知類型',
            user_email: r.user_id ? `User ID: ${r.user_id.substring(0, 8)}...` : '未知使用者',
            // student_id: '', // 移除
            // bed_number: '', // 移除
        }));
        // --- 結束修改 ---

        if (isExport) {
            // --- 修改匯出資料結構: 移除學號/床位號 ---
            const csvData = processedData.map(report => ({
                '報告ID': report.id,
                '檢查日期': new Date(report.created_at).toLocaleString('zh-TW'),
                '區域': report.dorm_zone,
                '樓層': report.floor,
                '戶': report.household,
                '房間號': report.room_number,
                '檢查類型': report.check_type_text,
                '檢查人員 (姓名)': report.inspector_name || '',
                '檢查人員 (帳號)': report.user_email, // 顯示 User ID
                // '學號': '', // 移除
                // '床位號': '', // 移除
                '良好數': report.good_count || 0,
                '損壞數': report.damaged_count || 0,
                '遺失數': report.missing_count || 0,
                '額外備註': report.additional_notes || '',
            }));
            return { data: csvData, count: count || 0 };
            // --- 結束修改 ---
        } else {
            reports.value = processedData;
            totalReports.value = count || 0;
            console.log(`Reports loaded: ${reports.value.length} of ${count}`);
            loading.value = false;
        }
    }
}


const applyFilters = () => {
    clearTimeout(filterTimeout);
    currentPage.value = 1;
    fetchReports();
}
const applyFiltersDebounced = () => {
    clearTimeout(filterTimeout);
    filterTimeout = setTimeout(() => {
        currentPage.value = 1;
        fetchReports();
    }, 300);
}

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

// 監聽篩選器變化
watch(() => [filters.check_type_id, filters.date, filters.inspector], applyFiltersDebounced, { deep: true });
// 注意：zone_id, floor, room_id 的變化由 onZoneChange, onFloorChange 和 select change 事件觸發 applyFilters


const handleViewReport = (report) => {
  const fullReport = reports.value.find(r => r.id === report.id);
  if (fullReport) {
    viewingReport.value = fullReport;
    reportDialog.value?.showModal();
  } else {
    showToast("無法載入報告詳情。", 'error');
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
    showToast(`刪除失敗: ${deleteError.message}`, 'error')
  } else {
    showToast('報告已刪除', 'success')
    if (reports.value.length === 1 && currentPage.value > 1) {
        currentPage.value--;
    }
    fetchReports();
  }
}

// *** exportReports 修改 ***
const exportReports = async () => {
    isExporting.value = true;
    showToast('開始準備匯出資料...', 'info');

    try {
        // 決定匯出範圍 (保持不變)
        let exportScope = "全部";
        const selectedZone = config.zones.find(z => z.id === filters.zone_id);
        const selectedRoom = availableRooms.value.find(r => r.id === filters.room_id);

        if (selectedRoom && selectedZone) {
             exportScope = `${selectedZone.name}-${filters.floor}-${selectedRoom.room_number}`;
        } else if (filters.floor && selectedZone) {
            exportScope = `${selectedZone.name}-${filters.floor}`;
        } else if (selectedZone) {
            exportScope = selectedZone.name;
        }

        const exportLimit = 5000;
        // fetchReports(true) 返回已處理好的 CSV 結構 (無學號/床位)
        const { data: dataForCsv, count } = await fetchReports(true, exportLimit);

        if (count > exportLimit) {
             showToast(`資料量過大 (${count} 筆)，僅匯出前 ${exportLimit} 筆。請縮小篩選範圍。`, 'warning');
        } else if (dataForCsv.length === 0) {
            showToast('沒有符合篩選條件的報告可供匯出。', 'info');
            isExporting.value = false;
            return;
        }

        // 使用 Papaparse 轉換
        const csvString = Papa.unparse(dataForCsv);

        // 建立並觸發下載 (保持不變)
        const blob = new Blob([`\uFEFF${csvString}`], { type: 'text/csv;charset=utf-8;' });
        const link = document.createElement('a');
        link.href = URL.createObjectURL(blob);
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
        link.download = `宿舍檢查報告_${exportScope}_${timestamp}.csv`;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        URL.revokeObjectURL(link.href);

        showToast('報告匯出成功！', 'success');

    } catch (error) {
        console.error("匯出報告失敗:", error);
        showToast(`匯出報告失敗: ${error.message}`, 'error');
    } finally {
        isExporting.value = false;
    }
};
// *** 結束 exportReports 修改 ***


const clearFilteredReports = async () => {
    showToast('「刪除篩選後」功能目前已停用以確保安全。請逐一刪除報告。', 'warning');
    return;
}


onMounted(fetchReports)

</script>

<style scoped>
/* 樣式保持不變 */
.form-control {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
.dialog-content-wrapper {
  scrollbar-width: thin;
}
.dialog-content-wrapper::-webkit-scrollbar {
  width: 8px;
}
.dialog-content-wrapper::-webkit-scrollbar-track {
  @apply bg-slate-100 dark:bg-slate-900;
  border-radius: 10px;
}
.dialog-content-wrapper::-webkit-scrollbar-thumb {
  @apply bg-slate-300 dark:bg-slate-600;
  border-radius: 10px;
}
.dialog-content-wrapper::-webkit-scrollbar-thumb:hover {
  @apply bg-slate-400 dark:bg-slate-500;
}
.report-preview-content :deep(div) {
    word-break: break-word;
}
.report-preview-content :deep(strong) {
    @apply font-semibold text-slate-700 dark:text-slate-200;
}
.report-preview-content :deep(a) {
    @apply text-blue-600 dark:text-blue-400 hover:underline;
}
.report-preview-content :deep(img.inline-block) {
    @apply h-10 w-10 object-cover rounded border border-slate-200 dark:border-slate-700 ml-2 align-middle;
}
</style>