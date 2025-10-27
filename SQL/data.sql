-- --- 宿舍檢查系統 - 範例資料 SQL 腳本 ---
--
-- 此腳本使用 CTEs (Common Table Expressions) 來新增資料，
-- 並自動抓取新生成的 UUID，以便在關聯表格 (如 rooms 和 checklist_items) 中使用。
--
-- ----------------------------------------------------------------

-- 清空舊的範例資料 (可選，如果您想重新執行)
-- DELETE FROM public.reports;
-- DELETE FROM public.checklist_items;
-- DELETE FROM public.checklist_categories;
-- DELETE FROM public.rooms;
-- DELETE FROM public.dorm_zones;
-- DELETE FROM public.check_types;

-- ----------------------------------------------------------------
-- 步驟 1：新增檢查類型 (ManageTypes.vue)
-- ----------------------------------------------------------------
WITH types_data AS (
    INSERT INTO public.check_types (name, description)
    VALUES
        ('學期初檢查', '檢查學生入住前的房間狀況'),
        ('期中安全檢查', '例行性的安全與衛生抽查'),
        ('寒假離宿檢查', '確認學生寒假離宿時的清空狀況')
    RETURNING id
)
SELECT count(*) || ' 筆檢查類型已新增' FROM types_data;


-- ----------------------------------------------------------------
-- 步驟 2：新增宿舍區域 (ManageZones.vue)
-- ----------------------------------------------------------------
WITH zones_data AS (
    INSERT INTO public.dorm_zones (name, description)
    VALUES
        ('A 區 (男生宿舍)', 'A 區位於東側，靠近籃球場'),
        ('B 區 (女生宿舍)', 'B 區位於西側，靠近餐廳')
    RETURNING id, name
),

-- ----------------------------------------------------------------
-- 步驟 3：為每個區域新增房間 (ManageRooms.vue)
-- ----------------------------------------------------------------
rooms_data AS (
    INSERT INTO public.rooms (zone_id, room_number)
    SELECT 
        zones_data.id, 
        room_list.room_number
    FROM zones_data
    -- 使用 CROSS JOIN 為每個區域建立房間
    CROSS JOIN (
        VALUES 
            ('101'), ('102'), ('201'), ('202')
    ) AS room_list(room_number)
    RETURNING id
)
SELECT 
    (SELECT count(*) FROM zones_data) || ' 筆區域已新增',
    (SELECT count(*) FROM rooms_data) || ' 筆房間已新增';


-- ----------------------------------------------------------------
-- 步驟 4：新增檢查項目分類 (ManageChecklist.vue)
-- ----------------------------------------------------------------
WITH categories_data AS (
    INSERT INTO public.checklist_categories (name, icon, display_order)
    VALUES
        ('寢室區域', '🛏️', 1),
        ('衛浴區域', '🛁', 2),
        ('公共區域/陽台', '🪴', 3)
    RETURNING id, name
),

-- ----------------------------------------------------------------
-- 步驟 5：為每個分類新增檢查項目 (ManageChecklist.vue)
-- ----------------------------------------------------------------
items_data AS (
    INSERT INTO public.checklist_items (category_id, name, display_order)
    VALUES
        -- 寢室區域
        ((SELECT id FROM categories_data WHERE name = '寢室區域'), '床架 (含床板)', 1),
        ((SELECT id FROM categories_data WHERE name = '寢室區域'), '書桌', 2),
        ((SELECT id FROM categories_data WHERE name = '寢室區域'), '椅子', 3),
        ((SELECT id FROM categories_data WHERE name = '寢室區域'), '衣櫃', 4),
        ((SELECT id FROM categories_data WHERE name = '寢室區域'), '冷氣 (含遙控器)', 5),
        
        -- 衛浴區域
        ((SELECT id FROM categories_data WHERE name = '衛浴區域'), '馬桶 (含水箱)', 1),
        ((SELECT id FROM categories_data WHERE name = '衛浴區域'), '洗手台 (含水龍頭)', 2),
        ((SELECT id FROM categories_data WHERE name = '衛浴區域'), '淋浴設備 (含蓮蓬頭)', 3),
        ((SELECT id FROM categories_data WHERE name = '衛浴區域'), '置物架', 4),

        -- 公共區域/陽台
        ((SELECT id FROM categories_data WHERE name = '公共區域/陽台'), '地板清潔', 1),
        ((SELECT id FROM categories_data WHERE name = '公共區域/陽台'), '陽台窗戶', 2)
    RETURNING id
)
SELECT 
    (SELECT count(*) FROM categories_data) || ' 筆分類已新增',
    (SELECT count(*) FROM items_data) || ' 筆項目已新增';