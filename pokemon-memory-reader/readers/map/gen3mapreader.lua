local gameUtils = require("utils.gameutils")
local mapIdToString = require("data.map_id_to_string")

local Gen3MapReader = {}
Gen3MapReader.__index = Gen3MapReader

function Gen3MapReader:new()
    local obj = setmetatable({}, Gen3MapReader)
    
    obj.ADDR_MAP_HEADER = 0x02037318
    obj.OFFSET_LAYOUT = 0x00
    obj.OFFSET_PRIMARY_TILESET = 0x10
    obj.OFFSET_SECONDARY_TILESET = 0x14
    obj.OFFSET_ATTRIBUTES_PTR = 0x10
    
    return obj
end

function Gen3MapReader:getRealBehavior(tile_id, layout_ptr)
    if not layout_ptr then return 0 end
    
    local tileset_ptr = 0
    local local_id = 0
    
    if tile_id < 0x200 then
        tileset_ptr = gameUtils.read32(layout_ptr + self.OFFSET_PRIMARY_TILESET)
        local_id = tile_id
    else
        tileset_ptr = gameUtils.read32(layout_ptr + self.OFFSET_SECONDARY_TILESET)
        local_id = tile_id - 0x200
    end
    
    if tileset_ptr < 0x08000000 then return 0 end
    
    local attributes_ptr = gameUtils.read32(tileset_ptr + self.OFFSET_ATTRIBUTES_PTR)
    if attributes_ptr < 0x08000000 then return 0 end
    
    local attribute_value = gameUtils.read16(attributes_ptr + (local_id * 2))
    local behavior = attribute_value & 0x00FF
    
    return behavior
end

function Gen3MapReader:behaviorToSymbol(behavior, collision)
    if behavior == 2 then return "~"
    elseif behavior == 3 or behavior == 7 then return "~"
    elseif behavior == 16 or behavior == 21 then return "W"
    elseif behavior == 59 then return "↓"
    elseif behavior == 56 then return "→"
    elseif behavior == 57 then return "←"
    elseif behavior == 58 then return "↑"
    elseif behavior == 96 or behavior == 105 then return "S"
    end
    
    if collision == 1 then return "#" end
    return "."
end

function Gen3MapReader:readMap(addresses)
    local layout_ptr = gameUtils.read32(self.ADDR_MAP_HEADER + self.OFFSET_LAYOUT)
    if layout_ptr < 0x02000000 or layout_ptr > 0x09FFFFFF then
        return {error = "Invalid layout pointer"}
    end
    
    local map_ptr, width, height = nil, 0, 0
    
    for offset = 0, 0x8000 - 12, 4 do
        local addr = 0x03000000 + offset
        local w = gameUtils.read32(addr)
        local h = gameUtils.read32(addr + 4)
        if w >= 10 and w <= 200 and h >= 10 and h <= 200 then
            local p = gameUtils.read32(addr + 8)
            if p >= 0x02000000 and p <= 0x02040000 then
                map_ptr, width, height = p, w, h
                break
            end
        end
    end
    
    if not map_ptr then
        return {error = "Map data not found"}
    end
    
    local mapBank = 0
    local mapNumber = 0
    local mapId = 0
    local mapName = "UNKNOWN"
    
    if addresses and addresses.mapBank and addresses.mapNumber then
        local mapBankAddr = gameUtils.hexToNumber(addresses.mapBank)
        local mapNumberAddr = gameUtils.hexToNumber(addresses.mapNumber)
        mapBank = gameUtils.read8(mapBankAddr)
        mapNumber = gameUtils.read8(mapNumberAddr)
        mapId = (mapBank << 8) | mapNumber
        mapName = mapIdToString.getMapName(mapId)
    end
    
    local mapData = {
        mapId = mapId,
        mapName = mapName,
        width = width,
        height = height,
        layout = {}
    }
    
    for y = 0, height - 1 do
        local row = ""
        for x = 0, width - 1 do
            local val = gameUtils.read16(map_ptr + (x + y * width) * 2)
            local tile_id = val & 0x03FF
            local collision = (val & 0x0C00) >> 10
            
            local behavior = self:getRealBehavior(tile_id, layout_ptr)
            local symbol = self:behaviorToSymbol(behavior, collision)
            
            row = row .. symbol
        end
        table.insert(mapData.layout, row)
    end
    
    return mapData
end

return Gen3MapReader
