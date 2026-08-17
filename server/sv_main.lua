-- =====================================================================
-- S82Studio - s82_vehitems - SERVER
-- Ho tro ESX / QBCore / QBox thong qua Bridge, da inventory, da ngon ngu
-- =====================================================================

local ActiveFlows = {}  -- [identifier] = true (dang trong qua trinh dung vat pham)
local Cooldowns   = {}  -- [identifier] = os.time() khi co the dung lai

local function dprint(...)
    if Config.Debug then
        print('[s82_vehitems]', ...)
    end
end

local function notify(src, msg, ntype)
    Bridge.Framework.Notify(src, msg, ntype or 'inform')
end

local function formatRemaining(seconds)
    if seconds <= 60 then
        return Locale('time_seconds', seconds)
    end
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    if s == 0 then
        return Locale('time_minutes', m)
    end
    return Locale('time_minutes_seconds', m, s)
end

-- =====================================================================
-- KIEM TRA BRIDGE DA SAN SANG CHUA (framework + inventory + vehicle)
-- =====================================================================
local function bridgeReady()
    return Bridge.Framework and Bridge.Framework.Name
        and Bridge.Inventory and Bridge.Inventory.Name
        and Bridge.Vehicle and Bridge.Vehicle.Create ~= nil
end

-- =====================================================================
-- BAT DAU LUONG SU DUNG VAT PHAM (goi tu hook cua framework)
-- =====================================================================
local function startUseItem(src, itemName, vehicleModel)
    if not bridgeReady() then
        notify(src, Locale('err_no_bridge'), 'error')
        return
    end

    local identifier = Bridge.Framework.GetIdentifier(src)
    if not identifier then
        notify(src, Locale('err_cannot_identify'), 'error')
        return
    end

    -- Kiem tra cooldown
    local now = os.time()
    if Cooldowns[identifier] and Cooldowns[identifier] > now then
        local remain = Cooldowns[identifier] - now
        notify(src, Locale('err_cooldown', formatRemaining(remain)), 'error')
        return
    end

    -- Kiem tra dang trong flow
    if ActiveFlows[identifier] then
        notify(src, Locale('err_already_flow'), 'error')
        return
    end

    -- Kiem tra con item khong
    if Bridge.Inventory.GetItemCount(src, itemName) < 1 then
        notify(src, Locale('err_no_item'), 'error')
        return
    end

    ActiveFlows[identifier] = true
    dprint(('startUseItem OK -> trigger client. src=%s item=%s model=%s'):format(src, itemName, vehicleModel))
    TriggerClientEvent('s82_vehitems:client:startUseFlow', src, itemName, vehicleModel)
end

-- =====================================================================
-- DANG KY ITEM USABLE QUA BRIDGE FRAMEWORK
-- =====================================================================
CreateThread(function()
    -- Cho Bridge khoi tao xong truoc khi dang ky item (Bridge.Framework duoc
    -- thiet lap ngay khi file bridge/sv_bridge.lua load, nen thuc te khong
    -- can cho, nhung giu lai de an toan neu co thay doi thu tu load sau nay)
    if not bridgeReady() then
        print('^1[s82_vehitems] Bridge chua san sang, khong the dang ky vat pham! Kiem tra lai Config.Framework / Config.Inventory.^0')
        return
    end

    for itemName, vehicleModel in pairs(Config.Items) do
        Bridge.Framework.CreateUseableItem(itemName, function(source, item)
            dprint(('item used: name=%s src=%s'):format(itemName, tostring(source)))
            startUseItem(source, itemName, vehicleModel)
        end)
        dprint(('da dang ky item usable: %s -> %s'):format(itemName, vehicleModel))
    end

    dprint(('framework=%s | inventory=%s'):format(Bridge.Framework.Name, Bridge.Inventory.Name))
end)

-- =====================================================================
-- CLIENT CANCEL / FAIL FLOW
-- =====================================================================
RegisterNetEvent('s82_vehitems:server:cancelFlow', function()
    local src = source
    local identifier = Bridge.Framework.GetIdentifier(src)
    if not identifier then return end
    ActiveFlows[identifier] = nil
    TriggerClientEvent('s82_vehitems:client:resetBusy', src)
end)

