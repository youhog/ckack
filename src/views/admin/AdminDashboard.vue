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
        <input type="text" placeholder="檢查人員 Email 或姓名" class="form-control" v-model="filters.inspector" @input="applyFiltersDebounced">
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
import { supabase } from '@/services/supabase' //
import { configStore } from '@/store/config' //
import ReportList from '@/components/ReportList.vue' //
import Papa from 'papaparse'; //
import { showToast } from '@/utils'; //

const loading = ref(true) //
const error = ref(null) //
const reports = ref([]) //
const reportDialog = ref(null) //
const viewingReport = ref(null) //
const config = configStore.state //

const currentPage = ref(1) //
const rowsPerPage = ref(20) // 每頁顯示數量 //
const totalReports = ref(0) //
let filterTimeout = null; //

const filters = reactive({ //
  zone_id: '', //
  floor: '', //
  room_id: '', // 改為 room_id //
  check_type_id: '', //
  date: '', //
  inspector: '' //
})

const availableFloors = ref([]); //
const floorsLoading = ref(false); //
const availableRooms = ref([]); //
const roomsLoading = ref(false); //

const isExporting = ref(false); //

const totalPages = computed(() => { //
    if (totalReports.value === 0) return 1; //
    return Math.ceil(totalReports.value / rowsPerPage.value) //
})

const fetchFloorsForZone = async () => { //
    if (!filters.zone_id) { //
        availableFloors.value = []; //
        return; //
    }
    floorsLoading.value = true; //
    availableFloors.value = []; // 清空舊樓層 //
    filters.floor = ''; // 重設樓層選擇 //
    filters.room_id = ''; // 重設房間選擇 //
    availableRooms.value = []; // 清空舊房間 //
    try {
        const { data, error } = await supabase //
            .from('rooms') //
            .select('floor') //
            .eq('zone_id', filters.zone_id) //
            .order('floor'); // 可選：排序樓層 //

        if (error) throw error; //
        // 去重並排序
        availableFloors.value = [...new Set(data.map(item => item.floor))].sort((a, b) => a.localeCompare(b, undefined, { numeric: true })); //
    } catch (e) {
        console.error("載入樓層失敗:", e); //
        showToast(`載入樓層失敗: ${e.message}`, 'error'); //
    } finally {
        floorsLoading.value = false; //
        applyFilters(); // 區域改變後立即觸發一次報告查詢 //
    }
}

const fetchRoomsForFloor = async () => { //
     if (!filters.zone_id || !filters.floor) { //
        availableRooms.value = []; //
        return; //
    }
    roomsLoading.value = true; //
    availableRooms.value = []; // 清空舊房間 //
    filters.room_id = ''; // 重設房間選擇 //
    try {
        const { data, error } = await supabase //
            .from('rooms') //
            .select('id, room_number') //
            .eq('zone_id', filters.zone_id) //
            .eq('floor', filters.floor) //
            .order('room_number'); // 按房號排序 //

        if (error) throw error; //
        availableRooms.value = data; //
    } catch (e) {
        console.error("載入房間失敗:", e); //
        showToast(`載入房間失敗: ${e.message}`, 'error'); //
    } finally {
        roomsLoading.value = false; //
        applyFilters(); // 樓層改變後立即觸發一次報告查詢 //
    }
}

const onZoneChange = () => { //
    fetchFloorsForZone(); //
}
const onFloorChange = () => { //
    fetchRoomsForFloor(); //
}

