--- @file custom.cfg
--- @description Handles all server side configurable options for the admin menu

return {

    --- @section Permissions

    enable_permissions = false, -- Enable/disable permission system for entire menu
    permissions = { -- Set specific permissions via ace perms
        --- Menus
        open_menu = { "dam.dev", "dam.admin" }, -- table | string | false - { "dam.dev" } | "dam.dev" | false (no perm check)
        view_players = { "dam.dev", "dam.admin" },
        view_bans = { "dam.dev", "dam.admin" },

        --- Bans
        remove_ban = { "dam.dev", "dam.admin" },

        --- Self Actions
        user = {
            noclip = { "dam.dev", "dam.admin" },
            godmode = { "dam.dev", "dam.admin" },
            invisible = { "dam.dev", "dam.admin" },
            freeze = { "dam.dev", "dam.admin" },
            teleport_waypoint = { "dam.dev", "dam.admin" },
            teleport_coords = { "dam.dev", "dam.admin" },
            revive = { "dam.dev", "dam.admin" },
            kill = { "dam.dev", "dam.admin" },
        },

        players = {
            godmode = { "dam.dev", "dam.admin" },
            invisible = { "dam.dev", "dam.admin" },
            kick = { "dam.dev", "dam.admin" },
            warn = { "dam.dev", "dam.admin" },
            ban = { "dam.dev", "dam.admin" },
            teleport = { "dam.dev", "dam.admin" },
            bring = { "dam.dev", "dam.admin" },
            revive = { "dam.dev", "dam.admin" },
            kill = { "dam.dev", "dam.admin" },
        },

        vehicles = {
            spawn = { "dam.dev", "dam.admin" },
            delete = { "dam.dev", "dam.admin" },
            repair = { "dam.dev", "dam.admin" }
        }
    }
}