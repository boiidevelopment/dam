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

--- @file input
--- @description Handles input component; field types: select (left/right arrows), number (left/right arrows), action (enter)

--- @section Constants

local KEY_UP = 27
local KEY_DOWN = 173
local KEY_LEFT = 174
local KEY_RIGHT = 175
local KEY_ENTER = 18
local KEY_ESCAPE = 322

local DEFAULT_STYLE = {
    x = nil,
    y = nil,
    width = 0.22,
    pad_x = 0.008,
    pad_y = 0.006,
    header_font = 4,
    header_scale = 0.34,
    header_height = 0.030,
    text_font = 0,
    text_scale = 0.30,
    line_h = 0.024,
    val_w = 0.07,
    colours = {
        bg = {0, 0, 0, 180},
        bg_inner = {255, 255, 255, 15},
        header = {20, 20, 20, 255},
        header_text = {255, 255, 255, 255},
        text = {220, 220, 220, 220},
        text_sel = {255, 255, 255, 255},
        highlight = {255, 255, 255, 30},
        accent = {228, 173, 41, 255},
        val_bg = {60, 60, 60, 200},
        val_fill = {228, 173, 41, 180},
    }
}

--- @section State

local _active = nil
local _visible = false

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

--- @class Input

local Input = {}
Input.__index = Input

