local _, MacroStudio = ...

local Sidebar = {
    categoryPool = {},
    visibleCategoryButtons = {},
    characterPool = {},
    visibleCharacterButtons = {},
}
MacroStudio.Sidebar = Sidebar

local BUTTON_HEIGHT = MacroStudio.Theme.spacing.navigation
local DEFAULT_EXPANDED_CHARACTER_LIMIT = 5
local COLLAPSED_CHARACTER_ICON = "Interface\\Buttons\\UI-PlusButton-UP"
local EXPANDED_CHARACTER_ICON = "Interface\\Buttons\\UI-MinusButton-UP"

local function createFilterButton(parent, label, onClick, atlas)
    local button = MacroStudio.Theme:CreateRowFrame(parent)
    button:SetHeight(BUTTON_HEIGHT)
    MacroStudio.Theme:Row(button)

    local icon
    if atlas then
        icon = button:CreateTexture(nil, "ARTWORK")
        icon:SetSize(16, 16)
        icon:SetPoint("LEFT", 7, 0)
        icon:SetAtlas(atlas)
        button.Icon = icon
    end

    local text = MacroStudio.Helpers:CreateLabel(button, "GameFontNormal", label)
    text:SetPoint("LEFT", icon or button, icon and "RIGHT" or "LEFT", icon and 5 or 8, 0)
    text:SetPoint("RIGHT", -6, 0)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    button.Text = text
    MacroStudio.Theme:RowState(button)

    button:SetScript("OnEnter", function(row)
        if not row.selected then
            MacroStudio.Theme:RowState(row, true)
        end
    end)
    button:SetScript("OnLeave", function(row)
        if not row.selected then
            MacroStudio.Theme:RowState(row)
        end
    end)
    button:SetScript("OnClick", onClick)
    return button
end

function Sidebar:Create(parent)
    BUTTON_HEIGHT = MacroStudio.Theme.spacing.navigation
    local panel = MacroStudio.Helpers:CreateRegion(parent)
    self.panel = panel

    local heading = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormal", "LIBRARY")
    heading:SetPoint("TOPLEFT", 10, -10)
    MacroStudio.Theme:Section(panel, heading)

    local navigation = {
        { kind = "favorites", text = "Favorites", atlas = "PetJournal-FavoritesIcon" },
        { kind = "all", text = "All Macros" },
        { kind = "account", text = "Account Macros" },
        { kind = "character", text = "Current Character" },
    }
    self.navigationButtons = {}
    local previous
    for _, definition in ipairs(navigation) do
        local filterKind = definition.kind
        local button = createFilterButton(panel, definition.text, function()
            MacroStudio:SetFilter(filterKind)
        end, definition.atlas)
        button.filterKind = filterKind
        button:SetPoint("LEFT", 10, 0)
        button:SetPoint("RIGHT", -10, 0)
        if previous then
            button:SetPoint("TOP", previous, "BOTTOM", 0, -1)
        else
            button:SetPoint("TOP", panel, "TOP", 0, -34)
        end
        self.navigationButtons[#self.navigationButtons + 1] = button
        previous = button
    end

    local scrollFrame = MacroStudio.Helpers:CreateScrollFrame(panel)
    scrollFrame:SetPoint("TOPLEFT", 10, -143)
    scrollFrame:SetPoint("BOTTOMRIGHT", -28, 76)
    self.scrollFrame = scrollFrame

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1)
    scrollFrame:SetScrollChild(scrollChild)
    self.scrollChild = scrollChild
    scrollFrame:SetScript("OnSizeChanged", function(frame)
        scrollChild:SetWidth(math.max(1, frame:GetWidth()))
        scrollChild:SetHeight(math.max(frame:GetHeight(), self.contentHeight or 1))
    end)
    local libraryHeading = MacroStudio.Helpers:CreateLabel(scrollChild, "GameFontNormalSmall", "CHARACTERS")
    libraryHeading:SetTextColor(unpack(MacroStudio.Theme.palette.gold))
    self.libraryHeading = libraryHeading

    local allCharactersButton = createFilterButton(scrollChild, "All Characters", function()
        MacroStudio:SetFilter("characters")
    end)
    self.allCharactersButton = allCharactersButton

    local characterToggleButton = createFilterButton(scrollChild, "Characters", function()
        self:ToggleCharacterList()
    end)
    local characterToggleIcon = characterToggleButton:CreateTexture(nil, "ARTWORK")
    characterToggleIcon:SetSize(16, 16)
    characterToggleIcon:SetPoint("LEFT", 6, 0)
    characterToggleIcon:SetTexture(COLLAPSED_CHARACTER_ICON)
    characterToggleButton.Text:ClearAllPoints()
    characterToggleButton.Text:SetPoint("LEFT", characterToggleIcon, "RIGHT", 5, 0)
    characterToggleButton.Text:SetPoint("RIGHT", -6, 0)
    self.characterToggleButton = characterToggleButton
    self.characterToggleIcon = characterToggleIcon

    local categoriesHeading = MacroStudio.Helpers:CreateLabel(scrollChild, "GameFontNormalSmall", "CATEGORIES")
    categoriesHeading:SetTextColor(unpack(MacroStudio.Theme.palette.gold))
    self.categoriesHeading = categoriesHeading


    local newButton = MacroStudio.Helpers:CreateButton(panel)
    newButton:SetHeight(23)
    newButton:SetPoint("BOTTOMLEFT", 10, 43)
    newButton:SetPoint("BOTTOMRIGHT", -10, 43)
    newButton:SetText("+ New Category")
    newButton:SetScript("OnClick", function()
        MacroStudio:PromptCreateCategory()
    end)
    self.newButton = newButton

    local renameButton = MacroStudio.Helpers:CreateButton(panel)
    renameButton:SetHeight(22)
    renameButton:SetPoint("BOTTOMLEFT", 10, 14)
    renameButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOM", -3, 14)
    renameButton:SetText("Rename")
    renameButton:SetScript("OnClick", function()
        MacroStudio:PromptRenameCategory()
    end)
    self.renameButton = renameButton

    local deleteButton = MacroStudio.Helpers:CreateButton(panel)
    deleteButton:SetHeight(22)
    deleteButton:SetPoint("BOTTOMLEFT", panel, "BOTTOM", 3, 14)
    deleteButton:SetPoint("BOTTOMRIGHT", -10, 14)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        if self.deleteMode == "character" then
            MacroStudio:PromptForgetActiveCharacter()
        elseif self.deleteMode == "category" then
            MacroStudio:PromptDeleteCategory()
        end
    end)
    self.deleteButton = deleteButton

    return panel
