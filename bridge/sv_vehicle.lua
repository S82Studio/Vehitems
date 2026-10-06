-- =====================================================================
-- S82Studio - BRIDGE VEHICLE (SERVER)
-- Chuan hoa: Create (luu DB), Spawn (tao entity), SetOwnedState, GiveKeys, Delete
--
-- LUU Y QUAN TRONG:
-- Voi QBCore va ESX, moi server co the dung garage script khac nhau
-- (qb-garages, wasabi_carlock, esx_society, ...) voi cau truc bang/statebag
-- khac nhau. Cac ham ben duoi implement theo cau truc PHO BIEN NHAT cua
-- tung framework. Neu server ban dung garage tuy bien, hay chinh lai
-- Bridge.Vehicle.Create / GiveKeys cho khop.
-- =====================================================================

Bridge = Bridge or {}
Bridge.Vehicle = {}

-- =====================================================================
-- HAM SPAWN XE DUNG CHUNG CHO CA 3 FRAMEWORK
-- Spawn hoan toan phia server (CreateVehicleServerSetter) - khong can
-- client tro ve network id, tranh phu thuoc vao module rieng cua tung fw
-- =====================================================================
-- LUU Y: Server KHONG co RequestModel / HasModelLoaded / SetVehicleFuelLevel /
-- SetVehicleEngineOn / SetVehRadioStation... (chi co o client). Vi vay:
--   1) Hoi client loai xe (automobile / bike / heli...) qua lib.callback
--      -> client tu load model + tra ve type (cache lai theo model)
--   2) Server tao entity bang CreateVehicleServerSetter voi dung type
--   3) Gui netId ve client de set fuel / may / radio (native client-only)
local VehicleTypeCache = {}

local function getVehicleType(src, model)
    if VehicleTypeCache[model] then
        return VehicleTypeCache[model]
    end

    local vType = lib.callback.await('s82_vehitems:client:getVehicleType', src, model)
    if vType then
        VehicleTypeCache[model] = vType
    end
    return vType
end

local function spawnVehicleServerSide(src, model, spawnPos, plate)
    local hash = joaat(model)

    local vType = getVehicleType(src, model)
    if not vType then
        return nil, 'model_invalid'
    end

    local vehicle = CreateVehicleServerSetter(hash, vType, spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w)

    -- Cho entity ton tai (toi da ~2s)
    local attempts = 0
    while (not vehicle or vehicle == 0 or not DoesEntityExist(vehicle)) and attempts < 200 do
        Wait(10)
        attempts = attempts + 1
    end

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil, 'spawn_failed'
    end

    -- Native server-side hop le
    SetVehicleNumberPlateText(vehicle, plate)
    local fuel = (Config.SpawnFuel or 100) + 0.0
    Entity(vehicle).state:set('fuel', fuel, true) -- ox_fuel / cac fuel script doc statebag nay

    -- Warp player vao ghe lai (lap lai den khi thanh cong, toi da ~3s)
    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        local tries = 0
        while GetVehiclePedIsIn(ped, false) ~= vehicle and tries < 60 do
            TaskWarpPedIntoVehicle(ped, vehicle, -1)
            Wait(50)
            tries = tries + 1
        end
    end

    -- Cho entity co owner (client da nhan entity) truoc khi lam gi tiep
    local ownerTries = 0
    while NetworkGetEntityOwner(vehicle) == -1 and ownerTries < 100 do
        Wait(20)
        ownerTries = ownerTries + 1
    end

    -- Client setup (fuel / bien so / may...) va CHO client xac nhan xong.
    -- Nho vay khi ham nay tra ve, xe da sync day du -> GiveKeys / fuel khong bi "som".
    local netId = NetworkGetNetworkIdFromEntity(vehicle)
    local ok = lib.callback.await('s82_vehitems:client:setupVehicle', src, netId, plate, fuel)
    if not ok and Config.Debug then
        print(('[s82_vehitems] WARN: client setup xe chua xac nhan (netId=%s)'):format(netId))
    end

    -- Cho bien so phia server khop (server setter can thoi gian sync)
    local plateTries = 0
    while plateTries < 50 do
        local cur = GetVehicleNumberPlateText(vehicle)
        if cur and cur:gsub('%s+', '') == plate:gsub('%s+', '') then break end
        Wait(20)
        plateTries = plateTries + 1
    end

    return vehicle
end
Bridge.Vehicle.SpawnGeneric = spawnVehicleServerSide

-- Statebag chung, dung cho ca 3 fw de cac resource khac (vd script kiem tra xe so huu) co the doc duoc
local function setOwnedStateGeneric(vehicle, vehicleId)
    Entity(vehicle).state:set('vehicleid', vehicleId, true)
