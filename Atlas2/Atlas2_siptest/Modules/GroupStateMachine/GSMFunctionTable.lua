local gsmFT = {}

local helpers       = require("GroupStateMachine/GSMHelpers")
local try = helpers.try

local AUTOMATION_BRIDGE_PLUGIN_KEY = 'automationBridgePlugin'
local AUTOMATION_BRIDGE_RESOURCE_KEY = 'AtlasAutomationBridge'

local function truncateFailureMsg(failureMsg)
    return string.sub(failureMsg, 1, 510)
end

-- aggregate start/stopDevice() call for Atlas 2.33.2.0+
local hasAggregatedStartStop = false
if Atlas.compareVersionTo('2.33.2.0') ~= Atlas.versionComparisonResult.lessThan then
    hasAggregatedStartStop = true
end

-- DeviceFT Functions

-- This function will call Group.startDevice and call deviceFT.setup for each device
gsmFT.deviceSetup = function (deviceFT, groupPluginTable, slots)
    local setupStatus = true
    local devicePluginTable = {}
    local mergedPluginTable = {}
    local pluginNamesToUnmanageTable = {}

    -- used only in aggregated startDevice() call
    local deviceNamesToSlot = {}

    for _, slot in ipairs(slots) do
        local deviceName = "G=" .. Group.index .. ":S=" .. slot
        if hasAggregatedStartStop == false then
            Group.startDevice(deviceName, slot)
        else
            deviceNamesToSlot[deviceName] = slot
        end
    end

    if hasAggregatedStartStop then Group.startDevices(deviceNamesToSlot) end

    -- user specificed device setup
    for _, deviceName in ipairs(Group.allDevices()) do
        -- pluginNamesToUnmanage could be nil if there is no plugin to unmanage.
        local devicePlugins, pluginNamesToUnmanage = deviceFT.setup(deviceName, groupPluginTable)
        if devicePlugins == nil then setupStatus = false end
        devicePluginTable[deviceName] = devicePlugins
        for k,v in pairs(groupPluginTable) do devicePlugins[k] = v end
        mergedPluginTable[deviceName] = devicePlugins
        pluginNamesToUnmanageTable[deviceName] = pluginNamesToUnmanage
    end


    if not setupStatus then error("devicePluginTable = nil from deviceFT.setup(...) : return empty table if you do not have any device plugins to return") end
    return devicePluginTable, mergedPluginTable, pluginNamesToUnmanageTable
end

-- This function will schedule and execute the DAG. It will use deviceFT.scheduleDAG and deviceFT.scheduleFinalDAG
gsmFT.executeTest = function (deviceFT, mergedPluginTable, pluginNamesToUnmanageTable)
    local prevDAGResults = nil
    local iter = 1
    local isFinalDAGScheduledPerDevice = {}
    for _,deviceName in ipairs(Group.allDevices()) do isFinalDAGScheduledPerDevice[deviceName] = false end

    repeat
        local isItFinalDAG = false

        for _,deviceName in ipairs(Group.allDevices()) do
            if not isFinalDAGScheduledPerDevice[deviceName] then
                local plugins = mergedPluginTable[deviceName]
                mergedPluginTable[deviceName] = plugins
                local dag = nil
                if next(plugins) == nil then
                    dag = Group.scheduler(deviceName)
                else
                    dag = Group.scheduler(deviceName, plugins)
                end

                -- unamange plugin specified by user
                local pluginNamesToUnmanage = pluginNamesToUnmanageTable[deviceName]
                if pluginNamesToUnmanage then
                    for _, name in ipairs(pluginNamesToUnmanage) do
                        dag.unmanage(name)
                    end
                end

                print("GroupStateMachine : scheduleDAG for device = " .. deviceName .. ", iteration (1 based) = "..iter)
                local isDAGScheduled = deviceFT.scheduleDAG(iter, dag, deviceName, plugins, prevDAGResults)
                print("GroupStateMachine : scheduleDAG for device = " .. deviceName .. ", iteration (1 based) = "..iter .. ", return = ".. tostring(isDAGScheduled))

                if isDAGScheduled == false then
                    print("GroupStateMachine : scheduleFinalDAG for device = " .. deviceName)
                    deviceFT.scheduleFinalDAG(dag, deviceName, plugins)
                    isFinalDAGScheduledPerDevice[deviceName] = true
                end
            end
        end

        prevDAGResults = Group.execute()

        iter = iter + 1
        local allFinalDAGScheduled = true
        for _,isFinalDAGScheduled in pairs(isFinalDAGScheduledPerDevice) do
            allFinalDAGScheduled = allFinalDAGScheduled and isFinalDAGScheduled
        end
    until allFinalDAGScheduled

    return true
