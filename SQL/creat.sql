-- --- 宿舍檢查系統 - 完整刪除與重建 SQL 腳本 (v12.5 - 加入既有帳號匯入) ---

-- ****** 警告：以下指令將徹底刪除所有相關表格和資料！ ******
-- ****** 請在執行前務必備份您的資料庫！ ******
--
-- ----------------------------------------------------------------

-- --- 第 -1 部分：完整刪除舊有結構 ---
DROP FUNCTION IF EXISTS public.get_my_role() CASCADE;
DROP FUNCTION IF EXISTS public.update_user_role(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.setup_permissions() CASCADE;
DROP FUNCTION IF EXISTS public.import_existing_users() CASCADE; -- 刪除新函數 (如果存在)

DROP TABLE IF EXISTS public.role_permissions CASCADE;
DROP TABLE IF EXISTS public.student_allocations CASCADE;
DROP TABLE IF EXISTS public.key_returns CASCADE;
DROP TABLE IF EXISTS public.reports CASCADE;
DROP TABLE IF EXISTS public.user_roles CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.checklist_items CASCADE;
DROP TABLE IF EXISTS public.checklist_categories CASCADE;
DROP TABLE IF EXISTS public.check_types CASCADE;
DROP TABLE IF EXISTS public.rooms CASCADE;
DROP TABLE IF EXISTS public.dorm_zones CASCADE;
DROP TABLE IF EXISTS public.permissions CASCADE;
DROP TABLE IF EXISTS public.roles CASCADE;

RAISE LOG '舊有表格和函數已刪除 (如果存在)';

-- --- 第 0 部分：預先刪除可能衝突的函數 (再次確保) ---
DROP FUNCTION IF EXISTS public.get_my_role() CASCADE;
DROP FUNCTION IF EXISTS public.update_user_role(uuid, text) CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.setup_permissions() CASCADE;
DROP FUNCTION IF EXISTS public.import_existing_users() CASCADE;

-- --- 第 1 部分：建立資料表 (安全模式) ---
--
-- ----------------------------------------------------------------

-- RBAC 基礎結構
CREATE TABLE IF NOT EXISTS public.roles (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text NULL
);
COMMENT ON TABLE public.roles IS 'RBAC: 儲存系統中所有可能的角色';

CREATE TABLE IF NOT EXISTS public.permissions (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    name text NOT NULL UNIQUE,
    description text NULL
);
COMMENT ON TABLE public.permissions IS 'RBAC: 儲存系統中所有可用的操作權限';

CREATE TABLE IF NOT EXISTS public.role_permissions (
    role_id uuid NOT NULL,
    permission_id uuid NOT NULL,
    PRIMARY KEY (role_id, permission_id)
);
COMMENT ON TABLE public.role_permissions IS 'RBAC: 角色與權限的關聯表';

-- 1. 宿舍區域
CREATE TABLE IF NOT EXISTS public.dorm_zones (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL UNIQUE,
    description text
);
COMMENT ON TABLE public.dorm_zones IS '宿舍區域';

-- 2. 房間
CREATE TABLE IF NOT EXISTS public.rooms (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    zone_id uuid NOT NULL,
    household text NULL,
    floor text NOT NULL,
    room_number text NOT NULL,
    capacity integer DEFAULT 4 NOT NULL,
    CONSTRAINT rooms_zone_floor_number_key UNIQUE (zone_id, floor, room_number),
    CONSTRAINT rooms_capacity_check CHECK ((capacity > 0))
);
COMMENT ON TABLE public.rooms IS '宿舍房間';
COMMENT ON COLUMN public.rooms.zone_id IS '所屬宿舍區域 ID';
COMMENT ON COLUMN public.rooms.household IS '所屬的戶/單元 (可選)';
COMMENT ON COLUMN public.rooms.floor IS '所在的樓層';
COMMENT ON COLUMN public.rooms.room_number IS '房間的編號 (不含樓層)';
COMMENT ON COLUMN public.rooms.capacity IS '房間的床位容量';

-- 3. 檢查類型
CREATE TABLE IF NOT EXISTS public.check_types (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL UNIQUE,
    description text
);
COMMENT ON TABLE public.check_types IS '檢查的類型';

-- 4. 檢查項目分類
CREATE TABLE IF NOT EXISTS public.checklist_categories (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    name text NOT NULL UNIQUE,
    icon text DEFAULT '📋'::text,
    display_order integer DEFAULT 0
);
COMMENT ON TABLE public.checklist_categories IS '檢查項目的分類';

-- 5. 檢查項目
CREATE TABLE IF NOT EXISTS public.checklist_items (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    category_id uuid NOT NULL,
    name text NOT NULL,
    display_order integer DEFAULT 0,
    CONSTRAINT checklist_items_category_id_name_key UNIQUE (category_id, name)
);
COMMENT ON TABLE public.checklist_items IS '隸屬於某個分類的具體檢查項目';

-- 6. 使用者公開資料 (profiles)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    email text UNIQUE
);
COMMENT ON TABLE public.profiles IS '儲存使用者的公開資料，與 auth.users 連動';

