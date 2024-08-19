local PListSerialization = {}

if Atlas ~= nil then 
    PListSerialization.PListPlugin = Atlas.loadPlugin("PListSerializationPlugin")
else
    PListSerialization.PListPlugin= require("PListSerializationPlugin")
end

--! @brief Load dictionary from PList file
--! @param PListFileName PList file name
--! @returns Dictionary object
function PListSerialization.LoadFromFile(PListFileName)
	
	local status, dict = pcall(PListSerialization.PListPlugin.decodeFile, PListFileName)
	if(status == true) then
		return dict
	else
		print("Failed to decode file: '" .. PListFileName .."'")
		return nil
	end
end

--! @brief Load dictionary from NSData
--! @param data NSData object
--! @returns Dictionary object
function PListSerialization.LoadFromData(data)
	return PListSerialization.PListPlugin.decodeData(data)
end


--! @brief Save dictionary to PList file
--! @param data Dictionary to save
--! @param PListFileName PList file name
function PListSerialization.SaveToFile(data, PListFileName)
	dataStr = PListSerialization.PListPlugin.encode(data)
	local file = io.open(PListFileName, "wb")
    if not file then 
    	print ("PListSerialization Error: Could not open file for writing")
    	return nil 
    end

    file:write(dataStr) 
	file:close()
end

--! @brief Save dictionary to Binary PList file
--! @param data Dictionary to save
--! @param PListFileName PList file name
function PListSerialization.SaveToBinaryFile(data, PListFileName)
	-- encodeToFile: true for binary format, false for XML format
	PListSerialization.PListPlugin.encodeToFile(data, PListFileName, true)
end

return PListSerialization
