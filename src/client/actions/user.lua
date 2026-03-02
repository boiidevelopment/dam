--- @script client.user
--- @description Handles user actions; noclip, godmode, invisible etc.

--- @section Modules

local callbacks = require("libs.graft.callbacks")
local keys = require("libs.graft.keys")
local key_list = keys.get_keys()

--- @section Constants

local BASE_SPEED = 0.8
local SLOW_SPEED = 0.03
local FAST_MULT = 4.0
local BASE_ACCEL = 0.04
local FRICTION = 0.85
local SCROLL_STEP = 0.5
local SCROLL_MIN = 0.5
local SCROLL_MAX = 6.0

--- @section State

local noclip_active = false
local noclip_cam = nil
local noclip_vel = vector3(0.0, 0.0, 0.0)
local noclip_speed_mult = 1.0
local godmode_active = false
local invisible_active = false
local freeze_active = false

--- @section Helper Functions

local function is_pressed(group, control)
    return IsControlPressed(group, control) or IsDisabledControlPressed(group, control)
end

local function find_ground(x, y, z)
    for i = 0, 500 do
        local found, ground_z = GetGroundZFor_3dCoord(x, y, z - i * 0.1, false)
        if found then return ground_z end
    end
    return z
end

--- @section Action Functions

local function start_noclip()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    noclip_cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(noclip_cam, pos.x, pos.y, pos.z + 2.0)
    SetCamRot(noclip_cam, 0.0, 0.0, GetEntityHeading(ped), 2)
    SetCamFov(noclip_cam, 70.0)
    RenderScriptCams(true, false, 0, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    noclip_vel = vector3(0.0, 0.0, 0.0)
    noclip_speed_mult = 1.0
    noclip_active = true
end

local function stop_noclip()
    noclip_active = false
    local cam_pos = GetCamCoord(noclip_cam)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(noclip_cam, false)
    noclip_cam = nil
    local ped = PlayerPedId()
    local ground_z = find_ground(cam_pos.x, cam_pos.y, cam_pos.z)
    SetEntityCoords(ped, cam_pos.x, cam_pos.y, ground_z + 0.5, false, false, false, false)
    FreezeEntityPosition(ped, false)
    SetEntityAlpha(ped, 255, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
end

--- @section Threads

CreateThread(function()
    local key_list = keys.get_keys()
    while true do
        Wait(0)
        if noclip_active and noclip_cam then
            local mx = GetDisabledControlNormal(0, 1)
            local my = GetDisabledControlNormal(0, 2)
            local rot = GetCamRot(noclip_cam, 2)
            local new_z = rot.z - mx * 5.0
            local new_x = math.max(-89.0, math.min(89.0, rot.x - my * 5.0))
            SetCamRot(noclip_cam, new_x, 0.0, new_z, 2)
            local rad_z = math.rad(new_z)
            local rad_x = math.rad(new_x)
            local fx = -math.sin(rad_z) * math.cos(rad_x)
            local fy =  math.cos(rad_z) * math.cos(rad_x)
            local fz =  math.sin(rad_x)
            local rx = -math.sin(math.rad(new_z - 90.0))
            local ry =  math.cos(math.rad(new_z - 90.0))
            if is_pressed(2, 15) then
                noclip_speed_mult = math.min(SCROLL_MAX, noclip_speed_mult + SCROLL_STEP)
            elseif is_pressed(2, 14) then
                noclip_speed_mult = math.max(SCROLL_MIN, noclip_speed_mult - SCROLL_STEP)
            end
            local top_speed = BASE_SPEED * noclip_speed_mult
            local accel = BASE_ACCEL * noclip_speed_mult
            if is_pressed(0, key_list["leftcontrol"]) then
                top_speed = SLOW_SPEED
                accel = BASE_ACCEL * 0.5
            elseif is_pressed(0, key_list["leftshift"]) then
                top_speed = BASE_SPEED * FAST_MULT * noclip_speed_mult
                accel = BASE_ACCEL * 4.0
            end
            local input = vector3(0.0, 0.0, 0.0)
            if is_pressed(0, key_list["w"]) then input = input + vector3(fx, fy, fz) end
            if is_pressed(0, key_list["s"]) then input = input - vector3(fx, fy, fz) end
            if is_pressed(0, key_list["a"]) then input = input - vector3(rx, ry, 0.0) end
            if is_pressed(0, key_list["d"]) then input = input + vector3(rx, ry, 0.0) end
            if is_pressed(0, key_list["q"]) then input = input + vector3(0.0, 0.0, 1.0) end
            if is_pressed(0, key_list["z"]) then input = input - vector3(0.0, 0.0, 1.0) end
            noclip_vel = noclip_vel + input * accel
            local spd = math.sqrt(noclip_vel.x^2 + noclip_vel.y^2 + noclip_vel.z^2)
            if spd > top_speed then
                noclip_vel = noclip_vel * (top_speed / spd)
            end
            noclip_vel = noclip_vel * FRICTION
            local pos = GetCamCoord(noclip_cam)
            local new_pos = vector3(pos.x + noclip_vel.x, pos.y + noclip_vel.y, pos.z + noclip_vel.z)
            SetCamCoord(noclip_cam, new_pos.x, new_pos.y, new_pos.z)
            SetEntityCoordsNoOffset(PlayerPedId(), new_pos.x, new_pos.y, new_pos.z, false, false, false)
            DisableAllControlActions(0)
        end
    end
end)

--- @section API

function toggle_noclip()
    callbacks.trigger("dam:sv:toggle_noclip", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({
                header = translate("notify.access_denied"),
                type = "error",
                message = translate("notify.no_noclip_permission"),
                duration = 4000
            })
            return
        end
        if noclip_active then stop_noclip() else start_noclip() end
    end)
end

function toggle_godmode()
    callbacks.trigger("dam:sv:toggle_godmode", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({
                header = translate("notify.access_denied"),
                type = "error",
                message = translate("notify.no_permission_action"),
                duration = 4000
            })
            return
        end
        godmode_active = not godmode_active
        SetEntityInvincible(PlayerPedId(), godmode_active)
        SetPlayerInvincible(PlayerId(), godmode_active)
        dam.send_notification({
            header = "God Mode",
            type = godmode_active and "success" or "info",
            message = godmode_active and "God mode enabled." or "God mode disabled.",
            duration = 3000
        })
    end)
end

function toggle_invisible()
    callbacks.trigger("dam:sv:toggle_invisible", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({
                header = translate("notify.access_denied"),
                type = "error",
                message = translate("notify.no_permission_action"),
                duration = 4000
            })
            return
        end
        invisible_active = not invisible_active
        SetEntityVisible(PlayerPedId(), not invisible_active, false)
        SetEntityAlpha(PlayerPedId(), invisible_active and 0 or 255, false)
        dam.send_notification({
            header = "Invisible",
            type = invisible_active and "success" or "info",
            message = invisible_active and "Invisibility enabled." or "Invisibility disabled.",
            duration = 3000
        })
    end)
end

function toggle_freeze()
    callbacks.trigger("dam:sv:toggle_freeze", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({header = translate("notify.access_denied"), type = "error", message = translate("notify.no_permission_action"), duration = 4000})
            return
        end
        freeze_active = not freeze_active
        FreezeEntityPosition(PlayerPedId(), freeze_active)
        dam.send_notification({
            header = "Freeze",
            type = freeze_active and "success" or "info",
            message = freeze_active and "Frozen." or "Unfrozen.",
            duration = 3000
        })
    end)
end

function teleport_to_waypoint()
    callbacks.trigger("dam:sv:can_teleport_waypoint", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({
                header = translate("notify.access_denied"),
                type = "error",
                message = translate("notify.no_permission_action"),
                duration = 4000
            })
            return
        end
        local blip = GetFirstBlipInfoId(8)
        if not DoesBlipExist(blip) then
            dam.send_notification({
                header = "Teleport",
                type = "error",
                message = "No waypoint set.",
                duration = 3000
            })
            return
        end
        local ped = PlayerPedId()
        local coords = GetBlipInfoIdCoord(blip)
        local vehicle = GetVehiclePedIsIn(ped, false)
        local entity = vehicle > 0 and vehicle or ped
        local old_coords = GetEntityCoords(ped)
        local x, y = coords.x, coords.y
        local ground_z = 850.0
        local found = false
        DoScreenFadeOut(500)
        while not IsScreenFadedOut() do Wait(0) end
        FreezeEntityPosition(entity, true)
        for i = 950.0, 0, -25.0 do
            local z = (i % 2) ~= 0 and (950.0 - i) or i
            NewLoadSceneStart(x, y, z, x, y, z, 50.0, 0)
            local t = GetGameTimer()
            while IsNetworkLoadingScene() do
                if GetGameTimer() - t > 1000 then break end
                Wait(0)
            end
            NewLoadSceneStop()
            SetPedCoordsKeepVehicle(ped, x, y, z)
            local t2 = GetGameTimer()
            while not HasCollisionLoadedAroundEntity(ped) do
                RequestCollisionAtCoord(x, y, z)
                if GetGameTimer() - t2 > 1000 then break end
                Wait(0)
            end
            found, ground_z = GetGroundZFor_3dCoord(x, y, z, false)
            if found then
                SetPedCoordsKeepVehicle(ped, x, y, ground_z)
                break
            end
            Wait(0)
        end
        FreezeEntityPosition(entity, false)
        DoScreenFadeIn(500)
        if not found then
            SetPedCoordsKeepVehicle(ped, old_coords.x, old_coords.y, old_coords.z)
            dam.send_notification({header = "Teleport", type = "error", message = "Could not find ground, returned to original position.", duration = 3000})
            return
        end
        dam.send_notification({header = "Teleport", type = "success", message = "Teleported to waypoint.", duration = 3000})
    end)
end

function teleport_to_coords()
    callbacks.trigger("dam:sv:can_teleport_coords", {}, function(response)
        if not response or not response.allowed then
            dam.send_notification({header = translate("notify.access_denied"), type = "error", message = translate("notify.no_permission_action"), duration = 4000})
            return
        end
        dam.close_menu("admin")
        CreateThread(function()
            local input = get_keyboard_input("Enter coords: x, y, z")
            if not input then open_admin_menu() return end
            local x, y, z = input:match("([%-%.%d]+),%s*([%-%.%d]+),%s*([%-%.%d]+)")
            x, y, z = tonumber(x), tonumber(y), tonumber(z)
            if not x or not y or not z then
                dam.send_notification({header = "Teleport", type = "error", message = "Invalid format. Use: x, y, z", duration = 3000})
                open_admin_menu()
                return
            end
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            local entity = vehicle > 0 and vehicle or ped
            local old_coords = GetEntityCoords(ped)
            local found = false
            local ground_z = 850.0
            DoScreenFadeOut(500)
            while not IsScreenFadedOut() do Wait(0) end
            FreezeEntityPosition(entity, true)
            for i = 950.0, 0, -25.0 do
                local zi = (i % 2) ~= 0 and (950.0 - i) or i
                NewLoadSceneStart(x, y, zi, x, y, zi, 50.0, 0)
                local t = GetGameTimer()
                while IsNetworkLoadingScene() do
                    if GetGameTimer() - t > 1000 then break end
                    Wait(0)
                end
                NewLoadSceneStop()
                SetPedCoordsKeepVehicle(ped, x, y, zi)
                local t2 = GetGameTimer()
                while not HasCollisionLoadedAroundEntity(ped) do
                    RequestCollisionAtCoord(x, y, zi)
                    if GetGameTimer() - t2 > 1000 then break end
                    Wait(0)
                end
                found, ground_z = GetGroundZFor_3dCoord(x, y, zi, false)
                if found then
                    SetPedCoordsKeepVehicle(ped, x, y, ground_z)
                    break
                end
                Wait(0)
            end
            FreezeEntityPosition(entity, false)
            DoScreenFadeIn(500)
            if not found then
                SetPedCoordsKeepVehicle(ped, old_coords.x, old_coords.y, old_coords.z)
                dam.send_notification({header = "Teleport", type = "error", message = "Could not find ground, returned to original position.", duration = 3000})
                open_admin_menu()
                return
            end
            dam.send_notification({header = "Teleport", type = "success", message = ("Teleported to %.1f, %.1f, %.1f"):format(x, y, ground_z), duration = 3000})
            open_admin_menu()
        end)
    end)
end

function revive_self()
    callbacks.trigger("dam:sv:revive_self", {}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No revive hook configured." or translate("notify.no_permission_action")
            dam.send_notification({header = "Revive", type = "error", message = msg, duration = 4000})
            return
        end
        dam.send_notification({header = "Revive", type = "success", message = "You revived yourself.", duration = 3000})
    end)
end

function kill_self()
    callbacks.trigger("dam:sv:kill_self", {}, function(r)
        if not r or not r.success then
            local msg = r and r.reason == "no_hook" and "No kill hook configured." or translate("notify.no_permission_action")
            dam.send_notification({header = "Kill", type = "error", message = msg, duration = 4000})
            return
        end
        dam.send_notification({header = "Kill", type = "success", message = "You killed yourself.", duration = 3000})
    end)
end