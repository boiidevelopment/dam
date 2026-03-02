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

--- @file menu
--- @description Handles menu system, supports infinite depth submenus via keyed navigation. 
--- Also supports multiple menus with tab focus switching.

--- @section Constants

local KEY_UP = 172
local KEY_DOWN = 173
local KEY_LEFT = 174
local KEY_RIGHT = 175
local KEY_ENTER = 191
local KEY_BACK = 177
local KEY_TAB = 37

local DEFAULT_STYLE = {
    x = 0.015,
    y = 0.0275,
    width = 0.22,
    pad_x = 0.008,
    pad_y = 0.006,
    max_vis = 10,
    header_font = 4,
    header_scale = 0.34,
    header_height = 0.030,
    text_font = 0,
    text_scale = 0.30,
    line_h = 0.024,
    wrap = 50,
    colours = {
        bg = {0, 0, 0, 180},
        bg_inner = {255, 255, 255, 15},
        header = {20, 20, 20, 255},
        header_text = {255, 255, 255, 255},
        text = {220, 220, 220, 220},
        text_sel = {255, 255, 255, 255},
        text_dim = {160, 160, 160, 200},
        highlight = {255, 255, 255, 30},
        accent = {228, 173, 41, 255},
        toggle_on = {80, 200, 120, 255},
        toggle_off = {200, 80, 80, 255},
        slider_bg = {60, 60, 60, 200},
        separator = {255, 255, 255, 30},
    }
}

--- @section State

local _instances = {}
local _order = {}
local _focused = nil
local _open = false

--- @section Helpers

local function resolve(style, key)
    if style and style[key] ~= nil then return style[key] end
    return DEFAULT_STYLE[key]
end

local function col(colours, key, alpha_override)
    local c = colours[key]
    return c[1], c[2], c[3], alpha_override or c[4]
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

local function draw_text(str, x, y, font, scale, r, g, b, a, centre, shadow)
    SetTextFont(font or DEFAULT_STYLE.text_font)
    SetTextScale(scale or DEFAULT_STYLE.text_scale, scale or DEFAULT_STYLE.text_scale)
    SetTextColour(r or 255, g or 255, b or 255, a or 255)
    SetTextCentre(centre and 1 or 0)
    if shadow then SetTextDropShadow() end
    SetTextEntry("STRING")
    AddTextComponentString(str)
    DrawText(x, y)
end

--- @class Menu

local Menu = {}
Menu.__index = Menu

function Menu.new(data)
    return setmetatable({
        title = data.title,
        items = data.items,
        index = 1,
        scroll = 0,
    }, Menu)
end

function Menu:current_item()
    return self.items[self.index]
end

function Menu:clamp_scroll(max_vis)
    if self.index - 1 < self.scroll then
        self.scroll = self.index - 1
    elseif self.index - 1 >= self.scroll + max_vis then
        self.scroll = self.index - max_vis
    end
end

function Menu:nav_up(max_vis)
    repeat
        self.index = self.index > 1 and self.index - 1 or #self.items
    until self.items[self.index].type ~= "separator"
    self:clamp_scroll(max_vis)
end

function Menu:nav_down(max_vis)
    repeat
        self.index = self.index < #self.items and self.index + 1 or 1
    until self.items[self.index].type ~= "separator"
    self:clamp_scroll(max_vis)
end

function Menu:adjust_slider(dir)
    local item = self:current_item()
    if item.type ~= "slider" then return end
    local step = item.step or 1
    item.value = math.max(item.min, math.min(item.max, item.value + (dir * step)))
    if item.on_change then item.on_change(item.value) end
end

--- @class Instance

local Instance = {}
Instance.__index = Instance

function Instance.new(data)
    local style = data.style or {}
    local colours = {}
    for k, v in pairs(DEFAULT_STYLE.colours) do colours[k] = v end
    if style.colours then
        for k, v in pairs(style.colours) do colours[k] = v end
    end
    local inst = setmetatable({
        id = data.id,
        root = data.root,
        menus = data.menus,
        active_key = data.root,
        active = nil,
        x = resolve(style, "x"),
        y = resolve(style, "y"),
        width = resolve(style, "width"),
        pad_x = resolve(style, "pad_x"),
        pad_y = resolve(style, "pad_y"),
        max_vis = resolve(style, "max_vis"),
        header_font = resolve(style, "header_font"),
        header_scale = resolve(style, "header_scale"),
        header_height = resolve(style, "header_height"),
        text_font = resolve(style, "text_font"),
        text_scale = resolve(style, "text_scale"),
        line_h = resolve(style, "line_h"),
        colours = colours,
    }, Instance)
    inst.active = Menu.new(data.menus[data.root])
    return inst
