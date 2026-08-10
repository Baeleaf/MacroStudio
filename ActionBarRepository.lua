local _, MacroStudio = ...

local ActionBarRepository = {
    usageByIndex = {},
    scanCount = 0,
}
MacroStudio.ActionBarRepository = ActionBarRepository

-- Retail FrameXML defines 12 slots per page and native action-bar page indexes
-- through 18 (vehicle 16, temporary shapeshift 17, override 18).
ActionBarRepository.MAX_ACTION_SLOTS = 12 * 18

local function safeToNumber(value)
    local ok, number = pcall(tonumber, value)
    if ok and type(number) == "number" and number > 0 then
        return number
    end
    return nil
end

local function safeToString(value)
    local ok, text = pcall(tostring, value)
    return ok and text or "<unavailable>"
end

local function getActionText(slot)
    local provider = C_ActionBar and C_ActionBar.GetActionText or GetActionText
    if type(provider) ~= "function" then
        return nil
    end

    local ok, text = pcall(provider, slot)
    return ok and type(text) == "string" and text or nil
end

local function getActionTexture(slot)
    local provider = C_ActionBar and C_ActionBar.GetActionTexture or GetActionTexture
    if type(provider) ~= "function" then
        return nil
    end

    local ok, texture = pcall(provider, slot)
    return ok and texture or nil
end

local function normalizeIcon(icon)
    if type(icon) == "number" then
        return icon
    end
    if type(icon) == "string" and type(GetFileIDFromPath) == "function" then
        local ok, fileID = pcall(GetFileIDFromPath, icon)
        if ok and type(fileID) == "number" then
            return fileID
        end
    end
    return icon
end

local function isDynamicMacroIcon(icon)
    local normalized = normalizeIcon(icon)
    if normalized == MacroStudio.DEFAULT_ICON then
        return true
    end
    if type(icon) ~= "string" then
        return false
    end

    local basename = icon:lower():gsub("\\", "/"):match("([^/]+)$") or ""
    basename = basename:gsub("%.blp$", ""):gsub("%.tga$", "")
    return basename == "inv_misc_questionmark"
end

local function iconsEqual(first, second)
    if first == second then
        return true
    end
    return normalizeIcon(first) == normalizeIcon(second)
end

local function getMacroSpellID(index)
    if type(GetMacroSpell) ~= "function" then
        return nil
    end

    local ok, first, second = pcall(GetMacroSpell, index)
    if not ok then
        return nil
    end
    return safeToNumber(first) or safeToNumber(second)
end

local function itemIDFromValue(value)
    local direct = safeToNumber(value)
    if direct then
        return direct
    end
    if type(value) ~= "string" then
        return nil
    end

    local linked = safeToNumber(value:match("item:(%d+)"))
    if linked then
        return linked
    end
    if C_Item and type(C_Item.GetItemIDForItemInfo) == "function" then
        local ok, itemID = pcall(C_Item.GetItemIDForItemInfo, value)
        if ok and safeToNumber(itemID) then
            return safeToNumber(itemID)
        end
    end
    if C_Item and type(C_Item.GetItemInfoInstant) == "function" then
        local ok, itemID = pcall(C_Item.GetItemInfoInstant, value)
        if ok and safeToNumber(itemID) then
            return safeToNumber(itemID)
        end
    end
    if type(GetItemInfoInstant) == "function" then
        local ok, itemID = pcall(GetItemInfoInstant, value)
        if ok and safeToNumber(itemID) then
            return safeToNumber(itemID)
        end
    end
    return nil
end

local function getMacroItemID(index)
    if type(GetMacroItem) ~= "function" then
        return nil
    end

    local ok, first, second = pcall(GetMacroItem, index)
    if not ok then
        return nil
    end
    return itemIDFromValue(second) or itemIDFromValue(first)
end

