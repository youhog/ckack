-- --- 宿舍檢查系統 - 終極完整 SQL 腳本 (v12 - 加入房間容量) ---

-- 此腳本包含：
-- 1. 完整資料表結構 (包含 RBAC 基礎表, rooms 表增加 capacity)
-- 2. 完整外鍵 (Foreign Key) 關聯
-- 3. 自動化函數 (Functions) 與觸發器 (Triggers)
-- 4. 儲存體 (Storage) 設定
-- 5. 完整 RLS (資料列層級安全性) 策略
-- 6. 範例資料 (包含所有 RBAC 基礎數據)
--
-- ----------------------------------------------------------------

-- --- 第 0 部分：預先刪除可能衝突的函數 (使用 CASCADE) ---
DROP FUNCTION IF EXISTS public.get_my_role() CASCADE;
DROP FUNCTION IF EXISTS public.update_user_role(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.setup_permissions() CASCADE;

-- --- 第 1 部分：建立資料表 (安全模式) ---
--
-- ----------------------------------------------------------------

-- RBAC 基礎結構 (為未來權限管理打下基礎)
CREATE TABLE IF NOT EXISTS public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL UNIQUE,
    description text NULL,
    CONSTRAINT roles_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.roles IS 'RBAC: 儲存系統中所有可能的角色，例如 admin, inspector';

CREATE TABLE IF NOT EXISTS public.permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    name text NOT NULL UNIQUE,
    description text NULL,
    CONSTRAINT permissions_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.permissions IS 'RBAC: 儲存系統中所有可用的操作權限';

CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    CONSTRAINT role_permissions_pkey PRIMARY KEY (role_id, permission_id)
);
COMMENT ON TABLE public.role_permissions IS 'RBAC: 角色與權限的關聯表';
-- 結束 RBAC 基礎結構


-- 1. 宿舍區域
CREATE TABLE IF NOT EXISTS public.dorm_zones (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    description text,
    CONSTRAINT dorm_zones_pkey PRIMARY KEY (id),
    CONSTRAINT dorm_zones_name_key UNIQUE (name)
);
COMMENT ON TABLE public.dorm_zones IS '宿舍區域 (例如: F 區, A 區)';

-- 2. 房間
好的，瞭解！在資料庫中加入「戶」和「樓層」是更結構化的做法。這需要在 rooms 資料表中新增欄位。

以下是修改後的 SQL/creat.sql 檔案中 CREATE TABLE public.rooms 的部分，加入了 household 和 floor 欄位：

SQL

-- SQL/creat.sql (部分修改)

-- ... 其他 CREATE TABLE ...

-- 2. 房間
CREATE TABLE IF NOT EXISTS public.rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    zone_id uuid NOT NULL,                 -- 區域 ID (外鍵)
    household text NULL,                   -- 戶 (例如 'A', 'B', '1', '2', 可選)
    floor text NOT NULL,                   -- 樓層 (例如 '1', '2', 'B1', 必填)
    room_number text NOT NULL,             -- 房間號 (例如 '01', '02', '101' - 不含樓層)
    capacity integer DEFAULT 4 NOT NULL,   -- 床位容量
    CONSTRAINT rooms_pkey PRIMARY KEY (id),
    -- 確保同一個區域、同一戶、同一樓層的房間號唯一
    -- 如果 household 可以是 NULL，這個唯一約束需要調整或拆分
    -- 為了簡化，我們先假設 zone_id + floor + room_number 是唯一的組合
    -- 如果 household 也是唯一性的一部分，請取消註解下一行並調整
    -- CONSTRAINT rooms_zone_household_floor_number_key UNIQUE (zone_id, household, floor, room_number),
    CONSTRAINT rooms_zone_floor_number_key UNIQUE (zone_id, floor, room_number), -- 簡化版唯一約束
    CONSTRAINT rooms_capacity_check CHECK ((capacity > 0))
);
COMMENT ON TABLE public.rooms IS '宿舍房間，包含區域、戶(可選)、樓層、房號和容量';
COMMENT ON COLUMN public.rooms.zone_id IS '所屬宿舍區域 ID';
COMMENT ON COLUMN public.rooms.household IS '所屬的戶/單元 (可選)';
COMMENT ON COLUMN public.rooms.floor IS '所在的樓層';
COMMENT ON COLUMN public.rooms.room_number IS '房間的編號 (不含樓層)';
COMMENT ON COLUMN public.rooms.capacity IS '房間的床位容量 (例如 2 或 4)';好的，瞭解！在資料庫中加入「戶」和「樓層」是更結構化的做法。這需要在 rooms 資料表中新增欄位。

以下是修改後的 SQL/creat.sql 檔案中 CREATE TABLE public.rooms 的部分，加入了 household 和 floor 欄位：

SQL

-- SQL/creat.sql (部分修改)

-- ... 其他 CREATE TABLE ...

