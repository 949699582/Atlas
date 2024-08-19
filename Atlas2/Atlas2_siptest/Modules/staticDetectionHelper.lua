-- static detection with dummy resource.
-- generate dummy device url for every slots defined in station configuration plist.
-- generate dummy resource url named "dummy" for every group defined in station configuration plist.
local helper = {}

-- Very simple static dispatch.
-- usage:
-- static detection using default device URL and resource URL
--     helper.run()

-- using customized prefix to generate url; the actual url generated:
-- deviceURL: prefix..groupIndex..'-'..slotName
-- resourceURL: prefix..groupIndex
--     helper.run('device-url-prefix-')
--     helper.run('device-url-prefix-', 'resource-url-prefix-')
function helper.run(deviceURLPrefix, resourceURLPrefix)
    if deviceURLPrefix == nil then
        deviceURLPrefix = 'uart://fake-path-'
    end
    if resourceURLPrefix == nil then
        resourceURLPrefix = 'uart://resource-group-'
    end

    for _, group in ipairs(Detection.groups()) do
        for _, device in ipairs(Detection.slots()) do
            Detection.addDevice(deviceURLPrefix .. group .. '-' .. device)
        end
        Detection.addResource(resourceURLPrefix .. group)
    end

    local routingCallback = function(url)
        local pattern = '([0-9]+)%-(.+)$'
        local group_index, slot = string.match(url, pattern)
        group_index = tonumber(group_index)
        return slot, group_index
    end

    local resourceRoutingCallback = function(url)
        pattern = '([0-9]+)$'
        group_index = string.match(url, pattern)
        group_index = tonumber(group_index)
        return 'dummy', group_index
    end

    Detection.setExpectedResources({'dummy'})
    Detection.setDeviceRoutingCallback(routingCallback)
    Detection.setResourceRoutingCallback(resourceRoutingCallback)
end

return helper
