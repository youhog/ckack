<template>
  <main class="space-y-6">
    <div id="inspectionNavigation" v-if="config.checklistCategories.length > 0" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 mb-8">
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
                  class="flex-1 min-w-[160px] px-4 py-3 text-center rounded-lg font-medium cursor-pointer transition-all duration-200 relative flex items-center justify-center gap-2 whitespace-nowrap"
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
      :is-per-person="isPerPersonCategory(currentCategory.id)" 
      v-model:checkData="checkData"
      v-model:notesData="notesData"
      v-model:photoData="photoData"
    />
     <div v-else-if="config.loading" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-slate-500">
        正在載入檢查項目設定...
    </div>
     <div v-else-if="!currentCategory && config.checklistCategories.length > 0" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-slate-500">
        無法找到當前分類。
    </div>
    <div v-else-if="config.checklistCategories.length === 0" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 text-center text-slate-500">
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
        
        <div class="flex flex-col sm:flex-row gap-3">
            <button 
                v-if="summary.pendingCount > 0"
                @click="markAllGood"
                class="inline-flex items-center justify-center px-4 py-2.5 text-lg font-semibold rounded-xl transition-all duration-300 cursor-pointer w-full sm:w-1/2 bg-green-500 hover:bg-green-600 text-white shadow-md hover:shadow-lg focus:outline-none focus:ring-4 focus:ring-green-500/30"
            >
                ✨ 一鍵標記全部良好 ({{ summary.pendingCount }}項)
            </button>
            <button 
                id="generateReportBtn" 
                @click="generateReport"
                class="w-full py-4 text-lg font-semibold text-white bg-gradient-to-r from-blue-500 to-blue-700 rounded-xl shadow-md transition-all duration-300 transform hover:shadow-lg hover:-translate-y-0.5 focus:outline-none focus:ring-4 focus:ring-blue-500/30 disabled:opacity-60 disabled:cursor-not-allowed"
                :class="{'sm:w-1/2': summary.pendingCount > 0}"
                :disabled="isGenerateDisabled"
            >
                <span class="flex items-center justify-center gap-3">
                    <span v-if="loading">
                      <svg class="animate-spin -ml-1 mr-2 h-5 w-5 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
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

    </div>

    <div id="reportPreview" class="bg-white dark:bg-slate-800 rounded-2xl shadow-lg p-6 mt-6" v-if="reportPreviewHtml">
        <h3 class="text-xl font-semibold text-slate-800 dark:text-slate-100 mb-4">📋 檢查報告預覽</h3>
        <div id="reportContent" class="space-y-2 text-sm report-preview-content" v-html="reportPreviewHtml"></div>
        <div class="mt-6 flex flex-col sm:flex-row gap-3">
            <button
              id="downloadReportBtn"
              @click="downloadReport"
              class="inline-flex items-center justify-center px-5 py-2.5 text-sm font-medium rounded-xl transition-all duration-200 cursor-pointer bg-green-100 dark:bg-green-500/20 text-green-700 dark:text-green-300 hover:bg-green-200 dark:hover:bg-green-500/30"
            >
                💾 下載報告
            </button>
            <button
              id="printReportBtn"
              @click="printReport"
              class="inline-flex items-center justify-center px-5 py-2.5 text-sm font-medium rounded-xl transition-all duration-200 cursor-pointer bg-white dark:bg-slate-700 border border-slate-900/10 dark:border-slate-600 text-slate-700 dark:text-slate-200 hover:bg-slate-50 dark:hover:bg-slate-600"
            >
                🖨️ 列印報告
            </button>
        </div>
    </div>
  </main>
</template>

<script setup>
import { ref, computed, watch, onMounted } from 'vue'
import { supabase } from '@/services/supabase' //
import { userStore } from '@/store/user' //
import { configStore } from '@/store/config' //
import { escapeHTML, showToast } from '@/utils/index.js' //
import Checklist from '@/components/Checklist.vue' //

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

const user = userStore.state.user //
const config = configStore.state //

// *** MODIFIED CONSTANTS FOR NUMERIC LABELS ***
const OCCUPANCY_COUNT = 4; // Max occupancy for standard room
const SUFFIXES = ['-1', '-2', '-3', '-4']; 
const OCCUPANT_LABELS = ['1 號床', '2 號床', '3 號床', '4 號床'];
// *** END MODIFIED CONSTANTS ***

