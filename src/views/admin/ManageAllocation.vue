// src/views/admin/ManageAllocation.vue
// (保持原樣即可)

<template>
  <div class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6">
    <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-2">管理學生床位分配</h3>
    <p class="text-sm text-slate-500 dark:text-slate-400 mb-6">透過 CSV 檔案批次匯入或更新學生的床位分配資料。系統會以「學號」為依據新增或更新。</p>

    <div class="mb-8 p-4 bg-slate-50 dark:bg-slate-900/50 rounded-lg border border-slate-200 dark:border-slate-700">
      <h4 class="text-lg font-medium text-slate-800 dark:text-slate-100 mb-4">批次匯入 CSV</h4>

      <div class="flex flex-col sm:flex-row justify-between items-start mb-4">
        <label for="allocationFile" class="block text-sm font-medium text-slate-700 dark:text-slate-300">
          選擇 CSV 檔案 (必含：學號, 區域名稱, 房間號碼, 床位號) </label>
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
         <div class="p-3 rounded-lg text-center bg-yellow-100 dark:bg-yellow-900/20 text-yellow-800 dark:text-yellow-300">
          <p class="text-sm font-medium">驗證錯誤</p>
          <p class="text-2xl font-bold">{{ importResults.validationErrorsCount }}</p> </div>
      </div>

      <div v-if="importResults.errors.length > 0" class="mt-4">
        <h4 class="text-lg font-semibold text-red-700 dark:text-red-400 mb-2">失敗詳情 (最多顯示 20 筆)</h4>
        <ul class="list-disc list-inside bg-red-50 dark:bg-red-900/20 p-4 rounded-lg text-red-800 dark:text-red-300 text-sm max-h-48 overflow-y-auto">
          <li v-for="(error, index) in importResults.errors.slice(0, 20)" :key="index">{{ error }}</li>
           <li v-if="importResults.errors.length > 20">...還有 {{ importResults.errors.length - 20 }} 筆錯誤未顯示</li>
        </ul>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, reactive } from 'vue'
import { supabase } from '@/services/supabase'
// configStore 不再需要，因為房間查找邏輯已內化
// import { configStore } from '@/store/config'
import { showToast } from '@/utils'
import Papa from 'papaparse';

// const config = configStore.state; // 不再需要
const isSaving = ref(false);
const selectedFile = ref(null);
const importResults = reactive({ // 改用 reactive
  totalProcessed: 0,
  successCount: 0,
  failedCount: 0,
  validationErrorsCount: 0, // 新增：計算驗證錯誤數量
  errors: [],
});
const roomsMap = ref(new Map()); // Map<`ZONE_NAME-ROOM_NUMBER`, { room_id, zone_id }>

// 元件掛載時，獲取所有房間資料以建立查找 Map
onMounted(async () => {
    await fetchAllRoomsForMapping();
});

// 獲取所有房間資料以建立查找 Map
const fetchAllRoomsForMapping = async () => {
    roomsMap.value.clear(); // 清空舊的 Map
    try {
        // 同時獲取房間和區域資料
        const [{ data: roomsData, error: roomsError }, { data: zonesData, error: zonesError }] = await Promise.all([
             supabase.from('rooms').select('id, room_number, zone_id'),
             supabase.from('dorm_zones').select('id, name')
        ]);

        if (roomsError) throw roomsError;
        if (zonesError) throw zonesError;

        // 建立 zone ID 到 zone Name 的 Map
        const zoneNameMap = new Map((zonesData || []).map(z => [z.id, z.name]));

        // 遍歷房間資料，建立查找 Map
        (roomsData || []).forEach(room => {
            const zoneName = zoneNameMap.get(room.zone_id);
            if (zoneName && room.room_number) { // 確保區域名稱和房號都存在
                const key = `${zoneName}-${room.room_number}`; // 使用 '區域名稱-房間號碼' 作為 key
                roomsMap.value.set(key, { room_id: room.id, zone_id: room.zone_id });
            } else {
                 console.warn(`無法建立房間映射: 房間 ID ${room.id} 的區域名稱或房號缺失。`);
            }
        });
        console.log(`ManageAllocation: Rooms mapping built, total valid keys: ${roomsMap.value.size}`);

    } catch (e) {
        showToast(`初始化房間/區域快取失敗: ${e.message}`, 'error');
        console.error("Fetch All Rooms/Zones for Mapping Error:", e);
        // 如果載入失敗，Map 會是空的，後續驗證會失敗
    }
}


const handleFileSelect = (event) => {
  selectedFile.value = event.target.files[0];
  // 重置結果狀態
  Object.assign(importResults, {
      totalProcessed: 0,
      successCount: 0,
      failedCount: 0,
      validationErrorsCount: 0,
      errors: []
  });
};

