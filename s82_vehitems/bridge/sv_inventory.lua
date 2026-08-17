-- =====================================================================
-- S82Studio - BRIDGE INVENTORY (SERVER)
-- Tu dong nhan dien he thong tui do: ox_inventory / qs-inventory /
-- qb-inventory / ps-inventory / esx (mac dinh)
-- Chuan hoa: GetItemCount, RemoveItem
-- =====================================================================

Bridge = Bridge or {}
Bridge.Inventory = {}

local function resourceReady(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

local detected = Config.Inventory
if detected == 'auto' then
    if resourceReady('ox_inventory') then
        detected = 'ox'
    elseif resourceReady('qs-inventory') then
        detected = 'qs'
    elseif resourceReady('qb-inventory') or resourceReady('ps-inventory') then
        detected = 'qb'
    elseif Bridge.Framework and Bridge.Framework.Name == 'esx' then
        detected = 'esx'
    else
        detected = nil
    end
end

Bridge.Inventory.Name = detected

-- =====================================================================
-- ox_inventory
-- =====================================================================
if detected == 'ox' then
    Bridge.Inventory.GetItemCount = function(src, item)
        local count = exports.ox_inventory:Search(src, 'count', item)
        return tonumber(count) or 0
    end

    Bridge.Inventory.RemoveItem = function(src, item, count)
        return exports.ox_inventory:RemoveItem(src, item, count or 1)
    end

-- =====================================================================
-- qs-inventory
-- =====================================================================
elseif detected == 'qs' then
    Bridge.Inventory.GetItemCount = function(src, item)
        local it = exports['qs-inventory']:GetItemByName(src, item)
        return it and (it.amount or it.count) or 0
    end

    Bridge.Inventory.RemoveItem = function(src, item, count)
        local ok = exports['qs-inventory']:RemoveItem(src, item, count or 1)
        return ok ~= false
    end

-- =====================================================================
-- qb-inventory / ps-inventory (deu chay qua Player.Functions cua qb-core)
-- =====================================================================
elseif detected == 'qb' then
    Bridge.Inventory.GetItemCount = function(src, item)
        local Player = Bridge.Framework.GetPlayer(src)
        if not Player then return 0 end
        local it = Player.Functions.GetItemByName(item)
        return it and it.amount or 0
    end

    Bridge.Inventory.RemoveItem = function(src, item, count)
        local Player = Bridge.Framework.GetPlayer(src)
        if not Player then return false end
        return Player.Functions.RemoveItem(item, count or 1)
    end

-- =====================================================================
-- ESX (inventory mac dinh, khong dung addon rieng)
-- =====================================================================
elseif detected == 'esx' then
    Bridge.Inventory.GetItemCount = function(src, item)
        local xPlayer = Bridge.Framework.GetPlayer(src)
        if not xPlayer then return 0 end
        local it = xPlayer.getInventoryItem(item)
        return it and it.count or 0
    end

    Bridge.Inventory.RemoveItem = function(src, item, count)
        local xPlayer = Bridge.Framework.GetPlayer(src)
        if not xPlayer then return false end
        xPlayer.removeInventoryItem(item, count or 1)
        return true
    end

else
    print('^1[s82_vehitems] KHONG THE NHAN DIEN HE THONG TUI DO! Vui long dat Config.Inventory thu cong (ox / qs / qb / esx).^0')
end
