--- @file src.server.actions.user
--- @description Handles all user actions *(self)*

--- @section Modules

local hooks = require("custom.hooks")
local cfg = require("custom.cfg")
local callbacks = require("libs.graft.callbacks")

--- @section Callbacks

callbacks.register("dam:sv:toggle_noclip", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.user.noclip) })
end)

callbacks.register("dam:sv:toggle_godmode", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.user.godmode) })
end)

callbacks.register("dam:sv:toggle_invisible", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.user.invisible) })
end)

callbacks.register("dam:sv:toggle_freeze", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.user.freeze) })
end)

callbacks.register("dam:sv:can_teleport_waypoint", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.user.teleport_waypoint) })
end)

callbacks.register("dam:sv:can_teleport_coords", function(source, data, cb)
    cb({ allowed = dam.has_permission(source, cfg.permissions.user.teleport_coords) })
end)

callbacks.register("dam:sv:revive_self", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.user.revive) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    if not hooks.revive_player then
        cb({ success = false, reason = "no_hook" })
        return
    end
    local ok, err = pcall(hooks.revive_player, source)
    if not ok then
        print("[dam] revive_player hook error: " .. tostring(err))
        cb({ success = false, reason = "hook_error" })
        return
    end
    cb({ success = true })
end)

callbacks.register("dam:sv:kill_self", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.user.kill) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    if not hooks.kill_player then
        cb({ success = false, reason = "no_hook" })
        return
    end
    local ok, err = pcall(hooks.kill_player, source)
    if not ok then
        print("[dam] kill_player hook error: " .. tostring(err))
        cb({ success = false, reason = "hook_error" })
        return
    end
    cb({ success = true })
end)

callbacks.register("dam:sv:revive_player", function(source, data, cb)
    local target = tonumber(data.target) or source
    if not dam.has_permission(source, cfg.permissions.user.revive) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    if not hooks.revive_player then
        cb({ success = false, reason = "no_hook" })
        return
    end
    local ok, err = pcall(hooks.revive_player, target)
    if not ok then
        print("[dam] revive_player hook error: " .. tostring(err))
        cb({ success = false, reason = "hook_error" })
        return
    end
    cb({ success = true })
end)

callbacks.register("dam:sv:kill_player", function(source, data, cb)
    local target = tonumber(data.target) or source
    if not dam.has_permission(source, cfg.permissions.user.kill) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    if not hooks.kill_player then
        cb({ success = false, reason = "no_hook" })
        return
    end
    local ok, err = pcall(hooks.kill_player, target)
    if not ok then
        print("[dam] kill_player hook error: " .. tostring(err))
        cb({ success = false, reason = "hook_error" })
        return
    end
    cb({ success = true })
end)