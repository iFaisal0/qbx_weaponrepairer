Inventory = {}

local function dbg(...)
	if Config.Settings.Debug then
		print("[qbx_weaponrepairer:inventory]", ...)
	end
end

local function detectInventory()
	local inventory = Config.Settings.Inventory
	if inventory == "ox" then
		return "ox"
	elseif inventory == "qb" then
		return "qb"
	elseif inventory == "custom" then
		return "custom"
	end

	if GetResourceState("ox_inventory") == "started" then
		dbg("Detected ox_inventory")
		return "ox"
	elseif GetResourceState("qb-inventory") == "started" then
		dbg("Detected qb-inventory")
		return "qb"
	end

	dbg("WARNING: Could not detect inventory, defaulting to ox")
	return "ox"
end

function Inventory.search(src, searchType, searchValue)
	local inv = detectInventory()

	if inv == "ox" then
		local invExport = exports.ox_inventory
		return invExport:Search(src, searchType, searchValue)
	elseif inv == "qb" then
		if searchType == "count" then
			return exports["qb-inventory"]:GetItemCount(src, searchValue) or 0
		elseif searchType == "slots" then
			local items = exports["qb-inventory"]:GetItemsByName(src, searchValue)
			if not items or #items == 0 then
				return nil
			end

			local results = {}
			for _, item in ipairs(items) do
				table.insert(results, {
					slot = item.slot,
					name = item.name,
					label = item.label,
					metadata = item.info or {},
					amount = item.amount,
				})
			end
			return #results > 0 and results or nil
		end
	end

	return nil
end

function Inventory.removeItem(src, item, amount)
	local inv = detectInventory()

	if inv == "ox" then
		local ok = exports.ox_inventory:RemoveItem(src, item, amount)
		return ok == true
	elseif inv == "qb" then
		return exports["qb-inventory"]:RemoveItem(src, item, amount, nil, "qbx_weaponrepairer")
	end

	return false
end

function Inventory.addItem(src, item, amount, metadata)
	local inv = detectInventory()

	if inv == "ox" then
		local invExport = exports.ox_inventory
		return invExport:AddItem(src, item, amount, metadata)
	elseif inv == "qb" then
		return exports["qb-inventory"]:AddItem(src, item, amount, nil, metadata or {}, "qbx_weaponrepairer")
	end

	return false
end

function Inventory.getItemsDefinition()
	local inv = detectInventory()

	if inv == "ox" then
		local invExport = exports.ox_inventory
		return invExport:Items()
	elseif inv == "qb" then
		return exports["qb-core"]:GetItemList()
	end

	return {}
end

function Inventory.getPlayerItems(src)
	local inv = detectInventory()

	if inv == "ox" then
		return exports.ox_inventory:GetInventoryItems(src) or {}
	elseif inv == "qb" then
		local player = exports["qb-core"]:GetPlayer(src)
		if not player then
			return {}
		end
		return player.PlayerData.items or {}
	end

	return {}
end

function Inventory.updateWeaponDurability(src, slot, metadata, itemName)
	local inv = detectInventory()

	if inv == "ox" then
		return exports.ox_inventory:SetMetadata(src, slot, metadata) ~= false
	elseif inv == "qb" then
		local info = type(metadata) == "table" and metadata or { durability = metadata }
		return exports["qb-inventory"]:SetItemData(src, itemName, "info", info, slot) ~= false
	end

	return false
end

function Inventory.getWeaponBySerial(src, itemName, serial)
	local inv = detectInventory()

	if inv == "ox" then
		local invExport = exports.ox_inventory

		local searchName = itemName
		if string.lower(searchName):sub(1, 7) == "weapon_" then
			searchName = string.upper(searchName)
		end

		local list = invExport:Search(src, "slots", searchName)
		if type(list) ~= "table" then
			return nil
		end

		for _, slot in pairs(list) do
			if slot and slot.metadata and slot.metadata.serial == serial then
				return slot
			end
		end
	elseif inv == "qb" then
		local items = exports["qb-inventory"]:GetItemsByName(src, itemName)

		if not items or #items == 0 then
			return nil
		end

		for _, item in ipairs(items) do
			local itemSerial = item.info and (item.info.serial or item.info.serie)
			if itemSerial == serial then
				return {
					slot = item.slot,
					name = item.name,
					label = item.label,
					metadata = item.info or {},
					amount = item.amount,
				}
			end
		end
	end

	return nil
end

function Inventory.listWeapons(src)
	local inv = detectInventory()
	local weapons = {}

	if inv == "ox" then
		local items = exports.ox_inventory:GetInventoryItems(src) or {}
		local defs = exports.ox_inventory:Items() or {}

		for _, slot in pairs(items) do
			if slot and slot.name and slot.metadata and slot.metadata.serial then
				local lower = string.lower(slot.name)
				if lower:sub(1, 7) == "weapon_" then
					local def = defs[slot.name] or defs[lower]
					weapons[#weapons + 1] = {
						name = lower,
						rawName = slot.name,
						label = (def and def.label) or slot.name,
						slot = slot.slot,
						serial = slot.metadata.serial,
						durability = slot.metadata.durability or 0,
					}
				end
			end
		end
	elseif inv == "qb" then
		local player = exports["qb-core"]:GetPlayer(src)
		if not player then
			return weapons
		end
		local items = player.PlayerData.items or {}

		for slotId, item in pairs(items) do
			if item and item.name then
				local lower = string.lower(item.name)
				local info = item.info or {}
				local serial = info.serial or info.serie
				if lower:sub(1, 7) == "weapon_" and serial then
					weapons[#weapons + 1] = {
						name = lower,
						rawName = item.name,
						label = item.label or item.name,
						slot = item.slot or slotId,
						serial = serial,
						durability = info.durability or info.quality or 0,
					}
				end
			end
		end
	end

	table.sort(weapons, function(a, b)
		return a.durability < b.durability
	end)
	return weapons
end

return Inventory