end

function Instance:go_to(key)
    local data = self.menus[key]
    if not data then return end
    self.active = Menu.new(data)
    self.active_key = key
    self.active.scroll = 0
end

function Instance:close()
    _instances[self.id] = nil
    for i, id in ipairs(_order) do
        if id == self.id then
            table.remove(_order, i)
            break
        end
    end
    if _focused == self.id then
        _focused = _order[1] or nil
    end
    if #_order == 0 then
        _open = false
    end
end

function Instance:activate()
    local item = self.active:current_item()
    if not item then return end
    local handlers = {
        action = function()
            if item.on_action then item.on_action() end
            if not item.keep_open then self:close() end
        end,
        toggle = function()
            item.value = not item.value
            if item.on_change then item.on_change(item.value) end
        end,
        slider = function()
            self.active:adjust_slider(1)
        end,
        close = function()
            self:close()
        end,
        back = function()
            if item.key then
                self:go_to(item.key)
            else
                self:close()
            end
        end,
        submenu = function()
            if item.submenu then self:go_to(item.submenu) end
        end,
    }
    local handler = handlers[item.type]
    if handler then handler() end
end

function Instance:draw(focused)
    local x = self.x
    local y = self.y
    local w = self.width
    local cx = x + w / 2
    local max_vis = self.max_vis
    local menu = self.active
    local c = self.colours
    local vis = math.min(#menu.items, max_vis)
    local has_scroll = #menu.items > max_vis
    local sel = menu:current_item()
    local has_desc = sel and sel.desc and sel.type ~= "separator"
    local desc_h = has_desc and (self.line_h + self.pad_y) or 0
    local scroll_h = has_scroll and self.line_h or 0
    local wrap_limit = self.wrap or DEFAULT_STYLE.wrap or 28
    local item_layouts = {}
    local total_h = 0
    for i = 1, vis do
        local idx = menu.scroll + i
        local item = menu.items[idx]
        if not item then break end
        if item.type == "separator" then
            item_layouts[i] = { item = item, idx = idx, lines = {item.label or ""}, h = self.line_h }
        else
            local lines = wrap_text(item.label or "", wrap_limit)
            item_layouts[i] = { item = item, idx = idx, lines = lines, h = #lines * self.line_h }
        end
        total_h = total_h + item_layouts[i].h
    end
    local box_h = self.header_height + (self.pad_y * 2) + total_h + scroll_h + desc_h + self.pad_y
    local cy = y + box_h / 2
    local bg_a = focused and 180 or 100
    DrawRect(cx, cy, w, box_h, col(c, "bg", bg_a))
    DrawRect(cx, cy, w - 0.001, box_h - 0.001, col(c, "bg_inner"))
    local hcy = y + self.header_height / 2
    DrawRect(cx, hcy, w, self.header_height, col(c, "header"))
    if focused then
        DrawRect(cx, hcy - (self.header_height / 2) + 0.001, w, 0.002, col(c, "accent"))
    end
    if self.active_key ~= self.root then
        draw_text("<", x + self.pad_x, hcy - 0.0125, self.text_font, self.text_scale, col(c, "accent"))
    end
    draw_text(menu.title, cx, hcy - 0.0125, self.header_font, self.header_scale, col(c, "header_text"), nil, nil, nil, true)
    local cur_y = y + self.header_height + self.pad_y
    for _, layout in ipairs(item_layouts) do
        local item = layout.item
        local idx = layout.idx
        local is_sel = focused and idx == menu.index
        local row_cy = cur_y + layout.h / 2
        if item.type == "separator" then
            DrawRect(cx + 0.001, row_cy, w - self.pad_x * 10, 0.002, col(c, "separator"))
            if item.label and item.label ~= "" then
                draw_text(item.label, x + self.pad_x, cur_y + 0.002, self.text_font, 0.24, col(c, "text_dim"))
            end
        else
            if is_sel then
                DrawRect(cx, row_cy, w, layout.h, col(c, "highlight"))
            end
            local tc = is_sel and "text_sel" or "text"
            for li, line in ipairs(layout.lines) do
                draw_text(line, x + self.pad_x, cur_y + ((li - 1) * self.line_h) - 0.001, self.text_font, self.text_scale, col(c, tc))
            end
            local rx = x + w - self.pad_x
            if item.type == "toggle" then
                local ck = item.value and "toggle_on" or "toggle_off"
                draw_text(item.value and "ON" or "OFF", rx - 0.0175, cur_y - 0.001, self.text_font, self.text_scale, col(c, ck))
            elseif item.type == "slider" then
                local pct = (item.value - item.min) / (item.max - item.min)
                local tw = 0.07
                local tx = rx - tw
                DrawRect(tx + tw / 2, row_cy, tw, 0.006, col(c, "slider_bg"))
                if pct > 0 then
                    local fw = tw * pct
                    DrawRect(tx + fw / 2, row_cy, fw, 0.006, col(c, "accent"))
                end
                draw_text(tostring(item.value), tx - 0.019, cur_y - 0.001, self.text_font, self.text_scale, col(c, "text"))
            elseif item.type == "submenu" then
                draw_text(">>", rx - 0.012, cur_y - 0.001, self.text_font, self.text_scale, col(c, "accent"))
            end
        end
        cur_y = cur_y + layout.h
    end
    if has_desc then
        local dy = y + box_h - desc_h - self.pad_y / 2
        DrawRect(cx, dy + desc_h / 2, w, desc_h + self.pad_y, 0, 0, 0, 120)
        draw_text(sel.desc, x + 0.008, dy + 0.002, self.text_font, 0.26, col(c, "text_dim"))
    end
end

--- @section Threads

local function start_threads()
    CreateThread(function()
        while _open do
            Wait(0)
            for _, id in ipairs(_order) do
                local inst = _instances[id]
                if inst then
                    inst:draw(id == _focused)
                end
            end
        end
    end)

    CreateThread(function()
        while _open do
            Wait(0)
            if is_input_open and is_input_open() then Wait(0) end

            local inst = _focused and _instances[_focused]
            if not inst then break end

            DisableControlAction(0, KEY_UP, true)
            DisableControlAction(0, KEY_DOWN, true)
            DisableControlAction(0, KEY_LEFT, true)
            DisableControlAction(0, KEY_RIGHT, true)
            DisableControlAction(0, KEY_ENTER, true)
            DisableControlAction(0, KEY_BACK, true)
            DisableControlAction(0, KEY_TAB, true)

            if IsDisabledControlJustPressed(0, KEY_TAB) then
                local idx = 1
                for i, id in ipairs(_order) do
                    if id == _focused then idx = i break end
                end
                _focused = _order[(idx % #_order) + 1]
            elseif IsDisabledControlJustPressed(0, KEY_UP) then
                inst.active:nav_up(inst.max_vis)
            elseif IsDisabledControlJustPressed(0, KEY_DOWN) then
                inst.active:nav_down(inst.max_vis)
            elseif IsDisabledControlJustPressed(0, KEY_LEFT) then
                inst.active:adjust_slider(-1)
            elseif IsDisabledControlJustPressed(0, KEY_RIGHT) then
                inst.active:adjust_slider(1)
            elseif IsDisabledControlJustPressed(0, KEY_ENTER) then
                inst:activate()
            elseif IsDisabledControlJustPressed(0, KEY_BACK) then
                if inst.active_key ~= inst.root then
                    inst:go_to(inst.root)
                else
                    inst:close()
                end
            end
        end
    end)
end

--- @section API

local function open_menu(data)
    if not data.id then return end
    local inst = Instance.new(data)
    _instances[data.id] = inst
    _order[#_order + 1] = data.id
    _focused = data.id
    if not _open then
        _open = true
        start_threads()
    end
end

exports("open_menu", open_menu)
if dam then dam.open_menu = open_menu end

local function close_menu(id)
    if id then
        local inst = _instances[id]
        if inst then inst:close() end
    else
        _instances = {}
        _order = {}
        _focused = nil
        _open = false
    end
end

exports("close_menu", close_menu)
if dam then dam.close_menu = close_menu end

local function update_menu(id, menu_key, data)
    local inst = _instances[id]
    if not inst then return end
    if not inst.menus[menu_key] then return end
    inst.menus[menu_key].items = data.items
    if inst.active_key == menu_key then
        local prev_index = inst.active.index
        inst.active = Menu.new(inst.menus[menu_key])
        inst.active.index = math.min(prev_index, #inst.active.items)
        inst.active:clamp_scroll(inst.max_vis)
    end
end

exports("update_menu", update_menu)
if dam then dam.update_menu = update_menu end

function update_menus(id, menus)
    local inst = _instances[id]
    if not inst then return end
    for key, menu in pairs(menus) do
        inst.menus[key] = menu
    end
    if inst.active_key and inst.menus[inst.active_key] then
        local prev_index = inst.active.index
        inst.active = Menu.new(inst.menus[inst.active_key])
        inst.active.index = math.min(prev_index, #inst.active.items)
        inst.active:clamp_scroll(inst.max_vis)
    end
end

exports("update_menus", update_menus)
if dam then dam.update_menus = update_menus end

function is_menu_open(id)
    if id then return _instances[id] ~= nil end
    return _open
end

exports("is_menu_open", is_menu_open)
if dam then dam.is_menu_open = is_menu_open end

--- @section Test Command

RegisterCommand("dam:menu", function()
    if is_menu_open() then close_menu() return end

    open_menu({
        id = "main",
        root = "menu_1",
        style = {x = 0.015, y = 0.0275, width = 0.22},
        menus = {
            menu_1 = {
                title = "Main Menu",
                items = {
                    {
                        type = "action",
                        label = "Item 1",
                        desc = "Can trigger a function.",
                        on_action = function() print("item 1 did a thing") end
                    },
                    {
                        type = "toggle",
                        label = "Item 2",
                        value = false,
                        desc = "Flips on and off.",
                        on_change = function(v) print("item 2 did a thing") end
                    },
                    {
                        type = "slider",
                        label = "Item 3",
                        min = 1, max = 10, value = 1, step = 1,
                        desc = "Move a slider.",
                    },
                    {type = "submenu", label = "Submenu 1", desc = "Open submenu 1.", submenu = "menu_2"},
                    {type = "separator"},
                    {type = "close", label = "Close", desc = "Close the menu."},
                }
            },
            menu_2 = {
                title = "Submenu 1",
                items = {
                    {type = "submenu", label = "Submenu 2", desc = "Open submenu 2.", submenu = "menu_3"},
                    {type = "submenu", label = "Submenu 3", desc = "Open submenu 3.", submenu = "menu_4"},
                    {type = "separator"},
                    {type = "back", key = "menu_1", label = "Back", desc = "Return to main menu."},
                }
            },
            menu_3 = {
                title = "Submenu 2",
                items = {
                    {
                        type = "slider",
                        label = "Item 1",
                        min = 0, max = 100, value = 80, step = 5,
                        desc = "Adjust a value.",
                        on_change = function(v) print("slider", v) end
                    },
                    {type = "separator"},
                    {type = "back", key = "menu_2", label = "Back", desc = "Return to submenu 1."},
                }
            },
            menu_4 = {
                title = "Submenu 3",
                items = {
                    {
                        type = "toggle",
                        label = "Item 1",
                        value = false,
                        desc = "Flips on and off.",
                        on_change = function(v) print("toggle", v) end
                    },
                    {type = "separator"},
                    {type = "back", key = "menu_2", label = "Back", desc = "Return to submenu 1."},
                }
            },
        }
    })

    open_menu({
        id = "secondary",
        root = "menu_1",
        style = {x = 0.260, y = 0.0275, width = 0.22},
        menus = {
            menu_1 = {
                title = "Secondary Menu",
                items = {
                    {
                        type = "action",
                        label = "Item A",
                        desc = "Does something else.",
                        on_action = function() print("item A did a thing") end
                    },
                    {
                        type = "toggle",
                        label = "Item B",
                        value = false,
                        desc = "Another toggle.",
                        on_change = function(v) print("item B toggled", v) end
                    },
                    {type = "separator"},
                    {type = "close", label = "Close", desc = "Close this menu."},
                }
            },
        }
    })
end, false)