const isPerPersonCategory = (categoryId) => {
    const category = config.checklistCategories.find(c => c.id === categoryId); //
    return category && category.name === '寢室區域'; 
}

const totalItems = computed(() => config.checklistItems.length) //


// 初始化/重設 (項目預設為 'pending')
const initializeChecklist = () => {
  const newCheckData = {}
  if (config.checklistItems && config.checklistItems.length > 0) { //
      config.checklistItems.forEach(item => { //
         newCheckData[item.id] = 'pending' 
      })
      checkData.value = newCheckData;
      notesData.value = {}; 
      photoData.value = {};
      additionalNotes.value = '';
      reportPreviewHtml.value = null;
      if (config.checklistCategories.length > 0) {
          currentCategoryIndex.value = 0;
      } else {
          currentCategoryIndex.value = -1;
      }
      updateProgress();
  } else {
       checkData.value = {};
       currentCategoryIndex.value = -1;
       updateProgress();
  }
}

let initTimeoutId = null;
watch(() => [config.loading, config.checklistItems, config.checklistCategories], ([isLoading, items, categories]) => { //
  clearTimeout(initTimeoutId); 
  initTimeoutId = setTimeout(() => {
    if (!isLoading && items && items.length > 0 && categories.length > 0) {
      initializeChecklist();
    } else if (!isLoading) {
      initializeChecklist();
    }
  }, 100); 
}, { immediate: true, deep: true })


const currentCategory = computed(() => {
  if (config.checklistCategories && config.checklistCategories.length > currentCategoryIndex.value && currentCategoryIndex.value !== -1) { //
     return config.checklistCategories[currentCategoryIndex.value] //
  }
  return null;
})

const itemsForCurrentCategory = computed(() => {
  if (!currentCategory.value || !config.checklistItems) return [] //
  
  return config.checklistItems //
      .filter(item => item.category_id === currentCategory.value.id);
})

const summary = computed(() => {
    let goodCount = 0;
    let damagedCount = 0;
    let missingCount = 0;
    let pendingCount = 0;

    for (const item of config.checklistItems) { //
        const baseStatus = checkData.value[item.id] || 'pending';
        const isPerPerson = isPerPersonCategory(item.category_id);

        if (isPerPerson) {
            if (baseStatus === 'pending') {
                pendingCount += OCCUPANCY_COUNT;
                continue;
            }
            
            const occupantStatus = notesData.value[item.id]?.occupantStatus || {};
            
            for (let i = 0; i < OCCUPANCY_COUNT; i++) {
                const suffix = SUFFIXES[i];
                const status = occupantStatus[suffix] || baseStatus; 

                if (status === 'damaged') {
                    damagedCount++;
                } else if (status === 'missing') {
                    missingCount++;
                } else {
                    goodCount++;
                }
            }
            
        } else {
            if (baseStatus === 'damaged') {
                damagedCount++;
            } else if (baseStatus === 'missing') {
                missingCount++;
            } else if (baseStatus === 'good') {
                goodCount++;
            } else {
                pendingCount++;
            }
        }
    }

    return { goodCount, damagedCount, missingCount, pendingCount };
})


const updateProgress = () => {
    const trueTotal = config.checklistItems.reduce((acc, item) =>  //
        acc + (isPerPersonCategory(item.category_id) ? OCCUPANCY_COUNT : 1)
    , 0);
    const completed = summary.value.goodCount + summary.value.damagedCount + summary.value.missingCount;
    const pending = summary.value.pendingCount;

    const actualCompleted = trueTotal - pending; 
    const percentage = trueTotal > 0 ? Math.round((actualCompleted / trueTotal) * 100) : 0;

    emit('checklist-updated', {
        completed: actualCompleted,
        total: trueTotal,
        percentage
    });
};

watch(checkData, updateProgress, { deep: true });
watch(notesData, updateProgress, { deep: true }); 


