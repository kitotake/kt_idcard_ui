fx_version 'cerulean'
game 'gta5'

name        'kt_idcard_ui'
author      'Kitotake'
description 'Système UI carte identité premium v3 — 9 types + 3 cartes bancaires + boutique documents'
version     '3.3.0'

dependencies {
    'oxmysql',
    'kt_lib',
    'union',
    'kt_context',
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*.js',
    'web/dist/assets/*.css',
}

shared_scripts {
    '@kt_lib/init.lua',
    'shared/config/config.lua',
}

client_scripts {
    'client/logger_client.lua', -- EN PREMIER
    'client/main.lua',
    'client/shop_ped.lua',
    'client/photo_capture.lua',
    -- npc_helpers.lua retiré : n'était pas utilisé
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logger.lua',
    'server/main.lua',
    'server/shop.lua',
    'server/photo_save.lua',
}

server_exports {
    'ShowCard',
    'UseIdentityCard',
    'UseLicenseCard',
    'UseWeaponCard',
    'UsePoliceCard',
    'UseEMSCard',
    'UsePassport',
}
