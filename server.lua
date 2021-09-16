local thisResource = GetCurrentResourceName()

-- Internal resources that should never be shown
local internalResources = {
	["_cfx_internal"] = true
}

-- Default resources that should be hidden by default
local defaultResources = {
	["fivem"] = true,
	["hardcap"] = true,
	["chat"] = true,
	["example-loadscreen"] = true,
	["baseevents"] = true,
	["basic-gamemode"] = true,
	["chat-theme-gtao"] = true,
	["fivem-map-hipster"] = true,
	["fivem-map-skater"] = true,
	["harcap"] = true,
	["mapmanager"] = true,
	["money"] = true,
	["money-fountain"] = true,
	["money-fountain-example-map"] = true,
	["monitor"] = true,
	["ped-money-drops"] = true,
	["player-data"] = true,
	["playernames"] = true,
	["rconlog"] = true,
	["redm-map-one"] = true,
	["runcode"] = true,
	["sessionmanager"] = true,
	["sessionmanager-rdr3"] = true,
	["spawnmanager"] = true,
	["webadmin"] = true,
	["webpack"] = true,
	["yarn"] = true
}

-- Metadata to fetch for resources
local metadataNames = {
	"name",
	"version",
	"author",
	"description",
	"url",
	"repository"
}

-- Get all dependencies for a resource, and all dependencies for those
-- dependencies,and so on.
local function getDependencies(resource, dependencies)
	if not dependencies then
		dependencies = {}
	end

	for i = 0, GetNumResourceMetadata(resource, "dependency") - 1 do
		local dep = GetResourceMetadata(resource, "dependency", i)

		local traverse = not dependencies[dep]

		dependencies[dep] = true

		if traverse then
			getDependencies(dep, dependencies)
		end
	end

	return dependencies
end

-- Get all resources that depend on a resource.
local function getDependants(resource)
	local dependants = {}

	for i = 0, GetNumResources() - 1 do
		local otherResource = GetResourceByFindIndex(i)

		if getDependencies(otherResource)[resource] then
			dependants[otherResource] = true
		end
	end

	return dependants
end

-- Get the full chain of dependencies for resourcemanager. Stopping a
-- dependency anywhere in the chain can cause the server to crash!
local dependencies = getDependencies(thisResource)

-- Determine if resource can be omitted from the list
local function ignoreResource(resource)
	return resource == thisResource or internalResources[resource] or dependencies[resource]
end

-- Check if the number of arguments is what was expected
local function argCountMatches(args, wanted)
	if #args == wanted then
		return true
	else
		print(("Argument count mismatch (passed %d, wanted %d)"):format(#args, wanted))
		return false
	end
end

-- Detect if a resource is part of a circular dependency.
local function hasCircularDependency(resource)
	return getDependencies(resource)[resource] == true
end

-- Stop a resource, ignoring those which are part of a circular dependency
local function safelyStopResource(resource)
	if dependencies[resource] then
		print(("%s is a dependency of %s and cannot be stopped by it."):format(resource, thisResource))
		return false
	elseif hasCircularDependency(resource) then
		print(("Circular dependency detected. Stopping %s would cause the server to crash!"):format(resource))
		return false
	else
		StopResource(resource)
		return true
	end
end

-- Restart a resource, ignoring those which are part of a circular dependency
local function safelyRestartResource(resource)
	if dependencies[resource] then
		print(("%s is a dependency of %s and cannot be restarted by it."):format(resource, thisResource))
		return false
	elseif hasCircularDependency(resource) then
		print(("Circular dependency detected. Restarting %s would cause the server to crash!"):format(resource))
		return false
	else
		StopResource(resource)
		StartResource(resource)
		return true
	end
end

exports("safelyStopResource", safelyStopResource)
exports("safelyRestartResource", safelyRestartResource)

-- Restart a resource and all resources that depend on it automatically
RegisterCommand("restart_all", function(source, args, raw)
	if not argCountMatches(args, 1) then
		return
	end

	local targetResource = args[1]

	local resources = {}

	for i = 0, GetNumResources() - 1 do
		local resource = GetResourceByFindIndex(i)

		if GetResourceState(resource) == "started" then
			table.insert(resources, resource)
		end
	end

	if not safelyStopResource(targetResource) then
		return
	end

	for _, resource in ipairs(resources) do
		local deps = getDependencies(resource)

		if deps[targetResource] then
			StartResource(resource)
		end
	end
end, true)

-- Stop a resource, ignoring those in circular dependencies.
RegisterCommand("safe_stop", function(source, args, raw)
	if not argCountMatches(args, 1) then
		return
	end

	local resource = args[1]

	if GetResourceState(resource) == "started" then
		safelyStopResource(args[1])
	end
end, true)

-- Restart a resource, ignoring those in circular dependencies.
RegisterCommand("safe_restart", function(source, args, raw)
	if not argCountMatches(args, 1) then
		return
	end

	local resource = args[1]

	if GetResourceState(resource) == "stopped" then
		safelyRestartResource(resource)
	end
end, true)

-- Ensure a resource, ignoring those in circular dependencies.
RegisterCommand("safe_ensure", function(source, args, raw)
	if not argCountMatches(args, 1) then
		return
	end

	safelyRestartResource(args[1])
end, true)

-- List all dependencies (direct and indirect) of a resource.
RegisterCommand("list_dependencies", function(source, args, raw)
	if not argCountMatches(args, 1) then
		return
	end

	for dependency, _ in pairs(getDependencies(args[1])) do
		print(dependency)
	end
end, true)

-- List all resources that depend on a resource (directly or indirectly).
RegisterCommand("list_dependants", function(source, args, raw)
	if not argCountMatches(args, 1) then
		return
	end

	for dependant, _ in pairs(getDependants(args[1])) do
		print(dependant)
	end
end, true)

-- Start/stop managed resources
Citizen.CreateThread(function()
	while true do
		local time = os.date("*t")

		for resource, condition in pairs(config.managedResources) do
			if condition(time) then
				if GetResourceState(resource) == "stopped" then
					print("Starting resource " .. resource)
					StartResource(resource)
				end
			else
				if GetResourceState(resource) == "started" then
					print("Stopping resource " .. resource)
					safelyStopResource(resource)
				end
			end
		end

		Citizen.Wait(60000)
	end
end)

SetHttpHandler(exports.httpmanager:createHttpHandler{
	authorization = config.authorization,
	routes = {
		["^/resources$"] = function(req, res, helpers)
			local resources = {}

			for i = 0, GetNumResources() - 1 do
				local resourceName = GetResourceByFindIndex(i)

				if not ignoreResource(resourceName) then
					local metadata = {}

					for _, metadataName in ipairs(metadataNames) do
						metadata[metadataName] = GetResourceMetadata(resourceName, metadataName, 0)
					end

					table.insert(resources, {
						name = resourceName,
						path = GetResourcePath(resourceName),
						state = GetResourceState(resourceName),
						metadata = metadata,
						isDefaultResource = defaultResources[resourceName],
						isManagedResource = config.managedResources[resourceName]
					})
				end
			end

			res.sendJson(resources)
		end,

		["^/start/(.+)$"] = function(req, res, helpers, resource)
			StartResource(resource)
			res.sendJson{}
		end,

		["^/stop/(.+)$"] = function(req, res, helpers, resource)
			safelyStopResource(resource)
			res.sendJson{}
		end,

		["^/restart/(.+)$"] = function(req, res, helpers, resource)
			safelyRestartResource(resource)
			res.sendJson{}
		end,

		["^/refresh$"] = function(req, res, helpers)
			ExecuteCommand("refresh")
			res.sendJson{}
		end
	}
})