const getCategoryStatus = (categoryId) => {
  const itemsInCategory = config.checklistItems.filter(item => item.category_id === categoryId); //
  if (itemsInCategory.length === 0) return 'good'; 

  let hasPending = false;
  let hasIssues = false;

  for (const item of itemsInCategory) {
    const baseStatus = checkData.value[item.id] || 'pending';
    const isPerPerson = isPerPersonCategory(item.category_id);
    
    if (baseStatus === 'pending') {
        hasPending = true;
    } else if (isPerPerson) {
        const occupantStatus = notesData.value[item.id]?.occupantStatus || {};
        if (Object.values(occupantStatus).some(s => s !== 'good')) {
            hasIssues = true;
        }
    } else if (baseStatus === 'damaged' || baseStatus === 'missing') {
        hasIssues = true;
    }
  }

  if (hasIssues) return 'damaged';
  if (hasPending) return 'pending';
  return 'good';
}


const getCategoryTabClass = (categoryId) => {
    const status = getCategoryStatus(categoryId);
    switch (status) {
        case 'damaged': return 'text-red-700 dark:text-red-400 hover:bg-red-100 dark:hover:bg-red-500/20';
        case 'pending': return 'text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700/50';
        case 'good': return 'text-green-700 dark:text-green-400 hover:bg-green-100 dark:hover:bg-green-500/20';
        default: return 'text-slate-700 dark:text-slate-300 hover:bg-slate-200 dark:hover:bg-slate-700';
    }
}

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
    if (config.loading) return '設定載入中'; //
    if (!props.formState.dormZone) return '請選擇區域';
    if (!props.formState.roomNumber) return '請選擇房間';
    if (!props.formState.checkType) return '請選擇類型';
    if (!props.formState.inspector) return '請填寫檢查人員';
    if (totalItems.value === 0) return '無檢查項目';
    return null; 
});
const isGenerateDisabled = computed(() => {
    return loading.value || config.loading || !!missingInfoReason.value; //
});


const markAllGood = () => {
    if (summary.value.pendingCount === 0) {
        showToast('所有項目均已檢查完畢。', 'info'); //
        return;
    }
    
    if (!confirm(`確定要將剩餘的 ${summary.value.pendingCount} 個項目標記為「良好」嗎？`)) {
        return;
    }

    const newCheckData = { ...checkData.value };
    const newNotesData = { ...notesData.value };
    const newPhotoData = { ...photoData.value };

    config.checklistItems.forEach(item => { //
        const baseStatus = newCheckData[item.id] || 'pending';
        
        if (baseStatus === 'pending') {
            newCheckData[item.id] = 'good'; 
            delete newNotesData[item.id];
            delete newPhotoData[item.id];
        }
    });

    checkData.value = newCheckData;
    notesData.value = newNotesData;
    photoData.value = newPhotoData;
    
    showToast('所有未檢查項目已標記為良好！', 'success'); //
}


