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
