fx_version 'cerulean'
game 'gta5'

name        'kt_idcard_ui'
author      'Kitotake'
description "arte d'identité + Permis de conduire — bridge Union / kt_inventory / kt_interact / kt_target"
version     '2.0.0'

-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
-- DÉPENDANCES OBLIGATOIRES
-- union doit être démarré avant ce module.
-- kt_inventory, kt_interact, kt_target sont optionnels
-- (le code gère leur absence avec pcall/GetResourceState).
-- ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
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
    'ShowIdentity',       -- exports["kt_idcard_ui"]:ShowIdentity(src)
    'UseIdentityCard',    -- callback item kt_inventory (export-based)
    'UseLicenseCard',     -- callback item permis kt_inventory (export-based)
}