-- 2. 房間
CREATE TABLE IF NOT EXISTS public.rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    zone_id uuid NOT NULL,                 -- 區域 ID (外鍵)
    household text NULL,                   -- 戶 (例如 'A', 'B', '1', '2', 可選)
    floor text NOT NULL,                   -- 樓層 (例如 '1', '2', 'B1', 必填)
    room_number text NOT NULL,             -- 房間號 (例如 '01', '02', '101' - 不含樓層)
    capacity integer DEFAULT 4 NOT NULL,   -- 床位容量
    CONSTRAINT rooms_pkey PRIMARY KEY (id),
    -- 確保同一個區域、同一戶、同一樓層的房間號唯一
    -- 如果 household 可以是 NULL，這個唯一約束需要調整或拆分
    -- 為了簡化，我們先假設 zone_id + floor + room_number 是唯一的組合
    -- 如果 household 也是唯一性的一部分，請取消註解下一行並調整
    -- CONSTRAINT rooms_zone_household_floor_number_key UNIQUE (zone_id, household, floor, room_number),
    CONSTRAINT rooms_zone_floor_number_key UNIQUE (zone_id, floor, room_number), -- 簡化版唯一約束
    CONSTRAINT rooms_capacity_check CHECK ((capacity > 0))
);
COMMENT ON TABLE public.rooms IS '宿舍房間，包含區域、戶(可選)、樓層、房號和容量';
COMMENT ON COLUMN public.rooms.zone_id IS '所屬宿舍區域 ID';
COMMENT ON COLUMN public.rooms.household IS '所屬的戶/單元 (可選)';
COMMENT ON COLUMN public.rooms.floor IS '所在的樓層';
COMMENT ON COLUMN public.rooms.room_number IS '房間的編號 (不含樓層)';
COMMENT ON COLUMN public.rooms.capacity IS '房間的床位容量 (例如 2 或 4)';


-- 3. 檢查類型
CREATE TABLE IF NOT EXISTS public.check_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    description text,
    CONSTRAINT check_types_pkey PRIMARY KEY (id),
    CONSTRAINT check_types_name_key UNIQUE (name)
);
COMMENT ON TABLE public.check_types IS '檢查的類型 (例如: 寒假檢查, 學期初檢查)';

-- 4. 檢查項目分類
CREATE TABLE IF NOT EXISTS public.checklist_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL,
    icon text DEFAULT '📋'::text,
    display_order integer DEFAULT 0,
    CONSTRAINT checklist_categories_pkey PRIMARY KEY (id),
    CONSTRAINT checklist_categories_name_key UNIQUE (name)
);
COMMENT ON TABLE public.checklist_categories IS '檢查項目的分類 (例如: 寢具區域, 衛浴區域)';

-- 5. 檢查項目
CREATE TABLE IF NOT EXISTS public.checklist_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    category_id uuid NOT NULL,
    name text NOT NULL,
    display_order integer DEFAULT 0,
    CONSTRAINT checklist_items_pkey PRIMARY KEY (id),
    CONSTRAINT checklist_items_category_id_name_key UNIQUE (category_id, name)
);
COMMENT ON TABLE public.checklist_items IS '隸屬於某個分類的具體檢查項目 (例如: 床架, 衣櫃)';

-- 6. 使用者公開資料 (profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    email text,
    CONSTRAINT profiles_pkey PRIMARY KEY (id),
    CONSTRAINT profiles_email_key UNIQUE (email)
);
COMMENT ON TABLE public.profiles IS '儲存使用者的公開資料，與 auth.users 連動';

-- 7. 使用者角色 (user_roles) - 僅儲存用戶與角色的 TEXT 關聯
CREATE TABLE IF NOT EXISTS public.user_roles (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL,
    role text NOT NULL,
    CONSTRAINT user_roles_pkey PRIMARY KEY (id),
    CONSTRAINT user_roles_user_id_key UNIQUE (user_id)
);
COMMENT ON TABLE public.user_roles IS '儲存使用者的角色 (admin 或 inspector)';

-- 8. 檢查報告
CREATE TABLE IF NOT EXISTS public.reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid,
    zone_id uuid,
    room_id uuid,
    check_type_id uuid,
    inspector_name text,
    additional_notes text,
    good_count integer DEFAULT 0,
    damaged_count integer DEFAULT 0,
    missing_count integer DEFAULT 0,
    check_data jsonb,
    notes_data jsonb,
    photo_data jsonb,
    report_content_html text,
    CONSTRAINT reports_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.reports IS '儲存所有提交的檢查報告';

-- 9. 鑰匙歸還記錄
CREATE TABLE IF NOT EXISTS public.key_returns (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid, -- 紀錄處理歸還的人
    zone_id uuid NOT NULL,
    room_id uuid NOT NULL,
    student_id text, -- 學生學號/ID
    bed_number text, -- 床位號碼 (例如: '1', 'A')
    return_notes text,
    is_returned boolean DEFAULT true NOT NULL,
    CONSTRAINT key_returns_pkey PRIMARY KEY (id)
);
COMMENT ON TABLE public.key_returns IS '儲存房間鑰匙歸還紀錄，並與特定床位/學生連結。';

