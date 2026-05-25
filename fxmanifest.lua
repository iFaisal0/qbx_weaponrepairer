fx_version("cerulean")
game("gta5")

name("qbx_weaponrepairer")
description("Weapon repair workbenches for QBX/QB-Core + ox_inventory/qb-inventory")
author("Faisal.")
version("1.0.0")

shared_scripts({
	"@ox_lib/init.lua",
	"shared/main.lua",
	"shared/framework.lua",
	"shared/inventory.lua",
	"shared/target.lua",
})

client_scripts({
	"client/*.lua",
})

server_scripts({
	"server/*.lua",
})

dependencies({
	"ox_lib",
})

lua54("yes")
