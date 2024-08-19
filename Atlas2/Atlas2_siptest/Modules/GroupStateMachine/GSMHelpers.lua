local helpers = {}

function helpers.try(f, catch_f, ...)
    local status, exception = xpcall(f, debug.traceback, ...)
    if not status
    then
        catch_f(exception)
    end
end

return helpers