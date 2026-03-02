--- @script client.user
--- @description Handles user actions; noclip, godmode, invisible etc.

--- @section Modules

local callbacks = require("libs.graft.callbacks")

--- @section Functions

function spawn_vehicle()
    dam.close_menu("admin")
    CreateThread(function()
        local input = get_keyboard_input("Enter vehicle model name")
        if not input or input == "" then open_admin_menu() return end
        callbacks.trigger("dam:sv:spawn_vehicle", {model = input:lower()}, function(r)
            if not r or not r.success then
                local msg = r and r.reason == "no_permission" and translate("notify.no_permission_action") or "Failed to spawn vehicle. Check model name."
                dam.send_notification({header = "Spawn Vehicle", type = "error", message = msg, duration = 3000})
                open_admin_menu()
                return
            end
            local timeout = GetGameTimer() + 5000
            repeat Wait(100) until NetworkDoesEntityExistWithNetworkId(r.net_id) or GetGameTimer() > timeout
            local vehicle = NetToVeh(r.net_id)
            if vehicle and vehicle ~= 0 then
                local ped = PlayerPedId()
                local current = GetVehiclePedIsIn(ped, false)
                if current ~= 0 then DeleteVehicle(current) end
                SetPedIntoVehicle(ped, vehicle, -1)
                dam.send_notification({header = "Spawn Vehicle", type = "success", message = ("Spawned: %s"):format(input:lower()), duration = 3000})
            else
                dam.send_notification({header = "Spawn Vehicle", type = "error", message = "Vehicle spawned but could not be found.", duration = 3000})
            end
            open_admin_menu()
        end)
    end)
end

function delete_vehicle()
    callbacks.trigger("dam:sv:delete_vehicle", {}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "not_in_vehicle" and "You are not in a vehicle." or translate("notify.no_permission_action")
            dam.send_notification({header = "Delete Vehicle", type = "error", message = msg, duration = 3000})
            return
        end
        dam.send_notification({header = "Delete Vehicle", type = "success", message = "Vehicle deleted.", duration = 3000})
    end)
end

function repair_vehicle()
    callbacks.trigger("dam:sv:repair_vehicle", {}, function(r)
        if not r or not r.success then
            dam.send_notification({header = "Repair", type = "error", message = translate("notify.no_permission_action"), duration = 3000})
            return
        end
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if not vehicle or vehicle == 0 then
            dam.send_notification({header = "Repair", type = "error", message = "You are not in a vehicle.", duration = 3000})
            return
        end
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        SetVehicleEngineHealth(vehicle, 1000.0)
        SetVehicleBodyHealth(vehicle, 1000.0)
        SetVehiclePetrolTankHealth(vehicle, 1000.0)
        SetVehicleFuelLevel(vehicle, 100.0)
        dam.send_notification({header = "Repair", type = "success", message = "Vehicle repaired.", duration = 3000})
    end)
end

function show_vehicle_panel()
    local vehicles = require("libs.graft.vehicles")
    dam.show_panel({
        id = "dam_vehicle_info",
        title = "Vehicle Info",
        style = {x = 0.015, y = 0.35, width = 0.16},
        lines = {
            {key = "Model", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return vehicles.get_model(veh)
            end},
            {key = "Class", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return vehicles.get_class(veh)
            end},
            {key = "Plate", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return vehicles.get_plate(veh)
            end},
            {key = "Body", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehicleBodyHealth(veh) / 1000) * 100)
            end},
            {key = "Engine", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehicleEngineHealth(veh) / 1000) * 100)
            end},
            {key = "Tank", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehiclePetrolTankHealth(veh) / 1000) * 100)
            end},
            {key = "Fuel", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", GetVehicleFuelLevel(veh))
            end},
            {key = "Oil", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.0f%%", (GetVehicleOilLevel(veh) / 1000) * 100)
            end},
            {key = "Dirt", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.1f", GetVehicleDirtLevel(veh))
            end},
            {key = "Eng. Temp", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.1f°", GetVehicleEngineTemperature(veh))
            end},
            {key = "Turbo", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", GetVehicleTurboPressure(veh))
            end},
            {key = "Max Speed", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.1f", vehicles.get_class_stats(veh).max_speed)
            end},
            {key = "Acceleration", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_acceleration)
            end},
            {key = "Agility", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_agility)
            end},
            {key = "Braking", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_braking)
            end},
            {key = "Traction", value = function()
                local veh = GetVehiclePedIsIn(PlayerPedId(), false)
                if not veh or veh == 0 then return "N/A" end
                return string.format("%.2f", vehicles.get_class_stats(veh).max_traction)
            end},
        }
    })
end