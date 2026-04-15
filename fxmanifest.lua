fx_version 'cerulean'
games { 'gta5' }

author 'Antigravity'
description 'Standalone EMS Dispatch System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/server.lua'
}

ui_page 'web/index.html'

files {
    'web/index.html',
    'web/style.css',
    'web/app.js',
    'web/fonts/*.woff2',
    'web/img/*.png'
}

dependency 'qbx_core'
dependency 'oxmysql'
dependency 'ox_lib'
