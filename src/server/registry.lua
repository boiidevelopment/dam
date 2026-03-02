--- @script server.registry
--- @description Server-side player registry handling accounts, validation, and player lifecycle.

--- @section Constants

local identifiers = { license = "license2", discord = "discord", ip = "ip" }

--- @section State

local temp_connected_players = {}
local connected_players = {}

--- @section Database Init

local function init_db()
    MySQL.transaction.await({
        [[CREATE TABLE IF NOT EXISTS `dam_players` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `unique_id` VARCHAR(255) NOT NULL,
            `name` VARCHAR(255) NOT NULL,
            `license` VARCHAR(255) NOT NULL,
            `discord` VARCHAR(255) DEFAULT NULL,
            `tokens` JSON NOT NULL DEFAULT (JSON_ARRAY()),
            `ip` VARCHAR(255) NOT NULL,
            `banned` TINYINT(1) NOT NULL DEFAULT 0,
            `last_login` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`unique_id`),
            KEY `id_idx` (`id`),
            KEY `license_idx` (`license`),
            KEY `banned_idx` (`banned`)
        ) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `dam_bans` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `unique_id` VARCHAR(255) NOT NULL,
            `banned_by` VARCHAR(255) NOT NULL DEFAULT 'auto_ban',
            `reason` TEXT DEFAULT NULL,
            `expires_at` TIMESTAMP NULL DEFAULT NULL,
            `expired` TINYINT(1) NOT NULL DEFAULT 0,
            `appealed` TINYINT(1) NOT NULL DEFAULT 0,
            `appealed_by` VARCHAR(255) DEFAULT NULL,
            `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `unique_id_idx` (`unique_id`),
            KEY `expired_idx` (`expired`),
            FOREIGN KEY (`unique_id`) REFERENCES `dam_players` (`unique_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
        [[CREATE TABLE IF NOT EXISTS `dam_warnings` (
            `id` INT NOT NULL AUTO_INCREMENT,
            `unique_id` VARCHAR(255) NOT NULL,
            `warned_by` VARCHAR(255) NOT NULL DEFAULT 'dam',
            `reason` TEXT DEFAULT NULL,
            `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            KEY `unique_id_idx` (`unique_id`),
            FOREIGN KEY (`unique_id`) REFERENCES `dam_players` (`unique_id`) ON DELETE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci]],
    })
    log("success", translate("init.db_table_ready"))
end
init_db()

--- @section Functions

local function generate_unique_id(length, table_name, column_name, json_path)
    local charset = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local function create_id()
        local new_id = ""
        for i = 1, length do
            local random_index = math.random(1, #charset)
            new_id = new_id .. charset:sub(random_index, random_index)
        end
        return new_id
    end
    local function id_exists(new_id)
        local query = json_path and string.format("SELECT COUNT(*) as count FROM %s WHERE JSON_EXTRACT(%s, '$.%s') = ?", table_name, column_name, json_path) or string.format("SELECT COUNT(*) as count FROM %s WHERE %s = ?", table_name, column_name)
        local result = MySQL.query.await(query, { new_id })
        return result and result[1] and result[1].count > 0
    end
    local id
    repeat
        id = create_id()
    until not id_exists(id)
    return id
end

local function check_if_user_data_exists(license)
    return MySQL.query.await("SELECT * FROM dam_players WHERE license = ?", { license })
end

local function create_user(name, unique_id, license, discord, tokens, ip)
    MySQL.insert.await("INSERT INTO dam_players (unique_id, name, license, discord, tokens, ip) VALUES (?, ?, ?, ?, ?, ?)", { unique_id, name, license, discord, json.encode(tokens), ip })
end

--- @section Event Handlers

local function on_player_connect(name, kick, deferrals)
    local source = source
    local ids = dam.get_identifiers(source)
    if not ids.license then kick("No valid license found.") return end
    local unique_id = generate_unique_id(6, "dam_players", "unique_id")
    deferrals.defer()
    Wait(100)
    local result = check_if_user_data_exists(ids.license)
    local user_data = result and result[1]
    if user_data then
        local ban = MySQL.query.await("SELECT id, reason, expires_at FROM dam_bans WHERE unique_id = ? AND expired = 0 ORDER BY created DESC LIMIT 1", { user_data.unique_id })
        local active_ban = ban and ban[1]
        if active_ban then
            if active_ban.expires_at then
                if os.time() > active_ban.expires_at / 1000 then
                    MySQL.prepare.await("UPDATE dam_bans SET expired = 1 WHERE id = ?", { active_ban.id })
                    MySQL.prepare.await("UPDATE dam_players SET banned = 0 WHERE unique_id = ?", { user_data.unique_id })
                else
                    deferrals.done(string.format("You are banned until %s.\nBan ID: %s\nReason: %s", os.date("%Y-%m-%d %H:%M:%S", active_ban.expires_at / 1000), user_data.unique_id, active_ban.reason or "No reason provided"))
                    return
                end
            else
                deferrals.done(string.format("You are permanently banned.\nBan ID: %s\nReason: %s", user_data.unique_id, active_ban.reason or "No reason provided"))
                return
            end
        end
        temp_connected_players[ids.license] = user_data
    else
        create_user(name, unique_id, ids.license, ids.discord, GetPlayerTokens(source), ids.ip)
        temp_connected_players[ids.license] = {
            name = name,
            unique_id = unique_id,
            license = ids.license,
            discord = ids.discord,
            tokens = json.encode(GetPlayerTokens(source)),
            ip = ids.ip,
            banned = false,
            last_login = os.date("%Y-%m-%d %H:%M:%S"),
            created = os.date("%Y-%m-%d %H:%M:%S")
        }
    end
    deferrals.done()
end

AddEventHandler("playerConnecting", on_player_connect)

local function on_player_joining()
    local source = source
    local ids = dam.get_identifiers(source)
    if ids.license and temp_connected_players[ids.license] then
        connected_players[source] = temp_connected_players[ids.license]
        temp_connected_players[ids.license] = nil
    end
end

AddEventHandler("playerJoining", on_player_joining)

AddEventHandler("playerDropped", function()
    connected_players[source] = nil
end)

--- @section API

function dam.get_identifiers(source)
    local ids = { license = identifiers.license, discord = identifiers.discord, ip = identifiers.ip }
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.match(id, "license") then
            ids.license = id
        elseif string.match(id, "discord") then
            ids.discord = id
        elseif string.match(id, "ip") then
            ids.ip = id
        end
    end
    return ids
end

function dam.ban_player(input, banned_by, reason, duration)
    local ids = dam.get_identifiers(input)
    if not ids.license then return false end
    local result = MySQL.query.await("SELECT unique_id FROM dam_players WHERE license = ?", { ids.license })
    if not result or not result[1] then
        local unique_id = generate_unique_id(6, "dam_players", "unique_id")
        create_user(GetPlayerName(input) or "Unknown", unique_id, ids.license, ids.discord, GetPlayerTokens(input), ids.ip)
        result = {{ unique_id = unique_id }}
    end
    local unique_id = result[1].unique_id
    local expires_at = duration and os.date("%Y-%m-%d %H:%M:%S", os.time() + duration) or nil
    MySQL.prepare.await("UPDATE dam_players SET banned = 1 WHERE unique_id = ?", { unique_id })
    MySQL.insert.await("INSERT INTO dam_bans (unique_id, banned_by, reason, expires_at) VALUES (?, ?, ?, ?)", { unique_id, banned_by or "dam", reason or "No reason provided", expires_at })
    DropPlayer(input, string.format("You have been banned.\nReason: %s", reason or "No reason provided"))
    connected_players[input] = nil
    return true
end

function dam.remove_ban(unique_id)
    if not unique_id then return false end
    local result = MySQL.query.await("SELECT banned FROM dam_players WHERE unique_id = ?", { unique_id })
    if not result or not result[1] or result[1].banned == 0 then return false end
    MySQL.prepare.await("UPDATE dam_players SET banned = 0 WHERE unique_id = ?", { unique_id })
    MySQL.prepare.await("UPDATE dam_bans SET expired = 1 WHERE unique_id = ? AND expired = 0 ORDER BY created DESC LIMIT 1", { unique_id })
    return true
end