--[[
--------------------------------------------------

This file is part of DRIP.
You are free to use these files within your own resources.
Please retain the original credit and attached MIT license.
Support honest development.

Author: Case @ BOII Development
License: MIT (https://github.com/boiidevelopment/drip/blob/main/LICENSE)
GitHub: https://github.com/boiidevelopment/drip

--------------------------------------------------
]]

if IsDuplicityVersion() then return end

--- @file client.notify
--- @description Handles notifcation component; types: "success", "error", "info", "warning"

--- @section Constants

local RESOURCE_NAME = GetCurrentResourceName()

local DEFAULT_STYLE = {
    x = 0.785,
    y = 0.0275,
    width = 0.20,
    gap = 0.006,
    header_font = 4,
    header_scale = 0.34,
    header_height = 0.030,
    text_font = 0,
    text_scale = 0.30,
    line_h = 0.024,
    pad_x = 0.008,
    pad_y = 0.006,
    wrap = 40,
    colours = {
        bg = {0, 0, 0, 180},
        bg_inner = {255, 255, 255, 15},
        header = {20, 20, 20, 255},
        text = {220, 220, 220, 220},
        success = {80, 200, 120, 255},
        error = {200, 80, 80, 255},
        info = {80, 160, 255, 255},
        warning = {228, 173, 41, 255},
    }
}

--- @section Helpers

local function resolve(style, key)
    if style and style[key] ~= nil then return style[key] end
    return DEFAULT_STYLE[key]
end

local function col(colours, key, alpha_override)
    local c = colours[key]
    return c[1], c[2], c[3], alpha_override or c[4]
end

local function draw_text(str, x, y, font, scale, r, g, b, a, centre, shadow)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(centre and 1 or 0)
    if shadow then SetTextDropShadow() end
    SetTextEntry("STRING")
    AddTextComponentString(str)
    DrawText(x, y)
end

local function wrap_text(str, limit)
    local lines = {}
    local current = ""
    for word in str:gmatch("%S+") do
        if #current + #word + 1 > limit then
            lines[#lines + 1] = current
            current = word
        else
            current = current == "" and word or current .. " " .. word
        end
    end
    if current ~= "" then lines[#lines + 1] = current end
    return lines
end

--- @section State

local _queue = {}

--- @class Notify

local Notify = {}
Notify.__index = Notify

function Notify.new(data)
    local style = data.style or {}
    local colours = {}
    for k, v in pairs(DEFAULT_STYLE.colours) do colours[k] = v end
    if style.colours then
        for k, v in pairs(style.colours) do colours[k] = v end
    end
    local wrap = resolve(style, "wrap")
    local lines = wrap_text(data.message or "", wrap)
    return setmetatable({
        header = data.header or "Notice",
        type = data.type or "info",
        lines = lines,
        duration = data.duration or 3000,
        expires = GetGameTimer() + (data.duration or 3000),
        x = resolve(style, "x"),
        width = resolve(style, "width"),
        header_font = resolve(style, "header_font"),
        header_scale = resolve(style, "header_scale"),
        header_height = resolve(style, "header_height"),
        text_font = resolve(style, "text_font"),
        text_scale = resolve(style, "text_scale"),
        line_h = resolve(style, "line_h"),
        pad_x = resolve(style, "pad_x"),
        pad_y = resolve(style, "pad_y"),
        colours = colours,
    }, Notify)
end

function Notify:is_expired()
    return GetGameTimer() > self.expires
end

function Notify:get_height()
    return self.header_height + (#self.lines * self.line_h) + (self.pad_y * 2)
end

function Notify:draw(y)
    local cx = self.x + self.width / 2
    local header_h = self.header_height
    local body_h = (#self.lines * self.line_h) + (self.pad_y * 2)
    local box_h = header_h + body_h
    local c = self.colours
    DrawRect(cx, y + box_h / 2, self.width, box_h, col(c, "bg"))
    DrawRect(cx, y + box_h / 2, self.width - 0.001, box_h - 0.001, col(c, "bg_inner"))
    local hcy = y + header_h / 2
    DrawRect(cx, hcy, self.width, header_h, col(c, "header"))
    DrawRect(cx, hcy - (header_h / 2) + 0.001, self.width, 0.002, col(c, self.type))
    local tr, tg, tb, ta = col(c, self.type)
    draw_text(self.header, cx, hcy - 0.013, self.header_font, self.header_scale, tr, tg, tb, ta, true)
    for i, line in ipairs(self.lines) do
        local ly = y + header_h + self.pad_y + ((i - 1) * self.line_h)
        draw_text(line, self.x + self.pad_x, ly, self.text_font, self.text_scale, col(c, "text"))
    end
end

--- @section API

local function send_notification(data)
    _queue[#_queue + 1] = Notify.new(data)
end

exports("send_notification", send_notification)
if dam then dam.send_notification = send_notification end

RegisterNetEvent(RESOURCE_NAME .. ":send_notification", function(data)
    if not data then return end
    send_notification(data)
end)

--- @section Threads

CreateThread(function()
    while true do
        Wait(0)
        if #_queue == 0 then Wait(500) end

        local y = DEFAULT_STYLE.y
        local i = 1

        while i <= #_queue do
            local n = _queue[i]
            if n:is_expired() then
                table.remove(_queue, i)
            else
                n:draw(y)
                y = y + n:get_height() + DEFAULT_STYLE.gap
                i = i + 1
            end
        end
    end
end)

--- @section Test Command

RegisterCommand("dam:notify", function()
    send_notification({style = {x = 0.785, width = 0.20}, header = "Success", type = "success", message = "Player has been healed. Player has been healed. Player has been healed. Player has been healed.", duration = 30000})
    send_notification({style = {x = 0.785, width = 0.20}, header = "Error", type = "error", message = "Something went wrong.", duration = 30000})
    send_notification({style = {x = 0.785, width = 0.20}, header = "Info", type = "info", message = "Server restart in 10 minutes.", duration = 30000})
    send_notification({style = {x = 0.785, width = 0.20}, header = "Warning", type = "warning", message = "Low server performance detected.", duration = 30000})
end, false)