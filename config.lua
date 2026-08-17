Config = {}

-- Bat/tat log debug trong console server (in ra khi dang ky item, khi dung item...)
Config.Debug = true

-- =====================================================================
-- NGON NGU
-- =====================================================================
-- 'vi' = Tieng Viet | 'en' = English
-- Toan bo text hien thi cho nguoi choi nam trong locales/en.lua va locales/vi.lua
Config.Locale = 'vi'

-- =====================================================================
-- FRAMEWORK
-- =====================================================================
-- 'auto' = tu dong nhan dien (qbx_core > qb-core > es_extended)
-- Hoac dat cung: 'qbx' | 'qb' | 'esx'
Config.Framework = 'auto'

-- =====================================================================
-- HE THONG TUI DO (INVENTORY)
-- =====================================================================
-- 'auto' = tu dong nhan dien (ox_inventory > qs-inventory > qb-inventory/ps-inventory > esx mac dinh)
-- Hoac dat cung: 'ox' | 'qs' | 'qb' | 'esx'
-- Luu y: 'qb' dung chung cho qb-inventory VA ps-inventory (ca hai deu
-- hoat dong qua Player.Functions.GetItemByName / RemoveItem)
Config.Inventory = 'auto'

-- =====================================================================
-- DANH SACH VAT PHAM => MODEL XE
-- Cu phap: ['ten_item'] = 'model_xe'
-- Ten item phai trung khop voi item trong file items cua he thong tui do dang dung
-- =====================================================================
Config.Items = {
    ['car_elegy'] = 'elegy',
    ['car_t20']   = 't20',
}

-- =====================================================================
-- THANH TIEN TRINH
-- =====================================================================
-- Thoi gian thanh tien trinh khi su dung vat pham (mili-giay)
-- Mac dinh: 15000 = 15 giay
Config.ProgressDuration = 15000

-- Animation hien thi khi cho thanh tien trinh
-- Dat dict = nil neu khong muon co animation
Config.ProgressAnim = {
    dict = 'anim@amb@business@bgen@bgen_no_work@',
    clip = 'stand_phone_phoneputdown_idle_nowork',
    flag = 49,
}

-- =====================================================================
-- CHONG SPAM
-- =====================================================================
-- Khoang thoi gian (giay) player phai cho moi co the dung lai vat pham
-- Mac dinh: 300 = 5 phut
Config.SpamCooldownSeconds = 300

-- =====================================================================
-- KIEM TRA VAT CAN XUNG QUANH
-- =====================================================================
-- Khoang cach phia truoc player de spawn xe (met)
Config.SpawnOffsetForward = 3.5

-- Ban kinh kiem tra vat can quanh vi tri spawn (met)
Config.ObstacleCheckRadius = 3.5

-- So luong xe toi da cho phep co trong ban kinh kiem tra
-- Vuot qua so nay -> chan khong cho su dung
Config.MaxNearbyVehicles = 0

-- So luong vat the/prop toi da cho phep co trong ban kinh kiem tra
-- Vuot qua so nay -> chan khong cho su dung
Config.MaxNearbyObjects = 2

-- Cam su dung khi player dang trong xe (kien nghi giu true)
Config.BlockInsideVehicle = true

-- Cam su dung khi player dang trong noi that (interior) - vi du trong nha
Config.BlockInInterior = true

-- =====================================================================
-- BIEN SO
-- =====================================================================
-- Format bien so: 1 = so ngau nhien, A = chu cai ngau nhien
-- Mac dinh "11AAA111" giong qbx (vd: 23ABC456)
-- Voi QBCore, neu QBCore.Functions.GeneratePlate ton tai thi se uu tien dung ham do,
-- neu khong se dung bo sinh bien so noi bo theo format nay.
Config.PlateFormat = '11AAA111'

-- =====================================================================
-- GARAGE MAC DINH (chi dung cho framework 'qb' khi insert vao player_vehicles)
-- Doi lai cho khop voi garage chinh cua server ban (vd garage script qb-garages)
-- =====================================================================
Config.DefaultGarage = 'pillboxgarage'

-- =====================================================================
-- HE THONG CHIA KHOA (chi ap dung cho framework 'esx')
-- Vi ESX khong co chuan chia khoa thong nhat, hay chon he thong ban dang dung.
-- 'esx_vehiclelock' | 'none' (khong gui event chia khoa nao, chi dung statebag)
-- =====================================================================
Config.EsxKeySystem = 'esx_vehiclelock'
