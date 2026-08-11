local _, MacroStudio = ...

local MinimapButton = {}
MacroStudio.MinimapButton = MinimapButton

local ICON = "Interface\\AddOns\\MacroStudio\\Media\\MacroStudioIcon.tga"
local RADIUS = 80

local function atan2(y, x)
    if math.atan2 then
        return math.atan2(y, x)
    end
    if x > 0 then
        return math.atan(y / x)
    elseif x < 0 and y >= 0 then
        return math.atan(y / x) + math.pi
    elseif x < 0 then
        return math.atan(y / x) - math.pi
    elseif y > 0 then
        return math.pi / 2
    elseif y < 0 then
        return -math.pi / 2
    end
    return 0
end

function MinimapButton:GetAngle()
    local settings = MacroStudio.db and MacroStudio.db.settings
    return settings and tonumber(settings.minimapAngle) or 225
end

function MinimapButton:SetAngle(angle)
    angle = (tonumber(angle) or 225) % 360
    MacroStudio.db.settings.minimapAngle = angle
    self:UpdatePosition()
end

function MinimapButton:UpdatePosition()
    if not self.button then
        return
    end
    local radians = math.rad(self:GetAngle())
    self.button:ClearAllPoints()
    self.button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * RADIUS, math.sin(radians) * RADIUS)
end

function MinimapButton:UpdateFromCursor()
    if not self.button or not Minimap or type(GetCursorPosition) ~= "function" then
        return
    end
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then
        return
    end
    local scale = tonumber(UIParent:GetEffectiveScale()) or 1
    if scale == 0 then
        scale = 1
    end
    local cursorX, cursorY = GetCursorPosition()
    cursorX, cursorY = cursorX / scale, cursorY / scale
    local angle = math.deg(atan2(cursorY - centerY, cursorX - centerX)) % 360
    MacroStudio.db.settings.minimapAngle = angle
    self:UpdatePosition()
end

function MinimapButton:Create()
    if self.button or not Minimap then
        return self.button
    end

    local button = CreateFrame("Button", "MacroStudioMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetClampedToScreen(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")

    local icon = button:CreateTexture(nil, "BACKGROUND")
    icon:SetSize(20, 20)
    icon:SetPoint("CENTER")
    icon:SetTexture(ICON)
    icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
    self.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(54, 54)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
    button:SetScript("OnClick", function(_, buttonName)
        if self.dragged then
            self.dragged = false
            return
        end
        MacroStudio.Access:HandleLauncherClick(buttonName)
    end)
    button:SetScript("OnDragStart", function()
        self.dragged = true
        button:SetScript("OnUpdate", function()
            self:UpdateFromCursor()
        end)
    end)
    button:SetScript("OnDragStop", function()
        self:UpdateFromCursor()
        button:SetScript("OnUpdate", nil)
    end)
    button:SetScript("OnEnter", function(owner)
        MacroStudio.Access:ShowLauncherTooltip(owner)
    end)
    button:SetScript("OnLeave", function()
        MacroStudio.Helpers:HideTooltip()
    end)

    self.button = button
    self:UpdatePosition()
    return button
end

function MinimapButton:SetShown(shown)
    shown = shown and true or false
    MacroStudio.db.settings.showMinimapButton = shown
    local button = self:Create()
    if button then
        button:SetShown(shown)
    end
    if MacroStudio.Settings then
        MacroStudio.Settings:Refresh()
    end
end

function MinimapButton:Initialize()
    if self.initialized then
        return
    end
    self.initialized = true
    local button = self:Create()
    if button then
        button:SetShown(MacroStudio.db.settings.showMinimapButton == true)
    end
end
