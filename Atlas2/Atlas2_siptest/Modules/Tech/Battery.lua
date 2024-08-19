local Battery = {}
local Record = require 'Matchbox/record'

function Battery.createParametricRecordExample(paraTab)
    local input = tonumber(paraTab.Input)
    Record.createParametricRecord(input, paraTab.Technology,
                                  paraTab.TestName .. paraTab.testNameSuffix, 'ExampleFunc',
                                  {relaxedLowerLimit=0, lowerLimit=10,
                                   upperLimit=100, relaxedUpperLimit=nil, units = '%'})
end

return Battery