const processImport = () => {
  if (!selectedFile.value) {
    showToast('請選擇一個 CSV 檔案。', 'info');
    return;
  }
  // 再次檢查 roomsMap 是否已成功建立
  if (roomsMap.value.size === 0) {
      showToast('房間查找資料尚未準備就緒，請稍後再試或重新整理頁面。', 'error');
      // 可以選擇再次嘗試載入
      // fetchAllRoomsForMapping();
      return;
  }


  isSaving.value = true;
   // 重置結果狀態
  Object.assign(importResults, {
      totalProcessed: 0,
      successCount: 0,
      failedCount: 0,
      validationErrorsCount: 0,
      errors: []
  });


  Papa.parse(selectedFile.value, {
    header: true,
    skipEmptyLines: true,
    complete: (results) => {
      if (results.errors.length > 0) {
        const errorMessages = results.errors.map(e => `第 ${e.row + 2} 行解析錯誤: ${e.message}`).join('; ');
        showToast(`CSV 解析時發生錯誤: ${errorMessages}`, 'error');
        importResults.errors.push(...results.errors.map(e => `第 ${e.row + 2} 行解析錯誤: ${e.message}`));
        importResults.failedCount = results.data.length; // 假設所有行都失敗
        importResults.totalProcessed = results.data.length;
        isSaving.value = false;
        return;
      }
      handleData(results.data);
    },
    error: (err, file) => { // PapaParse 錯誤回調接收 err 和 file
      showToast(`檔案讀取失敗: ${err.message}`, 'error');
      console.error("PapaParse file read error:", err, file);
      importResults.errors.push(`檔案讀取失敗: ${err.message}`);
      isSaving.value = false;
    }
  });
};

const handleData = async (data) => {
  const recordsToUpsert = [];
  const validationErrors = []; // 儲存驗證錯誤訊息

  // 預期 CSV 標頭 (提供多種可能的名稱)
  const HEADERS = {
    STUDENT_ID: ['學號', 'student_id', '學 生 號 碼'], // 增加可能包含空格的標頭
    ZONE_NAME: ['區域名稱', 'zone_name', '宿 舍 區 域'],
    ROOM_NUMBER: ['房間號碼', 'room_number', '房 間 號'],
    BED_NUMBER: ['床位號', 'bed_number', '床 位'], // 床位號是必填的
  };

  // 輔助函數：從 row 物件中根據可能的標頭名稱取得值
  const getRowValue = (row, possibleHeaders) => {
      for (const header of possibleHeaders) {
          // 檢查原始 CSV 數據中是否存在該鍵 (區分大小寫)
          if (row.hasOwnProperty(header)) {
              // 確保值轉換為字串並去除前後空格
              const value = String(row[header] ?? '').trim();
              if (value) return value; // 返回第一個找到的非空值
          }
           // 嘗試不區分大小寫查找 (如果需要)
          const lowerHeader = header.toLowerCase();
           for(const key in row) {
               if (key.toLowerCase() === lowerHeader) {
                    const value = String(row[key] ?? '').trim();
                    if (value) return value;
               }
           }
      }
      return ''; // 如果所有可能的標頭都找不到或值為空，返回空字串
  };

  // 遍歷 CSV 資料進行驗證和轉換
  data.forEach((row, index) => {
    const displayLineNumber = index + 2; // CSV 行號 (從 2 開始，因為有標頭)
    const studentId = getRowValue(row, HEADERS.STUDENT_ID);
    const zoneName = getRowValue(row, HEADERS.ZONE_NAME);
    const roomNumber = getRowValue(row, HEADERS.ROOM_NUMBER);
    const bedNumber = getRowValue(row, HEADERS.BED_NUMBER); // 床位號現在是必填

    // 基礎驗證：確保必填欄位存在
    if (!studentId || !zoneName || !roomNumber || !bedNumber) { // 檢查 bedNumber 是否為空
      validationErrors.push(`第 ${displayLineNumber} 行：資料不完整 (學號/區域名稱/房間號碼/床位號 均為必填)。`);
      return; // 跳過此行
    }

    // 查找房間和區域 ID
    const roomKey = `${zoneName}-${roomNumber}`;
    const roomInfo = roomsMap.value.get(roomKey);

    if (!roomInfo) {
      validationErrors.push(`第 ${displayLineNumber} 行：在系統中找不到對應的區域/房間組合 "${zoneName}-${roomNumber}"。請檢查名稱是否完全匹配。`);
      return; // 跳過此行
    }

    // 驗證床位號是否有效 (例如，是否為 1, 2, 3, 4)
    if (!['1', '2', '3', '4'].includes(bedNumber)) {
        validationErrors.push(`第 ${displayLineNumber} 行：無效的床位號 "${bedNumber}"。床位號應為 1, 2, 3 或 4。`);
        return; // 跳過此行
    }


    // 驗證通過，加入待處理列表
    recordsToUpsert.push({
      student_id: studentId,
      zone_id: roomInfo.zone_id,
      room_id: roomInfo.room_id,
      bed_number: bedNumber, // DDL 定義為 NOT NULL
    });
  });

  // 更新處理結果中的總數和驗證錯誤數
  importResults.totalProcessed = data.length;
  importResults.validationErrorsCount = validationErrors.length;
  importResults.errors = validationErrors; // 將驗證錯誤加入結果

  // 如果存在驗證錯誤，則不執行資料庫操作
  if (validationErrors.length > 0) {
    isSaving.value = false;
    showToast(`匯入中止，發現 ${validationErrors.length} 筆資料驗證錯誤。請修正後重試。`, 'error');
    console.warn("Validation Errors:", validationErrors);
    return; // 提前返回
  }

  // 如果沒有驗證錯誤且有資料需要處理
  if (recordsToUpsert.length > 0) {
      console.log(`準備寫入 ${recordsToUpsert.length} 筆資料到資料庫...`);
      // 分批處理以避免請求過大 (例如每批 500 筆)
      const batchSize = 500;
      let successfulUpserts = 0;
      const dbErrors = [];

      for (let i = 0; i < recordsToUpsert.length; i += batchSize) {
          const batch = recordsToUpsert.slice(i, i + batchSize);
          console.log(`處理批次 ${i / batchSize + 1}...`);
          const { data: upsertedData, error: dbError } = await supabase
              .from('student_allocations')
              .upsert(batch, { onConflict: 'student_id' }) // 使用 student_id 作為衝突鍵來更新或插入
              .select('id'); // 選擇 'id' 以計算成功數量

          if (dbError) {
              console.error("Supabase Upsert Error (Batch):", dbError);
              dbErrors.push(`資料庫寫入錯誤 (批次 ${i / batchSize + 1}): ${dbError.message} (詳情請見控制台)`);
              // 可以選擇中止處理或記錄錯誤繼續處理下一批
              // break; // 如果希望一有錯誤就停止
          } else {
              successfulUpserts += (upsertedData?.length || 0);
          }
      }

      // 更新最終結果
      importResults.successCount = successfulUpserts;
      importResults.failedCount = recordsToUpsert.length - successfulUpserts; // 僅計算資料庫操作失敗的數量
      importResults.errors.push(...dbErrors); // 將資料庫錯誤添加到結果

      if (dbErrors.length > 0) {
           showToast(`匯入完成，但有 ${dbErrors.length} 個批次寫入資料庫時發生錯誤。成功 ${successfulUpserts} 筆，失敗 ${importResults.failedCount} 筆。`, 'warning');
      } else {
           showToast(`床位分配匯入/更新成功！共 ${successfulUpserts} 筆記錄已處理。`, 'success');
      }

  } else {
      // 沒有資料需要處理 (可能是空檔案或所有行都有驗證錯誤)
      if (validationErrors.length === 0) {
        showToast('CSV 檔案中沒有有效的資料可供匯入。', 'info');
      }
      // 如果有驗證錯誤，上面的錯誤提示已顯示
  }


  isSaving.value = false;
  selectedFile.value = null; // 清空選擇的檔案
  // 清除檔案輸入元素的值，以便可以再次選擇同一個檔案
  const fileInput = document.getElementById('allocationFile');
  if(fileInput) fileInput.value = '';
};


