fx_version 'cerulean'
game 'gta5'

description 'Affichage des armes dans le dos - Compatible ESX/Core'
version '1.0.0'

shared_scripts {
    '@es_extended/imports.lua', -- Importation automatique d'ESX (Legacy)
    'config.lua'
}

client_scripts {
    'editable.lua',
    'client.lua'
}

server_script 'server.lua'

files {
    'data.json'
}