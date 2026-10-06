-- =====================================================================
-- S82Studio - s82_vehitems - CLIENT
-- Ho tro ESX / QBCore / QBox thong qua Bridge, da inventory, da ngon ngu
-- =====================================================================

local IsBusy = false

local function notify(msg, ntype)
    Bridge.Notify(msg, ntype or 'inform')
end

-- Kiem tra vat can xung quanh diem spawn xe
---@param spawnCoords vector3
---@return boolean ok, string|nil reason
local function checkObstacles(spawnCoords)
    -- Kiem tra xe quanh diem spawn
    local nearbyVehicles = lib.getNearbyVehicles(spawnCoords, Config.ObstacleCheckRadius, false)
    if #nearbyVehicles > Config.MaxNearbyVehicles then
        return false, Locale('err_too_many_vehicles')
    end

    -- Kiem tra object/prop quanh diem spawn
    local nearbyObjects = lib.getNearbyObjects(spawnCoords, Config.ObstacleCheckRadius)
    if #nearbyObjects > Config.MaxNearbyObjects then
        return false, Locale('err_too_many_objects')
    end

    -- Kiem tra ground level
    local _, groundZ = GetGroundZFor_3dCoord(spawnCoords.x, spawnCoords.y, spawnCoords.z + 2.0, false)
    if groundZ == 0.0 then
        return false, Locale('err_invalid_position')
    end

    return true, nil
end

-- Lay vi tri spawn xe (truoc mat player)
---@param ped number
---@return vector4
local function getSpawnCoords(ped)
    local pedCoords = GetEntityCoords(ped)
    local forward = GetEntityForwardVector(ped)
    local heading = GetEntityHeading(ped)

    local x = pedCoords.x + forward.x * Config.SpawnOffsetForward
    local y = pedCoords.y + forward.y * Config.SpawnOffsetForward
    local z = pedCoords.z

    -- Lay ground Z neu co
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 2.0, false)
    if found then z = groundZ end

    return vector4(x, y, z, heading)
end

-- =====================================================================
-- LUONG SU DUNG VAT PHAM
-- =====================================================================
RegisterNetEvent('s82_vehitems:client:startUseFlow', function(itemName, vehicleModel)
    if Config.Debug then
        print(('[s82_vehitems] client nhan startUseFlow: item=%s model=%s'):format(tostring(itemName), tostring(vehicleModel)))
    end
    if IsBusy then
        notify(Locale('err_busy'), 'error')
        return
    end

    local ped = PlayerPedId()

    -- Khong cho dung trong xe
    if Config.BlockInsideVehicle and IsPedInAnyVehicle(ped, false) then
        notify(Locale('err_in_vehicle'), 'error')
        TriggerServerEvent('s82_vehitems:server:cancelFlow')
        return
    end

    -- Khong cho dung trong interior
    if Config.BlockInInterior then
        local interior = GetInteriorFromEntity(ped)
        if interior ~= 0 then
            notify(Locale('err_in_interior'), 'error')
            TriggerServerEvent('s82_vehitems:server:cancelFlow')
            return
        end
    end

    IsBusy = true

    -- 1) Hop thoai xac nhan
    local choice = lib.alertDialog({
        header  = Locale('confirm_header'),
        content = Locale('confirm_content'),
        centered = true,
        cancel  = true,
        labels  = {
            confirm = Locale('confirm_confirm'),
            cancel  = Locale('confirm_cancel'),
        },
    })

    if choice ~= 'confirm' then
        IsBusy = false
        TriggerServerEvent('s82_vehitems:server:cancelFlow')
        return
    end

    -- 2) Kiem tra vat can xung quanh
    local spawnCoords = getSpawnCoords(ped)
    local ok, reason = checkObstacles(vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z))
    if not ok then
        IsBusy = false
        TriggerServerEvent('s82_vehitems:server:cancelFlow')
        notify(reason, 'error')
        return
    end

    -- 3) Thanh tien trinh - khong the cancel, khong the di chuyen
    local progressOpts = {
        duration    = Config.ProgressDuration,
        label       = Locale('progress_label'),
        useWhileDead = false,
        canCancel   = false,
        disable = {
            move    = true,
            car     = true,
            combat  = true,
            mouse   = false,
            sprint  = true,
        },
    }

    if Config.ProgressAnim and Config.ProgressAnim.dict then
        progressOpts.anim = {
            dict = Config.ProgressAnim.dict,
            clip = Config.ProgressAnim.clip,
            flag = Config.ProgressAnim.flag or 49,
        }
    end

    local success = lib.progressBar(progressOpts)

    ClearPedTasks(ped)

    if not success then
        IsBusy = false
        TriggerServerEvent('s82_vehitems:server:cancelFlow')
        notify(Locale('err_interrupted'), 'error')
        return
    end

    -- 4) Tinh lai vi tri spawn (player co the da xoay nguoi du khong di chuyen)
    spawnCoords = getSpawnCoords(ped)
    -- Kiem tra lai vat can lan cuoi
    local ok2, reason2 = checkObstacles(vector3(spawnCoords.x, spawnCoords.y, spawnCoords.z))
    if not ok2 then
        IsBusy = false
        TriggerServerEvent('s82_vehitems:server:cancelFlow')
        notify(reason2, 'error')
        return
    end

    -- 5) Gui yeu cau spawn xe ve server
    TriggerServerEvent('s82_vehitems:server:completeUse', vehicleModel, {
        x = spawnCoords.x,
        y = spawnCoords.y,
        z = spawnCoords.z,
        w = spawnCoords.w,
    })

    -- Server se gui event reset busy sau khi xu ly xong (du thanh cong hay khong)
