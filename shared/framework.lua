Framework = {}

local function dbg(...)
	if Config.Settings.Debug then
		print("[qbx_weaponrepairer:framework]", ...)
	end
end

local function detectFramework()
	local framework = Config.Settings.Framework
	if framework == "qbx" then
		return "qbx"
	elseif framework == "qb" then
		return "qb"
	elseif framework == "custom" then
		return "custom"
	end

	if GetResourceState("qbx_core") == "started" then
		dbg("Detected QBX framework")
		return "qbx"
	elseif GetResourceState("qb-core") == "started" then
		dbg("Detected QB-Core framework")
		return "qb"
	end

	dbg("WARNING: Could not detect framework, defaulting to qbx")
	return "qbx"
end

function Framework.getPlayer(src)
	local fw = detectFramework()

	if fw == "qbx" then
		return exports.qbx_core:GetPlayer(src)
	elseif fw == "qb" then
		return exports["qb-core"]:GetPlayer(src)
	end

	return nil
end

function Framework.getPlayerMoney(src, account)
	local player = Framework.getPlayer(src)
	if not player then
		return 0
	end

	local fw = detectFramework()

	if fw == "qbx" then
		return player.PlayerData.money[account] or 0
	elseif fw == "qb" then
		return player.PlayerData.money[account] or 0
	end

	return 0
end

function Framework.removePlayerMoney(src, account, amount, reason)
	local player = Framework.getPlayer(src)
	if not player then
		return false
	end

	local fw = detectFramework()

	if fw == "qbx" then
		return player.Functions.RemoveMoney(account, amount, reason)
	elseif fw == "qb" then
		return player.Functions.RemoveMoney(account, amount, reason)
	end

	return false
end

function Framework.addPlayerMoney(src, account, amount, reason)
	local player = Framework.getPlayer(src)
	if not player then
		return false
	end

	local fw = detectFramework()

	if fw == "qbx" then
		return player.Functions.AddMoney(account, amount, reason)
	elseif fw == "qb" then
		return player.Functions.AddMoney(account, amount, reason)
	end

	return false
end

function Framework.notify(src, title, description, type)
	local fw = detectFramework()

	if fw == "qbx" then
		TriggerClientEvent("ox_lib:notify", src, {
			title = title,
			description = description,
			type = type or "info",
			duration = 5000,
		})
	elseif fw == "qb" then
		TriggerClientEvent("QBCore:Notify", src, description, type or "primary")
	end
end

return Framework
