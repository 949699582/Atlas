local Process = {}
local Log = require 'Matchbox/logging'
local Record = require 'Matchbox/record'

function Process.nyquistExample(param)
    Record.createBinaryRecord(true, param.Technology, param.TestName, "Pass record")
end

function Process.nyquistExampleFail(param)
    error('Fail on purpose')
end

return Process
