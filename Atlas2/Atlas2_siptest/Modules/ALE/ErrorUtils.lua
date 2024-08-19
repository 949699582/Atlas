local ErrorUtils = {}

local function ErrorMsgWithTraceback(err)
	local retErr = {}
	retErr.message = err
	retErr.stacktrace = debug.traceback(nil, nil, 0)
	return retErr
end

--! @brief Similar to standard pcall() function, but the exception object produced will have a full error stack trace
function ErrorUtils.PCallWithTraceback(func, ...)
	return xpcall(func, ErrorMsgWithTraceback, ...)
end

--! @brief Try/Catch block helper
--! @code
--! ErrorUtils.Try(
--! 	function ()
--! 		results.get(device_name)
--! 		print(action.." for "..device_name .. " ran without issues")
--! 	end,
--! 	function (erawr)
--! 		TestGroup.failTestableDevice(device_name, "SW ran into trouble")
--! 		unit.teardown(pluginStore[device_name]["dut"], device_name)
--! 		pluginStore[device_name] = nil
--!
--! 		error(action.." for "..device_name .. " failed with error :" .. erawr)
--! 	end
--! @endcode
function ErrorUtils.Try(f, catch_f)
  local status, exception = ErrorUtils.PCallWithTraceback(f)
  if not status then
      catch_f(exception)
  end
end

--! @brief Raise error with specified error message
function ErrorUtils.RaiseError(message)
	error(message, 0)
end

return ErrorUtils
