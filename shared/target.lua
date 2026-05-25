Target = {}

local function dbg(...)
	if Config.Settings.Debug then
		print("[qbx_weaponrepairer:target]", ...)
	end
end

local function detectTarget()
	local target = Config.Settings.target
	if target == "ox_target" or target == "ox" then
		return "ox"
	elseif target == "qb-target" or target == "qb" then
		return "qb"
	elseif target == "custom" then
		return "custom"
	end

	if GetResourceState("ox_target") == "started" then
		dbg("Detected ox_target")
		return "ox"
	elseif GetResourceState("qb-target") == "started" then
		dbg("Detected qb-target")
		return "qb"
	end

	dbg("WARNING: Could not detect target, defaulting to ox_target")
	return "ox"
end

function Target.addEntity(entity, opts)
	if not entity or entity == 0 then
		return
	end
	local target = detectTarget()

	if target == "ox" then
		exports.ox_target:addLocalEntity(entity, {
			{
				name = opts.name,
				label = opts.label,
				icon = opts.icon,
				distance = opts.distance or 2.0,
				onSelect = opts.onSelect,
				canInteract = opts.canInteract,
			},
		})
	elseif target == "qb" then
		exports["qb-target"]:AddTargetEntity(entity, {
			options = {
				{
					type = "client",

					action = opts.onSelect,
					icon = opts.icon,
					label = opts.label,
					canInteract = opts.canInteract,
				},
			},
			distance = opts.distance or 2.0,
		})
	end
end

function Target.removeEntity(entity, opts)
	if not entity or entity == 0 then
		return
	end
	local target = detectTarget()

	if target == "ox" then
		exports.ox_target:removeLocalEntity(entity, opts and opts.name or nil)
	elseif target == "qb" then
		exports["qb-target"]:RemoveTargetEntity(entity, opts and opts.label or nil)
	end
end

return Target
