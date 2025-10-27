import { createClient } from '@supabase/supabase-js'

// 從環境變數讀取 Supabase URL 和 Anon Key
// Vite 會自動將 .env 檔案中的 VITE_ 開頭變數注入到 import.meta.env
const supabaseUrl = import.meta.env.VITE_SUPABASE_URL
const supabaseKey = import.meta.env.VITE_SUPABASE_ANON_KEY

// 檢查環境變數是否存在
if (!supabaseUrl || !supabaseKey) {
  // 在瀏覽器控制台顯示更詳細的錯誤訊息
  console.error("Supabase 環境變數未設定!");
  console.error("請確保在專案根目錄下建立了 .env 檔案，並且包含以下內容:");
  console.error("VITE_SUPABASE_URL=YOUR_SUPABASE_URL");
  console.error("VITE_SUPABASE_ANON_KEY=YOUR_ANON_KEY");
  console.error("修改 .env 後需要重新啟動 Vite 開發伺服器 (npm run dev)。");
  // 拋出錯誤以停止應用程式初始化
  throw new Error("Supabase URL 或 Anon Key 未在環境變數中設定。請檢查 .env 檔案和 Vite 設定。");
}

// 初始化 Supabase 客戶端
export const supabase = createClient(supabaseUrl, supabaseKey)

// (可選) 增加一個函數來檢查環境變數，方便除錯
// 可以在 main.js 或 App.vue 中呼叫此函數
export const checkSupabaseEnv = () => {
  console.log('VITE_SUPABASE_URL:', supabaseUrl ? '****** (已設定)' : '未設定');
  console.log('VITE_SUPABASE_ANON_KEY:', supabaseKey ? '****** (已設定)' : '未設定');
};

