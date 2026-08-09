local _, MacroStudio = ...

local Sidebar = {
    categoryPool = {},
    visibleCategoryButtons = {},
}
MacroStudio.Sidebar = Sidebar

local BUTTON_HEIGHT = 25

local function createFilterButton(parent, label, onClick, atlas)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetHeight(BUTTON_HEIGHT)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    button:SetBackdropColor(0.065, 0.08, 0.105, 1)

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
    button:SetScript("OnClick", onClick)
    return button
end

function Sidebar:Create(parent)
    local panel = MacroStudio.Helpers:CreatePanel(parent)
    self.panel = panel

    local heading = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalLarge", "NAVIGATION")
    heading:SetPoint("TOPLEFT", 14, -14)

    local navigation = {
        { kind = "favorites", text = "Favorites", atlas = "PetJournal-FavoritesIcon" },
        { kind = "all", text = "All Macros" },
        { kind = "account", text = "Account Macros" },
        { kind = "character", text = "Character Macros" },
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
            button:SetPoint("TOP", previous, "BOTTOM", 0, -3)
        else
            button:SetPoint("TOP", panel, "TOP", 0, -42)
        end
        self.navigationButtons[#self.navigationButtons + 1] = button
        previous = button
    end

    local categoryHeading = MacroStudio.Helpers:CreateLabel(panel, "GameFontNormalSmall", "CATEGORIES")
    categoryHeading:SetPoint("TOPLEFT", 14, -164)
    categoryHeading:SetTextColor(0.45, 0.72, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -184)
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

    local newButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    newButton:SetHeight(23)
    newButton:SetPoint("BOTTOMLEFT", 10, 43)
    newButton:SetPoint("BOTTOMRIGHT", -10, 43)
    newButton:SetText("+ New Category")
    newButton:SetScript("OnClick", function()
        MacroStudio:PromptCreateCategory()
    end)

    local renameButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    renameButton:SetHeight(22)
    renameButton:SetPoint("BOTTOMLEFT", 10, 14)
    renameButton:SetPoint("BOTTOMRIGHT", panel, "BOTTOM", -3, 14)
    renameButton:SetText("Rename")
    renameButton:SetScript("OnClick", function()
        MacroStudio:PromptRenameCategory()
    end)
    self.renameButton = renameButton

    local deleteButton = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    deleteButton:SetHeight(22)
    deleteButton:SetPoint("BOTTOMLEFT", panel, "BOTTOM", 3, 14)
    deleteButton:SetPoint("BOTTOMRIGHT", -10, 14)
    deleteButton:SetText("Delete")
    deleteButton:SetScript("OnClick", function()
        MacroStudio:PromptDeleteCategory()
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

function Sidebar:Rebuild(activeFilter)
    for _, button in ipairs(self.visibleCategoryButtons) do
        button:Hide()
        button.categoryId = nil
        self.categoryPool[#self.categoryPool + 1] = button
    end
    self.visibleCategoryButtons = {}

    local yOffset = 0
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
        button:SetBackdropColor(button.selected and 0.12 or 0.065, button.selected and 0.32 or 0.08, button.selected and 0.5 or 0.105, 1)
        self.visibleCategoryButtons[#self.visibleCategoryButtons + 1] = button
        yOffset = yOffset + BUTTON_HEIGHT + 3
    end

    if #categories == 0 then
        if not self.emptyText then
            self.emptyText = MacroStudio.Helpers:CreateLabel(self.scrollChild, "GameFontDisableSmall", "No categories yet")
            self.emptyText:SetPoint("TOPLEFT", 5, -5)
        end
        self.emptyText:Show()
    elseif self.emptyText then
        self.emptyText:Hide()
    end

    self.contentHeight = math.max(1, yOffset)
    self.scrollChild:SetHeight(math.max(self.scrollFrame:GetHeight(), self.contentHeight))

    for _, button in ipairs(self.navigationButtons) do
        button.selected = activeFilter and activeFilter.kind == button.filterKind
        button:SetBackdropColor(button.selected and 0.12 or 0.065, button.selected and 0.32 or 0.08, button.selected and 0.5 or 0.105, 1)
    end

    local categorySelected = activeFilter
        and activeFilter.kind == "category"
        and MacroStudio.MetadataRepository:GetCategory(activeFilter.categoryId) ~= nil
    MacroStudio.Helpers:SetButtonEnabled(self.renameButton, categorySelected)
    MacroStudio.Helpers:SetButtonEnabled(self.deleteButton, categorySelected)
end
