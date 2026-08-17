# s82_vehitems (S82Studio) — v3.0.0

Script vật phẩm xe đa framework: **ESX / QBCore / QBox**, đa hệ thống túi đồ
(**ox_inventory / qs-inventory / qb-inventory / ps-inventory / ESX mặc định**),
đa ngôn ngữ (**Tiếng Việt / English**).

Người chơi sử dụng một vật phẩm (ví dụ `car_elegy`) → xác nhận → thanh tiến trình 15 giây → nhận xe với quyền sở hữu được lưu vào database, có chìa khoá, được warp vào ghế lái.

## Tính năng

- ✅ Tự động nhận diện **framework** (QBox → QBCore → ESX) và **hệ thống túi đồ** (ox_inventory → qs-inventory → qb-inventory/ps-inventory → ESX mặc định) — hoặc chỉ định thủ công trong `config.lua`
- ✅ Đa ngôn ngữ: đổi `Config.Locale = 'vi'` hoặc `'en'`, dễ dàng thêm ngôn ngữ khác trong thư mục `locales/`
- ✅ Hộp thoại xác nhận trước khi sử dụng (ox_lib alertDialog)
- ✅ Thanh tiến trình 15 giây, **không thể hủy**, **không thể di chuyển / đánh nhau / sprint**
- ✅ Kiểm tra vật cản xung quanh (xe, prop, ground) trước khi spawn
- ✅ Kiểm tra trong xe / trong nhà → chặn
- ✅ Xe được lưu vào database theo đúng chuẩn của từng framework → người chơi sở hữu vĩnh viễn
- ✅ Tự động **warp ped vào xe** + **cấp chìa khoá**
- ✅ **Chống spam 5 phút** (theo identifier, giữ qua disconnect)
- ✅ Vật phẩm chỉ bị tiêu thụ **sau khi flow thành công** (cancel → không mất item)
- ✅ Bảo vệ chống gian lận: validate identifier, coords, item count cả phía server

## Kiến trúc Bridge

Script được tách thành 3 lớp Bridge để dễ mở rộng / bảo trì:

```
bridge/sv_bridge.lua     -> nhận diện framework (ESX/QBCore/QBox), GetPlayer, GetIdentifier, Notify, CreateUseableItem, GeneratePlate
bridge/sv_inventory.lua  -> nhận diện túi đồ, GetItemCount, RemoveItem
bridge/sv_vehicle.lua    -> Create (lưu DB), Spawn (tạo entity), SetOwnedState, GiveKeys, Delete (rollback)
bridge/cl_bridge.lua     -> Notify phía client theo từng framework
```

Toàn bộ `server/sv_main.lua` và `client/cl_main.lua` chỉ gọi qua `Bridge.*`, không gọi trực tiếp export của framework nào — muốn hỗ trợ thêm framework/túi đồ mới chỉ cần thêm nhánh mới trong các file bridge.

## ⚠️ Lưu ý quan trọng về garage/chìa khoá (QBCore & ESX)

Không giống QBox (có `qbx_vehicles` + `qbx_vehiclekeys` là chuẩn thống nhất),
**QBCore và ESX không có một chuẩn garage/chìa khoá duy nhất** — mỗi server
có thể dùng `qb-garages`, `wasabi_carlock`, `esx_vehiclelock`, `esx_society`,
garage tự viết, v.v. Script đã implement theo **cấu trúc phổ biến nhất**:

- **QBCore**: insert vào bảng `player_vehicles` (chuẩn qb-garages), cấp chìa khoá qua event `vehiclekeys:client:SetOwner` (chuẩn qb-vehiclekeys)
- **ESX**: insert vào bảng `owned_vehicles`, cấp chìa khoá qua `esx_vehiclelock:client:setOwnedVehicle` (đổi được qua `Config.EsxKeySystem`)

Nếu server bạn dùng garage/chìa khoá khác, hãy chỉnh lại `Bridge.Vehicle.Create` và `Bridge.Vehicle.GiveKeys` trong `bridge/sv_vehicle.lua` (2 hàm này là điểm tuỳ biến duy nhất bạn cần đổi).

## Cài đặt

### 1. Thêm vật phẩm vào hệ thống túi đồ đang dùng

Ví dụ với `ox_inventory/data/items.lua`:

```lua
['car_elegy'] = {
    label = 'Hộp xe Elegy',
    weight = 1000,
    stack = false,
    close = true,
    description = 'Sử dụng để nhận chiếc xe Elegy',
},
```

Với QBCore (`qb-core/shared/items.lua`) hoặc ESX (`items` table trong DB) — thêm item tương tự theo cú pháp của hệ thống bạn dùng.

### 2. Cấu hình `config.lua`

```lua
Config.Locale    = 'vi'    -- 'vi' | 'en'
Config.Framework = 'auto'  -- 'auto' | 'esx' | 'qb' | 'qbx'
Config.Inventory = 'auto'  -- 'auto' | 'ox' | 'qs' | 'qb' | 'esx'

Config.Items = {
    ['car_elegy'] = 'elegy',
    ['car_t20']   = 't20',
}
```

### 3. Khởi động resource

```cfg
ensure ox_lib
ensure oxmysql
-- framework của bạn (qbx_core / qb-core / es_extended) + hệ thống túi đồ tương ứng
ensure s82_vehitems
```

### 4. Cấp item để test

```
/giveitem [id] car_elegy 1
```

Click chuột phải vào item → "Use" → xác nhận → chờ 15s → nhận xe.

## Yêu cầu

- `ox_lib` (bắt buộc, dùng cho progressBar / alertDialog / getNearbyVehicles / getNearbyObjects)
- Một trong: `qbx_core` (+ `qbx_vehicles`, `qbx_vehiclekeys`) / `qb-core` / `es_extended`
- Một trong: `ox_inventory` / `qs-inventory` / `qb-inventory` / `ps-inventory` / (mặc định của ESX)
- `oxmysql`

## Lưu ý khác

- Khi player **cancel** ở hộp thoại hoặc bị **block do vật cản**, item **KHÔNG mất**.
- Khi spawn xe thất bại (model lỗi, lỗi DB...), bản ghi DB xe được **tự động rollback**.
- Cooldown lưu trong memory → reset khi restart server (đây là hành vi mong muốn để tránh accident permanent lock).
- Để thay đổi nội dung hộp thoại / nhãn progress bar / thông báo, chỉnh file tương ứng trong `locales/en.lua` hoặc `locales/vi.lua`.
- Muốn thêm ngôn ngữ mới: tạo `locales/xx.lua` theo mẫu, thêm vào `shared_scripts` trong `fxmanifest.lua`, rồi đặt `Config.Locale = 'xx'`.
