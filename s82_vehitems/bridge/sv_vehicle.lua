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
local function spawnVehicleServerSide(src, model, spawnPos, plate)
    local hash = GetHashKey(model)
    RequestModel(hash)

    local attempts = 0
    while not HasModelLoaded(hash) and attempts < 200 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(hash) then
        return nil, 'model_load_failed'
    end

    local vehicle = CreateVehicleServerSetter(hash, 'automobile', spawnPos.x, spawnPos.y, spawnPos.z, spawnPos.w)
    SetModelAsNoLongerNeeded(hash)

    if not vehicle or vehicle == 0 or not DoesEntityExist(vehicle) then
        return nil, 'spawn_failed'
    end

    SetVehicleNumberPlateText(vehicle, plate)
    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleFuelLevel(vehicle, 100.0)
    SetVehicleEngineOn(vehicle, true, true, false)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')

    local ped = GetPlayerPed(src)
    if ped and ped ~= 0 then
        Wait(150)
        TaskWarpPedIntoVehicle(ped, vehicle, -1)
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
        exports.qbx_vehiclekeys:GiveKeys(src, vehicle)
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