const fetchReports = async (isExport = false, exportLimit = 1000) => { //
    if (!isExport) { //
      loading.value = true; //
    }
    error.value = null; //
    console.log(`AdminDashboard: Fetching reports... Page: ${currentPage.value}, Export: ${isExport}`); //

    const from = isExport ? 0 : (currentPage.value - 1) * rowsPerPage.value; //
    const to = isExport ? exportLimit -1 : from + rowsPerPage.value - 1; //

    let query = supabase //
        .from('reports') //
        .select(`
          id, created_at, user_id, zone_id, room_id, check_type_id,
          inspector_name, additional_notes,
          good_count, damaged_count, missing_count, report_content_html,
          dorm_zones ( name ),
          rooms ( room_number, floor, household ),
          check_types ( name ),
          profiles ( email ),
          student_allocations ( student_id, bed_number )
        `, { count: 'exact' }) // 需要 student_allocations //
        .order('created_at', { ascending: false }); //

    // --- Filter Logic ---
    if (filters.zone_id) query = query.eq('zone_id', filters.zone_id); //
    // floor 和 room_id 篩選在 rooms() 關聯內部完成，或直接用 eq('room_id', ...)
    if (filters.floor && !filters.room_id) { //
       // 如果只選了樓層，需要找到該樓層所有 room_id 再篩選
       // 為了簡化，我們先只處理 room_id 的直接篩選
       // 複雜邏輯：
       // const { data: roomIds } = await supabase.from('rooms').select('id').eq('zone_id', filters.zone_id).eq('floor', filters.floor);
       // if (roomIds) query = query.in('room_id', roomIds.map(r => r.id));
    }
    if (filters.room_id) query = query.eq('room_id', filters.room_id); // 直接用 room_id 篩選 //
    if (filters.check_type_id) query = query.eq('check_type_id', filters.check_type_id); //
    if (filters.date) { //
        query = query.gte('created_at', `${filters.date}T00:00:00.000Z`); //
        query = query.lte('created_at', `${filters.date}T23:59:59.999Z`); //
    }
    if (filters.inspector) { //
        const inspectorLower = `%${filters.inspector.toLowerCase()}%`; //
        query = query.or( //
            `inspector_name.ilike.${inspectorLower},profiles.email.ilike.${inspectorLower}`, //
            { foreignTable: 'profiles' } //
        );
    }
    // --- End Filter Logic ---

    // Apply range/limit
    query = query.range(from, to); //

    const { data, error: fetchError, count } = await query; //

    if (fetchError) { //
        error.value = `載入報告失敗: ${fetchError.message}` //
        console.error("Fetch Error:", fetchError) //
        if (!isExport) loading.value = false; // 只有在非匯出時才更新 loading //
        throw fetchError; // 讓匯出函數知道出錯了 //
    } else {
        const processedData = data.map(r => ({ //
            ...r, //
            dorm_zone: r.dorm_zones?.name || '未知區域', //
            floor: r.rooms?.floor || '未知樓層', // 新增樓層 //
            household: r.rooms?.household || '', // 新增戶 //
            room_number: r.rooms?.room_number || '未知房間', //
            check_type_text: r.check_types?.name || '未知類型', //
            user_email: r.profiles?.email || '未知使用者', //
            student_id: r.student_allocations?.student_id || '', // 可能有多個，這裡取第一個 //
            bed_number: r.student_allocations?.bed_number || '', //
            // 注意：如果一個房間有多個學生，這裡的 student_allocations 可能需要更複雜的處理
            // 目前假設一個報告主要關聯一個學生（如果需要）或不關聯
        }));

        if (isExport) { //
            return { data: processedData, count: count || 0 }; // 匯出時返回數據 //
        } else {
            reports.value = processedData; //
            totalReports.value = count || 0; //
            console.log(`Reports loaded: ${reports.value.length} of ${count}`); //
            loading.value = false; //
        }
    }
}