end

-- =====================================================================
-- QBOX (qbx_core + qbx_vehicles + qbx_vehiclekeys)
-- =====================================================================
if Bridge.Framework.Name == 'qbx' then

    Bridge.Vehicle.Create = function(identifier, model, plate)
        local vehicleId, err = exports.qbx_vehicles:CreatePlayerVehicle({
            model = model,
            citizenid = identifier,
            props = { plate = plate },
        })
        if not vehicleId then
            return nil, (err and err.message) or 'unknown_error'
        end
        return vehicleId
    end

    Bridge.Vehicle.Delete = function(vehicleId)
        exports.qbx_vehicles:DeletePlayerVehicles('vehicleId', vehicleId)
    end

    Bridge.Vehicle.Spawn = spawnVehicleServerSide

    Bridge.Vehicle.SetOwnedState = setOwnedStateGeneric

    Bridge.Vehicle.GiveKeys = function(src, vehicle, plate)
        -- Thu toi da 5 lan, kiem tra lai bang HasKeys (neu ban qbx_vehiclekeys co export nay)
        for _ = 1, 5 do
            pcall(function() exports.qbx_vehiclekeys:GiveKeys(src, vehicle, true) end)
            Wait(200)
            local okCheck, has = pcall(function() return exports.qbx_vehiclekeys:HasKeys(src, vehicle) end)
            if not okCheck or has then return end -- khong co HasKeys -> coi nhu xong
        end
        print(('[s82_vehitems] WARN: khong cap duoc chia khoa cho src=%s plate=%s'):format(src, plate))
    end

-- =====================================================================
-- QBCORE (qb-core) - insert vao bang player_vehicles (chuan qb-garages)
-- =====================================================================
elseif Bridge.Framework.Name == 'qb' then

    Bridge.Vehicle.Create = function(identifier, model, plate)
        local hash = GetHashKey(model)
        local ok, vehicleId = pcall(function()
            return MySQL.insert.await(
                'INSERT INTO player_vehicles (citizenid, vehicle, hash, mods, plate, garage, state, fuel) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
                { identifier, model, hash, '{}', plate, Config.DefaultGarage or 'pillboxgarage', 1, 100 }
            )
        end)
        if not ok or not vehicleId then
            return nil, 'db_insert_failed'
        end
        return vehicleId
    end

    Bridge.Vehicle.Delete = function(vehicleId)
        MySQL.query('DELETE FROM player_vehicles WHERE id = ?', { vehicleId })
    end

    Bridge.Vehicle.Spawn = spawnVehicleServerSide

    Bridge.Vehicle.SetOwnedState = setOwnedStateGeneric

    Bridge.Vehicle.GiveKeys = function(src, vehicle, plate)
        -- Chuan qb-vehiclekeys pho bien nhat. Neu ban dung script chia khoa
        -- khac (vd wasabi_carlock), doi lai event nay cho khop.
        TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        -- Gui lai lan 2 phong truong hop client chua nhan dung bien so o lan dau
        SetTimeout(1000, function()
            TriggerClientEvent('vehiclekeys:client:SetOwner', src, plate)
        end)
    end

-- =====================================================================
-- ESX (es_extended) - insert vao bang owned_vehicles
-- =====================================================================
elseif Bridge.Framework.Name == 'esx' then

    Bridge.Vehicle.Create = function(identifier, model, plate)
        local vehicleProps = { model = GetHashKey(model), plate = plate }
        local ok, insertId = pcall(function()
            return MySQL.insert.await(
                'INSERT INTO owned_vehicles (owner, plate, vehicle, `type`, stored) VALUES (?, ?, ?, ?, 0)',
                { identifier, plate, json.encode(vehicleProps), 'car' }
            )
        end)
        if not ok or not insertId then
            return nil, 'db_insert_failed'
        end
        return insertId
    end

    Bridge.Vehicle.Delete = function(vehicleId)
        MySQL.query('DELETE FROM owned_vehicles WHERE id = ?', { vehicleId })
    end

    Bridge.Vehicle.Spawn = spawnVehicleServerSide

    Bridge.Vehicle.SetOwnedState = setOwnedStateGeneric

    Bridge.Vehicle.GiveKeys = function(src, vehicle, plate)
        if Config.EsxKeySystem == 'esx_vehiclelock' then
            TriggerClientEvent('esx_vehiclelock:client:setOwnedVehicle', src, plate)
        end
        -- 'none' -> chi dung statebag vehicleid, khong gui event chia khoa nao
    end

else
    print('^1[s82_vehitems] KHONG THE THIET LAP BRIDGE VEHICLE (framework khong xac dinh).^0')
end
