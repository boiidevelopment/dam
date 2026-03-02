--- @module locales.en
--- @description English language; you can replace these or add a new language file.

local locales = {}

locales.init = {
    mod_missing = "Module not found: %s",
    mod_compile = "Module compile error in %s: %s",
    mod_runtime = "Module runtime error in %s: %s",
    mod_return = "Module %s did not return a table (got %s)",
    ns_blocked = "Attempted to modify locked namespace: dam.%s",
    ns_ready = "%s namespace locked and ready",
    db_table_ready = "Database table ready",
    db_table_failed = "Failed to create or verify database table"
}

locales.notify = {
    access_denied = "Access Denied",
    no_permission = "You do not have permission to access the admin menu...",
    no_permission_action = "You do not have permission to do this...",
}

return locales