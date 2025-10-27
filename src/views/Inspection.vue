<template>
  <main class="space-y-6">
    <div id="inspectionNavigation" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 mb-8">
        <div class="text-center mb-4">
            <h3 class="text-lg font-semibold text-slate-700 dark:text-slate-200 flex items-center justify-center gap-2">
                🗂️ <span>檢查項目分類</span>
            </h3>
            <p class="text-sm text-slate-500 dark:text-slate-400 mt-1">點擊下方分類快速跳轉</p>
        </div>
        <div class="tab-container">
            <div class="flex bg-slate-100 dark:bg-slate-900/50 rounded-xl p-1 overflow-x-auto scrollbar-hide" id="categoryTabs">
                <div
                  v-for="(category, index) in config.checklistCategories"
                  :key="category.id"
                  class="flex-1 min-w-[150px] px-4 py-3 text-center rounded-lg font-medium cursor-pointer transition-all duration-200 relative flex items-center justify-center gap-2 whitespace-nowrap"
                  :class="[getCategoryTabClass(category.id), { 'bg-white dark:bg-slate-700 shadow-md': currentCategoryIndex === index }]"
                  @click="currentCategoryIndex = index"
                  :title="category.name"
                >
                  <div class_ ="w-2 h-2 rounded-full flex-shrink-0" :class="getCategoryStatusIndicator(category.id)"></div>
                  <span class="truncate">{{ category.icon }} {{ category.name }}</span>
                </div>
            </div>
        </div>
    </div>

    <Checklist
      v-if="currentCategory && !config.loading && itemsForCurrentCategory.length > 0"
      :category="currentCategory"
      :items="itemsForCurrentCategory"
      v-model:checkData="checkData"
      v-model:notesData="notesData"
      v-model:photoData="photoData"
    />
     <div v-else-if="config.loading" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-slate-500">
        正在載入檢查項目設定...
    </div>
     <div v-else-if="!currentCategory" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-slate-500">
        沒有可用的檢查分類。請管理員在後台新增。
    </div>
    <div v-else-if="itemsForCurrentCategory.length === 0" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-slate-500">
        此分類 "{{ currentCategory.name }}" 下沒有檢查項目。請管理員在後台新增。
    </div>
    <div v-else class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-red-500">
        無法載入檢查項目設定。錯誤: {{ config.error || '未知錯誤' }}
    </div>

    <div id="inspectionSummary" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 md:p-8 mt-8">
        <div class="flex items-center gap-3 mb-6">
            <div class="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center text-white text-xl">
                📝
            </div>
            <h3 class="text-2xl font-bold text-slate-800 dark:text-slate-100">檢查總結</h3>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <div class="rounded-2xl p-4 text-center bg-green-50 dark:bg-green-500/10">
                <div class="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3 bg-gradient-to-r from-green-500 to-emerald-500 text-white text-2xl">✅</div>
                <div class="text-3xl font-bold text-green-600 dark:text-green-400 mb-1">{{ summary.goodCount }}</div>
                <div class="text-sm text-slate-600 dark:text-slate-400">良好</div>
            </div>
            <div class="rounded-2xl p-4 text-center bg-red-50 dark:bg-red-500/10">
                <div class="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3 bg-gradient-to-r from-red-500 to-red-600 text-white text-2xl">❌</div>
                <div class="text-3xl font-bold text-red-600 dark:text-red-400 mb-1">{{ summary.damagedCount }}</div>
                <div class="text-sm text-slate-600 dark:text-slate-400">損壞</div>
            </div>
            <div class="rounded-2xl p-4 text-center bg-yellow-50 dark:bg-yellow-500/10">
                <div class="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3 bg-gradient-to-r from-yellow-500 to-amber-500 text-white text-2xl">⚠️</div>
                <div class="text-3xl font-bold text-yellow-600 dark:text-yellow-400 mb-1">{{ summary.missingCount }}</div>
                <div class="text-sm text-slate-600 dark:text-slate-400">遺失</div>
            </div>
             <div class="rounded-2xl p-4 text-center bg-slate-50 dark:bg-slate-500/10">
                <div class="w-12 h-12 rounded-xl flex items-center justify-center mx-auto mb-3 bg-gradient-to-r from-slate-500 to-gray-500 text-white text-2xl">⏳</div>
                <div class="text-3xl font-bold text-slate-600 dark:text-slate-400 mb-1">{{ summary.pendingCount }}</div>
                <div class="text-sm text-slate-600 dark:text-slate-400">待檢查</div>
            </div>
        </div>

        <div class="mb-6">
            <label for="additionalNotes" class="form-label">
                💭 <span>額外備註</span>
            </label>
            <textarea id="additionalNotes" rows="4" class="form-control" placeholder="請輸入其他需要記錄的事項..." v-model="additionalNotes"></textarea>
        </div>

        <button id="generateReportBtn" @click="generateReport" 
          class="w-full py-4 text-lg font-semibold text-white bg-gradient-to-r from-blue-500 to-blue-700 rounded-xl shadow-md transition-all duration-300 transform hover:shadow-lg hover:-translate-y-0.5 focus:outline-none focus:ring-4 focus:ring-blue-500/30 disabled:opacity-60 disabled:cursor-not-allowed"
          :disabled="isGenerateDisabled">
            <span class="flex items-center justify-center gap-3">
                <span v-if="loading">
                  <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                    <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                    <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                  </svg>
                </span>
                <span v-else>📄</span>
                <span v-if="loading">報告生成中...</span>
                <span v-else>生成檢查報告</span>
                 <span v-if="missingInfoReason && !loading" class="text-xs opacity-75">({{ missingInfoReason }})</span>
            </span>
        </button>
    </div>

    <div id="reportPreview" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 mt-6" v-if="reportPreviewHtml">
        <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-4">📋 檢查報告預覽</h3>
        <div id="reportContent" class="space-y-2 text-sm report-preview-content" v-html="reportPreviewHtml"></div>
        <div class="mt-6 flex flex-col sm:flex-row gap-3">
            <button 
              id="downloadReportBtn" 
              @click="downloadReport" 
              class="inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-300 hover:bg-green-200 dark:hover:bg-green-500/30"
            >
                💾 下載報告
            </button>
            <button 
              id="printReportBtn" 
              @click="printReport" 
              class="inline-flex items-center justify-center px-5 py-2.5 rounded-xl font-medium transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600"
            >
                🖨️ 列印報告
            </button>
        </div>
    </div>
  </main>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '@/services/supabase'
