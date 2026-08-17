fx_version 'cerulean'
game 'gta5'

author 'S82 Studio'
description 'S82Studio - Vehicle Item | Ho tro ESX / QBCore / QBox | Da inventory | Da ngon ngu'
version '3.0.0'

-- =====================================================================
-- LUU Y: Resource nay can ox_lib (dung cho progressBar, alertDialog,
-- getNearbyVehicles, getNearbyObjects). ox_lib hien duoc dung rong rai
-- tren ca ESX / QBCore / QBox nen day duoc coi la yeu cau bat buoc chung.
-- =====================================================================
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'locales/en.lua',
    'locales/vi.lua',
    'shared/sh_locale.lua',
}

client_scripts {
    'bridge/cl_bridge.lua',
    'client/cl_main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/sv_bridge.lua',
    'bridge/sv_inventory.lua',
    'bridge/sv_vehicle.lua',
    'server/sv_main.lua',
}

lua54 'yes'
