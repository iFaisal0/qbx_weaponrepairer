Config = {}

Config.Settings = {

	Framework = "auto", -- 'qbx', qb 'custom'
	Inventory = "auto", -- 'ox', 'qb', 'custom'
	target = "auto", -- 'auto', 'ox_target', 'qb-target', 'custom'
	Debug = false,

	-- 'items'
	-- 'money'
	-- 'both'
	CostType = "items",

	-- 'cash', 'bank'
	MoneyType = "cash",

	BrowseAnim = {
		dict = "anim@amb@business@weed@weed_inspecting_lo_med_hi@",
		clip = "weed_crouch_checkingleaves_idle_02_inspector",
		flag = 49,
	},

	Anim = {
		dict = "mini@repair",
		clip = "fixing_a_ped",

		flag = 16,
	},
}

Config.Tables = {
	{
		coords = vec4(861.17, -2507.84, 48.32, 85.0),
		model = `gr_prop_gr_bench_02a`,
		label = "Weapon Repair Bench",
		blip = { enabled = false, sprite = 110, color = 1, scale = 0.7 },
	},
	-- {
	-- 	coords = vec4(-1156.85, -1518.96, 10.63, 35.0),
	-- 	model  = `gr_prop_gr_bench_03b`,
	-- 	label  = 'Weapon Repair Bench',
	-- 	blip   = { enabled = false },
	-- },
}

Config.Weapons = {
	["weapon_pistol"] = {
		repairAmount = 50,
		time = 8,
		cooldown = 300,
		price = 500,
		materials = {
			["steel"] = 50,
			["rubber"] = 30,
		},
	},
	["weapon_heavypistol"] = {
		repairAmount = 50,
		time = 30,
		cooldown = 300,
		price = 4500,
		materials = {
			["steel"] = 350,
			["rubber"] = 270,
			["plastic"] = 370,
		},
	},
	["weapon_snspistol"] = {
		repairAmount = 50,
		time = 8,
		cooldown = 300,
		price = 500,
		materials = {
			["steel"] = 40,
			["rubber"] = 30,
		},
	},
	["weapon_ceramicpistol"] = {
		repairAmount = 50,
		time = 9,
		cooldown = 300,
		price = 1200,
		materials = {
			["steel"] = 70,
			["rubber"] = 65,
			["plastic"] = 60,
		},
	},
	["weapon_combatpistol"] = {
		repairAmount = 50,
		time = 10,
		cooldown = 300,
		price = 1500,
		materials = {
			["steel"] = 70,
			["rubber"] = 100,
			["plastic"] = 50,
		},
	},
	["weapon_pistol50"] = {
		repairAmount = 50,
		time = 35,
		cooldown = 300,
		price = 7500,
		materials = {
			["steel"] = 320,
			["rubber"] = 270,
			["plastic"] = 350,
		},
	},
	["weapon_pistol_mk2"] = {
		repairAmount = 50,
		time = 15,
		cooldown = 600,
		price = 4500,
		materials = {
			["steel"] = 310,
			["rubber"] = 230,
			["plastic"] = 340,
		},
	},
	["weapon_vintagepistol"] = {
		repairAmount = 50,
		time = 15,
		cooldown = 900,
		price = 3000,
		materials = {
			["steel"] = 400,
			["rubber"] = 150,
			["plastic"] = 200,
		},
	},
}
-- Other weapons
Config.Defaults = {
	repairAmount = 25,
	time = 30,
	cooldown = 600,
	price = 10000,
	materials = {
		["steel"] = 150,
		["rubber"] = 250,
		["plastic"] = 100,
	},
}
