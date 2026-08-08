local _, MacroStudio = ...

local Database = {
    CURRENT_SCHEMA_VERSION = 2,
}
MacroStudio.Database = Database

local function nextAvailableId(records, prefix)
    local highest = 0
    for id in pairs(records) do
        if type(id) == "string" then
            local number = tonumber(id:match("^" .. prefix .. "%-(%d+)$"))
            if number and number > highest then
                highest = number
            end
        end
    end
    return highest + 1
end

function Database:Initialize()
    if type(MacroStudioDB) ~= "table" then
        MacroStudioDB = {}
    end

    local previousSchema = tonumber(MacroStudioDB.schemaVersion) or 1

    if type(MacroStudioDB.settings) ~= "table" then
        MacroStudioDB.settings = {}
    end
    if type(MacroStudioDB.metadata) ~= "table" then
        MacroStudioDB.metadata = {}
    end
    if type(MacroStudioDB.metadata.records) ~= "table" then
        MacroStudioDB.metadata.records = {}
    end
    if type(MacroStudioDB.metadata.nextId) ~= "number" then
        MacroStudioDB.metadata.nextId = nextAvailableId(MacroStudioDB.metadata.records, "metadata")
    end

    if type(MacroStudioDB.categories) ~= "table" then
        MacroStudioDB.categories = {}
    end
    if type(MacroStudioDB.categories.byId) ~= "table" then
        MacroStudioDB.categories.byId = {}
    end
    if type(MacroStudioDB.categories.order) ~= "table" then
        MacroStudioDB.categories.order = {}
    end
    if type(MacroStudioDB.categories.nextId) ~= "number" then
        MacroStudioDB.categories.nextId = nextAvailableId(MacroStudioDB.categories.byId, "category")
    end

    if type(MacroStudioDB.history) ~= "table" then
        MacroStudioDB.history = {}
    end

    -- Never downgrade a database created by a newer addon version.
    if previousSchema <= self.CURRENT_SCHEMA_VERSION then
        MacroStudioDB.schemaVersion = self.CURRENT_SCHEMA_VERSION
    else
        MacroStudioDB.schemaVersion = previousSchema
    end

    MacroStudio.db = MacroStudioDB
end