-- 7. 使用者角色 (user_roles)
CREATE TABLE IF NOT EXISTS public.user_roles (
    id bigint GENERATED BY DEFAULT AS IDENTITY NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid NOT NULL UNIQUE,
    role text NOT NULL
);
COMMENT ON TABLE public.user_roles IS '儲存使用者的角色';

-- 8. 檢查報告
CREATE TABLE IF NOT EXISTS public.reports (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
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
    report_content_html text
);
COMMENT ON TABLE public.reports IS '儲存所有提交的檢查報告';

-- 9. 鑰匙歸還記錄
CREATE TABLE IF NOT EXISTS public.key_returns (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    user_id uuid,
    zone_id uuid NOT NULL,
    room_id uuid NOT NULL,
    student_id text,
    bed_number text,
    return_notes text,
    is_returned boolean DEFAULT true NOT NULL
);
COMMENT ON TABLE public.key_returns IS '儲存房間鑰匙歸還紀錄';

-- 10. 學生床位分配
CREATE TABLE IF NOT EXISTS public.student_allocations (
    id uuid DEFAULT gen_random_uuid() NOT NULL PRIMARY KEY,
    created_at timestamp with time zone DEFAULT now() NOT NULL,
    student_id text NOT NULL UNIQUE,
    zone_id uuid NOT NULL,
    room_id uuid NOT NULL,
    bed_number text NOT NULL,
    CONSTRAINT student_allocations_room_bed_key UNIQUE (room_id, bed_number)
);
COMMENT ON TABLE public.student_allocations IS '學生床位分配表';


-- --- 第 2 部分：建立外鍵關聯 ---
--
-- ----------------------------------------------------------------

ALTER TABLE public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_role_id_fkey;
ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_role_id_fkey FOREIGN KEY (role_id) REFERENCES public.roles (id) ON DELETE CASCADE;
ALTER TABLE public.role_permissions DROP CONSTRAINT IF EXISTS role_permissions_permission_id_fkey;
ALTER TABLE public.role_permissions ADD CONSTRAINT role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES public.permissions (id) ON DELETE CASCADE;
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_role_fkey;
ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_role_fkey FOREIGN KEY (role) REFERENCES public.roles (name) ON DELETE RESTRICT;
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_id_fkey;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users (id) ON DELETE CASCADE;
ALTER TABLE public.user_roles DROP CONSTRAINT IF EXISTS user_roles_user_id_fkey;
ALTER TABLE public.user_roles ADD CONSTRAINT user_roles_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE CASCADE;
ALTER TABLE public.rooms DROP CONSTRAINT IF EXISTS rooms_zone_id_fkey;
ALTER TABLE public.rooms ADD CONSTRAINT rooms_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE CASCADE;
ALTER TABLE public.checklist_items DROP CONSTRAINT IF EXISTS checklist_items_category_id_fkey;
ALTER TABLE public.checklist_items ADD CONSTRAINT checklist_items_category_id_fkey FOREIGN KEY (category_id) REFERENCES public.checklist_categories (id) ON DELETE CASCADE;
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_user_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE SET NULL;
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_zone_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE SET NULL;
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_room_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms (id) ON DELETE SET NULL;
ALTER TABLE public.reports DROP CONSTRAINT IF EXISTS reports_check_type_id_fkey;
ALTER TABLE public.reports ADD CONSTRAINT reports_check_type_id_fkey FOREIGN KEY (check_type_id) REFERENCES public.check_types (id) ON DELETE SET NULL;
ALTER TABLE public.key_returns DROP CONSTRAINT IF EXISTS key_returns_user_id_fkey;
ALTER TABLE public.key_returns ADD CONSTRAINT key_returns_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users (id) ON DELETE SET NULL;
ALTER TABLE public.key_returns DROP CONSTRAINT IF EXISTS key_returns_zone_id_fkey;
ALTER TABLE public.key_returns ADD CONSTRAINT key_returns_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE CASCADE;
ALTER TABLE public.key_returns DROP CONSTRAINT IF EXISTS key_returns_room_id_fkey;
ALTER TABLE public.key_returns ADD CONSTRAINT key_returns_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms (id) ON DELETE CASCADE;
ALTER TABLE public.student_allocations DROP CONSTRAINT IF EXISTS student_allocations_room_id_fkey;
ALTER TABLE public.student_allocations ADD CONSTRAINT student_allocations_room_id_fkey FOREIGN KEY (room_id) REFERENCES public.rooms (id) ON DELETE CASCADE;
ALTER TABLE public.student_allocations DROP CONSTRAINT IF EXISTS student_allocations_zone_id_fkey;
ALTER TABLE public.student_allocations ADD CONSTRAINT student_allocations_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES public.dorm_zones (id) ON DELETE CASCADE;


