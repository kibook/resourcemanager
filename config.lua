config = {}

-- Resources managed by resourcemanager, with the conditions for when they
-- should be started or stopped.
--
-- Example:
--
-- ["xmas"] = function(time) return time.month == 12 and time.day > 20 end
--
-- This would start the resource "xmas" only when the date is between Dec 21-Dec 31.
--
config.managedResources = {
}
