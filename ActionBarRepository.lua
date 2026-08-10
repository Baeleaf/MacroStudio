local _, MacroStudio = ...

local ActionBarRepository = {
    usageByIndex = {},
    scanCount = 0,
}
MacroStudio.ActionBarRepository = ActionBarRepository

-- Retail FrameXML defines 12 slots per page and native action-bar page indexes
-- through 18 (vehicle 16, temporary shapeshift 17, override 18).
ActionBarRepository.MAX_ACTION_SLOTS = 12 * 18

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
        local actionType, actionID = GetActionInfo(slot)
        actionID = tonumber(actionID)
        if actionType == "macro" and actionID then
            local listedMacro = MacroStudio.MacroRepository:FindByIndex(actionID)
            if listedMacro then
                local currentMacro = MacroStudio.MacroRepository:GetByIndex(actionID, listedMacro.scope)
                if currentMacro and MacroStudio.MacroRepository:SnapshotsEqual(currentMacro, listedMacro) then
                    local usage = usageByIndex[actionID]
                    if not usage then
                        usage = {
                            macro = MacroStudio.Helpers:CopyMacro(currentMacro),
                            slots = {},
                        }
                        usageByIndex[actionID] = usage
                    end
                    usage.slots[#usage.slots + 1] = slot
                end
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