end

-- This function will call Group.stopDevice and call deviceFT.teardown for each device
gsmFT.deviceTeardown = function (deviceFT, devicePluginTable, groupPluginTable)
    for _, deviceName in ipairs(Group.allDevices()) do
        deviceFT.teardown(deviceName, devicePluginTable[deviceName])
        if not hasAggregatedStartStop then Group.stopDevice(deviceName) end
    end

    if hasAggregatedStartStop then Group.stopDevices(Group.allDevices()) end
end

-- GroupFT Functions

-- This function will call groupFT.setup
gsmFT.groupSetup = function (groupFT, readyForAutomatedHandlingCallback, resourcesEnabled)
    local resources = {}
    if resourcesEnabled then
        resources = Group.getResources()
    end
    local groupPluginTable = groupFT.setup(resources)
    if readyForAutomatedHandlingCallback then
        groupPluginTable[AUTOMATION_BRIDGE_PLUGIN_KEY] = Remote.loadRemotePlugin(resources[AUTOMATION_BRIDGE_RESOURCE_KEY])
    end
    return groupPluginTable
end

-- This function will call groupFT.getSlots
gsmFT.groupGetSlots = function (groupFT, groupPluginTable, detectionTimeout, readyForAutomatedHandlingCallback)
    local slotsToTest = {}

    if readyForAutomatedHandlingCallback then
        -- Even though automated tests do not acquire their test slots through Group.getSlots(), this function
        -- still has to be called incase the user wishes to use Group.getDeviceTransport() later on
        Group.getSlots()

        print ("GroupStateMachine : Waiting for start message from Atlas Automation Bridge")
        try(function()
            readyForAutomatedHandlingCallback(groupPluginTable, groupPluginTable[AUTOMATION_BRIDGE_PLUGIN_KEY])

            eTravelers = groupPluginTable[AUTOMATION_BRIDGE_PLUGIN_KEY].waitForStart(Group.index)
            for device, _ in pairs(eTravelers) do
                table.insert(slotsToTest, device)
            end
        end,
        function(err)
            error("GroupStateMachine : Could not receive eTravelers from Atlas Automation Bridge.  Error: " .. err)
        end)
    else
        slotsToTest = groupFT.getSlots(groupPluginTable, table.unpack(detectionTimeout))
    end

    return slotsToTest
end

-- This function will call groupFT.start
gsmFT.groupStart = function (groupFT, groupPluginTable)
    return groupFT.start(groupPluginTable)
end

-- This function will call groupFT.stop
gsmFT.groupStop = function (groupFT, groupPluginTable)
    return groupFT.stop(groupPluginTable)
end

-- This function will call groupFT.loopAgain
gsmFT.loopAgain = function (groupFT, groupPluginTable)
    return groupFT.loopAgain(groupPluginTable)
end

-- This function will call groupFT.groupShouldExit
gsmFT.groupShouldExit = function (groupFT, groupPluginTable)
    return groupFT.groupShouldExit(groupPluginTable)
end

-- This function will call groupFT.teardown
gsmFT.groupTeardown = function (groupFT, groupPluginTable)
    return groupFT.teardown(groupPluginTable)
end

return gsmFT
