// src/utils/index.js

/**
 * 安全工具函數
 * 用於轉義 HTML，防止 XSS 攻擊
 * @param {string} str - 需要轉義的原始字串
 * @returns {string} - 轉義後的安全字串
 */
export function escapeHTML(str) {
    if (str === null || str === undefined) {
        return '';
    }
    // 將 &, <, >, ", ' 替換為對應的 HTML 實體
    return str.toString().replace(/[&<>"']/g, m => ({
        '&': '&amp;',
        '<': '&lt;',
        '>': '&gt;',
        '"': '&quot;',
        "'": '&#39;'
    })[m]);
}

/**
 * 顯示 Toast 提示訊息 (簡易版，可替換為 UI 庫元件)
 * @param {string} message - 要顯示的訊息
 * @param {'success'|'error'} type - 訊息類型
 */
export function showToast(message, type = 'success') {
    const icon = type === 'success' ? '✅' : '⚠️';
    const gradient = type === 'success'
        ? 'from-green-500 to-emerald-500'
        : 'from-red-500 to-red-600';

    // 移除可能存在的舊 toast
    const existingToast = document.querySelector('.toast');
    if (existingToast) {
        existingToast.remove();
    }

    const toast = document.createElement('div');
    toast.className = `toast fixed top-6 right-6 bg-gradient-to-r ${gradient} text-white px-6 py-4 rounded-2xl shadow-2xl z-[100] flex items-center gap-3 font-medium`; // 提高 z-index
    // 使用 textContent 防止 XSS
    const iconDiv = document.createElement('div');
    iconDiv.className = 'w-8 h-8 bg-white/20 rounded-lg flex items-center justify-center';
    iconDiv.textContent = icon;
    const span = document.createElement('span');
    span.textContent = message;

    toast.appendChild(iconDiv);
    toast.appendChild(span);
    document.body.appendChild(toast);

    // 添加進入動畫 (可選)
    toast.style.opacity = '0';
    toast.style.transform = 'translateY(-20px)';
    requestAnimationFrame(() => {
        toast.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
        toast.style.opacity = '1';
        toast.style.transform = 'translateY(0)';
    });

    // 3 秒後自動移除
    setTimeout(() => {
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(-20px)';
        setTimeout(() => toast.remove(), 300); // 等待動畫完成後移除
    }, 3000);
}

