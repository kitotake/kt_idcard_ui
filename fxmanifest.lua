fx_version 'cerulean'
game 'gta5'

name        'kt_idcard_ui'
author      'Kitotake'
description "Module carte d'identité — bridge Union / kt_inventory / kt_interact"
version     '1.0.0'

dependencies {
    'oxmysql',
    'kt_lib',
    'union',
}

ui_page 'html/identity.html'

files {
    'html/identity.html',
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
    'ShowIdentity',      
    'UseIdentityCard',
}