local function resolutionMatches(macro, actionID, actionSubtype)
    local spellID = getMacroSpellID(macro.index)
    local itemID = getMacroItemID(macro.index)
    local resolvedActionID = safeToNumber(actionID)

    if actionSubtype == "spell" then
        return spellID ~= nil and resolvedActionID == spellID, true
    end
    if actionSubtype == "item" then
        return itemID ~= nil and resolvedActionID == itemID, true
    end
    if actionSubtype ~= nil and actionSubtype ~= "" then
        return false, false
    end
    return spellID == nil and itemID == nil, false
end

local function candidateMatches(macro, actionText, actionTexture, actionID, actionSubtype)
    if macro.name ~= actionText then
        return false
    end

    local resolutionMatch, hasResolutionEvidence = resolutionMatches(macro, actionID, actionSubtype)
    if not resolutionMatch then
        return false
    end
    if isDynamicMacroIcon(macro.icon) then
        return hasResolutionEvidence
    end
    return actionTexture ~= nil and iconsEqual(macro.icon, actionTexture)
end

function ActionBarRepository:ResolveMacroAction(slot, actionID, actionSubtype)
    local actionText = getActionText(slot)
    local actionTexture = getActionTexture(slot)
    if not actionText or actionText == "" then
        return nil, "unresolved", actionText
    end

    local matches = {}
    for _, macro in ipairs(MacroStudio.MacroRepository:GetAll()) do
        if candidateMatches(macro, actionText, actionTexture, actionID, actionSubtype) then
            matches[#matches + 1] = macro
        end
    end

    if #matches > 1 then
        return nil, "ambiguous", actionText
    end
    if #matches == 0 then
        return nil, "unresolved", actionText
    end

    local listedMacro = matches[1]
    local currentMacro = MacroStudio.MacroRepository:GetByIndex(listedMacro.index, listedMacro.scope)
    if not currentMacro or not MacroStudio.MacroRepository:SnapshotsEqual(currentMacro, listedMacro) then
        return nil, "unresolved", actionText
    end
    return currentMacro, "exact", actionText
end

local function copySlots(slots)
    local copy = {}
    for index, slot in ipairs(slots or {}) do
        copy[index] = slot
    end
    return copy
end

function ActionBarRepository:Refresh()
    local usageByIndex = {}
    self.scanCount = self.scanCount + 1

    if type(GetActionInfo) ~= "function" then
        self.usageByIndex = usageByIndex
        return usageByIndex
    end

    for slot = 1, self.MAX_ACTION_SLOTS do
        local actionType, actionID, actionSubtype = GetActionInfo(slot)
        if actionType == "macro" then
            local currentMacro, identity, actionText = self:ResolveMacroAction(slot, actionID, actionSubtype)
            MacroStudio:Debug(
                "action-bar macro",
                "slot", slot,
                "type", safeToString(actionType),
                "id", safeToString(actionID),
                "subType", safeToString(actionSubtype),
                "text", safeToString(actionText),
                "resolvedIndex", currentMacro and currentMacro.index or "none",
                "identity", identity
            )
            if currentMacro then
                local usage = usageByIndex[currentMacro.index]
                if not usage then
                    usage = {
                        macro = MacroStudio.Helpers:CopyMacro(currentMacro),
                        slots = {},
                    }
                    usageByIndex[currentMacro.index] = usage
                end
                usage.slots[#usage.slots + 1] = slot
            end
        end
    end

    self.usageByIndex = usageByIndex
    MacroStudio:Debug("action-bar usage refreshed", self.scanCount)
    return usageByIndex
end

function ActionBarRepository:GetUsage(macro)
    if type(macro) ~= "table" or type(macro.index) ~= "number" then
        return 0, {}
    end

    local usage = self.usageByIndex[macro.index]
    if not usage or not MacroStudio.MacroRepository:SnapshotsEqual(usage.macro, macro) then
        return 0, {}
    end

    local slots = copySlots(usage.slots)
    return #slots, slots
end

function ActionBarRepository:GetScanCount()
    return self.scanCount
end