-- 10. 學生床位分配 (NEW TABLE)
CREATE TABLE IF NOT EXISTS public.student_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    student_id text NOT NULL, -- 學號 (唯一識別碼)
    zone_id uuid NOT NULL,
    room_id uuid NOT NULL,
    bed_number text NOT NULL, -- 實際床位號 (1, 2, 3, 4)
    CONSTRAINT student_allocations_pkey PRIMARY KEY (id),
    CONSTRAINT student_allocations_student_id_key UNIQUE (student_id),
    CONSTRAINT student_allocations_room_bed_key UNIQUE (room_id, bed_number)
);
COMMENT ON TABLE public.student_allocations IS '學生床位分配表，用於學號查詢。';


-- --- 第 2 部分：建立外鍵 (Foreign Key) 關聯 (安全模式) ---
--
-- ----------------------------------------------------------------

-- RBAC 關聯
ALTER TABLE public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_role_id_fkey;
ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles (id) ON DELETE CASCADE;
ALTER TABLE public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_permission_id_fkey;
ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions (id) ON DELETE CASCADE;

-- 【核心修復點】: user_roles.role 連結到 roles.name
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_role_fkey;
ALTER TABLE public.user_roles
ADD CONSTRAINT user_roles_role_fkey
FOREIGN KEY (role)
REFERENCES public.roles (name)
ON DELETE RESTRICT;

-- 1. `profiles` -> `auth.users`
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE;

-- 2. `user_roles` -> `auth.users`
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;

-- 3. `rooms` -> `dorm_zones`
ALTER TABLE public.rooms DROP CONSTRAINT IF EXISTS rooms_zone_id_fkey;
ALTER TABLE public.rooms ADD CONSTRAINT rooms_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE CASCADE;

-- 4. `checklist_items` -> `checklist_categories`
ALTER TABLE public.checklist_items DROP CONSTRAINT IF EXISTS checklist_items_category_id_fkey;
ALTER TABLE public.checklist_items ADD CONSTRAINT checklist_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.checklist_categories (id) ON DELETE CASCADE;

-- 5. `reports` -> `profiles` (或直接連到 auth.users)
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_user_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE SET NULL; -- 改連到 auth.users

-- 6. `reports` -> `dorm_zones`
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_zone_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE SET NULL;

-- 7. `reports` -> `rooms`
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_room_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms (id) ON DELETE SET NULL;

-- 8. `reports` -> `check_types`
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_check_type_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_check_type_id_fkey FOREIGN KEY (check_type_id) REFERENCES public.check_types (id) ON DELETE SET NULL;

-- 9. `key_returns` -> `auth.users` (記錄操作者)
ALTER TABLE public.key_returns DROP CONSTRAINT IF EXISTS key_returns_user_id_fkey;
ALTER TABLE public.key_returns ADD CONSTRAINT key_returns_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE SET NULL; -- 改連到 auth.users

-- 10. `key_returns` -> `dorm_zones` (歸還的區域)
ALTER TABLE public.key_returns DROP CONSTRAINT IF EXISTS key_returns_zone_id_fkey;
ALTER TABLE public.key_returns ADD CONSTRAINT key_returns_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE CASCADE; -- 改為 CASCADE 或 RESTRICT，取決於業務邏輯

-- 11. `key_returns` -> `rooms` (歸還的房間)
ALTER TABLE public.key_returns DROP CONSTRAINT IF EXISTS key_returns_room_id_fkey;
ALTER TABLE public.key_returns ADD CONSTRAINT key_returns_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms (id) ON DELETE CASCADE; -- 改為 CASCADE 或 RESTRICT

-- 12. `student_allocations` -> `rooms`
ALTER TABLE public.student_allocations DROP CONSTRAINT IF EXISTS student_allocations_room_id_fkey;
ALTER TABLE public.student_allocations ADD CONSTRAINT student_allocations_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms (id) ON DELETE CASCADE;

-- 13. `student_allocations` -> `dorm_zones`
ALTER TABLE public.student_allocations DROP CONSTRAINT IF EXISTS student_allocations_zone_id_fkey;
ALTER TABLE public.student_allocations ADD CONSTRAINT student_allocations_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE CASCADE;


-- --- 第 3 部分：資料庫函數 (RPC) 與觸發器 (Triggers) ---
--
-- ----------------------------------------------------------------

-- 1. 函數：獲取目前使用者的角色
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS text
LANGUAGE sql
SECURITY DEFINER -- 重要：允許函數內部查詢 user_roles
STABLE -- 表示函數不會修改數據庫，且結果在單一事務中不變
SET search_path = public -- 確保查找 public schema 下的表
AS $$
    SELECT role
    FROM public.user_roles
    WHERE user_id = auth.uid(); -- auth.uid() 獲取當前 JWT 的使用者 ID
$$;
COMMENT ON FUNCTION public.get_my_role() IS '獲取當前已驗證使用者的角色名稱 (來自 user_roles 表)';


