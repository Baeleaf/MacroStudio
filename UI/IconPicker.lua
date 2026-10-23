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
    return MacroStudio.Helpers:GetIconIdentity(icon)
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
        button.Selected:SetShown(
            icon ~= nil and getIconIdentity(icon) == getIconIdentity(self.selectedIcon)
        )
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
    selected:SetColorTexture(unpack(MacroStudio.Theme.palette.gold))
    selected:Hide()
    button.Selected = selected

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetAllPoints()
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.Icon = icon
    MacroStudio.Theme:IconBorder(button, icon)

    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.25)

    button:SetScript("OnEnter", function(row)
        MacroStudio.Helpers:ShowTooltip(row, "Choose Icon", self.selectionHelp or "Use this icon for the macro.")
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

    local frame = MacroStudio.Helpers:CreateWindow(UIParent)
    frame:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:SetScript("OnHide", function()
        local onClose = self.onClose
        self.onClose = nil
        self.onSelect = nil
        self.selectionHelp = nil
        if onClose then
            onClose()
        end
    end)
    frame:Hide()
    self.frame = frame

    local title = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalLarge", "Choose Macro Icon")
    title:SetPoint("TOPLEFT", 15, -14)
    MacroStudio.Theme:Dialog(frame, title)

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

    local scrollBar = CreateFrame("EventFrame", nil, frame, MacroStudio.Theme.resources.scrollBar)
    scrollBar:SetWidth(25)
    scrollBar:SetPoint("TOPLEFT", grid, "TOPRIGHT", 4, 0)
    scrollBar:SetPoint("BOTTOMLEFT", grid, "BOTTOMRIGHT", 4, 0)
    scrollBar:RegisterCallback(ScrollBarMixin.Event.OnScroll, function(_, percentage)
        self:SetTopRow(percentage * self:GetMaximumTopRow())
    end, self)
    MacroStudio.Theme:ScrollBar(scrollBar)
    self.scrollBar = scrollBar

    grid:SetScript("OnMouseWheel", function(_, delta)
        local maximum = self:GetMaximumTopRow()
        self:SetTopRow(self.topRow - (delta * 3))
        scrollBar:SetScrollPercentage(maximum > 0 and self.topRow / maximum or 0, true)
    end)

    local countText = MacroStudio.Helpers:CreateLabel(frame, "GameFontDisableSmall", "")
    countText:SetPoint("BOTTOMLEFT", 15, 17)
    self.countText = countText

    local cancel = MacroStudio.Helpers:CreateButton(frame)
    cancel:SetSize(86, 24)
    cancel:SetPoint("BOTTOMRIGHT", -15, 12)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        frame:Hide()
    end)

    return frame
end

function IconPicker:Open(currentIcon, callback, options)
    local frame = self:Create()
    local icons = self:BuildIconList()
    options = type(options) == "table" and options or {}
    self.selectedIcon = currentIcon or MacroStudio.DEFAULT_ICON
    self.onSelect = callback
    self.onClose = options.onClose
    self.selectionHelp = options.selectionHelp
    self.countText:SetText(string.format("%d available icons", #icons))

    local selectedIndex = 1
    for index, icon in ipairs(icons) do
        if getIconIdentity(icon) == getIconIdentity(self.selectedIcon) then
            selectedIndex = index
            break
        end
    end

    local selectedRow = math.floor((selectedIndex - 1) / COLUMNS)
    local maximum = self:GetMaximumTopRow()
    local totalRows = math.ceil(#icons / COLUMNS)
    self.scrollBar:Init(math.min(1, VISIBLE_ROWS / math.max(1, totalRows)), maximum > 0 and 1 / maximum or 0)
    self.scrollBar:SetScrollPercentage(maximum > 0 and math.min(selectedRow, maximum) / maximum or 0, true)
    self:SetTopRow(selectedRow)
    frame:Show()
    frame:Raise()
end
