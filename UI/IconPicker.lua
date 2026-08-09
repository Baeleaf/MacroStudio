local _, MacroStudio = ...

local IconPicker = {
    buttons = {},
    icons = nil,
    topRow = 0,
}
MacroStudio.IconPicker = IconPicker

local COLUMNS = 8
local VISIBLE_ROWS = 5
local ICON_SIZE = 36
local ICON_GAP = 5
local PITCH = ICON_SIZE + ICON_GAP
local GRID_WIDTH = COLUMNS * PITCH
local GRID_HEIGHT = VISIBLE_ROWS * PITCH
local WINDOW_WIDTH = GRID_WIDTH + 58
local WINDOW_HEIGHT = GRID_HEIGHT + 92

local function getIconIdentity(icon)
    if type(icon) == "number" then
        return "file:" .. tostring(icon)
    end
    if type(icon) ~= "string" or icon == "" then
        return nil
    end

    if type(GetFileIDFromPath) == "function" then
        local ok, fileId = pcall(GetFileIDFromPath, icon)
        if ok and type(fileId) == "number" and fileId > 0 then
            return "file:" .. tostring(fileId)
        end
    end

    local normalized = icon:lower():gsub("/", "\\"):gsub("%.blp$", "")
    local basename = normalized:match("([^\\]+)$") or normalized
    if basename == "inv_misc_questionmark" then
        return "file:" .. tostring(MacroStudio.DEFAULT_ICON)
    end
    return "path:" .. normalized
end

