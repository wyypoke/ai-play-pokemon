-- HTTP Utilities - HTTP 响应构建工具

local HttpUtils = {}

-- 发送 HTTP 响应
function HttpUtils.sendResponse(client, code, status, contentType, body)
    local response = "HTTP/1.1 " .. code .. " " .. status .. "\r\n" ..
                     "Content-Type: " .. contentType .. "\r\n" ..
                     "Content-Length: " .. #body .. "\r\n" ..
                     "Connection: close\r\n" ..
                     "Access-Control-Allow-Origin: *\r\n" ..
                     "Access-Control-Allow-Methods: GET, POST, OPTIONS\r\n" ..
                     "Access-Control-Allow-Headers: Content-Type\r\n" ..
                     "\r\n" ..
                     body
    client:send(response)
end

-- 发送 JSON 响应
function HttpUtils.sendJson(client, code, status, data)
    local json = require("json")
    local body = json.encode(data, {indent = true})
    HttpUtils.sendResponse(client, code, status, "application/json", body)
end

-- 发送错误响应
function HttpUtils.sendError(client, code, status, message)
    HttpUtils.sendJson(client, code, status, {
        error = true,
        message = message
    })
end

-- 解析查询参数
function HttpUtils.parseQuery(path)
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

return HttpUtils
