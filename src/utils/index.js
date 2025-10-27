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
 * 顯示 Toast 提示訊息 (使用 Tailwind classes)
 * @param {string} message - 要顯示的訊息
 * @param {'success'|'error'|'info'|'warning'} type - 訊息類型 (增加 info, warning)
 */
export function showToast(message, type = 'success') {
    let icon = '✅';
    let gradientClass = 'from-green-500 to-emerald-500'; // Success default
    let iconBgClass = 'bg-white/20';

    switch (type) {
        case 'error':
            icon = '⚠️';
            gradientClass = 'from-red-500 to-rose-500';
            break;
        case 'warning':
            icon = '🔔';
            gradientClass = 'from-yellow-500 to-amber-500';
            break;
        case 'info':
            icon = 'ℹ️';
            gradientClass = 'from-blue-500 to-indigo-500';
            break;
        // 'success' uses defaults
    }

    // 移除可能存在的舊 toast
    const existingToast = document.querySelector('.toast-notification');
    if (existingToast) {
        existingToast.remove();
    }

    const toast = document.createElement('div');
    // 【美化】: 使用 Tailwind classes 定義 Toast 樣式
    toast.className = `toast-notification fixed top-6 right-6 z-[100] flex items-center gap-3 rounded-2xl px-5 py-3 text-white font-medium shadow-lg bg-gradient-to-r ${gradientClass}`; 
    
    // 【美化】: Icon 樣式
    const iconDiv = document.createElement('div');
    iconDiv.className = `w-7 h-7 ${iconBgClass} rounded-lg flex items-center justify-center text-lg`;
    iconDiv.textContent = icon;
    
    // 【美化】: 訊息文字樣式
    const span = document.createElement('span');
    span.className = 'text-sm';
    span.textContent = message;

    toast.appendChild(iconDiv);
    toast.appendChild(span);
    document.body.appendChild(toast);

    // 添加進入動畫 (使用 Tailwind classes)
    toast.classList.add('opacity-0', 'translate-y-[-20px]', 'transform', 'transition-all', 'duration-300', 'ease-out');
    requestAnimationFrame(() => {
        toast.classList.remove('opacity-0', 'translate-y-[-20px]');
        toast.classList.add('opacity-100', 'translate-y-0');
    });

    // 3 秒後自動移除
    setTimeout(() => {
        toast.classList.remove('opacity-100', 'translate-y-0');
        toast.classList.add('opacity-0', 'translate-y-[-20px]');
        setTimeout(() => toast.remove(), 300); // 等待動畫完成後移除
    }, 3000);
}