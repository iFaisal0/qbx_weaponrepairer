local spawnedProps = {}
local spawnedBlips = {}
local isSetup = false

local function dbg(...)
	if Config.Settings.Debug then
		print("[qbx_weaponrepairer]", ...)
	end
end

local function loadModel(model)
	if not IsModelInCdimage(model) then
		return false
	end
	RequestModel(model)
	local timeout = GetGameTimer() + 5000
	while not HasModelLoaded(model) and GetGameTimer() < timeout do
		Wait(10)
	end
	return HasModelLoaded(model)
end

local function spawnTable(tbl)
	if not loadModel(tbl.model) then
		dbg("failed to load model", tbl.model)
		return
	end
	local c = tbl.coords
	local obj = CreateObject(tbl.model, c.x, c.y, c.z - 1.0, false, false, false)
	SetEntityHeading(obj, c.w or 0.0)
	FreezeEntityPosition(obj, true)
	SetEntityInvincible(obj, true)
	PlaceObjectOnGroundProperly(obj)
	SetModelAsNoLongerNeeded(tbl.model)
	return obj
end

local function Blipli(tbl)
	if not tbl.blip or not tbl.blip.enabled then
		return
	end
	local b = AddBlipForCoord(tbl.coords.x, tbl.coords.y, tbl.coords.z)
	SetBlipSprite(b, tbl.blip.sprite or 110)
	SetBlipColour(b, tbl.blip.color or 1)
	SetBlipScale(b, tbl.blip.scale or 0.7)
	SetBlipAsShortRange(b, true)
	BeginTextCommandSetBlipName("STRING")
	AddTextComponentSubstringPlayerName(tbl.label or "Weapon Repair")
	EndTextCommandSetBlipName(b)
	return b
end

local function getWeaponDef(itemName)
	return Config.Weapons[itemName] or Config.Defaults
end

