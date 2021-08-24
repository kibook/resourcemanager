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

-- Dependency chain for resourcemanager
local dependencies = {}

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
local function addDependencies(resource)
	for i = 0, GetNumResourceMetadata(resource, "dependency") - 1 do
		local dep = GetResourceMetadata(thisResource, "dependency", i)

		if not dependencies[dep] then
			addDependencies(dep)
		end

		dependencies[dep] = true
	end
end

-- Determine if resource can be omitted from the list
local function ignoreResource(resource)
	return resource == thisResource or internalResources[resource] or dependencies[resource]
end

-- Get the full chain of dependencies for resourcemanager. Stopping a
-- dependency anywhere in the chain can cause the server to crash!
addDependencies(thisResource)

-- Start conditional resources
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
					StopResource(resource)
				end
			end
		end

		Citizen.Wait(60000)
	end
end)

SetHttpHandler(exports.httpmanager:createHttpHandler{
	authorization = users,
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
			res.sendJson({})
		end,

		["^/stop/(.+)$"] = function(req, res, helpers, resource)
			StopResource(resource)
			res.sendJson({})
		end,

		["^/restart/(.+)$"] = function(req, res, helpers, resource)
			StopResource(resource)
			StartResource(resource)
			res.sendJson({})
		end,

		["^/refresh$"] = function(req, res, helpers)
			ExecuteCommand("refresh")
			res.sendJson({})
		end
	}
})
