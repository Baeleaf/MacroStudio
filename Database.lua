local _, MacroStudio = ...

local Database = {
    CURRENT_SCHEMA_VERSION = 1,
}
MacroStudio.Database = Database

function Database:Initialize()
    if type(MacroStudioDB) ~= "table" then
        MacroStudioDB = {}
    end

    if type(MacroStudioDB.schemaVersion) ~= "number" then
        MacroStudioDB.schemaVersion = self.CURRENT_SCHEMA_VERSION
    end
    if type(MacroStudioDB.settings) ~= "table" then
        MacroStudioDB.settings = {}
    end
    if type(MacroStudioDB.metadata) ~= "table" then
        MacroStudioDB.metadata = {}
    end
    if type(MacroStudioDB.history) ~= "table" then
        MacroStudioDB.history = {}
    end

    MacroStudio.db = MacroStudioDB
end
