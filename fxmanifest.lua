fx_version 'cerulean'
game 'gta5'

name        'kt_idcard_ui'
author      'Kitotake'
description 'Système UI carte identité premium v3 — 9 types + 3 cartes bancaires + boutique documents'
version     '3.2.0'

dependencies {
    'oxmysql',
    'kt_lib',
    'union',
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
    'client/logger_client.lua',
    'client/main.lua',
    'client/shop_ped.lua',      -- PNJ boutique documents
    'client/photo_capture.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'shared/config/config.lua',      -- si tu as une config partagée
    'server/logger.lua',      -- ← EN PREMIER, avant tout le reste
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