import { userStore } from '@/store/user'
import { configStore } from '@/store/config'
import { escapeHTML, showToast } from '@/utils/index.js'
import Checklist from '@/components/Checklist.vue'

const props = defineProps({
  formState: Object
})
const emit = defineEmits(['report-generated', 'checklist-updated'])

const loading = ref(false)
const currentCategoryIndex = ref(0)
const checkData = ref({})
const notesData = ref({})
const photoData = ref({})
const additionalNotes = ref('')
const reportPreviewHtml = ref(null)

const user = userStore.state.user
const config = configStore.state

const totalItems = computed(() => config.checklistItems.length)

// --- (initializeChecklist 函數保持不變) ---
const initializeChecklist = () => {
  console.log("初始化/重設檢查清單...");
  const newCheckData = {}
  if (config.checklistItems && config.checklistItems.length > 0) {
      config.checklistItems.forEach(item => {
        newCheckData[item.id] = 'pending' // 使用 item.id 作為 key
      })
      checkData.value = newCheckData;
      notesData.value = {};
      photoData.value = {};
      additionalNotes.value = '';
      reportPreviewHtml.value = null;
      currentCategoryIndex.value = 0;
      updateProgress();
  } else {
       console.warn("無法初始化檢查清單，因為設定尚未載入或為空。")
       checkData.value = {};
       updateProgress(); 
  }
}