end)

-- =====================================================================
-- SERVER HOI LOAI XE (server khong load duoc model)
-- Tra ve type dung cho CreateVehicleServerSetter
-- =====================================================================
lib.callback.register('s82_vehitems:client:getVehicleType', function(model)
    local hash = joaat(model)
    if not IsModelInCdimage(hash) or not IsModelAVehicle(hash) then
        return nil
    end

    lib.requestModel(hash, 10000)

    local vType
    if IsThisModelACar(hash) or IsThisModelAQuadbike(hash)
        or IsThisModelAnAmphibiousCar(hash) or IsThisModelAnAmphibiousQuadbike(hash) then
        vType = 'automobile'
    elseif IsThisModelABike(hash) or IsThisModelABicycle(hash) then
        vType = 'bike'
    elseif IsThisModelABoat(hash) or IsThisModelAJetski(hash) then
        vType = 'boat'
    elseif IsThisModelAHeli(hash) then
        vType = 'heli'
    elseif IsThisModelAPlane(hash) then
        vType = 'plane'
    elseif IsThisModelATrain(hash) then
        vType = 'train'
    else
        local class = GetVehicleClassFromName(hash)
        if class == 14 then
            vType = 'submarine'
        elseif class == 11 then
            vType = 'trailer'
        else
            vType = 'automobile'
        end
    end

    SetModelAsNoLongerNeeded(hash)
    return vType
end)

-- =====================================================================
-- SETUP XE SAU KHI SERVER SPAWN (native client-only)
-- =====================================================================
-- Do xang qua script xang dang dung + native (fuel script hay ghi de native,
-- nen phai goi qua export cua chinh no)
local FuelResources = {
    -- [resource] = function(vehicle, fuel)
    ['lc_fuel']    = function(v, f) exports['lc_fuel']:SetFuel(v, f) end,
    ['LegacyFuel'] = function(v, f) exports['LegacyFuel']:SetFuel(v, f) end,
    ['cdn-fuel']   = function(v, f) exports['cdn-fuel']:SetFuel(v, f) end,
    ['ps-fuel']    = function(v, f) exports['ps-fuel']:SetFuel(v, f) end,
    ['lj-fuel']    = function(v, f) exports['lj-fuel']:SetFuel(v, f) end,
    ['qb-fuel']    = function(v, f) exports['qb-fuel']:SetFuel(v, f) end,
    ['okokGasStation'] = function(v, f) exports['okokGasStation']:SetFuel(v, f) end,
}

local function applyFuel(vehicle, fuel)
    SetVehicleFuelLevel(vehicle, fuel)
    if DecorIsRegisteredAsType('_FUEL_LEVEL', 1) then
        DecorSetFloat(vehicle, '_FUEL_LEVEL', fuel) -- LegacyFuel / ban fork cu dung decor nay
    end

    -- ox_fuel doc statebag; chi owner moi set duoc tu client -> server da set san, set lai cho chac
    if GetResourceState('ox_fuel') == 'started' then
        Entity(vehicle).state:set('fuel', fuel, true)
    end

    local custom = Config.FuelResource
    if custom and custom ~= 'auto' and custom ~= '' then
        if FuelResources[custom] and GetResourceState(custom) == 'started' then
            pcall(FuelResources[custom], vehicle, fuel)
        end
        return
    end

    for res, fn in pairs(FuelResources) do
        if GetResourceState(res) == 'started' then
            pcall(fn, vehicle, fuel)
        end
    end
end

lib.callback.register('s82_vehitems:client:setupVehicle', function(netId, plate, fuel)
    fuel = fuel or 100.0

    -- 1) Cho entity ton tai phia client (lib.waitFor nem loi khi het gio -> pcall)
    local ok, vehicle = pcall(lib.waitFor, function()
        if NetworkDoesNetworkIdExist(netId) then
            local veh = NetToVeh(netId)
            if veh ~= 0 and DoesEntityExist(veh) then return veh end
        end
    end, nil, 7000)
    if not ok or not vehicle then return false end

    -- 2) Cho client lam owner (native set fuel/plate chi co tac dung khi la owner)
    local t = GetGameTimer()
    while not NetworkHasControlOfEntity(vehicle) and GetGameTimer() - t < 3000 do
        NetworkRequestControlOfEntity(vehicle)
        Wait(50)
    end

    -- 3) Ep dung bien so (fix truong hop chia khoa theo plate bi lech)
    if plate and GetVehicleNumberPlateText(vehicle):gsub('%s+', '') ~= plate:gsub('%s+', '') then
        SetVehicleNumberPlateText(vehicle, plate)
    end

    SetVehicleDirtLevel(vehicle, 0.0)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, 'OFF')
    SetVehicleEngineOn(vehicle, true, true, false)

    -- 4) Do xang ngay + do lai sau 1.5s (fuel script hay ghi de khi player vua vao xe)
    applyFuel(vehicle, fuel)
    SetTimeout(1500, function()
        if DoesEntityExist(vehicle) then applyFuel(vehicle, fuel) end
    end)

    return true
end)

-- Server bao reset trang thai busy
RegisterNetEvent('s82_vehitems:client:resetBusy', function()
    IsBusy = false
end)

-- Cleanup khi resource stop
AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        IsBusy = false
        ClearPedTasks(PlayerPedId())
    end
end)
