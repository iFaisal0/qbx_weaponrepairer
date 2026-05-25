local serialCooldowns = {}

local function dbg(...)
	if Config.Settings.Debug then
		print("[qbx_weaponrepairer]", ...)
	end
end

local function getWeaponDef(itemName)
	if type(itemName) ~= "string" then
		return Config.Defaults
	end
	return Config.Weapons[string.lower(itemName)] or Config.Defaults
end

local function nearAnyTable(coords)
	if not coords then
		return false
	end
	for _, t in ipairs(Config.Tables) do
		local d = #(vec3(coords.x, coords.y, coords.z) - vec3(t.coords.x, t.coords.y, t.coords.z))
		if d < 3.5 then
			return true
		end
	end
	return false
end

local function hasAllMaterials(src, materials)
	if not materials then
		return true
	end
	for item, amount in pairs(materials) do
		local count = Inventory.search(src, "count", item) or 0
		if (count or 0) < amount then
			return false, item, amount, count or 0
		end
	end
	return true
end

local function removeMaterials(src, materials)
	if not materials then
		return true
	end
	for item, amount in pairs(materials) do
		if not Inventory.removeItem(src, item, amount) then
			return false
		end
	end
	return true
end

local function resolvePayment(src, def, preferredPay)
	local mode = Config.Settings.CostType
	local account = Config.Settings.MoneyType

	if mode == "items" then
		local ok, missingItem, needed, have = hasAllMaterials(src, def.materials)
		if not ok then
			return false, nil, ("Missing %sx %s (have %s)"):format(needed, missingItem, have)
		end
		return true, "items"
	elseif mode == "money" then
		if Framework.getPlayerMoney(src, account) < (def.price or 0) then
			return false, nil, ("Need $%s in %s"):format(def.price or 0, account)
		end
		return true, "money"
	elseif mode == "both" then
		local ok, missingItem, needed, have = hasAllMaterials(src, def.materials)
		if not ok then
			return false, nil, ("Missing %sx %s (have %s)"):format(needed, missingItem, have)
		end
		if Framework.getPlayerMoney(src, account) < (def.price or 0) then
			return false, nil, ("Need $%s in %s"):format(def.price or 0, account)
		end
		return true, "both"
	end

	return false, nil, "Invalid CostType in config"
end

lib.callback.register("qbx_weaponrepairer:getWeapons", function(src)
	local weapons = Inventory.listWeapons(src) or {}

	for _, w in ipairs(weapons) do
		local def = getWeaponDef(w.name)
		w.time = def.time
		w.price = def.price or 0
		w.materials = def.materials
	end

	return weapons
end)

lib.callback.register("qbx_weaponrepairer:repair", function(src, payload)
	if type(payload) ~= "table" then
		return false, "Bad payload"
	end

	local itemName = payload.itemName
	local serial = payload.serial
	local slotId = payload.slot
	local playerPos = payload.coords
	local payPref = payload.payWith

	if type(itemName) ~= "string" or type(serial) ~= "string" or type(slotId) ~= "number" then
		return false, "Bad payload"
	end

	if not nearAnyTable(playerPos) then
		return false, "You are not at a repair table"
	end

	local def = getWeaponDef(itemName)
	if not def then
		return false, "This weapon cannot be repaired"
	end

	local now = os.time()
	local cdUntil = serialCooldowns[serial]
	if cdUntil and now < cdUntil then
		return false, ("On cooldown for %ss"):format(cdUntil - now)
	end

	local slot = Inventory.getWeaponBySerial(src, itemName, serial)
	if not slot then
		dbg(("repair: no slot found for %s serial=%s (player %s)"):format(itemName, serial, src))
		return false, "Weapon not found in inventory"
	end
	if slot.slot ~= slotId then
		dbg(("repair: slot id mismatch — server=%s client=%s"):format(slot.slot, slotId))
		return false, "Weapon slot mismatch"
	end

	local currentDur = (slot.metadata and slot.metadata.durability) or 0
	if currentDur >= 100 then
		return false, "Weapon is already in perfect condition"
	end

	local ok, payWith, err = resolvePayment(src, def, payPref)
	if not ok then
		return false, err
	end

	return true, {
		time = def.time,
		payWith = payWith,
		repairAmount = def.repairAmount,
	}
end)

lib.callback.register("qbx_weaponrepairer:finalize", function(src, payload)
	if type(payload) ~= "table" then
		return false, "Bad payload"
	end

	local itemName = payload.itemName
	local serial = payload.serial
	local slotId = payload.slot
	local payWith = payload.payWith
	local playerPos = payload.coords

	if not nearAnyTable(playerPos) then
		return false, "You left the workbench"
	end

	local def = getWeaponDef(itemName)
	if not def then
		return false, "Unknown weapon"
	end

	local slot = Inventory.getWeaponBySerial(src, itemName, serial)
	if not slot or slot.slot ~= slotId then
		return false, "Weapon not found in inventory"
	end

	local now = os.time()
	local cdUntil = serialCooldowns[serial]
	if cdUntil and now < cdUntil then
		return false, ("On cooldown for %ss"):format(cdUntil - now)
	end

	local ok, resolved, err = resolvePayment(src, def, payWith)
	if not ok then
		return false, err
	end

	if resolved == "items" or resolved == "both" then
		if not removeMaterials(src, def.materials) then
			return false, "Failed to remove materials"
		end
	end
	if resolved == "money" or resolved == "both" then
		local price = def.price or 0
		if price > 0 then
			if not Framework.removePlayerMoney(src, Config.Settings.MoneyType, price, "weapon-repair") then
				return false, "Failed to charge money"
			end
		end
	end

	local newMeta = {}
	for k, v in pairs(slot.metadata or {}) do
		newMeta[k] = v
	end

	local repairAmount = def.repairAmount
	local currentDur = newMeta.durability or 0
	local newDur = math.min(100, currentDur + repairAmount)
	newMeta.durability = newDur

	Inventory.updateWeaponDurability(src, slot.slot, newMeta, slot.name or itemName)

	local cd = def.cooldown
	serialCooldowns[serial] = now + cd

	dbg(
		("player %s repaired %s (serial %s) %s -> %s, paid via %s"):format(
			src,
			itemName,
			serial,
			currentDur,
			newDur,
			resolved
		)
	)

	return true, {
		newDurability = newDur,
		cooldown = cd,
	}
end)

CreateThread(function()
	while true do
		Wait(60000 * 10)
		local now = os.time()
		for serial, ts in pairs(serialCooldowns) do
			if ts <= now then
				serialCooldowns[serial] = nil
			end
		end
	end
end)
