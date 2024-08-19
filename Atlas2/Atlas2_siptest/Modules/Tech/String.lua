local String = {}
local libRecord = require 'Matchbox/record'
local comFunc = require 'Matchbox/CommonFunc'
local Log = require 'Matchbox/logging'

function String.regexInter(paraTab)
    local dataInput = paraTab.Input
    if dataInput == true or dataInput == false then
        return dataInput
    end    
    local strInput = tostring(paraTab.Input)
    log.LogInfo('Regex input is ',strInput)

    local pattern = paraTab.varSubAP()['pattern']
    -- local pattern = paraTab.AdditionalParameters["pattern"]
    log.LogInfo('Regex pattern is ',pattern)
    
    local Separator = paraTab.varSubAP()['sep'] or ' '
    function sum(_table,Separator)
        local sep = Separator
        if #_table >1 then
            str = ''
            for i,v in ipairs(_table) do
                if i ==1 then
                    if v then
                        str = str..v
                    end
                else
                    str = str..sep..v
                end
            end
            return str
        else
            return _table[1]
        end
    end
    str = sum({strInput:match(pattern)},Separator)
    log.LogInfo('The match result is ',str)
    if str ~= nil and #str>0 and str ~= 'nil'then 
        value = str
    else    
        value = false 
    end
    print('return value is :',value)
    return value
end
function String.regex(paraTab)
    local result = false
    function excuteF()
        result = String.regexInter(paraTab)
    end
    function errorF(err)
        print('regex fail',err)
    end
    local rRe = xpcall(excuteF,errorF)
    return result

end

function String.gmatch(str,pattern)
    temp_tab = {}
    for i in string.gmatch(str,pattern) do
        table.insert(temp_tab,i)
    end
    return temp_tab
end

 function String.split(szFullString, szSeparator)  
    local nFindStartIndex = 1  
    local nSplitIndex = 1  
    local nSplitArray = {}  
    while true do  
     local nFindLastIndex = string.find(szFullString, szSeparator, nFindStartIndex)  
     if not nFindLastIndex then  
      nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, string.len(szFullString))  
      break  
    end  
    nSplitArray[nSplitIndex] = string.sub(szFullString, nFindStartIndex, nFindLastIndex - 1)  
    nFindStartIndex = nFindLastIndex + string.len(szSeparator)  
    nSplitIndex = nSplitIndex + 1  
    end  
    return nSplitArray  
end  

return String


