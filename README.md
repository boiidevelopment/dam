# DAM - Drawn Admin Menu

Dam... son... where'd you find this!

So what is DAM?
Drawn Admin Menu or DAM for short is a standalone admin menu for FiveM.
Built on embedded [DRIP](https://github.com/boiidevelopment/drip) and select modules from [GRAFT](https://github.com/boiidevelopment/graft) - no HTML, no NUI, just native drawn UI that's quick to set up and easy to extend.

A large variety of options come pre-configured and I'm always down to add more, just give me a shout.

## Why Does This Exist?

1. It's a showcase for how DRIP works
2. I do a lot of work on servers without frameworks, or with varied ones - having a standalone admin menu is just useful
3. I'd rather reinvent the wheel than rely on something I didn't build

## What Can It Do?

*Everything and anything..*

Sky's the limit to what you want to add but by default it covers the following:

### Self Actions
- Noclip
- God Mode
- Invisibility
- Freeze
- Teleport to Waypoint
- Teleport to Coordinates
- Revive
- Kill

### Players
- Live player list
- Revive, Kill, Teleport To, Bring
- Kick with reason
- Warn with reason
- View warnings
- Ban with reason and duration

### Bans
- Live ban list
- View ban details
- Remove bans

### Vehicles
- Spawn by model name
- Delete current vehicle
- Repair current vehicle
- Live vehicle info panel (model, class, plate, health, fuel, oil, temp, class stats)

## Dependencies

OxMySql is required for database functions however it could be swapped out for file system if you really wanted, however not recommended.

* **[OxMySql](https://github.com/CommunityOx/oxmysql)**

## Permissions

DAM uses ace permissions for all checks.

You can disable permissions entirely in `custom/cfg.lua`:
```lua
enable_permissions = true,
```

Individual permissions accept a table of aces, a single ace string, or `false` to skip the check entirely:
```lua
open_menu = { "dam.dev", "dam.admin" },  -- any of these aces will pass
view_players = "dam.admin",              -- single ace check
view_bans = false,                       -- no check, anyone can access
```

### server.cfg
```
add_ace group.admin dam.admin allow
add_ace group.dev dam.dev allow

add_principal identifier.license:XXXXXXXX group.admin
add_principal identifier.license:XXXXXXXX group.dev
```

## Convars

You can set these convars in your `server.cfg` both are optional:

```
setr dam:debug false
setr dam:language en
```

| Convar | Default | Description |
|--------|---------|-------------|
| `dam:debug` | `false` | Enables debug prints server and client side |
| `dam:language` | `en` | Sets the language for UI strings, must match a file in `locales/` |

## Support

Something not working? Cant figure out how to make your own menu options?

**[Join the Discord](https://discord.gg/MUckUyS5Kq)**

> Support Hours: **Mon–Fri, 10AM–10PM GMT**  
> Outside those hours? Leave a message. We'll get to it.  
> Probably before you've calmed down about it.