// --- (watch config 函數保持不變) ---
let initTimeoutId = null;
watch(() => [config.loading, config.checklistItems], ([isLoading, items]) => {
  clearTimeout(initTimeoutId); 
  initTimeoutId = setTimeout(() => {
    console.log("Config/Items changed. Loading:", isLoading, "Items count:", items?.length);
    if (!isLoading && items && items.length > 0) {
      initializeChecklist();
    } else if (!isLoading && (!items || items.length === 0)) {
      checkData.value = {};
      updateProgress();
    }
  }, 100); 
}, { immediate: true, deep: true })

const currentCategory = computed(() => {
  if (config.checklistCategories && config.checklistCategories.length > currentCategoryIndex.value) {
     return config.checklistCategories[currentCategoryIndex.value]
  }
  return null;
})
const itemsForCurrentCategory = computed(() => {
  if (!currentCategory.value) return []
  return config.checklistItems.filter(item => item.category_id === currentCategory.value.id)
})

const summary = computed(() => {
  const allStatus = Object.values(checkData.value)
  const goodCount = allStatus.filter(s => s === 'good').length
  const damagedCount = allStatus.filter(s => s === 'damaged').length
  const missingCount = allStatus.filter(s => s === 'missing').length
  const pendingCount = allStatus.filter(s => s === 'pending').length
  return { goodCount, damagedCount, missingCount, pendingCount }
})

// --- (updateProgress 函數保持不變) ---
const updateProgress = () => {
    const total = totalItems.value > 0 ? totalItems.value : 0;
    const completed = summary.value.goodCount + summary.value.damagedCount + summary.value.missingCount;
    const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

    if (total > 0 || completed === 0) {
        emit('checklist-updated', {
            completed,
            total,
            percentage
        });
    } else if (total === 0) {
         emit('checklist-updated', { completed: 0, total: 0, percentage: 0 });
    }
};

watch(checkData, updateProgress, { deep: true });

// --- (getCategoryStatus 函數保持不變, 用於 JS 邏輯) ---
const getCategoryStatus = (categoryId) => {
  const itemsInCategory = config.checklistItems.filter(item => item.category_id === categoryId);
  if (itemsInCategory.length === 0) return 'good'; 

  let hasPending = false;
  let hasIssues = false;

  itemsInCategory.forEach(item => {
    const status = checkData.value[item.id] || 'pending';
    if (status === 'pending') hasPending = true;
    else if (status === 'damaged' || status === 'missing') hasIssues = true;
  });

  if (hasIssues) return 'damaged';
  if (hasPending) return 'pending';
  return 'good';
}

// 【美化】Tab 樣式
const getCategoryTabClass = (categoryId) => {
    const status = getCategoryStatus(categoryId);
    switch (status) {
        case 'damaged': return 'text-red-700 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20';
        case 'pending': return 'text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700/50';
        case 'good': return 'text-green-700 dark:text-green-400 hover:bg-green-100 dark:hover:bg-green-500/20';
        default: return 'text-slate-700 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700';
    }
}
// 【美化】Tab 指示燈樣式
const getCategoryStatusIndicator = (categoryId) => {
    const status = getCategoryStatus(categoryId);
    switch (status) {
        case 'damaged': return 'bg-red-500';
        case 'pending': return 'bg-slate-400';
        case 'good': return 'bg-green-500';
        default: return 'bg-slate-400';
    }
}


const missingInfoReason = computed(() => {
    if (config.loading) return '設定載入中';
    if (!props.formState.dormZone) return '請選擇區域';
    if (!props.formState.roomNumber) return '請選擇房間';
    if (!props.formState.checkType) return '請選擇類型';
    if (!props.formState.inspector) return '請填寫檢查人員';
    if (totalItems.value === 0) return '無檢查項目';
    return null; 
});
const isGenerateDisabled = computed(() => {
    return loading.value || config.loading || !!missingInfoReason.value;
});

