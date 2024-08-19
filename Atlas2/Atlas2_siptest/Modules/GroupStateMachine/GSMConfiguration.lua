local GSMConfiguration = {}

local _groupFT = "groupFunctionTable"
local _deviceFT = "deviceFunctionTable"
local _detectionTimeout = "detectionTimeout"
local _readyForAutomatedHandlingCallback = "readyForAutomatedHandlingCallback"
local _disabledResources = "disabledResources"

------------------- Internal APIs
local registeredConfiguration = {}
function GSMConfiguration.__getConfiguration()
  local localCopy = registeredConfiguration
  registeredConfiguration = nil
  return localCopy
end

GSMConfiguration.__groupFunctionTableKey      = _groupFT
GSMConfiguration.__deviceFunctionTableKey     = _deviceFT
GSMConfiguration.__detectionTimeoutKey        = _detectionTimeout
GSMConfiguration.__readyForAutomatedHandlingCallbackKey = _readyForAutomatedHandlingCallback
GSMConfiguration.__disabledResourcesKey       = _disabledResources

local function assertSystemStillEditable()
  if not registeredConfiguration then
    error("GroupStateMachine already configured. Cannot re-configure while state machine is active!")
  end
end

------------------- Group APIs
function GSMConfiguration.registerGroupFunctionTable(groupFunctionTable)
  assertSystemStillEditable()
  registeredConfiguration[_groupFT] = groupFunctionTable
end

function GSMConfiguration.registerDeviceFunctionTable(deviceFunctionTable)
  assertSystemStillEditable()
  registeredConfiguration[_deviceFT] = deviceFunctionTable
end

function GSMConfiguration.setDetectionTimeout(interarrival)
  GSMConfiguration.setDetectionTimeout(interarrival, -1)
end

function GSMConfiguration.setDetectionTimeout(interarrival, global)
  assertSystemStillEditable()
  if interarrival == nil or global == nil then
    error("Cannot set timeouts to nil. You can pass -1 for infinite timeout")
  end
  registeredConfiguration[_detectionTimeout] = { interarrival, global }
end

function GSMConfiguration.registerAutomatedHandlingCallback(readyForAutomatedHandlingCallback)
  assertSystemStillEditable()
  registeredConfiguration[_readyForAutomatedHandlingCallback] = readyForAutomatedHandlingCallback
end

function GSMConfiguration.disableResources()
  assertSystemStillEditable()
  registeredConfiguration[_disabledResources] = true
end

return GSMConfiguration