-- 2. 函數：處理新使用者註冊 (為 profiles 和 user_roles 設定紀錄)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER -- 重要：允許函數修改 public schema 下的表
SET search_path = public
AS $$
BEGIN
    -- 1. 在 profiles 建立紀錄 (如果不存在)
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email)
    ON CONFLICT (id) DO NOTHING; -- 如果 profiles 紀錄已存在 (例如手動創建)，則忽略

    -- 2. 在 user_roles 建立紀錄，預設為 'inspector' (如果不存在)
    -- 確保 'inspector' 角色存在於 roles 表中
    IF EXISTS (SELECT 1 FROM public.roles WHERE name = 'inspector') THEN
        INSERT INTO public.user_roles (user_id, role)
        VALUES (NEW.id, 'inspector')
        ON CONFLICT (user_id) DO NOTHING; -- 如果 user_roles 紀錄已存在，則忽略
    ELSE
        -- 如果 'inspector' 角色不存在，可以選擇拋出錯誤或設置為 NULL/其他預設值
        RAISE WARNING 'Default role "inspector" not found in roles table for new user %', NEW.id;
        -- 或者插入 NULL 或一個存在的預設角色
        -- INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, NULL) ON CONFLICT (user_id) DO NOTHING;
    END IF;


    RETURN NEW; -- 返回 NEW 以允許 INSERT 操作繼續
END;
$$;
COMMENT ON FUNCTION public.handle_new_user() IS '觸發器函數：當 auth.users 新增使用者時，自動在 profiles 和 user_roles 中創建對應記錄 (預設角色 inspector)';


-- 3. 觸發器：當 auth.users 有新使用者時，執行 handle_new_user
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
AFTER INSERT ON auth.users -- 在 auth.users 插入操作之後觸發
FOR EACH ROW -- 對每一行新插入的數據執行
EXECUTE FUNCTION public.handle_new_user();


-- 4. 函數：更新使用者角色 (供 admin 使用)
CREATE OR REPLACE FUNCTION public.update_user_role(target_user_id uuid, new_role text)
RETURNS void -- 不需要返回值
LANGUAGE plpgsql
SECURITY DEFINER -- 允許函數修改 user_roles 表
SET search_path = public
AS $$
DECLARE
    current_user_role text;
    target_user_current_role text;
BEGIN
    -- 獲取執行此函數的使用者的角色
    SELECT public.get_my_role() INTO current_user_role;

    -- 檢查執行者是否為 'admin' 或 'superadmin' (根據您的權限設計)
    IF current_user_role NOT IN ('admin', 'superadmin') THEN
        RAISE EXCEPTION '權限不足：只有 admin 或 superadmin 可以更改使用者角色 (執行者角色: %)', current_user_role;
    END IF;

    -- 檢查新角色是否存在於 roles 表中
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE name = new_role) THEN
        RAISE EXCEPTION '無效的角色：% ，該角色未在 roles 表中定義', new_role;
    END IF;

    -- 檢查是否試圖更改自己的角色
    IF target_user_id = auth.uid() THEN
        RAISE EXCEPTION '操作被拒絕：無法更改自己的角色';
    END IF;

    -- (可選) 檢查是否試圖更改 superadmin 的角色 (如果 superadmin 是最高權限)
    SELECT role INTO target_user_current_role FROM public.user_roles WHERE user_id = target_user_id;
    IF target_user_current_role = 'superadmin' THEN
         RAISE EXCEPTION '操作被拒絕：無法更改 superadmin 的角色';
    END IF;


    -- 更新或插入角色 (使用 UPSERT)
    INSERT INTO public.user_roles (user_id, role)
    VALUES (target_user_id, new_role)
    ON CONFLICT (user_id) -- 如果 user_id 已存在
    DO UPDATE SET role = new_role; -- 則更新 role 欄位

    RAISE LOG 'User % role updated to % by user % (role: %)', target_user_id, new_role, auth.uid(), current_user_role;

END;
$$;
COMMENT ON FUNCTION public.update_user_role(uuid, text) IS 'RPC 函數：供 admin/superadmin 更新指定使用者的角色 (不能改自己或 superadmin)';


-- 5. 函數：創建所有 RBAC 權限和基礎角色分配 (一次性運行或用於重置)
-- 注意：此函數會刪除現有分配，請謹慎執行
CREATE OR REPLACE FUNCTION public.setup_permissions()
RETURNS text -- 返回成功訊息
LANGUAGE plpgsql
AS $$
DECLARE
    role_admin_id uuid;
    role_inspector_id uuid;
    role_superadmin_id uuid;
    role_sdc_id uuid;
    role_sdsc_id uuid;
    inserted_roles integer := 0;
    inserted_permissions integer := 0;
    deleted_links integer := 0;
    inserted_links integer := 0;
