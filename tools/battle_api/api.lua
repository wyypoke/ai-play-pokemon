-- API Handlers
-- Handle HTTP requests

local json = require("dkjson")
local Config = require("config")
local Readers = require("readers")

local Api = {}

-- Helper: send JSON response
local function sendJson(client, data, status)
    status = status or 200
    local body = json.encode(data, {indent = true})
    local response = string.format(
        "HTTP/1.1 %d OK\r\nContent-Type: application/json\r\nContent-Length: %d\r\n\r\n%s",
        status, #body, body
    )
    client:send(response)
end

-- Helper: send error
local function sendError(client, message, status)
    status = status or 400
    sendJson(client, {error = message}, status)
end

-- GET /battle - Get battle pokemon
function Api.handleBattle(client)
    local mons = Readers.getBattleMons()
    sendJson(client, {
        inBattle = Readers.isInBattle(),
        isDouble = Readers.isDoubleBattle(),
        pokemon = mons
    })
end

-- GET /party - Get player party
function Api.handleParty(client)
    local party = Readers.getPlayerParty()
    sendJson(client, {party = party})
end

-- GET /enemy - Get enemy party
function Api.handleEnemy(client)
    local party = Readers.getEnemyParty()
    sendJson(client, {party = party})
end

-- GET /log - Get battle text
function Api.handleLog(client)
    local text = Readers.getBattleText()
    sendJson(client, {text = text})
end

-- GET /phase - Get battle phase
function Api.handlePhase(client)
    sendJson(client, {
        phase = Readers.getBattlePhase(),
        isDouble = Readers.isDoubleBattle(),
        inBattle = Readers.isInBattle()
    })
end

-- POST /action/enable - Enable hijack mode
function Api.handleActionEnable(client)
    local addr = Config.ADDRESS.ActionInjectData
    local actionOff = Config.ACTION_INJECT.offset.actions
    local actSize = Config.ACTION_INJECT.actionSize
    local actOff = Config.ACTION_INJECT.actionOffset

    -- Clear actions first
    for i = 0, 1 do
        local base = addr + actionOff + i * actSize
        memory.write_u8(base + actOff.action, 0)
        memory.write_u8(base + actOff.moveIndex, 0)
        memory.write_u8(base + actOff.target, 0)
        memory.write_u8(base + actOff.switchMon, 0)
    end

    -- Set magic and enable
    memory.write_u32_le(addr + Config.ACTION_INJECT.offset.magic, Config.ACTION_INJECT.magic)
    memory.write_u8(addr + Config.ACTION_INJECT.offset.enabled, 0)  -- Don't enable yet
    memory.write_u8(addr + Config.ACTION_INJECT.offset.waiting, 0)
    memory.write_u8(addr + 6, 0)  -- reserved[0]

    sendJson(client, {success = true, message = "Hijack mode enabled"})
end

-- POST /action/disable - Disable hijack mode
function Api.handleActionDisable(client)
    local addr = Config.ADDRESS.ActionInjectData
    memory.write_u8(addr + Config.ACTION_INJECT.offset.enabled, 0)
    sendJson(client, {success = true, message = "Hijack mode disabled"})
end

-- POST /action/move - Inject move action
function Api.handleActionMove(client, body)
    console.log("handleActionMove body: [" .. tostring(body) .. "]")
    local data = json.decode(body)
    console.log("decoded data: " .. tostring(data))
    if data then
        console.log("data.move = " .. tostring(data.move))
    end
    if not data or data.move == nil then
        sendError(client, "Missing 'move' parameter")
        return
    end

    local addr = Config.ADDRESS.ActionInjectData
    local actionOff = Config.ACTION_INJECT.offset.actions
    local actSize = Config.ACTION_INJECT.actionSize
    local actOff = Config.ACTION_INJECT.actionOffset

    -- Slot 0 (left pokemon)
    local base0 = addr + actionOff
    memory.write_u8(base0 + actOff.action, Config.B_ACTION.USE_MOVE)
    memory.write_u8(base0 + actOff.moveIndex, data.move or 0)
    memory.write_u8(base0 + actOff.target, data.target or 1)

    -- Slot 1 (right pokemon, double battle)
    if data.move2 then
        local base1 = addr + actionOff + actSize
        memory.write_u8(base1 + actOff.action, Config.B_ACTION.USE_MOVE)
        memory.write_u8(base1 + actOff.moveIndex, data.move2)
        memory.write_u8(base1 + actOff.target, data.target2 or 3)
    end

    -- Enable
    memory.write_u8(addr + Config.ACTION_INJECT.offset.enabled, 1)

    sendJson(client, {success = true, message = "Move injected"})
end

-- POST /action/switch - Inject switch action
function Api.handleActionSwitch(client, body)
    local data = json.decode(body)
    if not data or data.slot == nil then
        sendError(client, "Missing 'slot' parameter")
        return
    end

    local addr = Config.ADDRESS.ActionInjectData
    local actionOff = Config.ACTION_INJECT.offset.actions
    local actSize = Config.ACTION_INJECT.actionSize
    local actOff = Config.ACTION_INJECT.actionOffset

    -- Slot 0
    local base0 = addr + actionOff
    memory.write_u8(base0 + actOff.action, Config.B_ACTION.SWITCH)
    memory.write_u8(base0 + actOff.switchMon, data.slot)

    -- Slot 1 (double battle)
    if data.slot2 then
        local base1 = addr + actionOff + actSize
        memory.write_u8(base1 + actOff.action, Config.B_ACTION.SWITCH)
        memory.write_u8(base1 + actOff.switchMon, data.slot2)
    end

    -- Enable
    memory.write_u8(addr + Config.ACTION_INJECT.offset.enabled, 1)

    sendJson(client, {success = true, message = "Switch injected"})
end

-- GET /loadstate - Load save state
function Api.handleLoadState(client, query)
    if not query or not query.name then
        sendError(client, "Missing 'name' parameter")
        return
    end

    local statePath = Config.STATE_PATH .. query.name .. ".State"
    local success, err = pcall(function()
        return savestate.load(statePath)
    end)

    if success then
        sendJson(client, {success = true, message = "State loaded: " .. query.name})
    else
        sendError(client, "Failed to load state: " .. tostring(err), 500)
    end
end

-- Route request to appropriate handler
function Api.route(client, method, path, query, body)
    if method == "GET" then
        if path == "/battle" then
            Api.handleBattle(client)
        elseif path == "/party" then
            Api.handleParty(client)
        elseif path == "/enemy" then
            Api.handleEnemy(client)
        elseif path == "/log" then
            Api.handleLog(client)
        elseif path == "/phase" then
            Api.handlePhase(client)
        elseif path == "/loadstate" then
            Api.handleLoadState(client, query)
        else
            sendError(client, "Not found", 404)
        end
    elseif method == "POST" then
        if path == "/action/enable" then
            Api.handleActionEnable(client)
        elseif path == "/action/disable" then
            Api.handleActionDisable(client)
        elseif path == "/action/move" then
            Api.handleActionMove(client, body)
        elseif path == "/action/switch" then
            Api.handleActionSwitch(client, body)
        else
            sendError(client, "Not found", 404)
        end
    else
        sendError(client, "Method not allowed", 405)
    end
end

return Api