// --- (generateReport, downloadReport, printReport 函數保持不變) ---
// (為了簡潔，省略了這些函數的程式碼，它們的內部邏輯不需要修改)
const generateReport = async () => {
  // 再次驗證，雖然按鈕已禁用
  if (isGenerateDisabled.value) {
    if (missingInfoReason.value) {
        showToast(`無法生成報告: ${missingInfoReason.value}`, 'error');
    }
    return;
  }

  const { dormZone: zone_id, roomNumber: room_id, checkType: check_type_id, inspector } = props.formState;

  // 檢查是否有未檢查項目
  if (summary.value.pendingCount > 0) {
      if (!confirm(`還有 ${summary.value.pendingCount} 個項目未檢查，確定要生成報告嗎？`)) {
          return;
      }
  }

  loading.value = true
  reportPreviewHtml.value = null

  const { goodCount, damagedCount, missingCount } = summary.value

  // 從 ID 獲取文字
  const zoneName = config.zones.find(z => z.id === zone_id)?.name || '未知區域'
  const roomNum = config.rooms.find(r => r.id === room_id)?.room_number || '未知房間'
  const checkTypeText = config.checkTypes.find(t => t.id === check_type_id)?.name || '未知類型'

  // 1. 生成報告 HTML (使用 escapeHTML 防護 XSS)
  // 【美化】調整 HTML 報告樣式，使其在深色/淺色模式下都好看
  let reportContent = `
      <div class="space-y-4 text-slate-800 dark:text-slate-200">
          <div class="grid grid-cols-2 gap-4 p-4 bg-slate-50 dark:bg-slate-900 rounded-lg">
              <div><strong>宿舍分區:</strong> ${escapeHTML(zoneName)}</div>
              <div><strong>房間號碼:</strong> ${escapeHTML(roomNum)}</div>
              <div><strong>檢查類型:</strong> ${escapeHTML(checkTypeText)}</div>
              <div><strong>檢查人員:</strong> ${escapeHTML(inspector)}</div>
              <div><strong>檢查日期:</strong> ${escapeHTML(new Date().toLocaleDateString('zh-TW'))}</div>
          </div>
          <div class="border-t dark:border-slate-700 pt-4">
              <h4 class="font-medium text-lg mb-2">檢查結果統計</h4>
              <div class="grid grid-cols-3 gap-4">
                  <div class="text-center p-3 rounded-lg bg-green-50 dark:bg-green-500/10 text-green-700 dark:text-green-300">
                      <div class="text-2xl font-bold">${goodCount}</div><div class="text-sm">良好項目</div>
                  </div>
                  <div class="text-center p-3 rounded-lg bg-red-50 dark:bg-red-500/10 text-red-700 dark:text-red-300">
                      <div class="text-2xl font-bold">${damagedCount}</div><div class="text-sm">損壞項目</div>
                  </div>
                  <div class="text-center p-3 rounded-lg bg-yellow-50 dark:bg-yellow-500/10 text-yellow-700 dark:text-yellow-300">
                      <div class="text-2xl font-bold">${missingCount}</div><div class="text-sm">遺失項目</div>
                  </div>
              </div>
          </div>
          <div class="border-t dark:border-slate-700 pt-4">
              <h4 class="font-medium text-lg mb-2">詳細檢查項目</h4>
  `;

  config.checklistCategories.forEach(category => {
      reportContent += `<h5 class="font-medium mt-3 text-base">${escapeHTML(category.icon)} ${escapeHTML(category.name)}</h5>`;
      const itemsInCategory = config.checklistItems.filter(i => i.category_id === category.id);

      itemsInCategory.forEach(item => {
          const status = checkData.value[item.id] || 'pending';
          const statusText = status === 'good' ? '✅ 良好' :
                           status === 'damaged' ? '❌ 損壞' :
                           status === 'missing' ? '⚠️ 遺失' : '⏳ 未檢查';

          const notes = notesData.value[item.id] || '';
          const photoUrl = photoData.value[item.id] || '';

          reportContent += `<div class="text-sm ml-4 py-1">${escapeHTML(item.name)}: ${statusText}`;
          if (notes) {
              reportContent += `<br><span class="text-slate-600 dark:text-slate-400 ml-4">備註: ${escapeHTML(notes)}</span>`;
          }
          if (photoUrl) {
              reportContent += `<br><span class="text-slate-600 dark:text-slate-400 ml-4 flex items-center gap-2">照片: <a href="${escapeHTML(photoUrl)}" target="_blank" class="text-blue-600 dark:text-blue-400 hover:underline">查看</a> <img src="${escapeHTML(photoUrl)}" alt="照片預覽" class="inline-block h-10 w-10 object-cover rounded ml-2 border dark:border-slate-700"></span>`;
          }
          reportContent += `</div>`;
      });
  });

  if (additionalNotes.value) {
      reportContent += `
          <div class="border-t dark:border-slate-700 pt-4">
              <h4 class="font-medium text-lg mb-2">額外備註</h4>
              <div class="text-sm">${escapeHTML(additionalNotes.value)}</div>
          </div>
      `;
  }
  reportContent += `</div></div>`;

  // 2. 準備上傳到 Supabase 的資料
  const reportData = {
    user_id: user.id,
    zone_id: zone_id,
    room_id: room_id,
    check_type_id: check_type_id,
    inspector_name: inspector, 
    additional_notes: additionalNotes.value,
    good_count: goodCount,
    damaged_count: damagedCount,
    missing_count: missingCount,
    check_data: checkData.value,
    notes_data: notesData.value,
    photo_data: photoData.value,
    report_content_html: reportContent
  }

  // 3. 插入資料
  const { error } = await supabase.from('reports').insert(reportData)

  if (error) {
    showToast(`儲存報告失敗: ${error.message}`, 'error')
    console.error("儲存報告失敗:", error);
  } else {
    showToast('報告已成功儲存！', 'success')
    reportPreviewHtml.value = reportContent
    emit('report-generated')
    initializeChecklist()
  }
  loading.value = false
}
const downloadReport = () => {
    if (!reportPreviewHtml.value) return;
    const roomNumber = config.rooms.find(r => r.id === props.formState.roomNumber)?.room_number || '未知房間';
    const filename = `宿舍檢查報告_${roomNumber}_${new Date().toISOString().split('T')[0]}.html`;
    const contentForFile = reportPreviewHtml.value.replace(/<img[^>]*>/g, '(照片連結)');

    const fullHTML = `
        <!DOCTYPE html><html lang="zh-TW"><head><meta charset="UTF-8">
        <title>宿舍檢查報告 - ${escapeHTML(roomNumber)}</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; margin: 20px; line-height: 1.6; color: #333; background: #fff; }
            .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 1em;}
            .border-t { border-top: 1px solid #eee; padding-top: 1em; margin-top: 1em; }
            h2 { text-align: center; border-bottom: 1px solid #ccc; padding-bottom: 0.5em; margin-bottom: 1em; font-weight: 600; }
            h4 { color: #333; margin: 0 0 0.5em 0; font-size: 1.1em; font-weight: 600; }
            h5 { color: #555; margin-top: 1.5em; margin-bottom: 0.5em; font-size: 1em; font-weight: 600; }
            .ml-4 { margin-left: 20px; } .mb-2 { margin-bottom: 10px; }
            .text-gray-600 { color: #666; } .text-blue-600 { color: #0066cc; }
            .grid-cols-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
            .text-center { text-align: center; } .p-3 { padding: 12px; } .rounded-lg { border-radius: 8px; border: 1px solid #eee;}
            .bg-green-50 { background-color: #f0fdf4; border-color: #a7f3d0;} .text-green-700 { color: #047857; }
            .bg-red-50 { background-color: #fef2f2; border-color: #fecaca;} .text-red-700 { color: #b91c1c; }
            .bg-yellow-50 { background-color: #fefce8; border-color: #fde68a;} .text-yellow-700 { color: #b45309; }
            .text-2xl { font-size: 1.5rem; } .font-bold { font-weight: 700; } .text-sm { font-size: 0.875rem; }
            strong { font-weight: 600; }
            a { text-decoration: none; color: #0066cc; } a:hover { text-decoration: underline; }
            img { display:none; }
        </style></head><body>
        <h2>宿舍房間檢查報告</h2>
        ${contentForFile}
        </body></html>
    `;

    const blob = new Blob([fullHTML], { type: 'text/html;charset=utf-8' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}
const printReport = () => {
    if (!reportPreviewHtml.value) return;
    const roomNumber = config.rooms.find(r => r.id === props.formState.roomNumber)?.room_number || '未知房間';
    const printWindow = window.open('', '_blank', 'height=600,width=800');
    if (!printWindow) {
        showToast('無法開啟列印視窗，請檢查瀏覽器設定。', 'error');
        return;
    }
    printWindow.document.write(`
        <!DOCTYPE html><html lang="zh-TW"><head><title>宿舍檢查報告 - ${escapeHTML(roomNumber)}</title>
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
        <style>
            body { font-family: 'Inter', Arial, sans-serif; margin: 20px; line-height: 1.6; color: #333; }
            .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 1em; }
            .border-t { border-top: 1px solid #eee; padding-top: 1em; margin-top: 1em; }
            h2 { text-align: center; border-bottom: 1px solid #ccc; padding-bottom: 0.5em; margin-bottom: 1em; font-weight: 600;}
            h4 { color: #333; margin: 0 0 0.5em 0; font-size: 1.1em; font-weight: 600;}
            h5 { color: #555; margin-top: 1.5em; margin-bottom: 0.5em; font-size: 1em; font-weight: 600; }
            .ml-4 { margin-left: 20px; }
            .grid-cols-3 { display: grid; grid-template-columns: repeat(3, 1fr); gap: 1rem; }
            .text-center { text-align: center; } .p-3 { padding: 12px; } .rounded-lg { border-radius: 8px; border: 1px solid #eee; }
            .bg-green-50 { background-color: #f0fdf4 !important; border-color: #a7f3d0 !important;} .text-green-700 { color: #047857 !important; }
            .bg-red-50 { background-color: #fef2f2 !important; border-color: #fecaca !important;} .text-red-700 { color: #b91c1c !important; }
            .bg-yellow-50 { background-color: #fefce8 !important; border-color: #fde68a !important;} .text-yellow-700 { color: #b45309 !important; }
            .text-2xl { font-size: 1.5rem; } .font-bold { font-weight: 700; } .text-sm { font-size: 0.875rem; }
            strong { font-weight: 600; }
            a { text-decoration: none; color: #0066cc; }
            img.inline-block { display: none; }
            @media print {
              body { margin: 1cm; font-size: 10pt; }
              .grid-cols-3 { gap: 0.5rem; }
              .p-3 { padding: 8px; }
              .text-2xl { font-size: 1.2rem; }
              .btn, #downloadReportBtn, #printReportBtn { display: none; }
              #reportPreview { margin-top: 0; padding: 0; box-shadow: none; border: none; }
              .card { box-shadow: none; border: none; padding: 0 !important; margin: 0 !important; }
              *{-webkit-print-color-adjust: exact !important; color-adjust: exact !important;}
            }
        </style></head><body>
        <h2>宿舍房間檢查報告</h2>
        ${reportPreviewHtml.value}
        <script>
          setTimeout(() => {
            window.print();
            window.onafterprint = () => setTimeout(window.close, 100);
          }, 250);
        <\/script>
        </body></html>
    `);
    printWindow.document.close();
}


</script>

<style scoped>
/* 讓 Tab 可以水平滾動 */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

/* 穿透 .form-label 和 .form-control */
:deep(.form-label) {
  @apply block mb-2 text-sm font-medium text-slate-700 dark:text-slate-300;
}
:deep(.form-control) {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}

/* 預覽報告中圖片樣式 (使用 :deep() 穿透) */
:deep(.report-preview-content img.inline-block) {
    @apply h-10 w-10 object-cover rounded border border-slate-200 dark:border-slate-700 ml-2 align-middle;
}
:deep(.report-preview-content a) {
    @apply text-blue-600 dark:text-blue-400 hover:underline;
}
:deep(.report-preview-content strong) {
    @apply font-semibold text-slate-700 dark:text-slate-200;
}
</style>