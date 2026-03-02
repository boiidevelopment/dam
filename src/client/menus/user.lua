--- @script client.menus.user
--- @description User self-action menu builder.

local m = {}

function m.build()
    return {
        title = "Self",
        items = {
            { type = "toggle", label = "Noclip", desc = "Toggle noclip.", value = noclip_active, on_change = function() toggle_noclip() end },
            { type = "toggle", label = "God Mode", desc = "Toggle god mode.", value = godmode_active, on_change = function() toggle_godmode() end },
            { type = "toggle", label = "Invisible", desc = "Toggle invisibility.", value = invisible_active, on_change = function() toggle_invisible() end },
            { type = "toggle", label = "Freeze", desc = "Toggle freeze.", value = freeze_active, on_change = function() toggle_freeze() end },
            { type = "action", label = "Teleport to Waypoint", desc = "Teleport to your waypoint.", keep_open = true, on_action = teleport_to_waypoint },
            { type = "action", label = "Teleport to Coords", desc = "Teleport to specific coordinates.", keep_open = true, on_action = teleport_to_coords },
            { type = "action", label = "Revive", desc = "Revive yourself.", keep_open = true, on_action = revive_self },
            { type = "action", label = "Kill", desc = "Kill yourself.", keep_open = true, on_action = kill_self },
            { type = "separator" },
            { type = "back", key = "main", label = "Back", desc = "Go back to main menu." },
        }
    }
end

return m