-- --- 第 3 部分：資料庫函數與觸發器 ---
--
-- ----------------------------------------------------------------

CREATE OR REPLACE FUNCTION public.get_my_role() RETURNS text LANGUAGE sql SECURITY DEFINER STABLE SET search_path = public AS $$ SELECT role FROM public.user_roles WHERE user_id = auth.uid(); $$;
COMMENT ON FUNCTION public.get_my_role() IS '獲取當前已驗證使用者的角色名稱';

CREATE OR REPLACE FUNCTION public.handle_new_user() RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ BEGIN INSERT INTO public.profiles (id, email, created_at) VALUES (NEW.id, NEW.email, NEW.created_at) ON CONFLICT (id) DO NOTHING; IF EXISTS (SELECT 1 FROM public.roles WHERE name = 'inspector') THEN INSERT INTO public.user_roles (user_id, role) VALUES (NEW.id, 'inspector') ON CONFLICT (user_id) DO NOTHING; ELSE RAISE WARNING 'Default role "inspector" not found for new user %', NEW.id; END IF; RETURN NEW; END; $$;
COMMENT ON FUNCTION public.handle_new_user() IS '自動在 profiles 和 user_roles 中創建新用戶記錄';

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.update_user_role(target_user_id uuid, new_role text) RETURNS void LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$ DECLARE current_user_role text; target_user_current_role text; BEGIN SELECT public.get_my_role() INTO current_user_role; IF current_user_role NOT IN ('admin', 'superadmin') THEN RAISE EXCEPTION '權限不足'; END IF; IF NOT EXISTS (SELECT 1 FROM public.roles WHERE name = new_role) THEN RAISE EXCEPTION '無效的角色: %', new_role; END IF; IF target_user_id = auth.uid() THEN RAISE EXCEPTION '無法更改自己的角色'; END IF; SELECT role INTO target_user_current_role FROM public.user_roles WHERE user_id = target_user_id; IF target_user_current_role = 'superadmin' THEN RAISE EXCEPTION '無法更改 superadmin 的角色'; END IF; INSERT INTO public.user_roles (user_id, role) VALUES (target_user_id, new_role) ON CONFLICT (user_id) DO UPDATE SET role = new_role; RAISE LOG 'User % role updated to % by user %', target_user_id, new_role, auth.uid(); END; $$;
COMMENT ON FUNCTION public.update_user_role(uuid, text) IS 'RPC: 供 admin/superadmin 更新使用者角色';

