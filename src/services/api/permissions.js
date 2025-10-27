// src/services/api/permissions.js

import { supabase } from '@/services/supabase';

/**
 * 獲取特定角色的權限 ID 列表
 * @param {string} roleName - 角色的名稱 (e.g., 'inspector', 'admin')
 * @returns {Promise<Array<object>>} - 包含 { permission_id: UUID } 物件的陣列
 */
export async function fetchPermissionsForRole(roleName) {
    // 1. 查找角色的 UUID
    const { data: roleData, error: roleError } = await supabase
        .from('roles')
        .select('id')
        .eq('name', roleName)
        .single(); 

    // 如果找不到角色，返回空陣列
    if (roleError || !roleData) {
         return [];
    }
    const roleId = roleData.id;

    // 2. 獲取該角色的權限
    const { data: permsData, error: permsError } = await supabase
        .from('role_permissions')
        .select('permission_id')
        .eq('role_id', roleId);
        
    if (permsError) {
        console.error("Failed to fetch role permissions:", permsError);
        throw permsError;
    }
    // MODIFIED: 返回原始數據，讓調用者處理
    return permsData; 
}

/**
 * 更新角色的權限列表 (使用 Upsert/Delete 策略)
 * @param {string} roleId - 角色的 UUID
 * @param {Array<string>} permissionIds - 該角色應該擁有的所有權限 ID 陣列
 */
export async function updatePermissionsForRole(roleId, permissionIds) {
    // 1. 刪除該角色的所有現有權限
    const { error: deleteError } = await supabase
        .from('role_permissions')
        .delete()
        .eq('role_id', roleId);
    if (deleteError) throw deleteError;

    // 2. 插入新的權限列表
    if (permissionIds.length > 0) {
        const newLinks = permissionIds.map(pid => ({ role_id: roleId, permission_id: pid }));
        const { error: insertError } = await supabase
            .from('role_permissions')
            .insert(newLinks);
        if (insertError) throw insertError;
    }
    
    // 返回成功
    return true;
}