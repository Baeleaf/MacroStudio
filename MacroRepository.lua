local _, MacroStudio = ...

local MacroRepository = {
    macros = {},
    accountCount = 0,
    characterCount = 0,
}
MacroStudio.MacroRepository = MacroRepository

local FALLBACK_ACCOUNT_CAPACITY = 120

local function accountCapacity()
    return tonumber(MAX_ACCOUNT_MACROS) or FALLBACK_ACCOUNT_CAPACITY
end

local function normalizeCount(value)
    value = tonumber(value) or 0
    if value < 0 then
        return 0
    end
    return math.floor(value)
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
    MacroStudio:Debug("macro refresh", #refreshed, "macros")
    return refreshed
end

function MacroRepository:GetAll()
    return self.macros
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

function MacroRepository:ResolveLatest(snapshot)
    if type(snapshot) ~= "table" then
        return nil, "No macro is selected."
    end

    self:Refresh()

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
    if InCombatLockdown() then
        return false, nil, "Combat Lockdown — native macros cannot be modified until combat ends."
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

    -- Passing nil for name and icon preserves them; using the enumerated index
    -- avoids choosing an arbitrary duplicate by name.
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