CREATE OR REPLACE FUNCTION public.setup_permissions() RETURNS text LANGUAGE plpgsql AS $$ DECLARE role_admin_id uuid; role_inspector_id uuid; role_superadmin_id uuid; role_sdc_id uuid; role_sdsc_id uuid; BEGIN RAISE LOG '執行 setup_permissions()...'; INSERT INTO public.roles (name, description) VALUES ('admin', '管理員'), ('inspector', '檢查員'), ('superadmin', '超級管理員'), ('sdc', '宿委會'), ('sdsc', '宿服') ON CONFLICT (name) DO NOTHING; SELECT id INTO role_admin_id FROM public.roles WHERE name = 'admin'; SELECT id INTO role_inspector_id FROM public.roles WHERE name = 'inspector'; SELECT id INTO role_superadmin_id FROM public.roles WHERE name = 'superadmin'; SELECT id INTO role_sdc_id FROM public.roles WHERE name = 'sdc'; SELECT id INTO role_sdsc_id FROM public.roles WHERE name = 'sdsc'; IF role_admin_id IS NULL OR role_inspector_id IS NULL OR role_superadmin_id IS NULL OR role_sdc_id IS NULL OR role_sdsc_id IS NULL THEN RAISE EXCEPTION '基礎角色查詢失敗'; END IF; INSERT INTO public.permissions (name, description) VALUES ('read_all_reports', '讀取報告'), ('manage_zones', '管理區域'), ('manage_rooms', '管理房間'), ('manage_types', '管理類型'), ('manage_checklist', '管理檢查項目'), ('manage_allocations', '管理床位分配'), ('manage_users', '管理使用者'), ('manage_permissions', '管理權限') ON CONFLICT (name) DO NOTHING; DELETE FROM public.role_permissions WHERE role_id IN (role_admin_id, role_inspector_id, role_superadmin_id, role_sdc_id, role_sdsc_id); INSERT INTO public.role_permissions (role_id, permission_id) SELECT role_superadmin_id, id FROM public.permissions ON CONFLICT DO NOTHING; INSERT INTO public.role_permissions (role_id, permission_id) SELECT role_admin_id, id FROM public.permissions ON CONFLICT DO NOTHING; INSERT INTO public.role_permissions (role_id, permission_id) SELECT role_inspector_id, id FROM public.permissions WHERE name = 'read_all_reports' ON CONFLICT DO NOTHING; INSERT INTO public.role_permissions (role_id, permission_id) SELECT role_sdc_id, id FROM public.permissions WHERE name IN ('read_all_reports', 'manage_zones', 'manage_rooms', 'manage_checklist', 'manage_allocations') ON CONFLICT DO NOTHING; INSERT INTO public.role_permissions (role_id, permission_id) SELECT role_sdsc_id, id FROM public.permissions WHERE name = 'read_all_reports' ON CONFLICT DO NOTHING; RAISE LOG 'setup_permissions() 完成'; RETURN '基礎角色和權限設置完成'; END; $$;
COMMENT ON FUNCTION public.setup_permissions() IS '初始化/重置 RBAC 基礎角色與權限關聯';

-- ****** 新增：自動匯入既有帳號的函數 ******
CREATE OR REPLACE FUNCTION public.import_existing_users()
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER -- 需要權限讀取 auth.users 和寫入 public schema
SET search_path = public
AS $$
DECLARE
    user_record record;
    inserted_profiles integer := 0;
    inserted_roles integer := 0;
BEGIN
    RAISE LOG '開始執行 import_existing_users()...';

    -- 檢查 'inspector' 角色是否存在，若不存在則無法設定預設角色
    IF NOT EXISTS (SELECT 1 FROM public.roles WHERE name = 'inspector') THEN
        RAISE WARNING '預設角色 "inspector" 不存在於 roles 表中，無法為既有用戶設定預設角色。';
        RETURN '匯入中止：預設角色 "inspector" 不存在。';
    END IF;

    -- 遍歷 auth.users 中的所有使用者
    FOR user_record IN SELECT id, email, created_at FROM auth.users LOOP
        -- 1. 嘗試在 profiles 建立紀錄 (如果不存在)
        INSERT INTO public.profiles (id, email, created_at)
        VALUES (user_record.id, user_record.email, user_record.created_at)
        ON CONFLICT (id) DO NOTHING;
        -- 計算實際插入的數量 (可選)
        IF FOUND THEN
            inserted_profiles := inserted_profiles + 1;
        END IF;

        -- 2. 嘗試在 user_roles 建立紀錄，預設為 'inspector' (如果不存在)
        INSERT INTO public.user_roles (user_id, role)
        VALUES (user_record.id, 'inspector')
        ON CONFLICT (user_id) DO NOTHING;
        -- 計算實際插入的數量 (可選)
        IF FOUND THEN
            inserted_roles := inserted_roles + 1;
        END IF;
    END LOOP;

    RAISE LOG 'import_existing_users() 完成。新增了 % 筆 profile 記錄，新增了 % 筆 user_role 記錄 (預設 inspector)。', inserted_profiles, inserted_roles;
    RETURN '既有使用者匯入完成。新增 profiles: ' || inserted_profiles || ', 新增 user_roles: ' || inserted_roles;
