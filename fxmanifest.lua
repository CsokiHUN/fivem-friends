fx_version("cerulean")
game("gta5")
author("Csoki")

dependency("es_extended")
dependency("mysql") -- https://github.com/CsokiHUN/fivem-mysql

shared_script("@es_extended/imports.lua")
shared_script("shared.lua")

client_script("client.lua")
server_scripts({
	"@mysql/import.lua",
	"server.lua",
})

ui_page("ui/index.html")

files({
	"ui/*",
})
