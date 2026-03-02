--- @script client.menus.players
--- @description Players menu builder.

local callbacks = require("libs.graft.callbacks")

local m = {}
local cached_warnings = {}

local function build_player_menu(players)
    local menus = {
        players = { title = "Player List", items = {} }
    }
    for _, p in ipairs(players) do
        local key = "player_" .. p.source
        local warn_key = "warnings_" .. p.source
        menus.players.items[#menus.players.items + 1] = {
            type = "submenu",
            label = "[" .. p.source .. "] " .. p.name,
            submenu = key
        }
        local warn_items = {}
        local cached = cached_warnings[p.source]
        if cached then
            if #cached > 0 then
                for _, w in ipairs(cached) do
                    warn_items[#warn_items + 1] = { type = "action", label = "By: ".. w.warned_by .. " | For: " .. w.reason, desc = w.created, on_action = function() end }
                end
            else
                warn_items[#warn_items + 1] = { type = "action", label = "No warnings.", on_action = function() end }
            end
        else
            warn_items[#warn_items + 1] = { type = "action", label = "Loading...", on_action = function() end }
        end
        warn_items[#warn_items + 1] = { type = "separator" }
        warn_items[#warn_items + 1] = { type = "back", key = key, label = "Back", desc = "Return to player." }
        menus[warn_key] = { title = "Warnings: " .. p.name, items = warn_items }
        menus[key] = {
            title = "[" .. p.source .. "] " .. p.name,
            items = {
                { type = "action", label = "Revive", desc = "Revive player.", keep_open = true, on_action = function() revive_player(p.source) end },
                { type = "action", label = "Kill", desc = "Kill player.", keep_open = true, on_action = function() kill_player(p.source) end },
                { type = "action", label = "Teleport To", desc = "Teleport to player.", keep_open = true, on_action = function() teleport_to_player(p.source) end },
                { type = "action", label = "Bring", desc = "Bring player to you.", keep_open = true, on_action = function() bring_player(p.source) end },
                { type = "action", label = "Kick", desc = "Kick player.", keep_open = true, on_action = function() kick_player(p.source) end },
                { type = "action", label = "Warn", desc = "Warn player.", keep_open = true, on_action = function() warn_player(p.source) end },
                { type = "submenu", label = "View Warnings", desc = "View player warnings.", submenu = warn_key },
                { type = "action", label = "Ban", desc = "Ban player.", keep_open = true, on_action = function() ban_player(p.source) end },
                { type = "separator" },
                { type = "back", key = "players", label = "Back", desc = "Return to player list." },
            }
        }
    end
    menus.players.items[#menus.players.items + 1] = {type = "separator"}
    menus.players.items[#menus.players.items + 1] = {type = "close", label = "Close"}
    return menus
end

local function fetch_warnings(players)
    for _, p in ipairs(players) do
        if not cached_warnings[p.source] then
            callbacks.trigger("dam:sv:get_player_warnings", {target = p.source}, function(r)
                if r and r.success then
                    cached_warnings[p.source] = r.warnings
                end
            end)
        end
    end
end

local function open_player_menu(players)
    local menus = build_player_menu(players)
    if dam.is_menu_open("admin_players") then
        dam.update_menus("admin_players", menus)
        return
    end
    dam.open_menu({
        id = "admin_players",
        root = "players",
        style = { x = 0.250, y = 0.0275, width = 0.22 },
        menus = menus
    })
end

local function start_player_poll()
    cached_warnings = {}
    CreateThread(function()
        while dam.is_menu_open("admin_players") do
            callbacks.trigger("dam:sv:get_player_list", {}, function(response)
                if not response or not dam.is_menu_open("admin_players") then return end
                fetch_warnings(response.players)
                open_player_menu(response.players)
            end)
            Wait(5000)
        end
        cached_warnings = {}
    end)
end

local function start_ban_poll()
    CreateThread(function()
        while dam.is_menu_open("admin_bans") do
            callbacks.trigger("dam:sv:get_ban_list", {}, function(r)
                if not r or not dam.is_menu_open("admin_bans") then return end
                m.open_ban_menu(r.bans)
            end)
            Wait(30000)
        end
    end)
end

function m.build()
    return {
        title = "Player Actions",
        items = {
            {
                type = "action",
                label = "Player List",
                desc = "View and manage online players.",
                keep_open = true,
                on_action = function()
                    callbacks.trigger("dam:sv:can_view_players", {}, function(response)
                        if not response or not response.allowed then
                            dam.send_notification({header = translate("notify.access_denied"), type = "error", message = translate("notify.no_permission_action"), duration = 4000})
                            return
                        end
                        callbacks.trigger("dam:sv:get_player_list", {}, function(r)
                            if not r then return end
                            fetch_warnings(r.players)
                            open_player_menu(r.players)
                            start_player_poll()
                        end)
                    end)
                end
            },
            {
                type = "action",
                label = "Ban List",
                desc = "View and manage active bans.",
                keep_open = true,
                on_action = function()
                    callbacks.trigger("dam:sv:can_view_bans", {}, function(response)
                        if not response or not response.allowed then
                            dam.send_notification({header = translate("notify.access_denied"), type = "error", message = translate("notify.no_permission_action"), duration = 4000})
                            return
                        end
                        callbacks.trigger("dam:sv:get_ban_list", {}, function(r)
                            if not r then return end
                            m.open_ban_menu(r.bans)
                            start_ban_poll()
                        end)
                    end)
                end
            },
            { type = "separator" },
            { type = "back", key = "main", label = "Back", desc = "Go back to main menu." },
        }
    }
end

local function build_ban_menu(bans)
    local menus = {
        bans = { title = "Ban List", items = {} }
    }
    for _, b in ipairs(bans) do
        local key = "ban_" .. b.id
        menus.bans.items[#menus.bans.items + 1] = {
            type = "submenu",
            label = b.unique_id .. " | " .. b.name .. " | " .. (b.expires_formatted or "Permanent"),
            submenu = key
        }
        menus[key] = {
            title = b.name,
            items = {
                { type = "action", label = "Remove", desc = "Remove this ban.", keep_open = true, on_action = function() remove_ban(b.unique_id) end },
                { type = "separator" },
                { type = "back", key = "bans", label = "Back", desc = "Return to ban list." },
            }
        }
    end
    if #menus.bans.items == 0 then
        menus.bans.items[#menus.bans.items + 1] = { type = "action", label = "No active bans.", on_action = function() end }
    end
    menus.bans.items[#menus.bans.items + 1] = {type = "separator"}
    menus.bans.items[#menus.bans.items + 1] = {type = "close", label = "Close"}
    return menus
end

function m.open_ban_menu(bans)
    local menus = build_ban_menu(bans)
    if dam.is_menu_open("admin_bans") then
        dam.update_menus("admin_bans", menus)
        return
    end
    dam.open_menu({
        id = "admin_bans",
        root = "bans",
        style = { x = 0.485, y = 0.0275, width = 0.22 },
        menus = menus
    })
end

return m