END;
$$;
COMMENT ON FUNCTION public.import_existing_users() IS '將 auth.users 中已存在的用戶導入 profiles 和 user_roles (預設 inspector)';
-- ****** 結束新增函數 ******


-- --- 第 4 部分：儲存體 (Storage) ---
--
-- ****** 注意：此部分已完全移除 ******
-- ****** Bucket 'photos' 及其策略需透過 Supabase UI 手動建立 ******
-- ----------------------------------------------------------------


-- --- 第 5 部分：資料列層級安全性 (RLS) 策略 ---
--
-- ----------------------------------------------------------------

-- 啟用 RLS
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

-- 清除舊策略
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
DROP POLICY IF EXISTS "Allow admin update" ON public.reports;
DROP POLICY IF EXISTS "Allow user insert own" ON public.key_returns;
DROP POLICY IF EXISTS "Allow owner or admin read" ON public.key_returns;
DROP POLICY IF EXISTS "Allow admin delete" ON public.key_returns;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.student_allocations;
DROP POLICY IF EXISTS "Allow admin manage" ON public.student_allocations;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.roles;
DROP POLICY IF EXISTS "Allow admin manage" ON public.roles;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.permissions;
DROP POLICY IF EXISTS "Allow admin manage" ON public.permissions;
DROP POLICY IF EXISTS "Allow authenticated read" ON public.role_permissions;
DROP POLICY IF EXISTS "Allow admin manage" ON public.role_permissions;

-- 創建新策略
CREATE POLICY "Allow authenticated read" ON public.dorm_zones FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.dorm_zones FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.rooms FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.rooms FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.check_types FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.check_types FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.checklist_categories FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.checklist_categories FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.checklist_items FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.checklist_items FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow user read own" ON public.profiles FOR SELECT TO authenticated USING (id = auth.uid());
CREATE POLICY "Allow admin read all" ON public.profiles FOR SELECT TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow admin read all" ON public.user_roles FOR SELECT TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow user insert own" ON public.reports FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Allow owner or admin read" ON public.reports FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow owner or admin delete" ON public.reports FOR DELETE TO authenticated USING (user_id = auth.uid() OR public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow user insert own" ON public.key_returns FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());
CREATE POLICY "Allow owner or admin read" ON public.key_returns FOR SELECT TO authenticated USING (user_id = auth.uid() OR public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.student_allocations FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.student_allocations FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.roles FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.roles FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.permissions FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));
CREATE POLICY "Allow authenticated read" ON public.role_permissions FOR SELECT TO authenticated USING (true);
CREATE POLICY "Allow admin manage" ON public.role_permissions FOR ALL TO authenticated USING (public.get_my_role() IN ('admin', 'superadmin')) WITH CHECK (public.get_my_role() IN ('admin', 'superadmin'));


-- --- 第 6 部分：範例資料 (Sample Data) ---
--
-- ----------------------------------------------------------------

