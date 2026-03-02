--[[
--------------------------------------------------

This file is part of DAM.
You are free to use these files within your own resources.
Please retain the original credit and attached MIT license.
Support honest development.

Author: Case @ BOII Development
License: MIT (https://github.com/boiidevelopment/dam/blob/main/LICENSE)
GitHub: https://github.com/boiidevelopment/dam

--------------------------------------------------
]]

--- @script init
--- @description Main initialization file

--- @section Bootstrap

dam = setmetatable({}, { __index = _G })

dam.resource_name = GetCurrentResourceName()
dam.is_server = IsDuplicityVersion()
dam.debug = GetConvar("dam:debug", "false") == "true"
dam.language = GetConvar("dam:language", "en")

--- @section Resource Metadata

dam.resource_metadata = {
    name = GetResourceMetadata(dam.resource_name, "name", 0) or "unknown",
    description = GetResourceMetadata(dam.resource_name, "description", 0) or "unknown",
    version = GetResourceMetadata(dam.resource_name, "version", 0) or "unknown",
    author = GetResourceMetadata(dam.resource_name, "author", 0) or "Unknown"
}

--- @section Cache

dam.cache = {}
dam.locale = {}

--- @section Debugging

--- Gets the current time for debug logs
local function get_current_time()
    if dam.is_server then return os.date("%Y-%m-%d %H:%M:%S") end
    if GetLocalTime then
        local y, m, d, h, min, s = GetLocalTime()
        return string.format("%04d-%02d-%02d %02d:%02d:%02d", y, m, d, h, min, s)
    end
    return "0000-00-00 00:00:00"
end

--- Logs a stylized print message
--- @param level string: Debug level (debug, info, success, warn, error, critical, dev)
--- @param message string: Message to print
local function log(level, message)
    if not dam.debug then return end

    local colors = { reset = "^7", debug = "^6", info = "^5", success = "^2", warn = "^3", error = "^8", critical = "^1", dev = "^9" }

    local clr = colors[level] or "^7"
    local time = get_current_time()

    print(("%s[%s] [%s] [%s]:^7 %s"):format(clr, time, dam.resource_metadata.name, level:upper(), message))
end

dam.log = log
_G.log = log

--- Translates a string to a locale key
--- @param key string: Locale key string
--- @param ... any: Arguments for string.format
--- @return string: Translated string
local function translate(key, ...)
    local str = dam.locale[key]
    if not str and type(key) == "string" then
        local v = dam.locale
        for p in key:gmatch("[^%.]+") do v = v and v[p] end
        str = v
    end
    if type(str) == "string" then
        local ok, res = pcall(string.format, str, ...)
        return ok and res or str
    end
    return select("#", ...) > 0 and (tostring(key) .. " | " .. table.concat({...}, ", ")) or tostring(key)
end

dam.translate = translate
_G.translate = translate

--- @section Safe Module Loader

--- Safe require function for loading internal modules
--- @param key string: Path key e.g. `src.server.modules.database`
local function safe_require(key)
    if not key or type(key) ~= "string" then return nil end
    local rel_path = key:gsub("%.", "/")
    if not rel_path:match("%.lua$") then rel_path = rel_path .. ".lua" end
    local cache_key = ("%s:%s"):format(dam.resource_name, rel_path)
    if dam.cache[cache_key] then return dam.cache[cache_key] end
    local file = LoadResourceFile(dam.resource_name, rel_path)
    if not file then log("warn", translate("init.mod_missing", rel_path)) return nil end
    local module_env = setmetatable({}, { __index = _G })
    local chunk, err = load(file, ("@@%s/%s"):format(dam.resource_name, rel_path), "t", module_env)
    if not chunk then log("error", translate("init.mod_compile", rel_path, err)) return nil end
    local ok, result = pcall(chunk)
    if not ok then log("error", translate("init.mod_runtime", rel_path, result)) return nil end
    if type(result) ~= "table" then log("error", translate("init.mod_return", rel_path, type(result))) return nil end
    dam.cache[cache_key] = result
    return result
end

_G.require = safe_require

--- @section Locales

local loaded_locale = require("locales." .. dam.language)
if loaded_locale then
    dam.locale = loaded_locale
end

--- @section Startup Message

if dam.is_server then
    print("^2 ------------------------------------------------------------")
    print("^7  Name:        ^2" .. dam.resource_metadata.name)
    print("^7  Description: ^2" .. dam.resource_metadata.description)
    print("^7  Author:      ^2" .. dam.resource_metadata.author)
    print("^7  Version:     ^2" .. dam.resource_metadata.version)
    print("^2 ------------------------------------------------------------")
end

--- @section Namespace Protection

SetTimeout(250, function()
    setmetatable(dam, {
        __newindex = function(_, key)
            error(translate("init.ns_blocked", key), 2)
        end
    })
    
    log("success", translate("init.ns_ready", dam.resource_metadata.name))
end)