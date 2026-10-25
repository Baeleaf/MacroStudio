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
local WINDOW_HEIGHT = GRID_HEIGHT + 132

local RAID_NAMES = { "Star", "Circle", "Diamond", "Triangle", "Moon", "Square", "Cross", "Skull" }

local function getIconIdentity(icon)
    return MacroStudio.Helpers:GetIconIdentity(icon)
end

local function appendUnique(result, seen, icon)
    icon = MacroStudio.Helpers:NormalizeIcon(icon)
    local identity = getIconIdentity(icon)
    if identity and not seen[identity] then
        seen[identity] = true
        result[#result + 1] = icon
    end
end

function IconPicker:AddSearchEntry(icon, label, keywords)
    local identity = getIconIdentity(icon)
    if not identity then return end
    self.searchEntries[#self.searchEntries + 1] = {
        icon = MacroStudio.Helpers:NormalizeIcon(icon),
        text = (label .. " " .. (keywords or "")):lower(),
    }
    self.iconLabels[identity] = label
end

function IconPicker:BuildSearchEntries()
    self.searchEntries = {}
    self.iconLabels = {}
    for index, name in ipairs(RAID_NAMES) do
        local localized = _G["RAID_TARGET_" .. index] or name
        self:AddSearchEntry("Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index,
            localized, "raid marker target mark " .. name .. (index == 7 and " x" or ""))
    end

    -- Rebuild on open so changing specialization or learning a spell is reflected.
    local book = C_SpellBook
    local bank = Enum and Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Player
    if book and bank and book.GetNumSpellBookSkillLines and book.GetSpellBookSkillLineInfo
        and book.GetSpellBookItemInfo then
        for line = 1, book.GetNumSpellBookSkillLines() do
            local info = book.GetSpellBookSkillLineInfo(line)
            if info then
                for index = info.itemIndexOffset + 1, info.itemIndexOffset + info.numSpellBookItems do
                    local spell = book.GetSpellBookItemInfo(index, bank)
                    if spell and spell.name and spell.iconID then
                        self:AddSearchEntry(spell.iconID, spell.name)
                    end
                end
            end
        end
    end
end

function IconPicker:GetVisibleIcons()
    return self.filteredIcons or self:BuildIconList()
end

function IconPicker:UpdateScroll(row)
    local icons = self:GetVisibleIcons()
    local maximum = self:GetMaximumTopRow()
    local totalRows = math.ceil(#icons / COLUMNS)
    self.scrollBar:Init(math.min(1, VISIBLE_ROWS / math.max(1, totalRows)), maximum > 0 and 1 / maximum or 0)
    self.scrollBar:SetScrollPercentage(maximum > 0 and math.min(row or 0, maximum) / maximum or 0, true)
    self:SetTopRow(row or 0)
end

function IconPicker:Search(query)
    query = MacroStudio.Helpers:Trim(query):lower()
    self.filteredIcons = nil
    if query ~= "" then
        local result, seen = {}, {}
        -- A number is always an icon file ID, never a spell ID or list index.
        if query:match("^%d+$") then
            local id = tonumber(query)
            if id > 0 then appendUnique(result, seen, id) end
        else
            -- Exact names can resolve even when the ability isn't in this spellbook.
            if C_Spell and C_Spell.GetSpellInfo then
                local ok, spell = pcall(C_Spell.GetSpellInfo, query)
                if ok and spell and spell.iconID then
                    appendUnique(result, seen, spell.iconID)
                    self.iconLabels[getIconIdentity(spell.iconID)] = spell.name
                end
            end
            for _, entry in ipairs(self.searchEntries or {}) do
                if entry.text:find(query, 1, true) then appendUnique(result, seen, entry.icon) end
            end
            for _, icon in ipairs(self:BuildIconList()) do
                if type(icon) == "string" and icon:lower():gsub("_", " "):find(query, 1, true) then
                    appendUnique(result, seen, icon)
                end
            end
        end
        self.filteredIcons = result
    end
    local count = #self:GetVisibleIcons()
    self.countText:SetText(query == "" and string.format("%d available icons", count)
        or count == 0 and "No matching icons" or string.format("%d matching icons", count))
    self:UpdateScroll(0)
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
    for index = 1, #RAID_NAMES do
        appendUnique(icons, seen, "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. index)
    end

    self.icons = icons
    return icons
end

function IconPicker:GetMaximumTopRow()
    return math.max(0, math.ceil(#self:GetVisibleIcons() / COLUMNS) - VISIBLE_ROWS)
end

function IconPicker:RefreshGrid()
    local icons = self:GetVisibleIcons()
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
        local label = self.iconLabels and self.iconLabels[getIconIdentity(row.iconValue)] or "Choose Icon"
        MacroStudio.Helpers:ShowTooltip(row, label,
            (self.selectionHelp or "Use this icon for the macro.") .. "\nIcon: " .. tostring(row.iconValue))
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
        if self.searchBox then self.searchBox:ClearFocus() end
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

    local searchBox = MacroStudio.Helpers:CreateInput(frame)
    searchBox:SetHeight(24)
    searchBox:SetPoint("TOPLEFT", 15, -43)
    searchBox:SetPoint("TOPRIGHT", -45, -43)
    searchBox:SetMaxLetters(120)
    MacroStudio.Helpers:ConfigureEditBox(searchBox)
    self.searchBox = searchBox

    local placeholder = MacroStudio.Helpers:CreateLabel(searchBox, "GameFontDisableSmall", "Search abilities, raid, or icon ID...")
    placeholder:SetPoint("LEFT", 7, 0)
    local clear = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    clear:SetSize(24, 24)
    clear:SetPoint("LEFT", searchBox, "RIGHT", 2, 0)
    self.clearSearchButton = clear
    local function updateSearch()
        local empty = searchBox:GetText() == ""
        placeholder:SetShown(empty and not searchBox:HasFocus())
        clear:SetShown(not empty)
    end
    searchBox:HookScript("OnTextChanged", function(box)
        updateSearch()
        if not self.suppressSearch then self:Search(box:GetText()) end
    end)
    searchBox:HookScript("OnEditFocusGained", updateSearch)
    searchBox:HookScript("OnEditFocusLost", updateSearch)
    searchBox:HookScript("OnEnterPressed", function(box) box:ClearFocus() end)
    searchBox:HookScript("OnEscapePressed", function(box)
        if box:GetText() ~= "" then box:SetText("") else frame:Hide() end
    end)
    clear:SetScript("OnClick", function() searchBox:SetText(""); searchBox:SetFocus() end)
    MacroStudio.Helpers:SetButtonTooltip(clear, "Clear Search", "Show all available icons.")
    updateSearch()

    local grid = CreateFrame("Frame", nil, frame)
    grid:SetSize(GRID_WIDTH, GRID_HEIGHT)
    grid:SetPoint("TOPLEFT", 15, -84)
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
    self:BuildSearchEntries()
    self.filteredIcons = nil
    self.suppressSearch = true
    self.searchBox:SetText("")
    self.searchBox:ClearFocus()
    self.suppressSearch = false
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
    self:UpdateScroll(selectedRow)
    frame:Show()
    frame:Raise()
end
