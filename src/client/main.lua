--- @script client.main
--- @description Handles client side for admin menu.

--- @section Modules

local callbacks = require("libs.graft.callbacks")
local user_menu = require("src.client.menus.user")
local players_menu = require("src.client.menus.players")
local vehicles_menu = require("src.client.menus.vehicles")

--- @section Global Functions

function remove_ban(unique_id)
    callbacks.trigger("dam:sv:remove_ban", {unique_id = unique_id}, function(r)
        if not r or not r.success then
            dam.send_notification({header = "Unban", type = "error", message = translate("notify.no_permission_action"), duration = 4000})
            return
        end
        dam.send_notification({header = "Unban", type = "success", message = "Player unbanned.", duration = 3000})
        callbacks.trigger("dam:sv:get_ban_list", {}, function(res)
            if not res then return end
            dam.close_menu("admin_bans")
            players_menu.open_ban_menu(res.bans)
        end)
    end)
end

function get_keyboard_input(title, max_length)
    AddTextEntry("FMMC_KEY_TIP1", title)
    DisplayOnscreenKeyboard(1, "FMMC_KEY_TIP1", "", "", "", "", "", max_length or 20)
    while UpdateOnscreenKeyboard() == 0 do
        DisableAllControlActions(0)
        Wait(0)
    end
    if UpdateOnscreenKeyboard() == 1 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end

function open_admin_menu()
    if dam.is_menu_open("admin") then
        dam.close_menu("admin")
        dam.close_menu("admin_players")
        dam.close_menu("admin_bans")
        return
    end
    dam.open_menu({
        id = "admin",
        root = "main",
        menus = {
            main = {
                title = "Admin Menu",
                items = {
                    { type = "submenu", label = "Self", desc = "Perform actions on yourself.", submenu = "user" },
                    { type = "submenu", label = "Players", desc = "Perform actions and check bans.", submenu = "players" },
                    { type = "submenu", label = "Vehicles", desc = "Perform vehicle actions.", submenu = "vehicles" },
                    { type = "separator" },
                    { type = "close", label = "Close", desc = "Close the menu." },
                },
            },
            user = user_menu.build(),
            players = players_menu.build(),
            vehicles = vehicles_menu.build()
        }
    })
end

--- @section Commands

RegisterKeyMapping("dam", "Open Admin Menu", "keyboard", "F7")
RegisterCommand("dam", function()
    callbacks.trigger("dam:sv:can_open_menu", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({header = translate("notify.access_denied"), type = "error", message = translate("notify.no_permission"), duration = 4000})
            return
        end
        open_admin_menu()
    end)
end, false)