const generateReport = async () => {
  // ... (omitted boilerplate checks)

  loading.value = true
  reportPreviewHtml.value = null

  const { goodCount, damagedCount, missingCount } = summary.value
  const { dormZone: zone_id, roomNumber: room_id, checkType: check_type_id, inspector } = props.formState;

  // 從 ID 獲取文字
  const zoneName = config.zones.find(z => z.id === zone_id)?.name || '未知區域' //
  
  let roomNum = '未知房間';
  try {
      const { data } = await supabase.from('rooms').select('room_number').eq('id', room_id).single(); //
      roomNum = data?.room_number || '未知房間';
  } catch (e) {
      console.warn("無法從 DB 獲取房號文字:", e);
  }

  const checkTypeText = config.checkTypes.find(t => t.id === check_type_id)?.name || '未知類型' //

  // 1. 生成報告 HTML 
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

  config.checklistCategories.forEach(category => { //
      reportContent += `<h5 class="font-medium mt-3 text-base">${escapeHTML(category.icon)} ${escapeHTML(category.name)}</h5>`;
      const itemsInCategory = config.checklistItems.filter(i => i.category_id === category.id); //

      const isPerPerson = isPerPersonCategory(category.id);
      
      itemsInCategory.forEach(item => {
          const baseStatus = checkData.value[item.id] || 'pending';
          const itemNotes = notesData.value[item.id];
          
          if (isPerPerson) {
              const occupantStatus = itemNotes?.occupantStatus || {};
              let hasIssue = Object.values(occupantStatus).some(s => s !== 'good');
              let occupantDetails = [];

              if (hasIssue) {
                  for (let i = 0; i < OCCUPANCY_COUNT; i++) {
                      const suffix = SUFFIXES[i];
                      const label = OCCUPANT_LABELS[i];
                      const status = occupantStatus[suffix] || 'good'; 
                      const specificNotes = itemNotes?.occupantNotes?.[suffix] || '';
                      
                      if (status !== 'good') {
                          const statusText = status === 'damaged' ? '❌ 損壞' : '⚠️ 遺失';
                          occupantDetails.push(`
                               <span class="text-slate-600 dark:text-slate-400 ml-4">${label}: ${statusText}</span>
                               ${specificNotes ? `<br><span class="text-slate-500 dark:text-slate-500 ml-8">備註: ${escapeHTML(specificNotes)}</span>` : ''}
                          `);
                      }
                  }
                  
                  reportContent += `<div class="text-sm ml-4 py-1 font-semibold text-red-500 dark:text-red-400">${escapeHTML(item.name)}: 發現問題 (請見詳細清單)</div>`;
                  reportContent += occupantDetails.join('');
              } else {
                  const statusText = baseStatus === 'pending' ? '⏳ 未檢查' : '✅ 良好';
                  reportContent += `<div class="text-sm ml-4 py-1">${escapeHTML(item.name)}: ${statusText} (4人)</div>`;
              }
              
          } else {
              const statusText = baseStatus === 'good' ? '✅ 良好' :
                                 baseStatus === 'damaged' ? '❌ 損壞' :
                                 baseStatus === 'missing' ? '⚠️ 遺失' : '⏳ 未檢查';
              const notes = itemNotes || '';
              const photoUrl = photoData.value[item.id] || '';
              
              reportContent += `<div class="text-sm ml-4 py-1">${escapeHTML(item.name)}: ${statusText}`;
              if (notes) {
                  reportContent += `<br><span class="text-slate-600 dark:text-slate-400 ml-4">備註: ${escapeHTML(notes)}</span>`;
              }
              if (photoUrl) {
                  reportContent += `<br><span class="text-slate-600 dark:text-slate-400 ml-4 flex items-center gap-2">照片: <a href="${escapeHTML(photoUrl)}" target="_blank" class="text-blue-600 dark:text-blue-400 hover:underline">查看</a> <img src="${escapeHTML(photoUrl)}" alt="照片預覽" class="inline-block h-10 w-10 object-cover rounded ml-2 border dark:border-slate-700"></span>`;
              }
              reportContent += `</div>`;
          }
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

  const reportData = {
    user_id: user.id, //
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

  const { error } = await supabase.from('reports').insert(reportData) //

  if (error) {
    showToast(`儲存報告失敗: ${error.message}`, 'error') //
    console.error("儲存報告失敗:", error);
  } else {
    showToast('報告已成功儲存！', 'success') //
    reportPreviewHtml.value = reportContent
    emit('report-generated')
    initializeChecklist()
  }
  loading.value = false
}

// 下載報告 (保持不變)
const downloadReport = () => { /* ... */ }

// 列印報告 (保持不變)
const printReport = () => { /* ... */ }

</script>

<style scoped>
/* ... (樣式保持不變) ... */
.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
.scrollbar-hide::-webkit-scrollbar {
  display: none;
}
.tab-nav {
    overflow-x: auto;
    white-space: nowrap; 
}
.tab-item {
    display: inline-flex; 
    flex: 0 0 auto; 
    min-width: 160px; 
    max-width: 250px; 
    padding-left: 1rem; 
    padding-right: 1rem;
}
.tab-item span.truncate {
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
    display: inline-block; 
    max-width: 100%; 
    vertical-align: middle; 
}
:deep(.form-label) {
  @apply block mb-2 text-sm font-medium text-slate-700 dark:text-slate-300;
}
:deep(.form-control) {
  @apply w-full px-4 py-2.5 rounded-lg border border-slate-300 dark:border-slate-700 bg-white dark:bg-slate-900 transition-all duration-200 text-sm;
  @apply focus:outline-none focus:border-blue-500 focus:ring-2 focus:ring-blue-500/20;
}
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