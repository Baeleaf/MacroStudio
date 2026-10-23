local _, MacroStudio = ...
local Theme = MacroStudio.Theme

-- v1.2's blue/gray appearance shares the same UI controllers and repositories.
-- Select only after SavedVariables initialization; changing it requires reload.
local Legacy = {}
local legacyPalette = {
    text = { 0.82, 0.86, 0.92, 1 }, muted = { 0.6, 0.65, 0.72, 1 },
    secondary = { 0.6, 0.65, 0.72, 1 }, version = { 0.6, 0.65, 0.72, 1 },
    border = { 0.18, 0.22, 0.28, 1 }, focus = { 0.25, 0.62, 1, 1 },
    warning = { 1, 0.68, 0.2, 1 }, error = { 1, 0.3, 0.3, 1 },
    success = { 0.35, 0.9, 0.45, 1 },
}

local function backdrop(frame, background, border)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(unpack(background))
    frame:SetBackdropBorderColor(unpack(border or Theme.palette.border))
end

function Theme:IsLegacy()
    return self.activeAppearance == "legacy"
end

function Theme:Initialize()
    if self.activeAppearance then return end
    self.activeAppearance = MacroStudio.db.settings.appearance
    if not self:IsLegacy() then return end
    -- Keep the palette table identities captured by editor status/focus code.
    for key, color in pairs(legacyPalette) do
        for index, value in ipairs(color) do self.palette[key][index] = value end
    end
    self.spacing.title, self.spacing.gap, self.spacing.row = 42, 12, 48
    self.spacing.navigation = 25
    self.resources.button, self.resources.tab = "UIPanelButtonTemplate", "UIPanelButtonTemplate"
    for method, implementation in pairs(Legacy) do self[method] = implementation end
end

function Theme:SetAppearance(appearance)
    if appearance ~= "warcraft" and appearance ~= "legacy" then return false end
    MacroStudio.db.settings.appearance = appearance
    return true
end

function Theme:HasPendingAppearance()
    return MacroStudio.db.settings.appearance ~= self.activeAppearance
end

function Theme:CreateRowFrame(parent)
    return CreateFrame("Button", nil, parent, self:IsLegacy() and "BackdropTemplate" or nil)
end

function Legacy:CreateWindow(name, parent, portrait)
    local frame = CreateFrame("Frame", name, parent or UIParent, "BackdropTemplate")
    backdrop(frame, { 0.025, 0.03, 0.045, 0.99 }, { 0.25, 0.3, 0.38, 1 })
    local title = CreateFrame("Frame", nil, frame)
    title:SetPoint("TOPLEFT", 1, -1)
    title:SetPoint("TOPRIGHT", -1, -1)
    title:SetHeight(42)
    title.TitleText = title:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.TitleContainer = title
    if portrait then
        frame.CloseButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
        frame.CloseButton:SetPoint("TOPRIGHT", -3, -3)
    end
    return frame
end

function Legacy:Dialog(frame, title)
    frame.TitleContainer.TitleText:Hide()
    title:SetTextColor(0.35, 0.75, 1, 1)
end

function Legacy:CreateInset(parent, editor)
    local frame = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    backdrop(frame, editor and { 0.018, 0.024, 0.035, 1 } or { 0.045, 0.055, 0.075, 0.98 })
    return frame
end

function Legacy:CreateRegion(parent)
    return self:CreateInset(parent)
end

function Legacy:WorkbenchSurface() end
function Legacy:Divider() end
function Legacy:ScrollBar() end
function Legacy:IconBorder() end

function Legacy:Section(_, title)
    title:SetTextColor(1, 0.82, 0, 1)
end

function Legacy:Button(button)
    button:SetNormalFontObject(GameFontNormalSmall)
    button:SetHighlightFontObject(GameFontHighlightSmall)
    button:SetDisabledFontObject(GameFontDisableSmall)
    local label = button:GetFontString()
    if not label then
        label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        label:SetPoint("CENTER")
        button:SetFontString(label)
    end
    button.Text = label
end

function Legacy:SetButtonState(button, enabled)
    if button.Text then
        button.Text:SetTextColor(enabled and 1 or 0.5, enabled and 0.82 or 0.5, enabled and 0 or 0.5)
    end
end

function Legacy:Tab(button, selected)
    if selected then button:SetText(button:GetText() .. " (selected)") end
    button:SetButtonState(selected and "PUSHED" or "NORMAL", selected)
end

function Legacy:CreateFavoriteButton(parent)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    backdrop(button, { 0.06, 0.075, 0.1, 1 })
    button.macroStudioLegacyFavorite = true
    return button
end

function Legacy:ToggleButton(button, selected)
    if button.macroStudioLegacyFavorite then
        button:SetBackdropColor(unpack(selected and { 0.12, 0.22, 0.31, 1 } or { 0.06, 0.075, 0.1, 1 }))
        button:SetBackdropBorderColor(unpack(selected and self.palette.focus or self.palette.border))
    end
    button:SetButtonState(selected and "PUSHED" or "NORMAL", selected)
end

function Legacy:Input(box)
    box:SetFontObject(GameFontHighlight)
    box:SetTextInsets(6, 6, 0, 0)
    box:SetTextColor(unpack(self.palette.text))
end

function Legacy:Row(row)
    backdrop(row, { 0.06, 0.075, 0.1, 1 })
end

function Legacy:RowState(row, hovered)
    local selected = row.selected == true
    row:SetBackdropColor(unpack(selected and { 0.12, 0.24, 0.34, 1 }
        or hovered and { 0.1, 0.16, 0.22, 1 } or { 0.06, 0.075, 0.1, 1 }))
    row:SetBackdropBorderColor(unpack(selected and self.palette.focus or self.palette.border))
    local label = rawget(row, "nameText") or rawget(row, "Text")
    if label then label:SetTextColor(unpack(selected and self.palette.gold or self.palette.text)) end
end
