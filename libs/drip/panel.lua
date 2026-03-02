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

--- @file panel
--- @description Panel component. Data driven KVP text panel, supports multiple instances via id.

--- @section Constants

local DEFAULT_STYLE = {
    x = 0.015,
    y = 0.35,
    width = 0.14,
    header_font = 4,
    header_scale = 0.34,
    header_height = 0.030,
    text_font = 0,
    text_scale = 0.30,
    line_h = 0.024,
    pad_x = 0.008,
    pad_y = 0.006,
    colours = {
        bg = {0, 0, 0, 180},
        bg_inner = {255, 255, 255, 15},
        header = {20, 20, 20, 255},
        header_text = {255, 255, 255, 255},
        key = {228, 173, 41, 255},
        value = {220, 220, 220, 220},
    }
}

--- @section State

local _panels = {}

--- @section Helpers

local function resolve(style, key)
    if style and style[key] ~= nil then return style[key] end
    return DEFAULT_STYLE[key]
end

local function col(colours, key, alpha_override)
    local c = colours[key]
    return c[1], c[2], c[3], alpha_override or c[4]
end

local function draw_text(str, x, y, font, scale, r, g, b, a, centre)
    SetTextFont(font)
    SetTextScale(scale, scale)
    SetTextColour(r, g, b, a)
    SetTextCentre(centre and 1 or 0)
    SetTextEntry("STRING")
    AddTextComponentString(str)
    DrawText(x, y)
end

--- @class Panel

local Panel = {}
Panel.__index = Panel

function Panel.new(data)
    local style = data.style or {}
    local colours = {}
    for k, v in pairs(DEFAULT_STYLE.colours) do colours[k] = v end
    if style.colours then
        for k, v in pairs(style.colours) do colours[k] = v end
    end
    return setmetatable({
        id = data.id,
        title = data.title or "Panel",
        lines = type(data.lines) == "table" and data.lines or {data.lines},
        x = resolve(style, "x"),
        y = resolve(style, "y"),
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
    }, Panel)
end

function Panel:get_height()
    return self.header_height + (#self.lines * self.line_h) + (self.pad_y * 2)
end

function Panel:draw()
    local x = self.x
    local y = self.y
    local w = self.width
    local cx = x + w / 2
    local box_h = self:get_height()
    local c = self.colours

    DrawRect(cx, y + box_h / 2, w, box_h, col(c, "bg"))
    DrawRect(cx, y + box_h / 2, w - 0.001, box_h - 0.001, col(c, "bg_inner"))

    local hcy = y + self.header_height / 2
    DrawRect(cx, hcy, w, self.header_height, col(c, "header"))
    DrawRect(cx, hcy - (self.header_height / 2) + 0.001, w, 0.002, col(c, "key"))
    local hr, hg, hb, ha = col(c, "header_text")
    draw_text(self.title, cx, hcy - 0.0125, self.header_font, self.header_scale, hr, hg, hb, ha, true)
    for i, line in ipairs(self.lines) do
        local ly = y + self.header_height + self.pad_y + ((i - 1) * self.line_h)
        if type(line) == "table" then
            local kc = line.key_colour or c.key
            local vc = line.value_colour or c.value
            local val = type(line.value) == "function" and tostring(line.value()) or tostring(line.value or "")
            draw_text(line.key or "", x + self.pad_x, ly, self.text_font, self.text_scale, kc[1], kc[2], kc[3], kc[4], false)
            draw_text(val, x + self.pad_x + (w * 0.45), ly, self.text_font, self.text_scale, vc[1], vc[2], vc[3], vc[4], false)
        else
            draw_text(line, x + self.pad_x, ly, self.text_font, self.text_scale, col(c, "value"))
        end
    end
end

--- @section Threads

CreateThread(function()
    while true do
        Wait(0)
        for _, panel in pairs(_panels) do
            panel:draw()
        end
    end
end)

--- @section API

local function show_panel(data)
    if not data.id then return end
    _panels[data.id] = Panel.new(data)
end

exports("show_panel", show_panel)
if dam then dam.show_panel = show_panel end

local function hide_panel(id)
    _panels[id] = nil
end

exports("hide_panel", hide_panel)
if dam then dam.hide_panel = hide_panel end

local function update_panel(data)
    if not data.id or not _panels[data.id] then return end
    _panels[data.id] = Panel.new(data)
end

exports("update_panel", update_panel)
if dam then dam.update_panel = update_panel end

local function is_panel_visible(id)
    return _panels[id] ~= nil
end

exports("is_panel_visible", is_panel_visible)
if dam then dam.is_panel_visible = is_panel_visible end

--- @section Test Command

RegisterCommand("dam:panel", function()
    if is_panel_visible("controls") then
        hide_panel("controls")
        hide_panel("status")
        return
    end

    show_panel({
        id = "controls",
        title = "Free Camera",
        style = {x = 0.015, y = 0.35, width = 0.14},
        lines = {
            {key = "[W/A/S/D]", value = "Move"},
            {key = "[Q/E]", value = "Up / Down"},
            {key = "[SHIFT]", value = "Fast"},
            {key = "[CTRL]", value = "Slow"},
            {key = "[BACKSPACE]", value = "Exit"},
        }
    })

    show_panel({
        id = "status",
        title = "Server Status",
        style = {x = 0.015, y = 0.60, width = 0.14},
        lines = {
            {key = "Time", value = function() return string.format("%02d:%02d", GetClockHours(), GetClockMinutes()) end},
            {key = "Weather", value = function() return GetPrevWeatherTypeHashName() end},
            {key = "Zone", value = function() return GetLabelText(GetNameOfZone(table.unpack(GetEntityCoords(PlayerPedId())))) end},
        }
    })
end, false)