local function appendUnique(result, seen, icon)
    local identity = getIconIdentity(icon)
    if identity and not seen[identity] then
        seen[identity] = true
        result[#result + 1] = icon
    end
end

function IconPicker:BuildIconList()
    if self.icons then
        return self.icons
    end

    local gathered = {}

    -- Current Retail exposes the same provider used by Blizzard's macro UI.
    if IconDataProviderMixin and CreateAndInitFromMixin then
        local extraType = IconDataProviderExtraType and IconDataProviderExtraType.None
        local ok, provider = pcall(CreateAndInitFromMixin, IconDataProviderMixin, extraType)
        if ok and type(provider) == "table" and provider.GetNumIcons and provider.GetIconByIndex then
            for index = 1, provider:GetNumIcons() do
                gathered[#gathered + 1] = provider:GetIconByIndex(index)
            end
            if provider.Release then
                provider:Release()
            end
        end
    end

    -- Fallbacks remain useful if Blizzard's Macro UI provider is not loaded yet.
    if #gathered == 0 and type(GetMacroIcons) == "function" then
        GetMacroIcons(gathered)
        if type(GetMacroItemIcons) == "function" then
            GetMacroItemIcons(gathered)
        end
    end
    if #gathered == 0 and type(GetNumMacroIcons) == "function" and type(GetMacroIconInfo) == "function" then
        for index = 1, GetNumMacroIcons() do
            gathered[#gathered + 1] = GetMacroIconInfo(index)
        end
    end

    local icons = {}
    local seen = {}
    appendUnique(icons, seen, MacroStudio.DEFAULT_ICON)
    for _, icon in ipairs(gathered) do
        appendUnique(icons, seen, icon)
    end

    self.icons = icons
    return icons
end

function IconPicker:GetMaximumTopRow()
    return math.max(0, math.ceil(#self:BuildIconList() / COLUMNS) - VISIBLE_ROWS)
end

function IconPicker:RefreshGrid()
    local icons = self:BuildIconList()
    local first = self.topRow * COLUMNS

    for index, button in ipairs(self.buttons) do
        local icon = icons[first + index]
        button.iconValue = icon
        button.Icon:SetTexture(icon or MacroStudio.DEFAULT_ICON)
        button.Selected:SetShown(icon ~= nil and icon == self.selectedIcon)
        button:SetShown(icon ~= nil)
    end
end

function IconPicker:SetTopRow(row)
    local maximum = self:GetMaximumTopRow()
    self.topRow = math.max(0, math.min(maximum, math.floor((tonumber(row) or 0) + 0.5)))
    self:RefreshGrid()
end

function IconPicker:CreateIconButton(parent, index)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(ICON_SIZE, ICON_SIZE)
    button:SetPoint(
        "TOPLEFT",
        parent,
        "TOPLEFT",
        ((index - 1) % COLUMNS) * PITCH,
        -math.floor((index - 1) / COLUMNS) * PITCH
    )

    local selected = button:CreateTexture(nil, "BACKGROUND")
    selected:SetPoint("TOPLEFT", -2, 2)
    selected:SetPoint("BOTTOMRIGHT", 2, -2)
    selected:SetColorTexture(1, 0.78, 0.12, 0.95)
    selected:Hide()
    button.Selected = selected

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.Icon = icon

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.25)

    button:SetScript("OnEnter", function(row)
        MacroStudio.Helpers:ShowTooltip(row, "Choose Icon", "Use this icon for the new native macro.")
    end)
    button:SetScript("OnLeave", function()
        MacroStudio.Helpers:HideTooltip()
    end)
    button:SetScript("OnClick", function(row)
        if not row.iconValue then
            return
        end
        local callback = self.onSelect
        self.selectedIcon = row.iconValue
        self.frame:Hide()
        if callback then
            callback(row.iconValue)
        end
    end)

    return button
end

function IconPicker:Create()
    if self.frame then
        return self.frame
    end

    local frame = MacroStudio.Helpers:CreatePanel(UIParent)
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local title = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalLarge", "Choose Macro Icon")
    title:SetPoint("TOPLEFT", 15, -14)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local grid = CreateFrame("Frame", nil, frame)
    grid:SetSize(GRID_WIDTH, GRID_HEIGHT)
    grid:SetPoint("TOPLEFT", 15, -44)
    grid:EnableMouseWheel(true)
    self.grid = grid

    for index = 1, COLUMNS * VISIBLE_ROWS do
        self.buttons[index] = self:CreateIconButton(grid, index)
    end

    local scrollBar = CreateFrame("Slider", nil, frame, "BackdropTemplate")
    scrollBar:SetWidth(12)
    scrollBar:SetPoint("TOPLEFT", grid, "TOPRIGHT", 9, 0)
    scrollBar:SetPoint("BOTTOMLEFT", grid, "BOTTOMRIGHT", 9, 0)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    scrollBar:SetBackdropColor(0.08, 0.09, 0.12, 0.9)
    scrollBar:SetValueStep(1)
    scrollBar:SetObeyStepOnDrag(true)

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.45, 0.65, 0.85, 0.95)
    thumb:SetSize(12, 36)
    scrollBar:SetThumbTexture(thumb)
    scrollBar:SetScript("OnValueChanged", function(_, value)
        self:SetTopRow(value)
    end)
    self.scrollBar = scrollBar

    grid:SetScript("OnMouseWheel", function(_, delta)
        scrollBar:SetValue(self.topRow - (delta * 3))
    end)

    local countText = MacroStudio.Helpers:CreateLabel(frame, "GameFontDisableSmall", "")
    countText:SetPoint("BOTTOMLEFT", 15, 17)
    self.countText = countText

    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(86, 24)
    cancel:SetPoint("BOTTOMRIGHT", -15, 12)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

function IconPicker:Open(currentIcon, callback)
    local frame = self:Create()
    local icons = self:BuildIconList()
    self.selectedIcon = currentIcon or MacroStudio.DEFAULT_ICON
    self.onSelect = callback
    self.countText:SetText(string.format("%d available icons", #icons))

    local selectedIndex = 1
    for index, icon in ipairs(icons) do
        if icon == self.selectedIcon then
            selectedIndex = index
            break
        end
    end

    local selectedRow = math.floor((selectedIndex - 1) / COLUMNS)
    self.scrollBar:SetMinMaxValues(0, self:GetMaximumTopRow())
    self.scrollBar:SetValue(math.min(selectedRow, self:GetMaximumTopRow()))
    self:SetTopRow(selectedRow)
    frame:Show()
    frame:Raise()
end
