fx_version 'cerulean'
game 'gta5'

name        'kt_idcard_ui'
author      'Kitotake'
description 'Système UI carte d\'identité premium v3 — 9 types de cartes'
version     '3.0.0'

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
    'client/main.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

server_exports {
    'ShowCard',         -- exports["kt_idcard_ui"]:ShowCard(src, cardType, data)
    'UseIdentityCard',
    'UseLicenseCard',
    'UseWeaponCard',
    'UsePoliceCard',
    'UseEMSCard',
    'UsePassport',
}
