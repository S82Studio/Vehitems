-- =====================================================================
-- S82Studio - BRIDGE FRAMEWORK (CLIENT)
-- Chi dung de chuan hoa thong bao (Notify) theo tung framework
-- =====================================================================

Bridge = Bridge or {}

local function resourceReady(name)
    local state = GetResourceState(name)
    return state == 'started' or state == 'starting'
end

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

Bridge.FrameworkName = detected

if detected == 'qbx' then
    Bridge.Notify = function(msg, ntype)
        exports.qbx_core:Notify(msg, ntype or 'inform')
    end

elseif detected == 'qb' then
    local QBCore = exports['qb-core']:GetCoreObject()
    Bridge.Notify = function(msg, ntype)
        QBCore.Functions.Notify(msg, ntype or 'primary')
    end

elseif detected == 'esx' then
    Bridge.Notify = function(msg, ntype)
        TriggerEvent('esx:showNotification', msg)
    end

else
    -- Fallback cuoi cung: dung ox_lib notify de khong bao gio bi loi thieu ham
    Bridge.Notify = function(msg, ntype)
        lib.notify({ description = msg, type = ntype or 'inform' })
    end
end