BEGIN
    RAISE LOG '開始執行 setup_permissions()...';

    -- 創建所有基礎角色 (如果不存在)
    INSERT INTO public.roles (name, description) VALUES
    ('admin', '擁有所有管理權限'),
    ('inspector', '僅進行檢查與報告'),
    ('superadmin', '超級管理員 (擁有所有權限且不可修改)'),
    ('sdc', '宿委會 (中等管理權限)'),
    ('sdsc', '宿服 (僅供查看權限)')
    ON CONFLICT (name) DO NOTHING;
    GET DIAGNOSTICS inserted_roles = ROW_COUNT;
    RAISE LOG '插入了 % 個新角色', inserted_roles;

    -- 獲取角色的 UUID
    SELECT id INTO role_admin_id FROM public.roles WHERE name = 'admin';
    SELECT id INTO role_inspector_id FROM public.roles WHERE name = 'inspector';
    SELECT id INTO role_superadmin_id FROM public.roles WHERE name = 'superadmin';
    SELECT id INTO role_sdc_id FROM public.roles WHERE name = 'sdc';
    SELECT id INTO role_sdsc_id FROM public.roles WHERE name = 'sdsc';

    -- 檢查是否成功獲取所有角色 ID
    IF role_admin_id IS NULL OR role_inspector_id IS NULL OR role_superadmin_id IS NULL OR role_sdc_id IS NULL OR role_sdsc_id IS NULL THEN
        RAISE EXCEPTION '錯誤：一個或多個基礎角色未能成功創建或查詢，請檢查 roles 表。';
    END IF;
    RAISE LOG '所有基礎角色 ID 已獲取。';

    -- 創建所有權限 (如果不存在)
    INSERT INTO public.permissions (name, description) VALUES
    ('read_all_reports', '讀取所有檢查報告'),
    ('manage_zones', '管理宿舍區域'),
    ('manage_rooms', '管理宿舍房間'),
    ('manage_types', '管理檢查類型'),
    ('manage_checklist', '管理檢查項目'),
    ('manage_allocations', '匯入學生床位分配資料'),
    ('manage_users', '管理所有使用者帳號與角色'),
    ('manage_permissions', '管理所有角色權限分配')
    ON CONFLICT (name) DO NOTHING;
    GET DIAGNOSTICS inserted_permissions = ROW_COUNT;
    RAISE LOG '插入了 % 個新權限', inserted_permissions;

    -- **警告**: 刪除這些角色的所有現有權限指派
    RAISE LOG '正在刪除 admin, inspector, superadmin, sdc, sdsc 的現有權限...';
    DELETE FROM public.role_permissions
    WHERE role_id IN (role_admin_id, role_inspector_id, role_superadmin_id, role_sdc_id, role_sdsc_id);
    GET DIAGNOSTICS deleted_links = ROW_COUNT;
    RAISE LOG '刪除了 % 條權限關聯', deleted_links;

    -- 重新分配權限

    -- superadmin: 擁有所有權限
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_superadmin_id, id FROM public.permissions
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    GET DIAGNOSTICS inserted_links = ROW_COUNT;
    RAISE LOG '為 superadmin 分配了 % 個權限', inserted_links;

    -- admin: 擁有所有權限
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_admin_id, id FROM public.permissions
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    GET DIAGNOSTICS inserted_links = ROW_COUNT;
    RAISE LOG '為 admin 分配了 % 個權限', inserted_links;

    -- inspector: 只讀取報告
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_inspector_id, id FROM public.permissions WHERE name = 'read_all_reports'
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    GET DIAGNOSTICS inserted_links = ROW_COUNT;
    RAISE LOG '為 inspector 分配了 % 個權限', inserted_links;

    -- sdc: 中等管理權限
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_sdc_id, id FROM public.permissions WHERE name IN (
        'read_all_reports', 'manage_zones', 'manage_rooms', 'manage_checklist', 'manage_allocations'
    )
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    GET DIAGNOSTICS inserted_links = ROW_COUNT;
    RAISE LOG '為 sdc 分配了 % 個權限', inserted_links;

    -- sdsc: 最低查看權限
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_sdsc_id, id FROM public.permissions WHERE name = 'read_all_reports'
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    GET DIAGNOSTICS inserted_links = ROW_COUNT;
    RAISE LOG '為 sdsc 分配了 % 個權限', inserted_links;

    RAISE LOG 'setup_permissions() 執行完畢。';
    RETURN '基礎角色和權限設置完成。';
END;
$$;
COMMENT ON FUNCTION public.setup_permissions() IS '初始化/重置 RBAC 的基礎角色、權限以及它們之間的預設關聯 (會刪除現有分配!)';


-- --- 第 4 部分：儲存體 (Storage) ---
--
-- ----------------------------------------------------------------

-- 創建名為 'photos' 的儲存桶 (如果不存在)
-- public = true 表示允許公開訪問 URL，但仍需 RLS 控制上傳和讀取權限
INSERT INTO storage.buckets (id, name, public, allowed_mime_types, file_size_limit)
VALUES ('photos', 'photos', true, ARRAY['image/jpeg', 'image/png', 'image/gif', 'image/webp'], 5242880) -- 允許常見圖片類型，限制 5MB
ON CONFLICT (id) DO NOTHING; -- 如果已存在則忽略
COMMENT ON TABLE storage.buckets IS '用於儲存檢查報告相關照片';

-- 儲存策略 (Policies)

