local _, MacroStudio = ...

local CharacterMacroLibrary = {
    syncCount = 0,
    unknownIdentityCounter = 0,
}
MacroStudio.CharacterMacroLibrary = CharacterMacroLibrary

local function cleanString(value)
    if type(value) ~= "string" then
        return nil
    end
    value = MacroStudio.Helpers:Trim(value)
    return value ~= "" and value or nil
end

local function normalize(value)
    return (cleanString(value) or ""):lower()
end

local function currentTimestamp()
    if type(GetServerTime) == "function" then
        local ok, value = pcall(GetServerTime)
        value = ok and tonumber(value) or nil
        if value and value > 0 then
            return math.floor(value)
        end
    end
    if type(time) == "function" then
        local ok, value = pcall(time)
        value = ok and tonumber(value) or nil
        if value and value > 0 then
            return math.floor(value)
        end
    end
    return 0
end

local function copyCharacterSummary(record, isCurrent)
    return {
        id = record.id,
        guid = record.guid,
        name = record.name,
        realm = record.realm,
        displayName = record.displayName,
        normalizedDisplay = record.normalizedDisplay,
        lastSynced = record.lastSynced,
        isCurrent = isCurrent and true or false,
    }
end

local function copySnapshotMacro(record, macro)
    return {
        source = "SNAPSHOT",
        scope = "CHARACTER",
        characterKey = record.id,
        characterGUID = record.guid,
        characterName = record.name,
        realm = record.realm,
        characterDisplayName = record.displayName,
        lastSynced = record.lastSynced,
        snapshotOrder = macro.order,
        name = macro.name,
        icon = macro.icon,
        body = macro.body,
    }
end

local function copyLiveMacro(record, macro)
    return {
        source = "LIVE",
        scope = "CHARACTER",
        characterKey = record.id,
        characterGUID = record.guid,
        characterName = record.name,
        realm = record.realm,
        characterDisplayName = record.displayName,
        lastSynced = record.lastSynced,
        index = macro.index,
        name = macro.name,
        icon = macro.icon,
        selectedIcon = macro.selectedIcon,
        body = macro.body,
        duplicateName = macro.duplicateName,
        duplicateCount = macro.duplicateCount,
    }
end

