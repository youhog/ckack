<!-- src/views/Inspection.vue -->
<template>
  <main class="space-y-4">
    <!-- 檢查項目導航 (使用 category.id) -->
    <div id="inspectionNavigation" class="card p-6 mb-8">
        <div class="text-center mb-4">
            <h3 class="text-lg font-semibold text-gray-700 flex items-center justify-center gap-2">
                🗂️ <span>檢查項目分類</span>
            </h3>
            <p class="text-sm text-gray-500 mt-1">點擊下方分類快速跳轉</p>
        </div>
        <div class="tab-container">
            <div class="tab-nav scrollbar-hide" id="categoryTabs">
                <div
                  v-for="(category, index) in config.checklistCategories"
                  :key="category.id"
                  :class="['tab-item', getCategoryStatus(category.id), { 'active': currentCategoryIndex === index }]"
                  @click="currentCategoryIndex = index"
                  :title="category.name"
                >
                  <div class="status-indicator"></div>
                  <!-- 限制文字長度，避免換行 -->
                  <span class="truncate">{{ category.icon }} {{ category.name }}</span>
                </div>
            </div>
        </div>
    </div>

    <!-- 檢查項目 -->
    <Checklist
      v-if="currentCategory && !config.loading && itemsForCurrentCategory.length > 0"
      :category="currentCategory"
      :items="itemsForCurrentCategory"
      v-model:checkData="checkData"
      v-model:notesData="notesData"
      v-model:photoData="photoData"
    />
     <div v-else-if="config.loading" class="card p-6 text-center text-gray-500">
        正在載入檢查項目設定...
    </div>
     <div v-else-if="!currentCategory" class="card p-6 text-center text-gray-500">
        沒有可用的檢查分類。請管理員在後台新增。
    </div>
    <div v-else-if="itemsForCurrentCategory.length === 0" class="card p-6 text-center text-gray-500">
        此分類 "{{ currentCategory.name }}" 下沒有檢查項目。請管理員在後台新增。
    </div>
    <div v-else class="card p-6 text-center text-red-500">
        無法載入檢查項目設定。錯誤: {{ config.error || '未知錯誤' }}
    </div>

    <!-- 總結區域 -->
    <div id="inspectionSummary" class="card p-8 mt-8">
        <div class="flex items-center gap-3 mb-6">
            <div class="w-12 h-12 bg-gradient-to-r from-purple-500 to-pink-500 rounded-2xl flex items-center justify-center text-white text-xl">
                📝
            </div>
            <h3 class="text-2xl font-bold text-gray-800">檢查總結</h3>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
            <div class="stat-card text-center" style="background: linear-gradient(135deg, rgba(16, 185, 129, 0.1), rgba(5, 150, 105, 0.1))">
                <div class="stat-icon mx-auto mb-3" style="background: linear-gradient(135deg, #10b981, #059669); color: white;">✅</div>
                <div class="stat-value text-green-600 mb-1">{{ summary.goodCount }}</div>
                <div class="stat-label">良好</div>
            </div>
            <div class="stat-card text-center" style="background: linear-gradient(135deg, rgba(239, 68, 68, 0.1), rgba(220, 38, 38, 0.1))">
                <div class="stat-icon mx-auto mb-3" style="background: linear-gradient(135deg, #ef4444, #dc2626); color: white;">❌</div>
                <div class="stat-value text-red-600 mb-1">{{ summary.damagedCount }}</div>
                <div class="stat-label">損壞</div>
            </div>
            <div class="stat-card text-center" style="background: linear-gradient(135deg, rgba(245, 158, 11, 0.1), rgba(217, 119, 6, 0.1))">
                <div class="stat-icon mx-auto mb-3" style="background: linear-gradient(135deg, #f59e0b, #d97706); color: white;">⚠️</div>
                <div class="stat-value text-yellow-600 mb-1">{{ summary.missingCount }}</div>
                <div class="stat-label">遺失</div>
            </div>
            <div class="stat-card text-center" style="background: linear-gradient(135deg, rgba(100, 116, 139, 0.1), rgba(71, 85, 105, 0.1))">
                <div class="stat-icon mx-auto mb-3" style="background: linear-gradient(135deg, #64748b, #475569); color: white;">⏳</div>
                <div class="stat-value text-gray-600 mb-1">{{ summary.pendingCount }}</div>
                <div class="stat-label">待檢查</div>
            </div>
        </div>

        <div class="mb-6">
            <label for="additionalNotes" class="form-label flex items-center gap-2">
                💭 <span>額外備註</span>
            </label>
            <textarea id="additionalNotes" rows="4" class="form-control resize-none" placeholder="請輸入其他需要記錄的事項..." v-model="additionalNotes"></textarea>
        </div>

        <button id="generateReportBtn" @click="generateReport" class="btn btn-primary w-full py-4 text-lg" :disabled="isGenerateDisabled">
            <span class="flex items-center justify-center gap-3">
                <span>📄</span>
                <span v-if="loading">報告生成中...</span>
                <span v-else>生成檢查報告</span>
                 <span v-if="missingInfoReason" class="text-xs opacity-75">({{ missingInfoReason }})</span>
            </span>
        </button>
    </div>

    <!-- 報告預覽 -->
    <div id="reportPreview" class="card p-6 mt-6" v-if="reportPreviewHtml">
        <h3 class="text-xl font-semibold text-gray-800 mb-4">📋 檢查報告預覽</h3>
        <div id="reportContent" class="space-y-2 text-sm report-preview-content" v-html="reportPreviewHtml"></div>
        <div class="mt-6 flex gap-3">
            <button id="downloadReportBtn" @click="downloadReport" class="btn" style="background: rgba(16, 185, 129, 0.1); color: #10b981;">
                💾 下載報告
            </button>
            <button id="printReportBtn" @click="printReport" class="btn btn-secondary">
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
const checkData = ref({}) // { "item-uuid-1": "good", ... }
const notesData = ref({}) // { "item-uuid-1": "備註", ... }
const photoData = ref({}) // { "item-uuid-1": "https://url.com/photo.png", ... }
const additionalNotes = ref('')
const reportPreviewHtml = ref(null)

