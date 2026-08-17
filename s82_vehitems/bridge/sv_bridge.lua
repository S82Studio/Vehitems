-- =====================================================================
-- S82Studio - BRIDGE FRAMEWORK (SERVER)
-- Tu dong nhan dien framework: ESX / QBCore / QBox
-- Chuan hoa cac ham dung chung: GetPlayer, GetIdentifier, Notify,
-- CreateUseableItem, GeneratePlate
-- =====================================================================

Bridge = Bridge or {}
Bridge.Framework = {}
Bridge.Utils = Bridge.Utils or {}

local function resourceReady(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

-- Bo sinh bien so noi bo, dung khi framework khong co san ham rieng
-- Ho tro cu phap: '1' = so ngau nhien, 'A' = chu cai ngau nhien, ky tu khac giu nguyen
local function generatePlateGeneric()
    local format = Config.PlateFormat or '11AAA111'
    local letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local plate = ''

    for i = 1, #format do
        local c = format:sub(i, i)
        if c == '1' then
            plate = plate .. tostring(math.random(0, 9))
        elseif c == 'A' then
            local idx = math.random(1, #letters)
            plate = plate .. letters:sub(idx, idx)
        else
            plate = plate .. c
        end
    end

    return plate
end
Bridge.Utils.GeneratePlate = generatePlateGeneric

-- =====================================================================
-- NHAN DIEN FRAMEWORK
-- =====================================================================
local detected = Config.Framework
if detected == 'auto' then
    if resourceReady('qbx_core') then
        detected = 'qbx'
    elseif resourceReady('qb-core') then
        detected = 'qb'
    elseif resourceReady('es_extended') then
        detected = 'esx'
    else
        detected = nil
    end
end

Bridge.Framework.Name = detected

-- =====================================================================
-- QBOX (qbx_core)
-- =====================================================================
if detected == 'qbx' then
    Bridge.Framework.GetPlayer = function(src)
        return exports.qbx_core:GetPlayer(src)
    end

    Bridge.Framework.GetIdentifier = function(src)
        local p = Bridge.Framework.GetPlayer(src)
        return p and p.PlayerData and p.PlayerData.citizenid or nil
    end

    Bridge.Framework.Notify = function(src, msg, ntype)
        exports.qbx_core:Notify(src, msg, ntype or 'inform')
    end

    Bridge.Framework.CreateUseableItem = function(item, cb)
        exports.qbx_core:CreateUseableItem(item, cb)
    end

    Bridge.Framework.GeneratePlate = generatePlateGeneric

-- =====================================================================
-- QBCORE (qb-core)
-- =====================================================================
elseif detected == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()
    Bridge.QBCore = QBCore

    Bridge.Framework.GetPlayer = function(src)
        return QBCore.Functions.GetPlayer(src)
    end

    Bridge.Framework.GetIdentifier = function(src)
        local p = Bridge.Framework.GetPlayer(src)
        return p and p.PlayerData and p.PlayerData.citizenid or nil
    end

    Bridge.Framework.Notify = function(src, msg, ntype)
        QBCore.Functions.Notify(src, msg, ntype or 'primary')
    end

    Bridge.Framework.CreateUseableItem = function(item, cb)
        QBCore.Functions.CreateUseableItem(item, cb)
    end

    Bridge.Framework.GeneratePlate = function()
        if QBCore.Functions.GeneratePlate then
            local ok, plate = pcall(QBCore.Functions.GeneratePlate)
            if ok and plate then return plate end
        end
        return generatePlateGeneric()
    end

-- =====================================================================
-- ESX (es_extended)
-- =====================================================================
elseif detected == 'esx' then
    local ESX = exports['es_extended']:getSharedObject()
    Bridge.ESX = ESX

    Bridge.Framework.GetPlayer = function(src)
        return ESX.GetPlayerFromId(src)
    end

    Bridge.Framework.GetIdentifier = function(src)
        local p = Bridge.Framework.GetPlayer(src)
        return p and p.identifier or nil
    end

    Bridge.Framework.Notify = function(src, msg, ntype)
        TriggerClientEvent('esx:showNotification', src, msg)
    end

    Bridge.Framework.CreateUseableItem = function(item, cb)
        ESX.RegisterUsableItem(item, function(source)
            cb(source, nil)
        end)
    end

    Bridge.Framework.GeneratePlate = generatePlateGeneric

else
    print('^1[s82_vehitems] KHONG THE NHAN DIEN FRAMEWORK! Vui long dat Config.Framework thu cong (esx / qb / qbx).^0')
end