-- =====================================================================
-- CLIENT DA XONG PROGRESS BAR -> SERVER SPAWN XE
-- =====================================================================
RegisterNetEvent('s82_vehitems:server:completeUse', function(vehicleModel, coords)
    local src = source
    local identifier = Bridge.Framework.GetIdentifier(src)
    if not identifier then return end

    -- Validate dang trong flow (chong gian lan tu client)
    if not ActiveFlows[identifier] then
        notify(src, Locale('err_invalid_session'), 'error')
        TriggerClientEvent('s82_vehitems:client:resetBusy', src)
        return
    end

    -- Validate coords (phong client gui rac)
    if type(coords) ~= 'table' or not coords.x or not coords.y or not coords.z or not coords.w then
        ActiveFlows[identifier] = nil
        TriggerClientEvent('s82_vehitems:client:resetBusy', src)
        notify(src, Locale('err_invalid_coords'), 'error')
        return
    end

    -- Tim item name tu vehicle model
    local itemName
    for name, model in pairs(Config.Items) do
        if model == vehicleModel then
            itemName = name
            break
        end
    end
    if not itemName then
        ActiveFlows[identifier] = nil
        TriggerClientEvent('s82_vehitems:client:resetBusy', src)
        notify(src, Locale('err_unsupported_item'), 'error')
        return
    end

    -- Kiem tra lai con item
    if Bridge.Inventory.GetItemCount(src, itemName) < 1 then
        ActiveFlows[identifier] = nil
        TriggerClientEvent('s82_vehitems:client:resetBusy', src)
        notify(src, Locale('err_item_gone'), 'error')
        return
    end

    -- Sinh bien so ngau nhien
    local plate = Bridge.Framework.GeneratePlate()

    -- 1) Insert vao DB qua Bridge (qbx_vehicles / player_vehicles / owned_vehicles)
    local vehicleId, errorResult = Bridge.Vehicle.Create(identifier, vehicleModel, plate)

    if not vehicleId then
        ActiveFlows[identifier] = nil
        TriggerClientEvent('s82_vehitems:client:resetBusy', src)
        notify(src, Locale('err_register_failed', tostring(errorResult or 'unknown_error')), 'error')
        return
    end

    -- 2) Spawn xe server-side va warp player vao
    local spawnPos = vec4(coords.x + 0.0, coords.y + 0.0, coords.z + 0.5, coords.w + 0.0)

    local ok, vehicleOrErr = pcall(function()
        return Bridge.Vehicle.Spawn(src, vehicleModel, spawnPos, plate)
    end)

    local vehicle = ok and vehicleOrErr or nil

    if not ok or not vehicle or not DoesEntityExist(vehicle) then
        if not ok then
            print(('[s82_vehitems] Loi khi spawn xe: %s'):format(tostring(vehicleOrErr)))
        end
        ActiveFlows[identifier] = nil
        TriggerClientEvent('s82_vehitems:client:resetBusy', src)
        Bridge.Vehicle.Delete(vehicleId)
        notify(src, Locale('err_spawn_failed'), 'error')
        return
    end

    -- 3) Set statebag vehicleid de cac resource khac (garage, keys) nhan ra
    Bridge.Vehicle.SetOwnedState(vehicle, vehicleId)

    -- 4) Cap chia khoa
    Bridge.Vehicle.GiveKeys(src, vehicle, plate)

    -- 5) Tieu thu vat pham
    local removed = Bridge.Inventory.RemoveItem(src, itemName, 1)
    if not removed then
        -- Edge case: khong remove duoc (vd vat pham bi xoa boi resource khac trong khi flow)
        -- Khong rollback xe vi player da nhan, chi log
        print(('[s82_vehitems] WARN: khong the remove item %s tu player %s (id=%s) sau khi spawn xe %s')
            :format(itemName, src, identifier, tostring(vehicleId)))
    end

    -- 6) Set cooldown va clear flow
    Cooldowns[identifier] = os.time() + Config.SpamCooldownSeconds
    ActiveFlows[identifier] = nil
    TriggerClientEvent('s82_vehitems:client:resetBusy', src)

    notify(src, Locale('success_received', vehicleModel:upper(), plate), 'success')
end)

-- =====================================================================
-- CLEANUP
-- =====================================================================
AddEventHandler('playerDropped', function()
    local src = source
    local identifier = Bridge.Framework and Bridge.Framework.GetIdentifier(src)
    if identifier then
        ActiveFlows[identifier] = nil
        -- Giu lai cooldown qua disconnect
    end
end)

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        ActiveFlows = {}
    end
end)