-- 策略 1: 允許已驗證使用者上傳圖片到 'photos' 桶
DROP POLICY IF EXISTS "Allow authenticated users to upload photos" ON storage.objects;
CREATE POLICY "Allow authenticated users to upload photos"
ON storage.objects FOR INSERT -- 允許插入 (上傳)
TO authenticated -- 對所有已驗證使用者生效
WITH CHECK (
    bucket_id = 'photos' -- 確保目標是 'photos' 桶
    AND auth.uid() IS NOT NULL -- 再次確認使用者已驗證 (雖然 TO authenticated 已隱含)
    -- 可以加上傳檔案大小限制 (Supabase RLS 目前不直接支持檔案大小，但 bucket level 已限制)
    -- AND storage.get_size_by_path(name) <= 5242880 -- 假設有此函數 (Supabase 目前沒有)
    -- 檔案類型在 bucket level 控制
);
COMMENT ON POLICY "Allow authenticated users to upload photos" ON storage.objects IS '允許任何登入的使用者上傳圖片到 photos 儲存桶';

-- 策略 2: 允許任何人讀取 'photos' 桶中的圖片 (因為 bucket public = true)
-- 但我們仍可以創建一個 SELECT 策略作為明確說明或未來可能的限制
DROP POLICY IF EXISTS "Allow public read access to photos" ON storage.objects;
CREATE POLICY "Allow public read access to photos"
ON storage.objects FOR SELECT -- 允許讀取
USING ( bucket_id = 'photos' ); -- 只要是 'photos' 桶中的檔案即可
COMMENT ON POLICY "Allow public read access to photos" ON storage.objects IS '允許任何人通過 URL 讀取 photos 儲存桶中的圖片 (需 bucket public=true 配合)';

-- (可選) 策略 3: 允許使用者刪除/更新自己上傳的圖片
-- 注意：需要知道檔案路徑與 user_id 的關聯，通常檔案路徑會包含 user_id
DROP POLICY IF EXISTS "Allow user to manage their own photos" ON storage.objects;
CREATE POLICY "Allow user to manage their own photos"
ON storage.objects FOR UPDATE, DELETE -- 允許更新和刪除
TO authenticated
USING (
    bucket_id = 'photos'
    AND auth.uid()::text = split_part(name, '/', 1) -- 假設路徑是 "user_id/filename"
)
WITH CHECK (
    bucket_id = 'photos'
    AND auth.uid()::text = split_part(name, '/', 1) -- 同上
);
COMMENT ON POLICY "Allow user to manage their own photos" ON storage.objects IS '允許使用者更新或刪除自己上傳的圖片 (假設路徑格式為 user_id/...)';


-- --- 第 5 部分：資料列層級安全性 (RLS) 策略 ---
--
-- ----------------------------------------------------------------

-- 啟用 RLS 並設置策略 (如果表已存在，需要先啟用)
ALTER TABLE public.dorm_zones ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.check_types ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.checklist_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.key_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.student_allocations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.permissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.role_permissions ENABLE ROW LEVEL SECURITY;

-- 清除舊策略 (使用 IF EXISTS 避免錯誤)
DROP POLICY IF EXISTS "Allow authenticated read" ON public.dorm_zones;
DROP POLICY IF EXISTS "Allow admin manage" ON public.dorm_zones;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.rooms;
DROP POLICY IF EXISTS "Allow admin manage" ON public.rooms;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.check_types;
DROP POLICY IF EXISTS "Allow admin manage" ON public.check_types;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.checklist_categories;
DROP POLICY IF EXISTS "Allow admin manage" ON public.checklist_categories;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.checklist_items;
DROP POLICY IF EXISTS "Allow admin manage" ON public.checklist_items;
DROP POLICY IF EXISTS "Allow user read own" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin read all" ON public.profiles;
DROP POLICY IF EXISTS "Allow admin read all" ON public.user_roles;
DROP POLICY IF EXISTS "Allow user insert own" ON public.reports;
DROP POLICY IF EXISTS "Allow owner or admin read" ON public.reports;
DROP POLICY IF EXISTS "Allow owner or admin delete" ON public.reports;
DROP POLICY IF EXISTS "Allow admin update" ON public.reports; -- (可選，如果允許 admin 修改報告)
DROP POLICY IF EXISTS "Allow user insert own" ON public.key_returns;
DROP POLICY IF EXISTS "Allow owner or admin read" ON public.key_returns;
DROP POLICY IF EXISTS "Allow admin delete" ON public.key_returns; -- (可選)
DROP POLICY IF EXISTS "Allow authenticated read" ON public.student_allocations;
DROP POLICY IF EXISTS "Allow admin manage" ON public.student_allocations;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.roles;
DROP POLICY IF EXISTS "Allow admin manage" ON public.roles;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.permissions;
DROP POLICY IF EXISTS "Allow admin manage" ON public.permissions;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.role_permissions;
DROP POLICY IF EXISTS "Allow admin manage" ON public.role_permissions;


-- 創建新策略

-- 5a. dorm_zones: 登入可讀，admin 可管理
CREATE POLICY "Allow authenticated read" ON public.dorm_zones FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.dorm_zones FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin')) -- 使用 USING 檢查讀取/刪除/更新權限
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin')); -- 使用 WITH CHECK 檢查插入/更新權限