local function markDuplicateNames(macros)
    local groups = {}
    for _, macro in ipairs(macros) do
        macro.duplicateName = nil
        macro.duplicateCount = nil
        if type(macro.name) == "string" and macro.name ~= "" then
            local key = macro.name:lower()
            groups[key] = groups[key] or {}
            groups[key][#groups[key] + 1] = macro
        end
    end
    for _, group in pairs(groups) do
        if #group > 1 then
            for _, macro in ipairs(group) do
                macro.duplicateName = true
                macro.duplicateCount = #group
            end
        end
    end
end

local function macroMatches(macro, needle)
    if needle == "" then
        return true
    end
    return normalize(macro.name):find(needle, 1, true) ~= nil
        or normalize(macro.body):find(needle, 1, true) ~= nil
end

function CharacterMacroLibrary:GetStore()
    return MacroStudio.db and MacroStudio.db.characterLibrary or nil
end

function CharacterMacroLibrary:AllocateUnknownIdentity(name, realm)
    local store = self:GetStore()
    local base = string.format("unknown:%s:%s:%d", normalize(name), normalize(realm), currentTimestamp())
    local candidate
    repeat
        self.unknownIdentityCounter = self.unknownIdentityCounter + 1
        candidate = base .. ":" .. self.unknownIdentityCounter
    until not store.characters[candidate]
    return candidate
end

function CharacterMacroLibrary:ResolveCurrentCharacter()
    local guid
    if type(UnitGUID) == "function" then
        local ok, value = pcall(UnitGUID, "player")
        guid = ok and cleanString(value) or nil
    end

    local name, realm
    if type(UnitFullName) == "function" then
        local ok, unitName, unitRealm = pcall(UnitFullName, "player")
        if ok then
            name = cleanString(unitName)
            realm = cleanString(unitRealm)
        end
    end
    if not name and type(UnitName) == "function" then
        local ok, unitName, unitRealm = pcall(UnitName, "player")
        if ok then
            name = cleanString(unitName)
            realm = realm or cleanString(unitRealm)
        end
    end
    if type(GetRealmName) == "function" then
        local ok, value = pcall(GetRealmName)
        realm = ok and cleanString(value) or realm
    end
    if not realm and type(GetNormalizedRealmName) == "function" then
        local ok, value = pcall(GetNormalizedRealmName)
        realm = ok and cleanString(value) or nil
    end

    name = name or "Unknown Character"
    realm = realm or "Unknown Realm"
    local displayName = name .. " - " .. realm
    local id = guid and ("guid:" .. guid) or self:AllocateUnknownIdentity(name, realm)
    return {
        id = id,
        guid = guid,
        name = name,
        realm = realm,
        displayName = displayName,
        normalizedDisplay = displayName:lower(),
        identityCertain = guid ~= nil,
    }
end

function CharacterMacroLibrary:Initialize()
    if self.currentCharacter then
        return self.currentCharacter
    end

    local store = self:GetStore()
    if not store then
        return nil
    end

    local identity = self:ResolveCurrentCharacter()
    local record = store.characters[identity.id]
    if type(record) ~= "table" then
        record = {
            id = identity.id,
            macros = {},
            lastSynced = 0,
        }
        store.characters[identity.id] = record
        store.order[#store.order + 1] = identity.id
    end

    record.id = identity.id
    record.guid = identity.guid
    record.name = identity.name
    record.realm = identity.realm
    record.displayName = identity.displayName
    record.normalizedDisplay = identity.normalizedDisplay
    record.identityCertain = identity.identityCertain
    record.macros = type(record.macros) == "table" and record.macros or {}
    self.currentCharacter = record
    return record
end

function CharacterMacroLibrary:GetCurrentCharacter()
    local record = self.currentCharacter or self:Initialize()
    return record and copyCharacterSummary(record, true) or nil
end

function CharacterMacroLibrary:GetCharacter(characterId)
    local store = self:GetStore()
    return store and store.characters[characterId] or nil
end

function CharacterMacroLibrary:IsCurrentCharacter(characterOrId)
    local characterId = type(characterOrId) == "table" and characterOrId.id or characterOrId
    return self.currentCharacter ~= nil and characterId == self.currentCharacter.id
end

function CharacterMacroLibrary:IsOfflineMacro(macro)
    return type(macro) == "table" and macro.source == "SNAPSHOT"
end

function CharacterMacroLibrary:RefreshCurrentSnapshot(macros, syncedAt)
    local record = self.currentCharacter or self:Initialize()
    if not record then
        return false
    end

    local snapshot = {}
    for _, macro in ipairs(macros or MacroStudio.MacroRepository:GetAll()) do
        if macro.scope == "CHARACTER" then
            snapshot[#snapshot + 1] = {
                order = #snapshot + 1,
                name = type(macro.name) == "string" and macro.name or "",
                body = type(macro.body) == "string" and macro.body or "",
                icon = macro.selectedIcon or macro.icon or MacroStudio.DEFAULT_ICON,
            }
        end
    end

    record.macros = snapshot
    record.lastSynced = tonumber(syncedAt) or currentTimestamp()
    self.syncCount = self.syncCount + 1
    MacroStudio:Debug("character snapshot refreshed", record.displayName, #snapshot)
    return true, record
end

function CharacterMacroLibrary:GetSyncCount()
    return self.syncCount
end

function CharacterMacroLibrary:GetCharacters()
    local store = self:GetStore()
    local result = {}
    if not store then
        return result
    end

    for _, characterId in ipairs(store.order) do
        local record = store.characters[characterId]
        if type(record) == "table" then
            result[#result + 1] = copyCharacterSummary(record, self:IsCurrentCharacter(characterId))
        end
    end

    table.sort(result, function(first, second)
        if first.isCurrent ~= second.isCurrent then
            return first.isCurrent
        end
        local firstName = normalize(first.displayName)
        local secondName = normalize(second.displayName)
        if firstName == secondName then
            return first.id < second.id
        end
        return firstName < secondName
    end)
    return result
end

function CharacterMacroLibrary:GetViewGroups(filter, query, liveMacros)
    filter = type(filter) == "table" and filter or { kind = "characters" }
    local needle = MacroStudio.Search:NormalizeQuery(query)
    local groups = {}

    for _, summary in ipairs(self:GetCharacters()) do
        local includeCharacter = filter.kind == "characters"
            or (filter.kind == "libraryCharacter" and filter.characterId == summary.id)
        if includeCharacter then
            local record = self:GetCharacter(summary.id)
            local candidates = {}
            if summary.isCurrent then
                for _, macro in ipairs(liveMacros or MacroStudio.MacroRepository:GetAll()) do
                    if macro.scope == "CHARACTER" then
                        candidates[#candidates + 1] = copyLiveMacro(record, macro)
                    end
                end
            else
                for _, macro in ipairs(record.macros or {}) do
                    candidates[#candidates + 1] = copySnapshotMacro(record, macro)
                end
                markDuplicateNames(candidates)
            end

            local characterMatches = filter.kind == "characters"
                and needle ~= ""
                and (normalize(summary.name):find(needle, 1, true)
                    or normalize(summary.realm):find(needle, 1, true)
                    or normalize(summary.displayName):find(needle, 1, true))
            local matches = {}
            for _, macro in ipairs(candidates) do
                if characterMatches or macroMatches(macro, needle) then
                    matches[#matches + 1] = macro
                end
            end

            if filter.kind == "libraryCharacter"
                or needle == ""
                or characterMatches
                or #matches > 0 then
                groups[#groups + 1] = {
                    character = summary,
                    macros = matches,
                }
            end
        end
    end
    return groups
end

function CharacterMacroLibrary:FindSnapshot(snapshot)
    if not self:IsOfflineMacro(snapshot) then
        return nil
    end
    local record = self:GetCharacter(snapshot.characterKey)
    if not record or self:IsCurrentCharacter(record.id) then
        return nil
    end
    for _, macro in ipairs(record.macros or {}) do
        if macro.order == snapshot.snapshotOrder
            and macro.name == snapshot.name
            and macro.icon == snapshot.icon
            and macro.body == snapshot.body then
            return copySnapshotMacro(record, macro)
        end
    end
    return nil
end

function CharacterMacroLibrary:RecordsEqual(first, second)
    if self:IsOfflineMacro(first) or self:IsOfflineMacro(second) then
        return self:IsOfflineMacro(first)
            and self:IsOfflineMacro(second)
            and first.characterKey == second.characterKey
            and first.snapshotOrder == second.snapshotOrder
            and first.name == second.name
            and first.icon == second.icon
            and first.body == second.body
    end
    return MacroStudio.MacroRepository:SnapshotsEqual(first, second)
end

function CharacterMacroLibrary:ForgetCharacter(characterId)
    local store = self:GetStore()
    local record = store and store.characters[characterId] or nil
    if not record then
        return false, "This stored character snapshot no longer exists."
    end
    if self:IsCurrentCharacter(characterId) then
        return false, "The current character cannot be forgotten."
    end

    store.characters[characterId] = nil
    for index = #store.order, 1, -1 do
        if store.order[index] == characterId then
            table.remove(store.order, index)
        end
    end
    MacroStudio:Debug("character snapshot forgotten", record.displayName or characterId)
    return true, record
end

function CharacterMacroLibrary:ApplyPortableSnapshot(item)
    if type(item) ~= "table" or (item.action ~= "add" and item.action ~= "update") then
        return false, "Portable snapshot action is invalid."
    end
    local source = item.source
    local store = self:GetStore()
    if type(source) ~= "table" or not store then
        return false, "Portable snapshot data is unavailable."
    end

    local record
    if item.action == "update" then
        record = type(item.targetId) == "string" and store.characters[item.targetId] or nil
        if not record or self:IsCurrentCharacter(record.id) then
            return false, "The offline snapshot target is no longer safe."
        end
        if not source.guid or record.guid ~= source.guid then
            return false, "The offline snapshot GUID no longer matches."
        end
        local sourceTime = tonumber(source.lastSynced)
        local localTime = tonumber(record.lastSynced)
        if not sourceTime or not localTime or sourceTime <= localTime then
            return false, "The local offline snapshot is not older."
        end
    else
        local recordId
        if source.guid then
            recordId = "guid:" .. source.guid
            if store.characters[recordId] then
                return false, "That character snapshot already exists."
            end
        else
            recordId = self:AllocateUnknownIdentity(source.name, source.realm)
        end
        record = { id = recordId, macros = {} }
        store.characters[recordId] = record
        store.order[#store.order + 1] = recordId
    end

    local macros = {}
    for index, macro in ipairs(source.macros or {}) do
        macros[index] = {
            order = index,
            name = type(macro.name) == "string" and macro.name or "",
            icon = macro.icon or MacroStudio.DEFAULT_ICON,
            body = type(macro.body) == "string" and macro.body or "",
        }
    end
    record.guid = source.guid
    record.name = source.name
    record.realm = source.realm
    record.displayName = (source.name or "Unknown Character") .. " - " .. (source.realm or "Unknown Realm")
    record.normalizedDisplay = record.displayName:lower()
    record.identityCertain = source.guid ~= nil and source.identityCertain == true
    record.lastSynced = tonumber(source.lastSynced) or 0
    record.macros = macros
    MacroStudio:Debug("portable character snapshot applied", item.action, record.displayName, #macros)
    return true, record
end

function CharacterMacroLibrary:FormatLastSynced(timestamp)
    timestamp = tonumber(timestamp)
    if not timestamp or timestamp <= 0 or type(date) ~= "function" then
        return "Unknown"
    end
    local ok, value = pcall(date, "%b %d, %Y", timestamp)
    return ok and value or "Unknown"
end
