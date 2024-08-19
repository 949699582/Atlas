-- Example of EFI detect, for reference only
function main()
    local CommBuilder = Atlas.loadPlugin("CommBuilder")
    CommBuilder.setLineTerminator("\n")
    CommBuilder.setDelimiter(":-)")
    CommBuilder.setSendStringOnOpen(nil)
    CommBuilder.setPollDetectorTimeout(0.1, 5) -- (pollTimeout, pollRestPeriod)
    Detection.addDeviceDetector(CommBuilder.createPollDetector("uart:///dev/cu.kanzi-1"))

    local routingCallback = function(url)
        local groups = Detection.groups()
        local groupName = groups[1]
        if (string.sub(url, -1) == "1") then
            groupName = groups[2]
        end
        return Detection.slots()[1], groupName
    end

    Detection.setDeviceRoutingCallback(routingCallback)
end
