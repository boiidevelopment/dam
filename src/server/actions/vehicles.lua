--- @file src.server.actions.user
--- @description Handles all user actions *(self)*

--- @section Modules

local cfg = require("custom.cfg")
local callbacks = require("libs.graft.callbacks")
local vehicles = require("libs.graft.vehicles")

callbacks.register("dam:sv:spawn_vehicle", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.user.spawn_vehicle) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    if not data.model or data.model == "" then cb({ success = false }) return end
    local ped = GetPlayerPed(source)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local net_id = vehicles.spawn(data.model, {
        coords = vector4(coords.x, coords.y, coords.z, heading),
        vehicle_type = "automobile"
    })
    cb({ success = net_id ~= nil, net_id = net_id })
end)

callbacks.register("dam:sv:delete_vehicle", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.user.delete_vehicle) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    local ped = GetPlayerPed(source)
    local vehicle = GetVehiclePedIsIn(ped, false)
    if not vehicle or vehicle == 0 then cb({ success = false, reason = "not_in_vehicle" }) return end
    DeleteEntity(vehicle)
    cb({ success = true })
end)

callbacks.register("dam:sv:repair_vehicle", function(source, data, cb)
    if not dam.has_permission(source, cfg.permissions.user.repair_vehicle) then
        cb({ success = false, reason = "no_permission" })
        return
    end
    cb({ success = true })
end)