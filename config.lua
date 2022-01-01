config = {}

-- Resources managed by resourcemanager, with the conditions for when they
-- should be started or stopped.
--
-- Example:
--
-- ["xmas"] = function(onStartup, time) return time.month == 12 and time.day > 20 end
--
-- This would start the resource "xmas" only when the date is between Dec 21-Dec 31.
--
-- Parameters:
--
-- 	onStartup
-- 		true if this is executed when the server is first starting,
-- 		otherwise false. This allows you to ensure a resource is only
-- 		started/stopped when the server is restarted.
--
-- 	time
-- 		The current server time. This is useful for resources that
-- 		start/stop at certain times.
--
-- If the function returns true, the resource will be started if it is stopped.
-- If the function returns false, the resource will be stopped if it is started.
-- Any other return value means nothing will happen.
--
config.managedResources = {
	["xmas"] = function(onStartup, time)
		return time.month == 12
	end,
}

-- Realm or user list for HTTP handler authorization
config.authorization = "default"
