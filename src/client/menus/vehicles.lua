--- @script client.menus.vehicles
--- @description Vehicles menu builder.

local m = {}

function m.build()
    return {
        title = "Vehicles",
        items = {
            { type = "action", label = "Spawn Vehicle", desc = "Spawn a vehicle by model name.", keep_open = true, on_action = spawn_vehicle },
            { type = "action", label = "Delete Vehicle", desc = "Delete your current vehicle.", keep_open = true, on_action = delete_vehicle },
            { type = "action", label = "Repair Vehicle", desc = "Repair your current vehicle.", keep_open = true, on_action = repair_vehicle },
            { type = "action", label = "Vehicle Info", desc = "Toggle vehicle info panel.", keep_open = true, on_action = function()
                if dam.is_panel_visible("dam_vehicle_info") then
                    dam.hide_panel("dam_vehicle_info")
                else
                    show_vehicle_panel()
                end
            end },
            { type = "separator" },
            { type = "back", key = "main", label = "Back", desc = "Go back to main menu." },
        }
    }
end

return m