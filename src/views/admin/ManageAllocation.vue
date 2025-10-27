// youhog/ckack/ckack-10cc0a3bfb263ad24e91487d07fabdff03536175/src/views/admin/ManageAllocation.vue
<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理學生床位分配</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">透過 CSV 檔案批次匯入或更新學生的床位分配資料。系統會以「學號」為依據新增或更新。</p>

    <div class="mb-8 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
      <h4 class="text-lg font-medium text-slate-800 dark:text-slate-100 mb-4">批次匯入 CSV</h4>
      
      <div class="flex flex-col sm:flex-row justify-between items-start mb-4">
        <label for="allocationFile" class="block text-sm font-medium text-slate-700 dark:text-slate-300">
          選擇 CSV 檔案 (必含：學號, 區域名稱, 房間號碼)
        </label>
        <a href="#" @click.prevent="downloadSample" class="text-blue-600 dark:text-blue-400 hover:underline text-sm mt-2 sm:mt-0">下載範例檔</a>
      </div>
      
      <input type="file" id="allocationFile" @change="handleFileSelect" accept=".csv" class="w-full text-sm text-slate-700 dark:text-slate-300 border border-slate-300 dark:border-slate-700 rounded-lg p-2 focus:outline-none focus:ring-2 focus:ring-blue-500/20">
      <p v-if="selectedFile" class="text-slate-500 dark:text-slate-400 text-xs mt-2">已選擇檔案: {{ selectedFile.name }}</p>

      <button 
        @click="processImport" 
        :disabled="isSaving || !selectedFile" 
        class="btn-primary mt-5 w-full sm:w-auto"
      >
        <span v-if="isSaving">
          <svg class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
          匯入/更新中...
        </span>
        <span v-else>開始匯入/更新床位分配</span>
      </button>
    </div>

    <div v-if="importResults.totalProcessed > 0" class="mt-8 border-t dark:border-slate-700 pt-6">
      <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-4">匯入結果</h3>
      <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
        <div class="p-3 rounded-lg text-center bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-300">
          <p class="text-sm font-medium">總處理筆數</p>
          <p class="text-2xl font-bold">{{ importResults.totalProcessed }}</p>
        </div>
        <div class="p-3 rounded-lg text-center bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-300">
          <p class="text-sm font-medium">成功更新/新增</p>
          <p class="text-2xl font-bold">{{ importResults.successCount }}</p>
        </div>
        <div class="p-3 rounded-lg text-center bg-red-100 dark:bg-red-900/20 text-red-800 dark:text-red-300">
          <p class="text-sm font-medium">失敗筆數</p>
          <p class="text-2xl font-bold">{{ importResults.failedCount }}</p>
        </div>
      </div>
      
      <div v-if="importResults.errors.length > 0" class="mt-4">
        <h4 class="text-lg font-semibold text-red-700 dark:text-red-400 mb-2">失敗詳情</h4>
        <ul class="list-disc list-inside bg-red-50 dark:bg-red-900/20 p-4 rounded-lg text-red-800 dark:text-red-300 text-sm max-h-48 overflow-y-auto">
          <li v-for="(error, index) in importResults.errors" :key="index">{{ error }}</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { supabase } from '@/services/supabase'
import { configStore } from '@/store/config'
import { showToast } from '@/utils'
import Papa from 'papaparse'; 

const config = configStore.state
const isSaving = ref(false);
const selectedFile = ref(null);
const importResults = ref({
  totalProcessed: 0,
  successCount: 0,
  failedCount: 0,
  errors: [],
});
const roomsMap = ref(new Map()); 

onMounted(async () => {
    // REMOVED: 冗餘檢查 (configStore.fetchConfig())
    await fetchAllRooms();
});

// 為了更精確地查找 room_id，我們從 DB 獲取所有 room 數據
const fetchAllRooms = async () => {
    try {
        const { data: roomsData, error } = await supabase
            .from('rooms')
            .select('id, room_number, zone_id');
        
        if (error) throw error;

        // 構建 roomsMap: key: `ZONE_NAME-ROOM_NUMBER` -> { room_id, zone_id }
        const { data: zonesData } = await supabase.from('dorm_zones').select('id, name');
        const zoneNameMap = new Map(zonesData.map(z => [z.id, z.name]));
        
        roomsMap.value.clear();
        roomsData.forEach(room => {
            const zoneName = zoneNameMap.get(room.zone_id);
            if (zoneName) {
                const key = `${zoneName}-${room.room_number}`;
                roomsMap.value.set(key, { room_id: room.id, zone_id: room.zone_id });
            }
        });
        console.log(`ManageAllocation: Rooms mapping built, total keys: ${roomsMap.value.size}`);
    } catch (e) {
        showToast(`初始化房間快取失敗: ${e.message}`, 'error');
        console.error("Fetch All Rooms Error:", e);
    }
}


const handleFileSelect = (event) => {
  selectedFile.value = event.target.files[0];
  importResults.value = { totalProcessed: 0, successCount: 0, failedCount: 0, errors: [] };
};