local function materialsToString(materials)
	if not materials then
		return "None"
	end
	local parts = {}
	for item, amount in pairs(materials) do
		parts[#parts + 1] = ("%sx %s"):format(amount, item)
	end
	if #parts == 0 then
		return "None"
	end
	return table.concat(parts, ", ")
end

local function costSummary(def)
	local mode = Config.Settings.CostType
	if mode == "items" then
		return "Items: " .. materialsToString(def.materials)
	elseif mode == "money" then
		return ("$%s (%s)"):format(def.price or 0, Config.Settings.MoneyType)
	elseif mode == "both" then
		return ("Items: %s  +  $%s"):format(materialsToString(def.materials), def.price or 0)
	end
	return ""
end

local function listPlayerWeapons()
	local weapons = lib.callback.await("qbx_weaponrepairer:getWeapons", false)
	if Config.Settings.Debug then
		print("[qbx_weaponrepairer] weapons returned:", weapons and #weapons or 0)
	end
	return weapons or {}
end

local browsing = false

local function startBrowseAnim()
	if browsing then
		return
	end
	local cfg = Config.Settings.BrowseAnim
	if not cfg or not cfg.dict or not cfg.clip then
		return
	end
	browsing = true
	CreateThread(function()
		lib.requestAnimDict(cfg.dict)
		if not browsing then
			return
		end
		TaskPlayAnim(cache.ped, cfg.dict, cfg.clip, 4.0, -4.0, -1, cfg.flag or 49, 0, false, false, false)
	end)
end

local function stopBrowseAnim()
	if not browsing then
		return
	end
	browsing = false
	local cfg = Config.Settings.BrowseAnim
	if cfg and cfg.dict and cfg.clip and IsEntityPlayingAnim(cache.ped, cfg.dict, cfg.clip, 3) then
		StopAnimTask(cache.ped, cfg.dict, cfg.clip, 2.0)
	end
end

local function ListenToContext()
	CreateThread(function()
		local rootId = "qbx_weaponrepairer:menu"
		local subPrefix = "qbx_weaponrepairer:pay:"
		while browsing do
			Wait(250)
			local open = lib.getOpenContextMenu()
			if not open or (open ~= rootId and open:sub(1, #subPrefix) ~= subPrefix) then
				stopBrowseAnim()
				break
			end
		end
	end)
end

local repairing = false

local function playRepairAnim()
	local ped = cache.ped
	local cfg = Config.Settings.Anim
	lib.requestAnimDict(cfg.dict)

	local flag = (cfg.flag or 0) | 1

	repairing = true
	TaskPlayAnim(ped, cfg.dict, cfg.clip, 8.0, -8.0, -1, flag, 0, false, false, false)

	CreateThread(function()
		while repairing do
			if not IsEntityPlayingAnim(ped, cfg.dict, cfg.clip, 3) then
				TaskPlayAnim(ped, cfg.dict, cfg.clip, 8.0, -8.0, -1, flag, 0, false, false, false)
			end
			Wait(500)
		end
	end)

	local propCfg = cfg.prop
	if propCfg and propCfg.model then
		lib.requestModel(propCfg.model)
		local x, y, z = table.unpack(GetEntityCoords(ped))
		local prop = CreateObject(propCfg.model, x, y, z, true, true, false)
		AttachEntityToEntity(
			prop,
			ped,
			GetPedBoneIndex(ped, propCfg.bone or 28422),
			propCfg.pos.x,
			propCfg.pos.y,
			propCfg.pos.z,
			propCfg.rot.x,
			propCfg.rot.y,
			propCfg.rot.z,
			true,
			true,
			false,
			true,
			1,
			true
		)
		return prop
	end
end

local function stopRepairAnim(prop)
	repairing = false
	ClearPedTasks(cache.ped)
	if prop and DoesEntityExist(prop) then
		DeleteEntity(prop)
	end
end

local function WRepair(weapon, payWith)
	local coords = GetEntityCoords(cache.ped)
	local payload = {
		itemName = weapon.name,
		serial = weapon.serial,
		slot = weapon.slot,
		coords = vec3(coords.x, coords.y, coords.z),
		payWith = payWith,
	}

	local ok, result = lib.callback.await("qbx_weaponrepairer:repair", false, payload)
	if not ok then
		lib.notify({ type = "error", description = result or "Cannot repair" })
		return
	end

	local prop = playRepairAnim()

	local finished = lib.progressCircle({
		duration = (result.time or 8) * 1000,
		label = ("Repairing %s..."):format(weapon.label),
		position = "bottom",
		useWhileDead = false,
		canCancel = true,
		disable = { car = true, move = true, combat = true },
	})

	stopRepairAnim(prop)

	if not finished then
		lib.notify({ type = "error", description = "Repair cancelled" })
		return
	end

	local coords2 = GetEntityCoords(cache.ped)
	local okFinal, finalResult = lib.callback.await("qbx_weaponrepairer:finalize", false, {
		itemName = weapon.name,
		serial = weapon.serial,
		slot = weapon.slot,
		payWith = result.payWith,
		coords = vec3(coords2.x, coords2.y, coords2.z),
	})

	if not okFinal then
		lib.notify({ type = "error", description = finalResult or "Repair failed" })
		return
	end

	lib.notify({
		type = "success",
		description = ("%s repaired to %s%% durability"):format(weapon.label, math.floor(finalResult.newDurability)),
	})
end

local function openWeaponMenu()
	local weapons = listPlayerWeapons()
	if #weapons == 0 then
		lib.notify({ type = "error", description = "You have no weapons to repair" })
		return
	end

	local options = {}
	for _, w in ipairs(weapons) do
		local def = getWeaponDef(w.name)
		local description = ("Durability: %s%%  |  Time: %ss  |  %s"):format(
			math.floor(w.durability),
			def.time,
			costSummary(def)
		)

		options[#options + 1] = {
			title = w.label,
			description = description,
			metadata = { Serial = w.serial },
			onSelect = function()
				WRepair(w)
			end,
		}
	end

	lib.registerContext({
		id = "qbx_weaponrepairer:menu",
		title = "Weapon Repair Bench",
		options = options,
		onExit = stopBrowseAnim,
	})

	startBrowseAnim()
	lib.showContext("qbx_weaponrepairer:menu")
	ListenToContext()
end

local function SpawnTables()
	if isSetup then
		return
	end
	isSetup = true
	for i, tbl in ipairs(Config.Tables) do
		local obj = spawnTable(tbl)
		if obj then
			local optName = "qbx_weaponrepairer:open:" .. i

			spawnedProps[#spawnedProps + 1] = { entity = obj, optName = optName }
			Target.addEntity(obj, {
				name = optName,
				label = "Repair Weapon",
				icon = "fa-solid fa-wrench",
				distance = 2.0,
				onSelect = openWeaponMenu,
			})
		end
		local b = Blipli(tbl)
		if b then
			spawnedBlips[#spawnedBlips + 1] = b
		end
	end
end

local function DeleteTables()
	for _, p in ipairs(spawnedProps) do
		if DoesEntityExist(p.entity) then
			Target.removeEntity(p.entity, {
				name = p.optName,
				label = "Repair Weapon",
			})
			DeleteEntity(p.entity)
		end
	end
	for _, b in ipairs(spawnedBlips) do
		if DoesBlipExist(b) then
			RemoveBlip(b)
		end
	end
	spawnedProps, spawnedBlips = {}, {}
	isSetup = false
end
RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
	SpawnTables()
end)

AddEventHandler("onResourceStart", function(res)
	if res ~= GetCurrentResourceName() then
		return
	end
	SpawnTables()
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
	DeleteTables()
end)

AddEventHandler("onResourceStop", function(res)
	if res ~= GetCurrentResourceName() then
		return
	end
	DeleteTables()
end)
