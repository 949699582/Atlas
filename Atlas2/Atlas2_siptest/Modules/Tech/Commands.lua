-- tech lua for Commands.csv
local log = require 'Matchbox/logging'
m = {}

-- report error when var-substituted Commands doesn't match Input.
-- for using param.varSubCmd() and default variable pattern
function m.checkCommands(param)
    local postSubCmd = param.varSubCmd()
    assert(param.Input == postSubCmd, 'Variable in Commands is not substituted correctly; expect: '..param.Input..' actual: '..postSubCmd)
end

-- report error if m.checkCommands() doens't report error
-- used to verify failure case.
function m.checkCommandsFail(param)
    local ret, msg = pcall(m.checkCommands, param)
    if ret == true then error('Not fail as expected.') end
    if msg:find('not found')==nil and msg:find('is invalid')==nil then error('erorr msg not expected: '..msg) end
end

-- report error when var-substituted Commands doesn't match Input.
-- for using cosmized variable pattern.
function m.checkCommandsWithCustomPattern(param)
    local sub = require 'VariableSubstitute'
    local i = {param.getInput()}
    -- the last input item is expected string
    expect = i[#i]
    local customizedVariablePattern = '[[varname]]'
    local values = param.InputDict
    local p = {customizedVariablePattern, values}

    local common = require 'Matchbox/CommonFunc'
    local postSubCmd = sub.sub(param.Commands, {p})
    assert(expect == postSubCmd, 'Variable in Commands is not substituded correctly; expect: '..tostring(expect)..', actual: '..postSubCmd)
end

function m.checkAP(param)
    local ap = param.varSubAP()
    local expect = param.AdditionalParameters.expect
    ap.expect = nil
    local common = require 'Matchbox/CommonFunc'
    assert(common.deepCompare(expect, ap), 'AP not substituded correctly; expect: '..common.dump(expect)..', actual: '..common.dump(ap))
end

function m.returnNil(param)
end

return m
