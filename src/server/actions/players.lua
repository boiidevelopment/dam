
--- @file src.server.main
--- @description Handles main server side function for admin menu, mostly callbacks and perm checks

--- @section Modules

local cfg = require("custom.cfg")
local callbacks = require("libs.graft.callbacks")

--- @section Local Functions

local function get_player_list()
    local list = {}
    for _, source in ipairs(GetPlayers()) do
        source = tonumber(source)
        list[#list + 1] = {
            source = source,
            name = GetPlayerName(source) or "Unknown",
        }
    end
    return list
end

--- @section Callbacks

callbacks.register("dam:sv:can_view_players", function(source, data, cb)
    if not cfg.permissions.view_players then
        cb({ allowed = true })
        return
    end
    cb({ allowed = dam.has_permission(source, cfg.permissions.view_players) })
end)

callbacks.register("dam:sv:get_player_list", function(source, data, cb)
    if not cfg.permissions.view_players then
        cb({ players = get_player_list() })
        return
    end
    cb({ players = dam.has_permission(source, cfg.permissions.view_players) and get_player_list() or {} })
end)

callbacks.register("dam:sv:teleport_to_player", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.players.teleport) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ped = GetPlayerPed(target)
    if not ped or ped == 0 then cb({ success = false }) return end
    local coords = GetEntityCoords(ped)
    cb({ success = true, coords = {x = coords.x, y = coords.y, z = coords.z} })
end)

callbacks.register("dam:sv:bring_player", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.players.bring) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then cb({ success = false }) return end
    local coords = GetEntityCoords(ped)
    TriggerClientEvent("dam:cl:set_coords", target, {x = coords.x, y = coords.y, z = coords.z})
    cb({ success = true })
end)

callbacks.register("dam:sv:ban_player", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.players.ban) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local banned_by = GetPlayerName(source) or "dam"
    local ok = dam.ban_player(target, banned_by, data.reason, data.duration)
    cb({ success = ok })
end)

callbacks.register("dam:sv:kick_player", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.players.kick) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    DropPlayer(target, data.reason or "Kicked by admin.")
    cb({ success = true })
end)

callbacks.register("dam:sv:warn_player", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.players.warn) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ids = dam.get_identifiers(target)
    if not ids.license then cb({ success = false }) return end
    local result = MySQL.query.await("SELECT unique_id FROM dam_players WHERE license = ?", { ids.license })
    if not result or not result[1] then cb({ success = false }) return end
    local warned_by = GetPlayerName(source) or "dam"
    MySQL.insert.await("INSERT INTO dam_warnings (unique_id, warned_by, reason) VALUES (?, ?, ?)", { result[1].unique_id, warned_by, data.reason or "No reason provided." })
    TriggerClientEvent("dam:cl:warned", target, data.reason or "No reason provided.")
    cb({ success = true })
end)

callbacks.register("dam:sv:get_player_warnings", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.players.warn) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local target = tonumber(data.target)
    if not target then cb({ success = false }) return end
    local ids = dam.get_identifiers(target)
    if not ids.license then cb({ success = false }) return end
    local result = MySQL.query.await("SELECT unique_id FROM dam_players WHERE license = ?", { ids.license })
    if not result or not result[1] then cb({ success = false }) return end
    local warnings = MySQL.query.await("SELECT id, warned_by, reason, created FROM dam_warnings WHERE unique_id = ? ORDER BY created DESC", { result[1].unique_id })
    if warnings then
        for _, w in ipairs(warnings) do
            w.created = os.date("%d/%m/%y %H:%M", w.created / 1000)
        end
    end
    cb({ success = true, warnings = warnings or {} })
end)