-- 5b. rooms: 登入可讀，admin 可管理
CREATE POLICY "Allow authenticated read" ON public.rooms FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.rooms FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5c. check_types: 登入可讀，admin 可管理
CREATE POLICY "Allow authenticated read" ON public.check_types FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.check_types FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5d. checklist_categories: 登入可讀，admin 可管理
CREATE POLICY "Allow authenticated read" ON public.checklist_categories FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.checklist_categories FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5e. checklist_items: 登入可讀，admin 可管理
CREATE POLICY "Allow authenticated read" ON public.checklist_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.checklist_items FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5f. profiles: 使用者只能讀自己的，admin 可以讀所有 (通常不需要寫入/刪除 profiles 的 RLS，由觸發器處理)
CREATE POLICY "Allow user read own" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Allow admin read all" ON public.profiles FOR SELECT TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin'));
-- 注意：沒有 INSERT/UPDATE/DELETE 策略，因為這些通常由 auth.users 觸發器管理

-- 5g. user_roles: 只有 admin 可以讀取所有 (更新透過 RPC 函數控制)
CREATE POLICY "Allow admin read all" ON public.user_roles FOR SELECT TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin'));
-- 沒有 INSERT/UPDATE/DELETE 策略，因為插入由觸發器處理，更新由 RPC 處理

-- 5h. reports: 使用者可以新增自己的報告，自己和 admin 可以讀取/刪除
CREATE POLICY "Allow user insert own" ON public.reports FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Allow owner or admin read" ON public.reports FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow owner or admin delete" ON public.reports FOR DELETE TO authenticated USING (user_id = auth.uid() OR public.get_my_role() IN ('admin', 'superadmin'));
-- 可選：允許 admin 修改報告 (謹慎使用)
-- CREATE POLICY "Allow admin update" ON public.reports FOR UPDATE TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5i. key_returns: 使用者可以新增自己的歸還記錄，自己和 admin 可以讀取
CREATE POLICY "Allow user insert own" ON public.key_returns FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Allow owner or admin read" ON public.key_returns FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.get_my_role() IN ('admin', 'superadmin'));
-- 可選：允許 admin 刪除歸還記錄 (可能不需要)
-- CREATE POLICY "Allow admin delete" ON public.key_returns FOR DELETE TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin'));

-- 5j. student_allocations: 登入可讀，admin 可管理
CREATE POLICY "Allow authenticated read" ON public.student_allocations FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.student_allocations FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5k. roles (RBAC 表): 登入可讀，admin 可管理 (管理員才能增刪改角色)
CREATE POLICY "Allow authenticated read" ON public.roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.roles FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5l. permissions (RBAC 表): 登入可讀，admin 可管理 (管理員才能增刪改權限定義)
CREATE POLICY "Allow authenticated read" ON public.permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.permissions FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));

-- 5m. role_permissions (RBAC 表): 登入可讀，admin 可管理 (管理員才能修改角色和權限的關聯)
CREATE POLICY "Allow authenticated read" ON public.role_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.role_permissions FOR ALL TO authenticated
    USING (public.get_my_role() IN ('admin', 'superadmin'))
    WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));


-- --- 第 6 部分：範例資料 (Sample Data) ---
--
-- ----------------------------------------------------------------

-- 1. 插入基礎角色 (RBAC)
INSERT INTO public.roles (name, description) VALUES 
('admin', '擁有所有管理權限'), 
('inspector', '僅進行檢查與報告'),
('superadmin', '超級管理員 (保留給特殊用戶，擁有所有權限)'),
('sdc', '宿委會 (中等管理權限)'), 
('sdsc', '宿服 (僅供查看權限)')
ON CONFLICT (name) DO NOTHING;

-- 2. 插入所有權限 (RBAC)
INSERT INTO public.permissions (name, description) VALUES
('read_all_reports', '讀取所有檢查報告'),
('manage_zones', '管理宿舍區域'),
('manage_rooms', '管理宿舍房間'),
('manage_types', '管理檢查類型'),
('manage_checklist', '管理檢查項目'),
('manage_allocations', '匯入學生床位分配資料'),
('manage_users', '管理所有使用者帳號與角色'),
('manage_permissions', '管理所有角色權限分配')
ON CONFLICT (name) DO NOTHING;

-- 3. 分配權限 (RBAC)
DO $$
DECLARE
    role_admin_id uuid := (SELECT id FROM public.roles WHERE name = 'admin');
    role_inspector_id uuid := (SELECT id FROM public.roles WHERE name = 'inspector');
    role_superadmin_id uuid := (SELECT id FROM public.roles WHERE name = 'superadmin');
    role_sdc_id uuid := (SELECT id FROM public.roles WHERE name = 'sdc');
    role_sdsc_id uuid := (SELECT id FROM public.roles WHERE name = 'sdsc');
