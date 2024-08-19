-- tech lua for Commands.csv
local log = require 'Matchbox/logging'
m = {}

-- report error when var-substituted Commands doesn't match Input.
function m.checkInput(param)
    --local arrayInputs = {param.getInput()}
    --local x, y, z = param.getInput()
    local arrayInputs = param.InputValues
    print('XXXXXXXXXX arrayInput length: '..#arrayInputs..' '..tostring(arrayInputs[3])..tostring(z))
    local tableInputs = param.InputDict
    local expect = param.AdditionalParameters.expect
    if expect == nil then
        if param.Input == nil then return 
        else error('Input is not nil as expected')
        end
    end
    local arrayExpect = expect.array
    local tableExpect = expect.table
    
    local common = require 'Matchbox/CommonFunc'
    assert(common.deepCompare(arrayInputs, arrayExpect), 'Input array not expected: '..common.dump(arrayInputs)..'; expecting '..common.dump(arrayExpect))
    assert(common.deepCompare(tableInputs, tableExpect), 'Input table not expected: '..common.dump(tableInputs)..'; expecting '..common.dump(tableExpect))
end

-- report error if m.checkCommands() doens't report error
-- used to verify failure case.
function m.checkInputFail(param)
    local ret, msg = pcall(m.checkInput, param)
    if ret == true then error('Not fail as expected.') end
    if string.find(msg, 'not found') then error('erorr msg not expected: '..msg) end
end

-- function that do nothing to generate a variable with nil value
function m.returnNil(param)
end

return m
