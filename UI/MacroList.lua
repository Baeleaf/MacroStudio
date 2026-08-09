local _, MacroStudio = ...

local MacroList = {
    rowPool = {},
    headerPool = {},
    emptyPool = {},
}
MacroStudio.MacroList = MacroList

local ROW_HEIGHT = 48
local HEADER_HEIGHT = 27
local EMPTY_HEIGHT = 28
local CONTENT_GAP = 4

local function acquireFontString(pool, parent, fontObject)
    local fontString = pool[#pool]
    if fontString then
        pool[#pool] = nil
        fontString:Show()
        return fontString
    end
    return MacroStudio.Helpers:CreateLabel(parent, fontObject, "")
end

function MacroList:Create(parent)
    local panel = MacroStudio.Helpers:CreatePanel(parent)
    self.panel = panel

    local heading = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalLarge", "MACROS")
    heading:SetPoint("TOPLEFT", 14, -14)

    local newMacroButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    newMacroButton:SetSize(104, 22)
    newMacroButton:SetPoint("TOPRIGHT", -12, -10)
    newMacroButton:SetText("+ New Macro")
    newMacroButton:SetScript("OnClick", function()
        MacroStudio:ShowNewMacroDialog()
    end)
    self.newMacroButton = newMacroButton

    local clearSearchButton = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    clearSearchButton:SetSize(22, 22)
    clearSearchButton:SetPoint("TOPRIGHT", -10, -42)
    clearSearchButton:Hide()
    self.clearSearchButton = clearSearchButton

    local searchBox = CreateFrame("EditBox", nil, panel, "InputBoxTemplate")
    searchBox:SetHeight(24)
    searchBox:SetPoint("TOPLEFT", 14, -42)
    searchBox:SetPoint("TOPRIGHT", clearSearchButton, "TOPLEFT", -4, 0)
    searchBox:SetMaxLetters(120)
    MacroStudio.Helpers:ConfigureEditBox(searchBox)
    self.searchBox = searchBox

    local searchPlaceholder = MacroStudio.Helpers:CreateLabel(searchBox, "GameFontDisableSmall", "Search macros...")
    searchPlaceholder:SetPoint("LEFT", 7, 0)
    searchPlaceholder:SetTextColor(0.48, 0.54, 0.62)
    self.searchPlaceholder = searchPlaceholder

    local function updateSearchPresentation()
        local empty = searchBox:GetText() == ""
        searchPlaceholder:SetShown(empty and not searchBox:HasFocus())
        clearSearchButton:SetShown(not empty)
    end

    searchBox:HookScript("OnTextChanged", function(box)
        updateSearchPresentation()
        MacroStudio:SetSearchQuery(box:GetText())
    end)
    searchBox:HookScript("OnEditFocusGained", function()
        updateSearchPresentation()
    end)
    searchBox:HookScript("OnEditFocusLost", function()
        updateSearchPresentation()
    end)
    searchBox:HookScript("OnEscapePressed", function(box)
        if box:GetText() ~= "" then
            self:ClearSearch(true)
        else
            box:ClearFocus()
        end
    end)
    searchBox:HookScript("OnEnterPressed", function(box)
        box:ClearFocus()
    end)
    clearSearchButton:SetScript("OnClick", function()
        self:ClearSearch(true)
    end)
    MacroStudio.Helpers:SetButtonTooltip(clearSearchButton, "Clear Search", "Keep the current navigation filter and show all of its macros.")
    updateSearchPresentation()

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -73)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 10)
    self.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild

    scrollFrame:SetScript("OnSizeChanged", function(frame)
        scrollChild:SetWidth(math.max(1, frame:GetWidth()))
        scrollChild:SetHeight(math.max(frame:GetHeight(), self.contentHeight or 1))
    end)

    return panel
end

