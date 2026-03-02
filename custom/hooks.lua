--- @module custom.hooks
--- @description Handles all hooks for admin actions.
--- These are **extremely** important if you want access to framework specific actions.
--- This resource is entirely standalone, without these methods completely some actions will not work.

return {

    revive_player = function(source)
        exports.rig:run_player_method(source, "revive_player")
    end,

    kill_player = function(source)
        exports.rig:run_player_method(source, "kill_player")
    end

}