const user = userStore.state.user
const config = configStore.state

// 總項目數
const totalItems = computed(() => config.checklistItems.length)

// 初始化/重設
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
      // 初始化完成後立即更新一次進度
      updateProgress();
  } else {
       console.warn("無法初始化檢查清單，因為設定尚未載入或為空。")
       // 確保 checkData 為空物件
       checkData.value = {};
       updateProgress(); // 更新進度為 0/0
  }

}

// 當 configStore 載入完成後，或 checklistItems 變化時，初始化一次
// 添加防抖或節流可能更好，但目前 watch 應該足夠
let initTimeoutId = null;
watch(() => [config.loading, config.checklistItems], ([isLoading, items]) => {
  clearTimeout(initTimeoutId); // 清除之前的計時器
  initTimeoutId = setTimeout(() => {
    console.log("Config/Items changed. Loading:", isLoading, "Items count:", items?.length);
    // 確保不是正在載入，且確實有項目
    if (!isLoading && items && items.length > 0) {
      initializeChecklist();
    } else if (!isLoading && (!items || items.length === 0)) {
      // 如果載入完成但沒有項目，清空 checkData
      checkData.value = {};
      updateProgress(); // 更新進度為 0/0
    }
  }, 100); // 稍微延遲初始化，等待數據穩定
}, { immediate: true, deep: true }) // 使用 deep: true 確保 items 內部變化也能觸發

// 當前顯示的分類
const currentCategory = computed(() => {
  // 邊界檢查
  if (config.checklistCategories && config.checklistCategories.length > currentCategoryIndex.value) {
     return config.checklistCategories[currentCategoryIndex.value]
  }
  return null;
})
// 該分類下的項目
const itemsForCurrentCategory = computed(() => {
  if (!currentCategory.value) return []
  return config.checklistItems.filter(item => item.category_id === currentCategory.value.id)
})

// 總結
const summary = computed(() => {
  const allStatus = Object.values(checkData.value)
  const goodCount = allStatus.filter(s => s === 'good').length
  const damagedCount = allStatus.filter(s => s === 'damaged').length
  const missingCount = allStatus.filter(s => s === 'missing').length
  const pendingCount = allStatus.filter(s => s === 'pending').length
  return { goodCount, damagedCount, missingCount, pendingCount }
})