const processImport = () => {
  if (!selectedFile.value) {
    showToast('請選擇一個 CSV 檔案。', 'info');
    return;
  }
  
  isSaving.value = true;
  importResults.value = { totalProcessed: 0, successCount: 0, failedCount: 0, errors: [] };


  Papa.parse(selectedFile.value, {
    header: true,
    skipEmptyLines: true,
    complete: (results) => {
      if (results.errors.length > 0) {
        const errorMessages = results.errors.map(e => `第 ${e.row + 2} 行: ${e.message}`).join('; ');
        showToast(`CSV 解析錯誤: ${errorMessages}`, 'error');
        isSaving.value = false;
        return;
      }
      handleData(results.data);
    },
    error: (err) => {
      showToast(`檔案讀取失敗: ${err.message}`, 'error');
      isSaving.value = false;
    }
  });
};

const handleData = async (data) => {
  const recordsToUpsert = [];
  const validationErrors = [];
  
  // 預期 CSV 標頭
  const HEADERS = {
    STUDENT_ID: ['學號', 'student_id'],
    ZONE_NAME: ['區域名稱', 'zone_name'],
    ROOM_NUMBER: ['房間號碼', 'room_number'],
    BED_NUMBER: ['床位號', 'bed_number'], // 選填
  };

  const getRowValue = (row, possibleHeaders) => {
      for (const header of possibleHeaders) {
          // 檢查原始 CSV 數據中是否存在該鍵
          if (row.hasOwnProperty(header)) {
              const value = String(row[header]).trim();
              if (value) return value;
          }
      }
      return '';
  };

  data.forEach((row, index) => {
    const displayLineNumber = index + 2;
    const studentId = getRowValue(row, HEADERS.STUDENT_ID);
    const zoneName = getRowValue(row, HEADERS.ZONE_NAME);
    const roomNumber = getRowValue(row, HEADERS.ROOM_NUMBER);
    const bedNumber = getRowValue(row, HEADERS.BED_NUMBER);
    
    if (!studentId || !zoneName || !roomNumber) {
      validationErrors.push(`第 ${displayLineNumber} 行資料不完整 (學號/區域/房號為必填)。`);
      return;
    }

    const roomKey = `${zoneName}-${roomNumber}`;
    const roomInfo = roomsMap.value.get(roomKey);

    if (!roomInfo) {
      validationErrors.push(`第 ${displayLineNumber} 行：找不到對應的區域/房間組合 "${zoneName}-${roomNumber}"。`);
      return;
    }
    
    if (!bedNumber) {
        // 根據 DDL (bed_number TEXT NOT NULL) 這裡應該是必填
        validationErrors.push(`第 ${displayLineNumber} 行：床位號為必填，請檢查。`);
        return;
    }


    recordsToUpsert.push({
      student_id: studentId,
      zone_id: roomInfo.zone_id,
      room_id: roomInfo.room_id,
      bed_number: bedNumber, // bed_number is NOT NULL
    });
  });

  if (validationErrors.length > 0) {
    importResults.value.totalProcessed = data.length;
    importResults.value.failedCount = validationErrors.length;
    importResults.value.errors = validationErrors;
    isSaving.value = false;
    showToast(`匯入失敗，發現 ${validationErrors.length} 筆錯誤。`, 'error');
    return;
  }
  
  importResults.value.totalProcessed = recordsToUpsert.length;

  const { data: upsertedData, error } = await supabase
    .from('student_allocations')
    .upsert(recordsToUpsert, { onConflict: 'student_id' }) // 使用 student_id 作為衝突鍵
    .select('id');

  if (error) {
    console.error("Supabase Upsert Error:", error);
    showToast(`匯入失敗: ${error.message}`, 'error');
    importResults.value.failedCount = recordsToUpsert.length;
    importResults.value.errors = [`資料庫寫入錯誤: ${error.message}`];
  } else {
    const successCount = upsertedData.length;
    importResults.value.successCount = successCount;
    importResults.value.failedCount = recordsToUpsert.length - successCount;
    showToast(`床位分配匯入/更新成功！共 ${successCount} 筆。`, 'success');
  }

  isSaving.value = false;
  selectedFile.value = null;
  // Clear the file input visually
  const fileInput = document.getElementById('allocationFile');
  if(fileInput) fileInput.value = '';
};


const downloadSample = () => {
  const csvContent = '學號,區域名稱,房間號碼,床位號\n"A111001","A 區 (男生宿舍)","101","1"\n"A111002","A 區 (男生宿舍)","202","4"\n"A111003","B 區 (女生宿舍)","102","2"';
  const blob = new Blob([`\uFEFF${csvContent}`], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  link.href = URL.createObjectURL(blob);
  link.download = '學生床位分配匯入範例.csv';
  document.body.appendChild(link);
  link.click();
  document.body.removeChild(link);
  URL.revokeObjectURL(link.href);
};
</script>

<style scoped>
/* 樣式僅為了 btn-primary 保持一致 */
.btn-primary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
</style>