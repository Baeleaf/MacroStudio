local _, MacroStudio = ...

local MacroRepository = {
    macros = {},
    accountCount = 0,
    characterCount = 0,
    duplicateGroups = {},
}
MacroStudio.MacroRepository = MacroRepository

local FALLBACK_ACCOUNT_CAPACITY = 120
local FALLBACK_CHARACTER_CAPACITY = 30

local function accountCapacity()
    local macroConstants = Constants and Constants.MacroConsts
    return tonumber(macroConstants and macroConstants.MAX_ACCOUNT_MACROS)
        or tonumber(MAX_ACCOUNT_MACROS)
        or FALLBACK_ACCOUNT_CAPACITY
end

local function characterCapacity()
    local macroConstants = Constants and Constants.MacroConsts
    return tonumber(macroConstants and macroConstants.MAX_CHARACTER_MACROS)
        or tonumber(MAX_CHARACTER_MACROS)
        or FALLBACK_CHARACTER_CAPACITY
end

local function normalizeCount(value)
    value = tonumber(value) or 0
    if value < 0 then
        return 0
    end
    return math.floor(value)
end

local function isInCombat()
    return type(InCombatLockdown) == "function" and InCombatLockdown() and true or false
end

function MacroRepository:GetScopeForIndex(index)
    if type(index) ~= "number" then
        return nil
    end
    return index <= accountCapacity() and "ACCOUNT" or "CHARACTER"
end

function MacroRepository:GetByIndex(index, expectedScope)
    if type(GetMacroInfo) ~= "function" or type(index) ~= "number" then
        return nil
    end

    local name, icon, body = GetMacroInfo(index)
    if type(name) ~= "string" then
        return nil
    end

    local scope = self:GetScopeForIndex(index)
    if expectedScope and scope ~= expectedScope then
        return nil
    end

    return {
        index = index,
        name = name,
        icon = icon or MacroStudio.DEFAULT_ICON,
        body = type(body) == "string" and body or "",
        scope = scope,
    }
end

