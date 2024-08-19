local log = require 'Matchbox/logging'
m = {}
function m.rmStationJSONFile(param)
    os.execute('rm -rf /vault/data_collection/test_station_config; sleep 10')
end
return m