// 下載範例 CSV 檔案
const downloadSample = () => {
  // 確保標頭與 getRowValue 中的 HEADERS 保持一致或相容
  const csvContent = '"學號","區域名稱","房間號碼","床位號"\n"A111001","A 區 (男生宿舍)","101","1"\n"A111002","A 區 (男生宿舍)","101","2"\n"B222003","B 區 (女生宿舍)","202","4"';
  // 添加 BOM (Byte Order Mark) 確保 Excel 正確識別 UTF-8
  const blob = new Blob([`\uFEFF${csvContent}`], { type: 'text/csv;charset=utf-8;' });
  const link = document.createElement('a');
  if (link.download !== undefined) { // 檢查瀏覽器是否支援 download 屬性
    link.href = URL.createObjectURL(blob);
    link.download = '學生床位分配匯入範例.csv';
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
  } else {
    // 備用方案 (可能不適用所有瀏覽器)
    navigator.msSaveBlob(blob, '學生床位分配匯入範例.csv');
  }
};
</script>

<style scoped>
/* 樣式僅為了 btn-primary 保持一致 */
.btn-primary {
  @apply inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-gradient-to-r from-blue-500 to-blue-700 text-white shadow-md hover:shadow-lg hover:-translate-y-0.5 disabled:opacity-60 disabled:cursor-not-allowed;
}
/* 新增：為輸入框添加一些基本樣式 */
input[type="file"] {
  @apply file:mr-4 file:py-2 file:px-4 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 dark:file:bg-blue-900/50 file:text-blue-700 dark:file:text-blue-300 hover:file:bg-blue-100 dark:hover:file:bg-blue-900;
}
</style>