function MacroList:ClearSearch(keepFocus)
    if not self.searchBox then
        return
    end

    if self.searchBox:GetText() ~= "" then
        self.searchBox:SetText("")
    else
        MacroStudio:SetSearchQuery("")
    end
    if keepFocus then
        self.searchBox:SetFocus()
    else
        self.searchBox:ClearFocus()
    end
end

function MacroList:SetNewMacroState(enabled, reason)
    MacroStudio.Helpers:SetButtonEnabled(self.newMacroButton, enabled)
    MacroStudio.Helpers:SetButtonTooltip(
        self.newMacroButton,
        "Create Native Macro",
        enabled and "Create an Account or Character macro." or reason
    )
end

function MacroList:AcquireHeader()
    local header = acquireFontString(self.headerPool, self.scrollChild, "GameFontNormalSmall")
    header:SetTextColor(0.45, 0.72, 1)
    header:SetJustifyH("LEFT")
    return header
end

function MacroList:AcquireEmptyLabel()
    local label = acquireFontString(self.emptyPool, self.scrollChild, "GameFontDisableSmall")
    label:SetJustifyH("LEFT")
    return label
end

function MacroList:AcquireRow()
    local button = self.rowPool[#self.rowPool]
    if button then
        self.rowPool[#self.rowPool] = nil
        button:Show()
        return button
    end

    button = CreateFrame("Button", nil, self.scrollChild, "BackdropTemplate")
    button:SetHeight(ROW_HEIGHT)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(34, 34)
    icon:SetPoint("LEFT", 7, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.icon = icon

    local favorite = button:CreateTexture(nil, "OVERLAY")
    favorite:SetSize(16, 16)
    favorite:SetPoint("TOPRIGHT", icon, "TOPRIGHT", 5, 5)
    favorite:SetAtlas("PetJournal-FavoritesIcon")
    favorite:Hide()
    button.favorite = favorite

    local nameText = MacroStudio.Helpers:CreateLabel(button, "GameFontNormal", "")
    nameText:SetPoint("TOPLEFT", icon, "TOPRIGHT", 8, -1)
    nameText:SetPoint("TOPRIGHT", button, "TOPRIGHT", -7, -8)
    nameText:SetJustifyH("LEFT")
    nameText:SetWordWrap(false)
    button.nameText = nameText

    local detailText = MacroStudio.Helpers:CreateLabel(button, "GameFontHighlightSmall", "")
    detailText:SetPoint("BOTTOMLEFT", icon, "BOTTOMRIGHT", 8, 1)
    detailText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -7, 8)
    detailText:SetJustifyH("LEFT")
    detailText:SetWordWrap(false)
    detailText:SetTextColor(0.58, 0.64, 0.72)
    button.detailText = detailText

    button:SetScript("OnEnter", function(row)
        if not row.selected then
            row:SetBackdropColor(0.1, 0.13, 0.18, 1)
        end
    end)
    button:SetScript("OnLeave", function(row)
        if not row.selected then
            row:SetBackdropColor(0.065, 0.08, 0.105, 1)
        end
    end)
    button:SetScript("OnClick", function(row)
        if row.macro then
            MacroStudio:RequestSelectMacro(row.macro)
        end
    end)

    return button
end

function MacroList:ReleaseVisibleItems()
    if self.visibleRows then
        for _, row in ipairs(self.visibleRows) do
            row:Hide()
            row.macro = nil
            self.rowPool[#self.rowPool + 1] = row
        end
    end
    if self.visibleHeaders then
        for _, header in ipairs(self.visibleHeaders) do
            header:Hide()
            self.headerPool[#self.headerPool + 1] = header
        end
    end
    if self.visibleEmptyLabels then
        for _, label in ipairs(self.visibleEmptyLabels) do
            label:Hide()
            self.emptyPool[#self.emptyPool + 1] = label
        end
    end

    self.visibleRows = {}
    self.visibleHeaders = {}
    self.visibleEmptyLabels = {}
end

function MacroList:AddEmptyMessage(message, yOffset)
    local empty = self:AcquireEmptyLabel()
    empty:ClearAllPoints()
    empty:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 12, -yOffset)
    empty:SetText(message)
    self.visibleEmptyLabels[#self.visibleEmptyLabels + 1] = empty
    return yOffset + EMPTY_HEIGHT
end

function MacroList:AddSection(title, macros, yOffset, showEmpty)
    if #macros == 0 and not showEmpty then
        return yOffset, false
    end

    local header = self:AcquireHeader()
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 6, -yOffset)
    header:SetText(title)
    self.visibleHeaders[#self.visibleHeaders + 1] = header
    yOffset = yOffset + HEADER_HEIGHT

    if #macros == 0 then
        return self:AddEmptyMessage("No macros in this scope", yOffset), true
    end

    for _, macro in ipairs(macros) do
        local row = self:AcquireRow()
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        row:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -yOffset)
        row.macro = macro
        row.icon:SetTexture(macro.icon or MacroStudio.DEFAULT_ICON)
        row.favorite:SetShown(MacroStudio.MetadataRepository:IsFavorite(macro))
        row.nameText:SetText(macro.name ~= "" and macro.name or "Unnamed Macro")

        local length = MacroStudio.Helpers:TextLength(macro.body)
        local preview = MacroStudio.Helpers:FirstLine(macro.body, 28)
        if preview == "" then
            preview = "Empty body"
        end
        if macro.duplicateName then
            preview = "Duplicate name - " .. preview
        end
        row.detailText:SetText(string.format("%d / %d  |  %s", length, MacroStudio.MAX_BODY_LENGTH, preview))
        self.visibleRows[#self.visibleRows + 1] = row
        yOffset = yOffset + ROW_HEIGHT + CONTENT_GAP
    end

    return yOffset, true
end

function MacroList:Rebuild(macros, selectedMacro, activeFilter, searchQuery)
    self:ReleaseVisibleItems()
    local visibleQuery = MacroStudio.Helpers:Trim(searchQuery or "")

    local accountMacros = {}
    local characterMacros = {}
    for _, macro in ipairs(macros or {}) do
        if macro.scope == "ACCOUNT" then
            accountMacros[#accountMacros + 1] = macro
        else
            characterMacros[#characterMacros + 1] = macro
        end
    end

    local filterKind = activeFilter and activeFilter.kind or "all"
    local showAccount = filterKind ~= "character"
    local showCharacter = filterKind ~= "account"
    local showEmptySections = visibleQuery == ""
        and (filterKind == "all" or filterKind == "account" or filterKind == "character")
    local yOffset = 2
    local addedSection = false

    if showAccount then
        local added
        yOffset, added = self:AddSection("ACCOUNT MACROS", accountMacros, yOffset, showEmptySections)
        addedSection = addedSection or added
    end
    if showCharacter then
        if addedSection then
            yOffset = yOffset + 8
        end
        local added
        yOffset, added = self:AddSection("CHARACTER MACROS", characterMacros, yOffset, showEmptySections)
        addedSection = addedSection or added
    end
    if not addedSection then
        local message
        if visibleQuery ~= "" then
            message = string.format('No macros match "%s".', visibleQuery)
        else
            message = "No macros match this filter."
        end
        yOffset = self:AddEmptyMessage(message, yOffset + 8)
    end

    self.contentHeight = yOffset + 4
    self.scrollChild:SetHeight(math.max(self.scrollFrame:GetHeight(), self.contentHeight))
    self:SetSelected(selectedMacro)
end

function MacroList:SetSelected(selectedMacro)
    for _, row in ipairs(self.visibleRows or {}) do
        local selected = MacroStudio.MacroRepository:SnapshotsEqual(row.macro, selectedMacro)
        row.selected = selected
        if selected then
            row:SetBackdropColor(0.12, 0.32, 0.5, 1)
        else
            row:SetBackdropColor(0.065, 0.08, 0.105, 1)
        end
    end
end