function Input.new(data)
    local style = data.style or {}
    local colours = {}
    for k, v in pairs(DEFAULT_STYLE.colours) do colours[k] = v end
    if style.colours then
        for k, v in pairs(style.colours) do colours[k] = v end
    end

    local fields = {}
    for i, field in ipairs(data.inputs or {}) do
        local f = {
            id = field.id,
            type = field.type or "select",
            label = field.label or "",
        }
        if field.type == "select" then
            f.options = field.options or {}
            f.option_index = field.default_index or 1
            local opt = f.options[f.option_index]
            f.value = opt and (type(opt) == "table" and opt.value or opt) or ""
        elseif field.type == "number" then
            f.min = field.min or 0
            f.max = field.max or 100
            f.step = field.step or 1
            f.value = field.default ~= nil and field.default or f.min
        end
        fields[i] = f
    end

    fields[#fields + 1] = {id = "__confirm", type = "action", label = "Confirm"}
    fields[#fields + 1] = {id = "__cancel", type = "action", label = "Cancel"}

    return setmetatable({
        title = data.title or "Input",
        fields = fields,
        index = 1,
        on_confirm = data.on_confirm,
        on_cancel = data.on_cancel,
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
        val_w = resolve(style, "val_w"),
        colours = colours,
    }, Input)
end

function Input:current_field()
    return self.fields[self.index]
end

function Input:nav_up()
    self.index = self.index > 1 and self.index - 1 or #self.fields
end

function Input:nav_down()
    self.index = self.index < #self.fields and self.index + 1 or 1
end

function Input:nav_left()
    local field = self:current_field()
    if not field then return end
    if field.type == "select" then
        field.option_index = field.option_index > 1 and field.option_index - 1 or #field.options
        local opt = field.options[field.option_index]
        field.value = type(opt) == "table" and opt.value or opt
    elseif field.type == "number" then
        field.value = math.max(field.min, field.value - field.step)
    end
end

function Input:nav_right()
    local field = self:current_field()
    if not field then return end
    if field.type == "select" then
        field.option_index = field.option_index < #field.options and field.option_index + 1 or 1
        local opt = field.options[field.option_index]
        field.value = type(opt) == "table" and opt.value or opt
    elseif field.type == "number" then
        field.value = math.min(field.max, field.value + field.step)
    end
end

function Input:activate()
    local field = self:current_field()
    if not field then return end
    if field.id == "__confirm" then
        local values = {}
        for _, f in ipairs(self.fields) do
            if f.type ~= "action" then
                values[f.id] = f.value
            end
        end
        _visible = false
        _active = nil
        if self.on_confirm then self.on_confirm(values) end
    elseif field.id == "__cancel" then
        _visible = false
        _active = nil
        if self.on_cancel then self.on_cancel() end
    end
end

function Input:get_height()
    local total = self.header_height + self.pad_y
    for _, _ in ipairs(self.fields) do
        total = total + self.line_h + self.pad_y
    end
    return total + self.pad_y
end

function Input:draw()
    local w = self.width
    local box_h = self:get_height()
    local x = self.x or (0.5 - w / 2)
    local y = self.y or (0.5 - box_h / 2)
    local cx = x + w / 2
    local c = self.colours

    DrawRect(cx, y + box_h / 2, w, box_h, col(c, "bg"))
    DrawRect(cx, y + box_h / 2, w - 0.001, box_h - 0.001, col(c, "bg_inner"))

    local hcy = y + self.header_height / 2
    DrawRect(cx, hcy, w, self.header_height, col(c, "header"))
    DrawRect(cx, hcy - (self.header_height / 2) + 0.001, w, 0.002, col(c, "accent"))
    local hr, hg, hb, ha = col(c, "header_text")
    draw_text(self.title, cx, hcy - 0.0125, self.header_font, self.header_scale, hr, hg, hb, ha, true)

    local fy = y + self.header_height + self.pad_y * 2
    local vw = self.val_w

    for i, field in ipairs(self.fields) do
        local is_sel = i == self.index
        local row_cy = fy + self.line_h / 2
        local vx = x + w - self.pad_x - vw
        local tc = is_sel and "text_sel" or "text"

        if is_sel then
            DrawRect(cx, row_cy, w, self.line_h, col(c, "highlight"))
        end
        if field.type == "action" then
            local tr, tg, tb, ta = col(c, tc)
            draw_text(field.label, cx, fy - 0.001, self.text_font, self.text_scale, tr, tg, tb, ta, true)
        else
            draw_text(field.label, x + self.pad_x, fy - 0.001, self.text_font, self.text_scale, col(c, is_sel and "text_sel" or "text"))
            if field.type == "select" then
                local opt = field.options[field.option_index]
                local display = type(opt) == "table" and opt.label or tostring(opt or "")
                local vr, vg, vb, va = col(c, is_sel and "accent" or "text")
                DrawRect(vx + vw / 2, row_cy, vw, self.line_h - 0.004, col(c, "val_bg"))
                draw_text(display, vx + vw / 2, fy + 0.001, self.text_font, 0.26, vr, vg, vb, va, true)
            elseif field.type == "number" then
                local pct = (field.value - field.min) / math.max(field.max - field.min, 1)
                DrawRect(vx + vw / 2, row_cy, vw, self.line_h - 0.004, col(c, "val_bg"))
                if pct > 0 then
                    local fw = vw * pct
                    DrawRect(vx + fw / 2, row_cy, fw, self.line_h - 0.004, col(c, "val_fill"))
                end
                local vr, vg, vb, va = col(c, is_sel and "accent" or "text")
                draw_text(tostring(field.value), vx + vw / 2, fy + 0.001, self.text_font, 0.26, vr, vg, vb, va, true)
            end
        end

        fy = fy + self.line_h + self.pad_y
    end
end

--- @section Threads

CreateThread(function()
    while true do
        Wait(0)
        if _visible and _active then
            _active:draw()
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if _visible and _active then
            DisableControlAction(0, KEY_UP, true)
            DisableControlAction(0, KEY_DOWN, true)
            DisableControlAction(0, KEY_LEFT, true)
            DisableControlAction(0, KEY_RIGHT, true)
            DisableControlAction(0, KEY_ENTER, true)
            DisableControlAction(0, KEY_ESCAPE, true)

            if IsDisabledControlJustPressed(0, KEY_UP) then
                _active:nav_up()
            elseif IsDisabledControlJustPressed(0, KEY_DOWN) then
                _active:nav_down()
            elseif IsDisabledControlJustPressed(0, KEY_LEFT) then
                _active:nav_left()
            elseif IsDisabledControlJustPressed(0, KEY_RIGHT) then
                _active:nav_right()
            elseif IsDisabledControlJustPressed(0, KEY_ENTER) then
                _active:activate()
            elseif IsDisabledControlJustPressed(0, KEY_ESCAPE) then
                local inst = _active
                _visible = false
                _active = nil
                if inst and inst.on_cancel then inst.on_cancel() end
            end
        end
    end
end)

--- @section API

local function open_input(data)
    _active = Input.new(data)
    _visible = true
end

exports("open_input", open_input)
if dam then dam.open_input = open_input end

local function close_input()
    _visible = false
    _active = nil
end

exports("close_input", close_input)
if dam then dam.close_input = close_input end

local function is_input_open()
    return _visible
end

exports("is_input_open", is_input_open)
if dam then dam.is_input_open = is_input_open end