function MacroRepository:DetectDuplicateNames()
    local candidates = {}
    self.duplicateGroups = {}

    for _, macro in ipairs(self.macros) do
        macro.duplicateName = nil
        macro.duplicateCount = nil
        if macro.name ~= "" then
            local key = macro.scope .. "\031" .. macro.name:lower()
            candidates[key] = candidates[key] or {}
            candidates[key][#candidates[key] + 1] = macro
        end
    end

    for key, group in pairs(candidates) do
        if #group > 1 then
            self.duplicateGroups[key] = group
            for _, macro in ipairs(group) do
                macro.duplicateName = true
                macro.duplicateCount = #group
            end
            MacroStudio:Debug("duplicate macro name detected", group[1].scope, group[1].name, #group)
        end
    end
end

function MacroRepository:Refresh()
    local refreshed = {}
    local accountCount, characterCount = 0, 0

    if type(GetNumMacros) == "function" then
        accountCount, characterCount = GetNumMacros()
    end

    self.accountCount = normalizeCount(accountCount)
    self.characterCount = normalizeCount(characterCount)

    for index = 1, self.accountCount do
        local macro = self:GetByIndex(index, "ACCOUNT")
        if macro then
            refreshed[#refreshed + 1] = macro
        end
    end

    local firstCharacterIndex = accountCapacity() + 1
    for offset = 0, self.characterCount - 1 do
        local macro = self:GetByIndex(firstCharacterIndex + offset, "CHARACTER")
        if macro then
            refreshed[#refreshed + 1] = macro
        end
    end

    self.macros = refreshed
    self:DetectDuplicateNames()
    MacroStudio:Debug("repository refreshed", #refreshed, "macros")
    return refreshed
end

function MacroRepository:GetAll()
    return self.macros
end

function MacroRepository:GetDuplicateGroups()
    return self.duplicateGroups
end

function MacroRepository:GetCapacity(scope)
    if scope == "CHARACTER" then
        return self.characterCount, characterCapacity()
    end
    return self.accountCount, accountCapacity()
end

function MacroRepository:FindByIndex(index)
    for _, macro in ipairs(self.macros) do
        if macro.index == index then
            return macro
        end
    end
    return nil
end

function MacroRepository:SnapshotsEqual(first, second)
    return type(first) == "table"
        and type(second) == "table"
        and first.index == second.index
        and first.scope == second.scope
        and first.name == second.name
        and first.icon == second.icon
        and first.body == second.body
end

function MacroRepository:IsSnapshotCurrent(snapshot)
    if type(snapshot) ~= "table" or type(snapshot.index) ~= "number" then
        return false
    end
    return self:SnapshotsEqual(self:GetByIndex(snapshot.index, snapshot.scope), snapshot)
end

function MacroRepository:ResolveLatest(snapshot, refreshFirst)
    if type(snapshot) ~= "table" then
        return nil, "No macro is selected."
    end

    if refreshFirst ~= false then
        self:Refresh()
    end

    local sameIndex = self:FindByIndex(snapshot.index)
    local exactMatch
    local exactMatches = 0
    for _, macro in ipairs(self.macros) do
        if macro.scope == snapshot.scope
            and macro.name == snapshot.name
            and macro.icon == snapshot.icon
            and macro.body == snapshot.body then
            exactMatch = macro
            exactMatches = exactMatches + 1
        end
    end
    if exactMatches == 1 then
        return exactMatch
    end

    local likelyMatch
    local likelyMatches = 0
    for _, macro in ipairs(self.macros) do
        if macro.scope == snapshot.scope
            and macro.name == snapshot.name
            and macro.icon == snapshot.icon then
            likelyMatch = macro
            likelyMatches = likelyMatches + 1
        end
    end
    if likelyMatches == 1 then
        return likelyMatch
    end

    if sameIndex
        and sameIndex.scope == snapshot.scope
        and sameIndex.name == snapshot.name
        and sameIndex.icon == snapshot.icon then
        return nil, "The selected index now matches multiple duplicate macros, so MacroStudio will not guess."
    end

    if exactMatches > 1 or likelyMatches > 1 then
        return nil, "The selected macro is ambiguous because duplicate macros match it."
    end
    return nil, "The selected macro no longer exists or changed identity."
end

function MacroRepository:ValidateCreateRequest(request)
    request = type(request) == "table" and request or {}
    local name = MacroStudio.Helpers:Trim(request.name)
    local body = type(request.body) == "string" and request.body or ""
    local scope = request.scope

    if isInCombat() then
        return false, "Combat Lockdown - native macros cannot be created until combat ends."
    end
    if type(CreateMacro) ~= "function" then
        return false, "The WoW CreateMacro API is unavailable."
    end
    if name == "" then
        return false, "Enter a macro name."
    end
    if MacroStudio.Helpers:TextLength(name) > MacroStudio.MAX_NAME_LENGTH then
        return false, string.format("Macro names are limited to %d characters.", MacroStudio.MAX_NAME_LENGTH)
    end
    if MacroStudio.Helpers:TextLength(body) > MacroStudio.MAX_BODY_LENGTH then
        return false, string.format("Macro bodies are limited to %d characters.", MacroStudio.MAX_BODY_LENGTH)
    end
    if scope ~= "ACCOUNT" and scope ~= "CHARACTER" then
        return false, "Choose Account or Character scope."
    end
    if type(request.icon) ~= "number" and (type(request.icon) ~= "string" or request.icon == "") then
        return false, "Choose a valid macro icon."
    end

    local count, capacity = self:GetCapacity(scope)
    if count >= capacity then
        return false, string.format("%s macros are full (%d/%d).", scope == "ACCOUNT" and "Account" or "Character", count, capacity)
    end
    return true
end

local function matchesCreatedResult(macro, request)
    return macro
        and macro.scope == request.scope
        and macro.name == request.name
        and macro.body == request.body
end

function MacroRepository:Create(request)
    request = type(request) == "table" and request or {}
    request = {
        name = MacroStudio.Helpers:Trim(request.name),
        body = type(request.body) == "string" and request.body or "",
        scope = request.scope,
        icon = request.icon or MacroStudio.DEFAULT_ICON,
    }

    self:Refresh()
    local valid, message = self:ValidateCreateRequest(request)
    if not valid then
        return false, nil, message
    end

    local ok, returnedIndex = pcall(CreateMacro, request.name, request.icon, request.body, request.scope == "CHARACTER")
    if not ok then
        return false, nil, "WoW rejected the macro creation request: " .. tostring(returnedIndex)
    end

    self:Refresh()
    local created = tonumber(returnedIndex) and self:FindByIndex(tonumber(returnedIndex)) or nil
    if matchesCreatedResult(created, request) then
        return true, created
    end

    local uniqueMatch
    local matchCount = 0
    for _, macro in ipairs(self.macros) do
        if matchesCreatedResult(macro, request) then
            uniqueMatch = macro
            matchCount = matchCount + 1
        end
    end
    if matchCount == 1 then
        return true, uniqueMatch
    end
    if matchCount > 1 then
        return true, nil, "Created, but duplicate macros made automatic selection ambiguous."
    end
    return false, nil, "WoW did not confirm the new macro."
end

local function matchesSavedResult(macro, original, body)
    return macro
        and macro.scope == original.scope
        and macro.name == original.name
        and macro.icon == original.icon
        and macro.body == body
end

function MacroRepository:Update(snapshot, newBody)
    MacroStudio:Debug("save attempted", snapshot and snapshot.index or "no index")

    if type(snapshot) ~= "table" or type(snapshot.index) ~= "number" then
        return false, nil, "No macro is selected."
    end
    if type(newBody) ~= "string" then
        return false, nil, "The editor buffer is unavailable."
    end
    if isInCombat() then
        return false, nil, "Combat Lockdown - native macros cannot be modified until combat ends."
    end

    local bodyLength = MacroStudio.Helpers:TextLength(newBody)
    if bodyLength > MacroStudio.MAX_BODY_LENGTH then
        return false, nil, string.format(
            "Macro is too long by %d characters. Nothing was saved.",
            bodyLength - MacroStudio.MAX_BODY_LENGTH
        )
    end

    local current = self:GetByIndex(snapshot.index, snapshot.scope)
    if not current then
        return false, nil, "The selected macro no longer exists at its expected index."
    end
    if not self:SnapshotsEqual(current, snapshot) then
        return false, nil, "The selected macro changed outside MacroStudio. Refresh or Revert before saving."
    end
    if type(EditMacro) ~= "function" then
        return false, nil, "The WoW EditMacro API is unavailable."
    end

    local returnedIndex = EditMacro(current.index, nil, nil, newBody)
    self:Refresh()

    local returnedMacro = tonumber(returnedIndex) and self:FindByIndex(tonumber(returnedIndex)) or nil
    if matchesSavedResult(returnedMacro, current, newBody) then
        if returnedMacro.index ~= current.index then
            MacroStudio:Debug("macro index changed after save", current.index, "->", returnedMacro.index)
        end
        MacroStudio:Debug("save succeeded", returnedMacro.index)
        return true, returnedMacro
    end

    local originalIndexMacro = self:FindByIndex(current.index)
    if matchesSavedResult(originalIndexMacro, current, newBody) then
        MacroStudio:Debug("save succeeded", originalIndexMacro.index)
        return true, originalIndexMacro
    end

    local uniqueMatch
    local matchCount = 0
    for _, macro in ipairs(self.macros) do
        if matchesSavedResult(macro, current, newBody) then
            uniqueMatch = macro
            matchCount = matchCount + 1
        end
    end
    if matchCount == 1 then
        MacroStudio:Debug("macro index changed after save", current.index, "->", uniqueMatch.index)
        MacroStudio:Debug("save succeeded", uniqueMatch.index)
        return true, uniqueMatch
    end
    if matchCount > 1 then
        return true, nil, "Saved, but duplicate macros made automatic re-selection ambiguous. Refresh and select the macro again."
    end

    return false, nil, "WoW did not confirm the macro update. The editor buffer was preserved."
end

function MacroRepository:Delete(snapshot)
    if type(snapshot) ~= "table" or type(snapshot.index) ~= "number" then
        return false, "No macro is selected."
    end
    if isInCombat() then
        return false, "Combat Lockdown - native macros cannot be deleted until combat ends."
    end
    if type(DeleteMacro) ~= "function" then
        return false, "The WoW DeleteMacro API is unavailable."
    end

    self:Refresh()
    local current = self:GetByIndex(snapshot.index, snapshot.scope)
    if not current or not self:SnapshotsEqual(current, snapshot) then
        return false, "The selected macro changed outside MacroStudio. Refresh before deleting it."
    end

    local previousCount = current.scope == "ACCOUNT" and self.accountCount or self.characterCount
    local ok, failure = pcall(DeleteMacro, current.index)
    if not ok then
        return false, "WoW rejected the delete request: " .. tostring(failure)
    end

    self:Refresh()
    local currentCount = current.scope == "ACCOUNT" and self.accountCount or self.characterCount
    if currentCount == previousCount - 1 then
        return true
    end
    return false, "WoW did not confirm that the macro was deleted."
end
