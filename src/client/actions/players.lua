--- @script client.user
--- @description Handles user actions; noclip, godmode, invisible etc.

--- @section Modules

local callbacks = require("libs.graft.callbacks")

--- @section Functions

function revive_player(target)
    callbacks.trigger("dam:sv:revive_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No revive hook configured." or translate("notify.no_permission_action")
            dam.send_notification({header = "Revive", type = "error", message = msg, duration = 4000})
            return
        end
        dam.send_notification({header = "Revive", type = "success", message = "Player revived.", duration = 3000})
    end)
end

function kill_player(target)
    callbacks.trigger("dam:sv:kill_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No kill hook configured." or translate("notify.no_permission_action")
            dam.send_notification({header = "Kill", type = "error", message = msg, duration = 4000})
            return
        end
        dam.send_notification({header = "Kill", type = "success", message = "Player killed.", duration = 3000})
    end)
end

function teleport_to_player(target)
    callbacks.trigger("dam:sv:teleport_to_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_permission" and translate("notify.no_permission_action") or "Failed to teleport."
            dam.send_notification({header = "Teleport", type = "error", message = msg, duration = 4000})
            return
        end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        local entity = vehicle > 0 and vehicle or ped
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        SetPedCoordsKeepVehicle(ped, r.coords.x, r.coords.y, r.coords.z)
        DoScreenFadeIn(500)
        dam.send_notification({header = "Teleport", type = "success", message = "Teleported to player.", duration = 3000})
    end)
end

function bring_player(target)
    callbacks.trigger("dam:sv:bring_player", {target = target}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_permission" and translate("notify.no_permission_action") or "Failed to bring player."
            dam.send_notification({header = "Bring", type = "error", message = msg, duration = 4000})
            return
        end
        dam.send_notification({header = "Bring", type = "success", message = "Player brought to you.", duration = 3000})
    end)
end

function ban_player(target)
    dam.close_menu("admin_players")
    CreateThread(function()
        local reason = get_keyboard_input("Enter ban reason", 100)
        if not reason or reason == "" then reason = "No reason provided." end
        local duration_input = get_keyboard_input("Enter duration in minutes (0 = permanent)", 10)
        local duration = tonumber(duration_input)
        if duration and duration > 0 then duration = duration * 60 else duration = nil end
        callbacks.trigger("dam:sv:ban_player", {target = target, reason = reason, duration = duration}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and translate("notify.no_permission_action") or "Failed to ban player."
                dam.send_notification({header = "Ban", type = "error", message = msg, duration = 4000})
                return
            end
            dam.send_notification({header = "Ban", type = "success", message = "Player banned.", duration = 3000})
        end)
    end)
end

function kick_player(target)
    dam.close_menu("admin_players")
    CreateThread(function()
        local reason = get_keyboard_input("Enter kick reason", 100)
        if not reason or reason == "" then reason = "No reason provided." end
        callbacks.trigger("dam:sv:kick_player", {target = target, reason = reason}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and translate("notify.no_permission_action") or "Failed to kick player."
                dam.send_notification({header = "Kick", type = "error", message = msg, duration = 4000})
                return
            end
            dam.send_notification({header = "Kick", type = "success", message = "Player kicked.", duration = 3000})
        end)
    end)
end

function warn_player(target)
    dam.close_menu("admin_players")
    CreateThread(function()
        local reason = get_keyboard_input("Enter warn reason", 100)
        if not reason or reason == "" then reason = "No reason provided." end
        callbacks.trigger("dam:sv:warn_player", {target = target, reason = reason}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and translate("notify.no_permission_action") or "Failed to warn player."
                dam.send_notification({header = "Warn", type = "error", message = msg, duration = 4000})
                return
            end
            dam.send_notification({header = "Warn", type = "success", message = "Player warned.", duration = 3000})
        end)
    end)
end

RegisterNetEvent("dam:cl:warned", function(reason)
    dam.send_notification({header = "Warning", type = "error", message = "You have been warned: " .. reason, duration = 6000})
end)