// 更新進度
const updateProgress = () => {
    // 確保 totalItems > 0 才計算
    const total = totalItems.value > 0 ? totalItems.value : 0;
    // 從 summary 計算 completed
    const completed = summary.value.goodCount + summary.value.damagedCount + summary.value.missingCount;
    const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

    // 只有在 total > 0 時才發送有效進度，或者 completed 為 0 (表示 0/0)
    if (total > 0 || completed === 0) {
        emit('checklist-updated', {
            completed,
            total,
            percentage
        });
    } else if (total === 0) {
        // 如果 totalItems 為 0，確保發送 0/0
         emit('checklist-updated', { completed: 0, total: 0, percentage: 0 });
    }
};


// 當 checkData 變化時，更新進度
watch(checkData, updateProgress, { deep: true });

// 獲取分類狀態
const getCategoryStatus = (categoryId) => {
  const itemsInCategory = config.checklistItems.filter(item => item.category_id === categoryId);
  if (itemsInCategory.length === 0) return 'good'; // 空分類視為良好

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

// 計算生成按鈕是否應禁用
const missingInfoReason = computed(() => {
    if (config.loading) return '設定載入中';
    if (!props.formState.dormZone) return '請選擇區域';
    if (!props.formState.roomNumber) return '請選擇房間';
    if (!props.formState.checkType) return '請選擇類型';
    if (!props.formState.inspector) return '請填寫檢查人員';
    if (totalItems.value === 0) return '無檢查項目'; // 新增檢查
    return null; // 沒有缺少資訊
});
const isGenerateDisabled = computed(() => {
    return loading.value || config.loading || !!missingInfoReason.value;
});

// 生成報告
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
  let reportContent = `
      <div class="space-y-4">
          <div class="grid grid-cols-2 gap-4">
              <div><strong>宿舍分區:</strong> ${escapeHTML(zoneName)}</div>
              <div><strong>房間號碼:</strong> ${escapeHTML(roomNum)}</div>
              <div><strong>檢查類型:</strong> ${escapeHTML(checkTypeText)}</div>
              <div><strong>檢查人員:</strong> ${escapeHTML(inspector)}</div>
              <div><strong>檢查日期:</strong> ${escapeHTML(new Date().toLocaleDateString('zh-TW'))}</div>
          </div>
          <div class="border-t pt-4">
              <h4 class="font-medium mb-2">檢查結果統計</h4>
              <div class="grid grid-cols-3 gap-4">
                  <div class="text-center p-3 rounded-lg bg-green-50 text-green-700">
                      <div class="text-2xl font-bold">${goodCount}</div><div class="text-sm">良好項目</div>
                  </div>
                  <div class="text-center p-3 rounded-lg bg-red-50 text-red-700">
                      <div class="text-2xl font-bold">${damagedCount}</div><div class="text-sm">損壞項目</div>
                  </div>
                  <div class="text-center p-3 rounded-lg bg-yellow-50 text-yellow-700">
                      <div class="text-2xl font-bold">${missingCount}</div><div class="text-sm">遺失項目</div>
                  </div>
              </div>
          </div>
          <div class="border-t pt-4">
              <h4 class="font-medium mb-2">詳細檢查項目</h4>
  `;

  config.checklistCategories.forEach(category => {
      reportContent += `<h5 class="font-medium mt-3">${escapeHTML(category.icon)} ${escapeHTML(category.name)}</h5>`;
      const itemsInCategory = config.checklistItems.filter(i => i.category_id === category.id);

      itemsInCategory.forEach(item => {
          const status = checkData.value[item.id] || 'pending';
          const statusText = status === 'good' ? '✅ 良好' :
                           status === 'damaged' ? '❌ 損壞' :
                           status === 'missing' ? '⚠️ 遺失' : '⏳ 未檢查';

          const notes = notesData.value[item.id] || '';
          const photoUrl = photoData.value[item.id] || '';

          reportContent += `<div class="text-sm ml-4">${escapeHTML(item.name)}: ${statusText}`;
          if (notes) {
              reportContent += `<br><span class="text-gray-600 ml-4">備註: ${escapeHTML(notes)}</span>`;
          }
          if (photoUrl) {
              // 在預覽中直接顯示圖片縮圖
              reportContent += `<br><span class="text-gray-600 ml-4 flex items-center gap-2">照片: <a href="${escapeHTML(photoUrl)}" target="_blank" class="text-blue-600 hover:underline">查看</a> <img src="${escapeHTML(photoUrl)}" alt="照片預覽" class="inline-block h-10 w-10 object-cover rounded ml-2 border"></span>`;
          }
          reportContent += `</div>`;
      });
  });

  if (additionalNotes.value) {
      reportContent += `
          <div class="border-t pt-4">
              <h4 class="font-medium mb-2">額外備註</h4>
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
    inspector_name: inspector, // 儲存手動輸入的姓名
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
    // 顯示預覽
    reportPreviewHtml.value = reportContent
    // 發出事件，清空 AppLayout 中的表單 (除了 inspector)
    emit('report-generated')
    // 清空本地狀態
    initializeChecklist()
  }
  loading.value = false
}

// 下載報告
const downloadReport = () => {
    if (!reportPreviewHtml.value) return;
    const roomNumber = config.rooms.find(r => r.id === props.formState.roomNumber)?.room_number || '未知房間';
    const filename = `宿舍檢查報告_${roomNumber}_${new Date().toISOString().split('T')[0]}.html`;

    // 移除預覽中的圖片縮圖，改為純連結
    const contentForFile = reportPreviewHtml.value.replace(/<img[^>]*>/g, '(照片連結)');

    const fullHTML = `
        <!DOCTYPE html><html lang="zh-TW"><head><meta charset="UTF-8">
        <title>宿舍檢查報告 - ${escapeHTML(roomNumber)}</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; margin: 20px; line-height: 1.6; color: #333; }
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
            .report-preview-content .flex { display: flex; } /* Basic flex for layout */
            .report-preview-content .items-center { align-items: center; }
            .report-preview-content .gap-2 { gap: 0.5rem; }
            img { display:none; } /* Don't show images in download */
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

// 列印報告
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
            img.inline-block { display: none; } /* 列印時隱藏縮圖 */
            @media print {
              body { margin: 1cm; font-size: 10pt; }
              .grid-cols-3 { gap: 0.5rem; }
              .p-3 { padding: 8px; }
              .text-2xl { font-size: 1.2rem; }
              .btn, #downloadReportBtn, #printReportBtn { display: none; } /* 隱藏按鈕 */
              #reportPreview { margin-top: 0; padding: 0; box-shadow: none; border: none; }
              .card { box-shadow: none; border: none; padding: 0 !important; margin: 0 !important; }
              /* 強制列印背景色 */
              *{-webkit-print-color-adjust: exact !important; color-adjust: exact !important;}
            }
        </style></head><body>
        <h2>宿舍房間檢查報告</h2>
        ${reportPreviewHtml.value}
        <script>
          setTimeout(() => {
            window.print();
            window.onafterprint = () => setTimeout(window.close, 100); // 列印後延遲關閉
          }, 250); // 稍微延遲以確保內容載入
        <\/script>
        </body></html>
    `);
    printWindow.document.close();
}


</script>

<style scoped>
/* 讓 Tab 可以水平滾動 */
.scrollbar-hide {
  -ms-overflow-style: none;  /* IE and Edge */
  scrollbar-width: none;  /* Firefox */
}
.scrollbar-hide::-webkit-scrollbar {
  display: none; /* Chrome, Safari and Opera */
}
.tab-nav {
    overflow-x: auto;
    white-space: nowrap; /* 防止 Tab 換行 */
}
.tab-item {
    display: inline-flex; /* 讓 Tab 水平排列 */
    flex: 0 0 auto; /* 防止 Tab 被壓縮 */
    min-width: 160px; /* 增加最小寬度 */
    max-width: 250px; /* 增加最大寬度 */
    padding-left: 1rem; /* 增加左右 padding */
    padding-right: 1rem;
}
.tab-item span.truncate {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    display: inline-block; /* 確保 truncate 生效 */
    max-width: 100%; /* 確保不超過容器寬度 */
    vertical-align: middle; /* 垂直居中 */
}
/* 預覽報告中圖片樣式 (使用 :deep() 穿透) */
:deep(.report-preview-content img.inline-block) {
    height: 2.5rem; /* 40px */
    width: 2.5rem; /* 40px */
    object-fit: cover;
    border-radius: 0.25rem; /* 4px */
    margin-left: 0.5rem; /* 8px */
    border: 1px solid #e5e7eb; /* gray-200 */
    vertical-align: middle;
}
</style>