end

function Sidebar:AcquireCategoryButton()
    local button = self.categoryPool[#self.categoryPool]
    if button then
        self.categoryPool[#self.categoryPool] = nil
        button:Show()
        return button
    end

    return createFilterButton(self.scrollChild, "", function(row)
        if row.categoryId then
            MacroStudio:SetFilter("category", row.categoryId)
        end
    end)
end
function Sidebar:AcquireCharacterButton()
    local button = self.characterPool[#self.characterPool]
    if button then
        self.characterPool[#self.characterPool] = nil
        button:Show()
        return button
    end

    return createFilterButton(self.scrollChild, "", function(row)
        if row.characterId then
            MacroStudio:SetFilter("libraryCharacter", row.characterId)
        end
    end)
end

function Sidebar:GetCharacterListExpanded(characterCount)
    local settings = MacroStudio.db and MacroStudio.db.settings
    if not settings then
        return false
    end

    local expanded = settings.characterLibraryExpanded
    if type(expanded) ~= "boolean" then
        expanded = (tonumber(characterCount) or 0) <= DEFAULT_EXPANDED_CHARACTER_LIMIT
        settings.characterLibraryExpanded = expanded
    end

    return expanded
end

function Sidebar:ToggleCharacterList()
    local settings = MacroStudio.db and MacroStudio.db.settings
    if not settings then
        return
    end

    local characterCount = #MacroStudio.CharacterMacroLibrary:GetCharacters()
    settings.characterLibraryExpanded = not self:GetCharacterListExpanded(characterCount)
    self:Rebuild(MacroStudio.activeFilter)
end

function Sidebar:Rebuild(activeFilter)
    for _, button in ipairs(self.visibleCategoryButtons) do
        button:Hide()
        button.categoryId = nil
        self.categoryPool[#self.categoryPool + 1] = button
    end
    self.visibleCategoryButtons = {}

    for _, button in ipairs(self.visibleCharacterButtons) do
        button:Hide()
        button.characterId = nil
        self.characterPool[#self.characterPool + 1] = button
    end
    self.visibleCharacterButtons = {}

    local yOffset = 0
    self.categoriesHeading:ClearAllPoints()
    self.categoriesHeading:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 4, -yOffset)
    yOffset = yOffset + 20

    local categories = MacroStudio.MetadataRepository:GetCategories()
    for _, category in ipairs(categories) do
        local button = self:AcquireCategoryButton()
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
        button:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -yOffset)
        button.categoryId = category.id
        button.Text:SetText(category.name)
        button.selected = activeFilter
            and activeFilter.kind == "category"
            and activeFilter.categoryId == category.id
        MacroStudio.Theme:RowState(button)
        self.visibleCategoryButtons[#self.visibleCategoryButtons + 1] = button
        yOffset = yOffset + BUTTON_HEIGHT + 3
    end

    if #categories == 0 then
        if not self.emptyText then
            self.emptyText = MacroStudio.Helpers:CreateLabel(self.scrollChild, "GameFontDisableSmall", "No categories yet")
            self.emptyText:SetJustifyH("LEFT")
            self.emptyText:SetWordWrap(true)
        end
        self.emptyText:ClearAllPoints()
        self.emptyText:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 5, -yOffset - 4)
        self.emptyText:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", -5, -yOffset - 4)
        self.emptyText:Show()
        yOffset = yOffset + math.max(24, math.ceil(self.emptyText:GetStringHeight() or 0) + 8)
    elseif self.emptyText then
        self.emptyText:Hide()
    end

    yOffset = yOffset + 9
    self.libraryHeading:ClearAllPoints()
    self.libraryHeading:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 4, -yOffset)
    yOffset = yOffset + 20

    self.allCharactersButton:ClearAllPoints()
    self.allCharactersButton:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
    self.allCharactersButton:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -yOffset)
    self.allCharactersButton.selected = activeFilter and activeFilter.kind == "characters"
    MacroStudio.Theme:RowState(self.allCharactersButton)
    yOffset = yOffset + BUTTON_HEIGHT + 3

    local characters = MacroStudio.CharacterMacroLibrary:GetCharacters()
    self.charactersExpanded = self:GetCharacterListExpanded(#characters)

    self.characterToggleButton:ClearAllPoints()
    self.characterToggleButton:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
    self.characterToggleButton:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -yOffset)
    self.characterToggleButton.Text:SetText("Characters")
    self.characterToggleIcon:SetTexture(
        self.charactersExpanded and EXPANDED_CHARACTER_ICON or COLLAPSED_CHARACTER_ICON
    )
    self.characterToggleButton.selected = false
    MacroStudio.Theme:RowState(self.characterToggleButton)
    yOffset = yOffset + BUTTON_HEIGHT + 3

    if self.charactersExpanded then
        for _, character in ipairs(characters) do
            local button = self:AcquireCharacterButton()
            button:ClearAllPoints()
            button:SetPoint("TOPLEFT", self.scrollChild, "TOPLEFT", 0, -yOffset)
            button:SetPoint("TOPRIGHT", self.scrollChild, "TOPRIGHT", 0, -yOffset)
            button.characterId = character.id
            button.Text:SetText(character.displayName .. (character.isCurrent and "  Current" or ""))
            button.selected = activeFilter
                and activeFilter.kind == "libraryCharacter"
                and activeFilter.characterId == character.id
            MacroStudio.Theme:RowState(button)
            local detail = character.isCurrent
                and "Current character - live native macros."
                or ("Read-only snapshot. Last synced: "
                    .. MacroStudio.CharacterMacroLibrary:FormatLastSynced(character.lastSynced))
            MacroStudio.Helpers:SetButtonTooltip(button, character.displayName, detail)
            self.visibleCharacterButtons[#self.visibleCharacterButtons + 1] = button
            yOffset = yOffset + BUTTON_HEIGHT + 3
        end
    end

    self.contentHeight = math.max(1, yOffset)
    self.scrollChild:SetHeight(math.max(self.scrollFrame:GetHeight(), self.contentHeight))

    for _, button in ipairs(self.navigationButtons) do
        button.selected = activeFilter and activeFilter.kind == button.filterKind
        MacroStudio.Theme:RowState(button)
    end

    local categorySelected = activeFilter
        and activeFilter.kind == "category"
        and MacroStudio.MetadataRepository:GetCategory(activeFilter.categoryId) ~= nil
    local libraryCharacter = activeFilter
        and activeFilter.kind == "libraryCharacter"
        and MacroStudio.CharacterMacroLibrary:GetCharacter(activeFilter.characterId) or nil
    local canForgetCharacter = libraryCharacter
        and not MacroStudio.CharacterMacroLibrary:IsCurrentCharacter(libraryCharacter.id)

    MacroStudio.Helpers:SetButtonEnabled(self.renameButton, categorySelected)
    if categorySelected then
        self.deleteMode = "category"
        self.deleteButton:SetText("Delete")
        MacroStudio.Helpers:SetButtonEnabled(self.deleteButton, true)
        MacroStudio.Helpers:SetButtonTooltip(self.deleteButton, "Delete Category", "Delete this virtual category only.")
    elseif libraryCharacter then
        self.deleteMode = "character"
        self.deleteButton:SetText("Forget")
        MacroStudio.Helpers:SetButtonEnabled(self.deleteButton, canForgetCharacter)
        MacroStudio.Helpers:SetButtonTooltip(
            self.deleteButton,
            "Forget Character",
            canForgetCharacter
                and "Remove only this offline MacroStudio snapshot."
                or "The current character cannot be forgotten."
        )
    else
        self.deleteMode = nil
        self.deleteButton:SetText("Delete")
        MacroStudio.Helpers:SetButtonEnabled(self.deleteButton, false)
        MacroStudio.Helpers:SetButtonTooltip(self.deleteButton)
    end
end
