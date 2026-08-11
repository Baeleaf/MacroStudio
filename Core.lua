local addonName, MacroStudio = ...

MacroStudio.ADDON_NAME = addonName
MacroStudio.VERSION = "1.2.0-r3"
MacroStudio.MAX_BODY_LENGTH = 255
MacroStudio.MAX_NAME_LENGTH = tonumber(MAX_MACRO_NAME_LENGTH) or 16
MacroStudio.BODY_WARNING_LENGTH = 230
MacroStudio.DEFAULT_WIDTH = 1100
MacroStudio.DEFAULT_HEIGHT = 650
MacroStudio.MIN_WIDTH = 900
MacroStudio.MIN_HEIGHT = 500
MacroStudio.DEFAULT_ICON = 134400 -- INV_Misc_QuestionMark
MacroStudio.debug = false
MacroStudio.inCombat = false

local function joinArguments(...)
    local parts = {}
    for index = 1, select("#", ...) do
        parts[index] = tostring(select(index, ...))
    end
    return table.concat(parts, " ")
end

function MacroStudio:Print(...)
    print("|cff59b8ffMacroStudio|r:", joinArguments(...))
end

function MacroStudio:Debug(...)
    if self.debug then
        print("|cff8bd0ffMacroStudio Debug|r:", joinArguments(...))
    end
end

function MacroStudio:SetDebug(enabled)
    self.debug = enabled and true or false
    self:Print("Debug logging " .. (self.debug and "enabled." or "disabled."))
end

function MacroStudio:OnAddonLoaded()
    if self.Database then
        self.Database:Initialize()
    end
    self.inCombat = InCombatLockdown() and true or false
    self:Debug("ADDON_LOADED")
end

function MacroStudio:OnPlayerLogin()
    self:Debug("PLAYER_LOGIN")
    if self.Initialize then
        self:Initialize()
    end
    if self.Access then
        self.Access:ScheduleInitialize()
    end
    if self.MinimapButton then
        self.MinimapButton:Initialize()
    end
end

function MacroStudio:OnCombatEvent(inCombat)
    self.inCombat = inCombat and true or false
    self:Debug(self.inCombat and "combat lockdown entered" or "combat lockdown ended")
    if self.UpdateCombatState then
        self:UpdateCombatState()
    end
end

local eventFrame = CreateFrame("Frame")
MacroStudio.eventFrame = eventFrame

local actionBarEvents = {
    PLAYER_ENTERING_WORLD = true,
    ACTIONBAR_SLOT_CHANGED = true,
    ACTIONBAR_PAGE_CHANGED = true,
    UPDATE_BONUS_ACTIONBAR = true,
    UPDATE_VEHICLE_ACTIONBAR = true,
    UPDATE_OVERRIDE_ACTIONBAR = true,
    UPDATE_SHAPESHIFT_FORM = true,
    UPDATE_POSSESS_BAR = true,
}

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("UPDATE_MACROS")
for event in pairs(actionBarEvents) do
    eventFrame:RegisterEvent(event)
end

eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local loadedAddon = ...
        if loadedAddon == addonName then
            MacroStudio:OnAddonLoaded()
        end
    elseif event == "PLAYER_LOGIN" then
        MacroStudio:OnPlayerLogin()
    elseif event == "PLAYER_REGEN_DISABLED" then
        MacroStudio:OnCombatEvent(true)
    elseif event == "PLAYER_REGEN_ENABLED" then
        MacroStudio:OnCombatEvent(false)
    elseif event == "UPDATE_MACROS" and MacroStudio.OnMacrosChanged then
        MacroStudio:OnMacrosChanged("UPDATE_MACROS")
    elseif actionBarEvents[event] and MacroStudio.OnActionBarChanged then
        MacroStudio:OnActionBarChanged(event, ...)
    end
end)
