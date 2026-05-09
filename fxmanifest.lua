fx_version 'cerulean'
game 'gta5'

name 'kt_idcard_ui'
author 'Kitotake'
description 'Module d\'identité pour FiveM'
version '1.0.0'

dependencies {
    'oxmysql',
    'kt_lib',
    'kt_inventory'
}

ui_page 'html/identity.html'

files {
    'html/identity.html',
}

shared_scripts {
    '@kt_lib/init.lua',
    'shared/config/config.lua',
    'shared/locales/fr.lua'
}

client_scripts {
    'client/main.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

server_exports {
    'GiveCharacter',    -- (si pas encore ajouté)
    'ShowIdentity',     
}