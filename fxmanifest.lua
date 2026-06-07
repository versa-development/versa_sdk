fx_version 'cerulean'
lua54 'yes'
use_experimental_fxv2_oal 'yes'
dependencies {
  '/onesync', -- requires state awareness to be enabled
}

name 'versa_sdk'
author 'Versa Development'
version '1.0.1'
games { 'rdr3', 'gta5' }
description 'Core SDK for FiveM & RedM — modular systems, framework bridges & dev tools'

files {
  'config.lua',
  'data/*.lua',
  'bridge/**/**/*.lua',
  'modules/*.lua',
  'utils/*.lua',
}

shared_scripts {
  '@ox_lib/init.lua',
  'init.lua'
}

client_scripts {
  'runtime/**/client.lua',
}

server_scripts {
  'runtime/**/server.lua',
}