--- @file src.server.main
--- @description Handles main server side function for admin menu, mostly callbacks and perm checks

--- @section Modules

local cfg = require("custom.cfg")
local callbacks = require("libs.graft.callbacks")

--- @section API

function dam.has_permission(source, aces)
    if not cfg.enable_permissions then return true end
    if not aces or aces == false then return false end
    if type(aces) == "string" then aces = { aces } end
    for _, ace in ipairs(aces) do
        if IsPlayerAceAllowed(source, ace) then return true end
    end
    return false
end

--- @section Callbacks

--- Menu Access

callbacks.register("dam:sv:can_open_menu", function(source, data, cb)
    if not cfg.permissions.open_menu then
        cb({ allowed = true })
        return
    end
    cb({ allowed = dam.has_permission(source, cfg.permissions.open_menu) })
end)

callbacks.register("dam:sv:can_view_bans", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.view_bans) })
end)

callbacks.register("dam:sv:get_ban_list", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.view_bans) then
        cb({ bans = {} })
        return
    end
    local result = MySQL.query.await([[
        SELECT b.id, b.unique_id, b.banned_by, b.reason, b.expires_at, p.name
        FROM dam_bans b
        JOIN dam_players p ON p.unique_id = b.unique_id
        WHERE b.expired = 0
        ORDER BY b.created DESC
    ]], {})
    if result then
        for _, ban in ipairs(result) do
            ban.expires_formatted = ban.expires_at and os.date("%d/%m/%y %H:%M", ban.expires_at / 1000) or "Permanent"
        end
    end
    cb({ bans = result or {} })
end)

callbacks.register("dam:sv:remove_ban", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.remove_ban) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local ok = dam.remove_ban(data.unique_id)
    cb({ success = ok })
end)