BEGIN
    -- 刪除所有舊的權限指派
    DELETE FROM public.role_permissions WHERE role_id IN (role_admin_id, role_inspector_id, role_superadmin_id, role_sdc_id, role_sdsc_id);

    -- 分配權限給 superadmin (所有權限)
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_superadmin_id, id FROM public.permissions
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- 分配權限給 admin (所有權限)
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_admin_id, id FROM public.permissions
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- 分配權限給 inspector (範例：只讀取報告)
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_inspector_id, id FROM public.permissions WHERE name IN ('read_all_reports')
    ON CONFLICT (role_id, permission_id) DO NOTHING;
    
    -- 分配權限給 SDC (中等管理權限 - 示範)
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_sdc_id, id FROM public.permissions WHERE name IN ('read_all_reports', 'manage_zones', 'manage_rooms', 'manage_checklist', 'manage_allocations')
    ON CONFLICT (role_id, permission_id) DO NOTHING;

    -- 分配權限給 SDSC (最低查看權限 - 示範)
    INSERT INTO public.role_permissions (role_id, permission_id)
    SELECT role_sdsc_id, id FROM public.permissions WHERE name IN ('read_all_reports')
    ON CONFLICT (role_id, permission_id) DO NOTHING;

END $$;
-- 結束 RBAC 數據填充

-- 4. 插入基礎數據
INSERT INTO public.check_types (name, description)
VALUES
    ('學期初檢查', '檢查學生入住前的房間狀況'),
    ('期中安全檢查', '例行性的安全與衛生抽查'),
    ('寒假離宿檢查', '確認學生寒假離宿時的清空狀況')
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.dorm_zones (name, description)
VALUES
    ('A 區 (男生宿舍)', 'A 區位於東側，靠近籃球場'),
    ('B 區 (女生宿舍)', 'B 區位於西側，靠近餐廳')
ON CONFLICT (name) DO NOTHING;

-- 插入房間時包含容量
INSERT INTO public.rooms (zone_id, room_number, capacity)
SELECT z.id, room_list.room_number, room_list.cap
FROM public.dorm_zones z,
     (VALUES ('101', 4), ('102', 4), ('201', 2), ('202', 4)) AS room_list(room_number, cap)
WHERE z.name LIKE 'A 區%' -- 只為 A 區插入範例房間
ON CONFLICT (zone_id, room_number) DO NOTHING;

INSERT INTO public.rooms (zone_id, room_number, capacity)
SELECT z.id, room_list.room_number, room_list.cap
FROM public.dorm_zones z,
     (VALUES ('101', 4), ('102', 2), ('201', 4), ('202', 4)) AS room_list(room_number, cap)
WHERE z.name LIKE 'B 區%' -- 只為 B 區插入範例房間
ON CONFLICT (zone_id, room_number) DO NOTHING;


-- 範例床位分配 (用於測試 KeyReturn.vue 的查找功能)
INSERT INTO public.student_allocations (student_id, zone_id, room_id, bed_number)
SELECT
    'A111001',
    dz.id,
    r.id,
    '1'
FROM
    public.dorm_zones dz
JOIN
    public.rooms r ON dz.id = r.zone_id
WHERE
    dz.name = 'A 區 (男生宿舍)' AND r.room_number = '101'
ON CONFLICT (student_id) DO NOTHING;

INSERT INTO public.student_allocations (student_id, zone_id, room_id, bed_number)
SELECT
    'B222002',
    dz.id,
    r.id,
    '2'
FROM
    public.dorm_zones dz
JOIN
    public.rooms r ON dz.id = r.zone_id
WHERE
    dz.name = 'B 區 (女生宿舍)' AND r.room_number = '102' -- 假設 B102 是 2人房
ON CONFLICT (student_id) DO NOTHING;


-- 插入檢查分類和項目
INSERT INTO public.checklist_categories (name, icon, display_order)
VALUES
    ('寢室區域', '🛏️', 1),
    ('衛浴區域', '🛁', 2),
    ('公共區域/陽台', '🪴', 3)
ON CONFLICT (name) DO NOTHING;

INSERT INTO public.checklist_items (category_id, name, display_order)
SELECT c.id, item_list.item_name, item_list.ord
FROM public.checklist_categories c,
     (VALUES
        ('寢室區域', '床架 (含床板)', 1),
        ('寢室區域', '書桌', 2),
        ('寢室區域', '椅子', 3),
        ('寢室區域', '衣櫃', 4),
        ('寢室區域', '冷氣 (含遙控器)', 5),
        ('衛浴區域', '馬桶 (含水箱)', 1),
        ('衛浴區域', '洗手台 (含水龍頭)', 2),
        ('衛浴區域', '淋浴設備 (含蓮蓬頭)', 3),
        ('衛浴區域', '置物架', 4),
        ('公共區域/陽台', '地板清潔', 1),
        ('公共區域/陽台', '陽台窗戶', 2)
     ) AS item_list(cat_name, item_name, ord)
WHERE c.name = item_list.cat_name
ON CONFLICT (category_id, name) DO NOTHING;




-- ----------------------------------------------------------------
-- --- 腳本執行完畢 ---
-- ----------------------------------------------------------------
-- 記得在 Supabase SQL 編輯器中執行 SELECT public.setup_permissions(); 來初始化 RBAC 權限分配
-- ----------------------------------------------------------------