INSERT INTO public.check_types (name, description) VALUES ('學期初檢查', '入住前狀況'), ('期中安全檢查', '例行抽查'), ('寒假離宿檢查', '離宿清空狀況') ON CONFLICT (name) DO NOTHING;
INSERT INTO public.dorm_zones (name, description) VALUES ('A 區 (男生宿舍)', '東側'), ('B 區 (女生宿舍)', '西側') ON CONFLICT (name) DO NOTHING;
INSERT INTO public.rooms (zone_id, floor, room_number, capacity) SELECT z.id, r.floor, r.room_number, r.cap FROM public.dorm_zones z, (VALUES ('1', '101', 4), ('1', '102', 4), ('2', '201', 2), ('2', '202', 4)) AS r(floor, room_number, cap) WHERE z.name LIKE 'A 區%' ON CONFLICT (zone_id, floor, room_number) DO NOTHING;
INSERT INTO public.rooms (zone_id, household, floor, room_number, capacity) SELECT z.id, r.household, r.floor, r.room_number, r.cap FROM public.dorm_zones z, (VALUES ('H1', '1', '101', 4), ('H1', '1', '102', 2), ('H2', '2', '201', 4), ('H2', '2', '202', 4)) AS r(household, floor, room_number, cap) WHERE z.name LIKE 'B 區%' ON CONFLICT (zone_id, floor, room_number) DO NOTHING;
INSERT INTO public.student_allocations (student_id, zone_id, room_id, bed_number) SELECT 'S12345678', dz.id, r.id, '1' FROM public.dorm_zones dz JOIN public.rooms r ON dz.id = r.zone_id WHERE dz.name = 'A 區 (男生宿舍)' AND r.floor = '1' AND r.room_number = '101' ON CONFLICT (student_id) DO UPDATE SET zone_id=EXCLUDED.zone_id, room_id=EXCLUDED.room_id, bed_number=EXCLUDED.bed_number;
INSERT INTO public.student_allocations (student_id, zone_id, room_id, bed_number) SELECT 'S87654321', dz.id, r.id, '2' FROM public.dorm_zones dz JOIN public.rooms r ON dz.id = r.zone_id WHERE dz.name = 'A 區 (男生宿舍)' AND r.floor = '1' AND r.room_number = '101' ON CONFLICT (student_id) DO UPDATE SET zone_id=EXCLUDED.zone_id, room_id=EXCLUDED.room_id, bed_number=EXCLUDED.bed_number;
INSERT INTO public.student_allocations (student_id, zone_id, room_id, bed_number) SELECT 'S99988877', dz.id, r.id, '1' FROM public.dorm_zones dz JOIN public.rooms r ON dz.id = r.zone_id WHERE dz.name = 'B 區 (女生宿舍)' AND r.household = 'H1' AND r.floor = '1' AND r.room_number = '102' ON CONFLICT (student_id) DO UPDATE SET zone_id=EXCLUDED.zone_id, room_id=EXCLUDED.room_id, bed_number=EXCLUDED.bed_number;
INSERT INTO public.student_allocations (student_id, zone_id, room_id, bed_number) SELECT 'S11122233', dz.id, r.id, '2' FROM public.dorm_zones dz JOIN public.rooms r ON dz.id = r.zone_id WHERE dz.name = 'B 區 (女生宿舍)' AND r.household = 'H1' AND r.floor = '1' AND r.room_number = '102' ON CONFLICT (student_id) DO UPDATE SET zone_id=EXCLUDED.zone_id, room_id=EXCLUDED.room_id, bed_number=EXCLUDED.bed_number;
INSERT INTO public.checklist_categories (name, icon, display_order) VALUES ('寢室區域', '🛏️', 1), ('衛浴區域', '🛁', 2), ('公共區域/陽台', '🪴', 3) ON CONFLICT (name) DO NOTHING;
INSERT INTO public.checklist_items (category_id, name, display_order) SELECT c.id, item.name, item.ord FROM public.checklist_categories c, (VALUES ('寢室區域', '床架 (含床板)', 1), ('寢室區域', '書桌', 2), ('寢室區域', '椅子', 3), ('寢室區域', '衣櫃', 4), ('寢室區域', '冷氣 (含遙控器)', 5), ('衛浴區域', '馬桶 (含水箱)', 1), ('衛浴區域', '洗手台 (含水龍頭)', 2), ('衛浴區域', '淋浴設備 (含蓮蓬頭)', 3), ('衛浴區域', '置物架', 4), ('公共區域/陽台', '地板清潔', 1), ('公共區域/陽台', '陽台窗戶', 2)) AS item(cat_name, name, ord) WHERE c.name = item.cat_name ON CONFLICT (category_id, name) DO NOTHING;

-- --- 第 7 部分：執行初始化函數 ---
--
-- ----------------------------------------------------------------
SELECT public.import_existing_users(); -- <<-- 匯入既有帳號
SELECT public.setup_permissions(); -- <<-- 初始化 RBAC 權限分配

-- ----------------------------------------------------------------
-- --- 腳本執行完畢 ---
-- ----------------------------------------------------------------
-- 記得在 Supabase UI 中建立 'photos' Bucket 及其策略
-- ----------------------------------------------------------------