const fetchReportsFallback = async (from, to) => { //
    console.warn("Fallback fetch executed. Student ID might be missing."); //
    let query = supabase //
        .from('reports') //
        .select(`
          id, created_at, user_id, zone_id, room_id, check_type_id,
          inspector_name, additional_notes,
          good_count, damaged_count, missing_count, report_content_html,
          dorm_zones ( name ),
          rooms ( room_number, floor, household ),
          check_types ( name )
        `, { count: 'exact' }) //
        .order('created_at', { ascending: false }); //

    if (filters.zone_id) query = query.eq('zone_id', filters.zone_id); //
    if (filters.room_id) query = query.eq('room_id', filters.room_id); // // 使用 room_id
    if (filters.check_type_id) query = query.eq('check_type_id', filters.check_type_id); //
    if (filters.date) { //
        query = query.gte('created_at', `${filters.date}T00:00:00.000Z`); //
        query = query.lte('created_at', `${filters.date}T23:59:59.999Z`); //
    }
    if (filters.inspector) { //
        query = query.ilike('inspector_name', `%${filters.inspector}%`); //
    }

    query = query.range(from, to); //
    const { data, error: fetchError, count } = await query; //

    if (fetchError) { //
        error.value = `載入報告失敗 (Fallback): ${fetchError.message}` //
        console.error("Fetch Error (Fallback):", fetchError) //
    } else {
        reports.value = data.map(r => ({ //
          ...r, //
          dorm_zone: r.dorm_zones?.name || '未知區域', //
          floor: r.rooms?.floor || '未知樓層', //
          household: r.rooms?.household || '', //
          room_number: r.rooms?.room_number || '未知房間', //
          check_type_text: r.check_types?.name || '未知類型', //
          user_email: 'N/A (備用模式)', //
          student_id: '', // Fallback 無法取得
          bed_number: '' // Fallback 無法取得
        }))
        totalReports.value = count || 0; //
    }
    loading.value = false; //
}


const applyFilters = () => { //
    clearTimeout(filterTimeout); //
    currentPage.value = 1; //
    fetchReports(); //
}
const applyFiltersDebounced = () => { //
    clearTimeout(filterTimeout); //
    filterTimeout = setTimeout(() => { //
        currentPage.value = 1; //
        fetchReports(); //
    }, 300);
}

const nextPage = () => { //
    if (currentPage.value < totalPages.value) { //
        currentPage.value++; //
        fetchReports(); //
    }
}
const prevPage = () => { //
    if (currentPage.value > 1) { //
        currentPage.value--; //
        fetchReports(); //
    }
}

// 監聽非 room_id 的篩選器變化
watch(() => [filters.check_type_id, filters.date, filters.inspector], applyFiltersDebounced, { deep: true }); //


const handleViewReport = (report) => { //
  const fullReport = reports.value.find(r => r.id === report.id); //
  if (fullReport) { //
    viewingReport.value = fullReport; //
    reportDialog.value?.showModal(); //
  } else {
    showToast("無法載入報告詳情。", 'error'); //
  }
}

const closeReportDialog = () => { //
    reportDialog.value?.close(); //
    viewingReport.value = null; //
}


const handleDeleteReport = async (reportId) => { //
  if (!confirm('管理員權限：確定要刪除此報告嗎？此操作無法復原。')) return //

  const { error: deleteError } = await supabase //
    .from('reports') //
    .delete() //
    .eq('id', reportId) //

  if (deleteError) { //
    showToast(`刪除失敗: ${deleteError.message}`, 'error') //
  } else {
    showToast('報告已刪除', 'success') //
    // 如果刪除的是當前頁最後一筆，可能需要跳回上一頁
    if (reports.value.length === 1 && currentPage.value > 1) { //
        currentPage.value--; //
    }
    fetchReports(); // 重新載入 //
  }
}

