-- HTTP Server
-- Simple HTTP server for BizHawk

local Config = require("config")
local Api = require("api")
local Readers = require("readers")

local Server = {}

local socket = require("socket")
local server = nil
local clients = {}
local isRunning = false

-- Parse query string
local function parseQuery(path)
    local query = {}
    local queryStart = path:find("?")
    if queryStart then
        local queryString = path:sub(queryStart + 1)
        for key, value in queryString:gmatch("([^&=]+)=([^&=]+)") do
            query[key] = value
        end
        path = path:sub(1, queryStart - 1)
    end
    return path, query
end

-- Start server
function Server.start()
    if isRunning then return true end

    server = socket.tcp()
    if not server then
        console.log("Failed to create socket")
        return false
    end

    server:settimeout(0)
    server:setoption("reuseaddr", true)

    local success, err = server:bind(Config.SERVER.host, Config.SERVER.port)
    if not success then
        console.log("Failed to bind: " .. (err or "unknown"))
        server:close()
        return false
    end

    success, err = server:listen(5)
    if not success then
        console.log("Failed to listen: " .. (err or "unknown"))
        server:close()
        return false
    end

    isRunning = true
    console.log("Battle API server started on http://" .. Config.SERVER.host .. ":" .. Config.SERVER.port)
    console.log("Endpoints:")
    console.log("  GET /battle - Battle pokemon")
    console.log("  GET /party - Player party")
    console.log("  GET /enemy - Enemy party")
    console.log("  GET /log - Battle text")
    console.log("  GET /phase - Battle phase")
    console.log("  GET /loadstate?name=xxx - Load state")
    console.log("  POST /action/enable - Enable hijack")
    console.log("  POST /action/move - Inject move")
    console.log("  POST /action/switch - Inject switch")

    return true
end

-- Stop server
function Server.stop()
    if not isRunning then return end

    for i = #clients, 1, -1 do
        clients[i]:close()
        table.remove(clients, i)
    end

    if server then
        server:close()
        server = nil
    end

    isRunning = false
    console.log("Server stopped")
end

-- Update server (call each frame)
function Server.update()
    if not isRunning or not server then return end

    -- Update log history every frame
    Readers.updateLog()

    -- Accept new connections
    local client = server:accept()
    if client then
        client:settimeout(0)
        table.insert(clients, client)
    end

    -- Process clients
    for i = #clients, 1, -1 do
        local client = clients[i]
        local request, err = client:receive("*l")

        if request then
            -- Parse request line
            local method, path, protocol = request:match("^(%S+)%s+(%S+)%s+(%S+)")

            if method and path then
                -- Parse query
                local query
                path, query = parseQuery(path)

                -- Read headers
                local headers = {}
                while true do
                    local line, err = client:receive("*l")
                    if not line or line == "" then break end
                    local key, value = line:match("^([^:]+):%s*(.+)")
                    if key and value then
                        headers[key:lower()] = value
                    end
                end

                -- Read body for POST
                local body = ""
                if method == "POST" then
                    local contentLength = tonumber(headers["content-length"]) or 0
                    console.log("POST content-length: " .. tostring(contentLength))
                    if contentLength > 0 then
                        body = client:receive(contentLength) or ""
                    end
                    console.log("POST body: [" .. body .. "]")
                end

                -- Route request
                Api.route(client, method, path, query, body)
            end

            client:close()
            table.remove(clients, i)
        elseif err == "closed" then
            client:close()
            table.remove(clients, i)
        end
    end
end

return Server