const exportReports = async () => { //
    isExporting.value = true; //
    showToast('開始準備匯出資料...', 'info'); //

    try {
        // 決定匯出範圍
        let exportScope = "全部"; //
        const selectedZone = config.zones.find(z => z.id === filters.zone_id); //
        const selectedRoom = availableRooms.value.find(r => r.id === filters.room_id); //

        if (selectedRoom && selectedZone) { //
             exportScope = `${selectedZone.name}-${filters.floor}-${selectedRoom.room_number}`; //
        } else if (filters.floor && selectedZone) { //
            exportScope = `${selectedZone.name}-${filters.floor}`; //
        } else if (selectedZone) { //
            exportScope = selectedZone.name; //
        }

        // Fetch all data matching filters (with a reasonable limit, e.g., 5000 records)
        // 注意：如果資料量非常大，可能需要後端實現匯出或分批匯出
        const exportLimit = 5000; // 設定匯出上限 //
        const { data: dataToExport, count } = await fetchReports(true, exportLimit); //

        if (count > exportLimit) { //
             showToast(`資料量過大 (${count} 筆)，僅匯出前 ${exportLimit} 筆。請縮小篩選範圍。`, 'warning'); //
        } else if (dataToExport.length === 0) { //
            showToast('沒有符合篩選條件的報告可供匯出。', 'info'); //
            isExporting.value = false; //
            return; //
        }

        // 準備 CSV 數據
        const csvData = dataToExport.map(report => ({ //
            '報告ID': report.id, //
            '檢查日期': new Date(report.created_at).toLocaleString('zh-TW'), //
            '區域': report.dorm_zone, //
            '樓層': report.floor, //
            '戶': report.household, //
            '房間號': report.room_number, //
            '檢查類型': report.check_type_text, //
            '檢查人員': report.inspector_name || report.user_email, // 優先使用填寫的名字 //
            '學號': report.student_id, // 加入學號 //
            '床位號': report.bed_number, // 加入床位號 //
            '良好數': report.good_count || 0, //
            '損壞數': report.damaged_count || 0, //
            '遺失數': report.missing_count || 0, //
            '額外備註': report.additional_notes || '', //
            // 可以選擇性加入 check_data, notes_data, photo_data 的簡化資訊
        }));

        // 使用 Papaparse 轉換為 CSV 字串
        const csvString = Papa.unparse(csvData); //

        // 建立並觸發下載
        const blob = new Blob([`\uFEFF${csvString}`], { type: 'text/csv;charset=utf-8;' }); // 加入 BOM //
        const link = document.createElement('a'); //
        link.href = URL.createObjectURL(blob); //
        const timestamp = new Date().toISOString().replace(/[:.]/g, '-'); //
        link.download = `宿舍檢查報告_${exportScope}_${timestamp}.csv`; //
        document.body.appendChild(link); //
        link.click(); //
        document.body.removeChild(link); //
        URL.revokeObjectURL(link.href); //

        showToast('報告匯出成功！', 'success'); //

    } catch (error) {
        console.error("匯出報告失敗:", error); //
        showToast(`匯出報告失敗: ${error.message}`, 'error'); //
    } finally {
        isExporting.value = false; //
    }
};

const clearFilteredReports = async () => { //
    // 考慮到風險和複雜性，建議在後端實現或禁用此功能
    showToast('「刪除篩選後」功能目前已停用以確保安全。請逐一刪除報告。', 'warning'); //
    // 如果確實需要實現：
    // 1. 確認篩選條件不為空，避免誤刪全部
    // 2. 彈出強烈警告確認框
    // 3. 調用 Supabase 函數 (Edge Function) 或在後端執行刪除操作，傳遞篩選條件
    // 4. 前端直接調用 delete() 搭配多個 .eq() / .ilike() 可能有效能問題或超時
    return; //
}


onMounted(fetchReports) //

</script>

<style scoped>
/* 樣式保持不變 */
.form-control {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm; /* */
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20; /* */
}
.dialog-content-wrapper { /* */
  scrollbar-width: thin; /* */
}
.dialog-content-wrapper::-webkit-scrollbar { /* */
  width: 8px; /* */
}
.dialog-content-wrapper::-webkit-scrollbar-track { /* */
  @apply bg-slate-100 dark:bg-slate-900; /* */
  border-radius: 10px; /* */
}
.dialog-content-wrapper::-webkit-scrollbar-thumb { /* */
  @apply bg-slate-300 dark:bg-slate-600; /* */
  border-radius: 10px; /* */
}
.dialog-content-wrapper::-webkit-scrollbar-thumb:hover { /* */
  @apply bg-slate-400 dark:bg-slate-500; /* */
}
.report-preview-content :deep(div) { /* */
    word-break: break-word; /* */
}
.report-preview-content :deep(strong) { /* */
    @apply font-semibold text-slate-700 dark:text-slate-200; /* */
}
.report-preview-content :deep(a) { /* */
    @apply text-blue-600 dark:text-blue-400 hover:underline; /* */
}
.report-preview-content :deep(img.inline-block) { /* */
    @apply h-10 w-10 object-cover rounded border border-slate-200 dark:border-slate-700 ml-2 align-middle; /* */
}
</style>