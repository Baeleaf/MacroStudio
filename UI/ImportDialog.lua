local _, MacroStudio = ...

local ImportDialog = {
    MAX_DISPLAY_BYTES = 4 * 1024 * 1024,
}
MacroStudio.ImportDialog = ImportDialog

local function conciseError(value)
    local message = tostring(value or "unknown error")
    message = message:gsub("[\r\n]+", " "):gsub("%s+", " ")
    if #message > 420 then message = message:sub(1, 417) .. "..." end
    return message
end

local function offlineMacroCount(model)
    local count = 0
    for _, character in ipairs(model.offlineCharacters or {}) do
        count = count + #(character.macros or {})
    end
    return count
end

local function previewText(plan)
    local model = plan.model
    local sourceFavorites = 0
    for _, association in ipairs(model.organization.associations) do
        if association.favorite then sourceFavorites = sourceFavorites + 1 end
    end
    local lines = {
        "IMPORT PREVIEW",
        "",
        string.format("Portable format: %d    Source MacroStudio: %s", model.formatVersion, model.addonVersion),
        string.format(
            "Export contents: %d Account macros, %d source-character macros, %d offline characters (%d snapshots)",
            #model.accountMacros, #model.currentCharacter.macros, #model.offlineCharacters, offlineMacroCount(model)
        ),
        string.format(
            "Export organization: %d categories, %d tags, %d associations, %d Favorites",
            #model.organization.categories, #model.organization.tags, #model.organization.associations, sourceFavorites),
        "",
        "ACCOUNT MACROS",
        string.format("Create: %d    Already present: %d    Ambiguous/skip: %d",
            plan.account.create, plan.account.present, plan.account.ambiguous),
        string.format("Capacity: %d required, %d available", plan.account.create, plan.accountAvailable),
        "",
        "CURRENT-CHARACTER MACROS",
        "Destination: " .. plan.currentCharacter,
        string.format("Create: %d    Already present: %d    Ambiguous/skip: %d    Disabled: %d",
            plan.character.create, plan.character.present, plan.character.ambiguous, plan.character.disabled),
        string.format("Capacity: %d required, %d available", plan.character.create, plan.characterAvailable),
        "",
        "OFFLINE LIBRARY",
        string.format("New snapshots: %d    Updates: %d    Existing/preserved: %d",
            plan.offline.added, plan.offline.updated, plan.offline.kept),
        "",
        "ORGANIZATION",
        string.format("Categories to add: %d    Tags to add: %d    Favorites to restore: %d",
            plan.categoriesAdded, plan.tagsAdded, plan.favoritesRestored),
        string.format("Metadata associations: %d    Category conflicts preserving destination: %d",
            #plan.associations, plan.categoryConflicts),
        "",
        "SAFETY",
        "Existing native macros will not be overwritten or deleted. Same-name macros with different content remain separate.",
        "Metadata is attached only after a unique exact native identity is confirmed.",
    }
    if #plan.warnings > 0 then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "WARNINGS"
        for _, warning in ipairs(plan.warnings) do lines[#lines + 1] = "- " .. warning end
    end
    return table.concat(lines, "\n")
end

local function resultText(success, result)
    local lines = {
        success and "IMPORT COMPLETE" or "IMPORT STOPPED",
        "",
        string.format("Account macros created: %d", result.accountCreated or 0),
        string.format("Account macros already present: %d", result.accountPresent or 0),
        string.format("Character macros created: %d", result.characterCreated or 0),
        string.format("Character macros already present: %d", result.characterPresent or 0),
        string.format("Offline characters added: %d", result.offlineAdded or 0),
        string.format("Offline snapshots updated: %d", result.offlineUpdated or 0),
        string.format("Offline snapshots preserved: %d", result.offlineKept or 0),
        string.format("Categories added: %d", result.categoriesAdded or 0),
        string.format("Tags added: %d", result.tagsAdded or 0),
        string.format("Favorites restored: %d", result.favoritesRestored or 0),
        string.format("Skipped/ambiguous native records: %d", result.ambiguousSkipped or 0),
        string.format("Metadata mappings skipped as ambiguous: %d", result.metadataSkipped or 0),
        string.format("Destination category conflicts preserved: %d", result.metadataConflicts or 0),
    }
    if result.message then
        lines[#lines + 1] = ""
        lines[#lines + 1] = result.message
    elseif success then
        lines[#lines + 1] = ""
        lines[#lines + 1] = "No existing native macros were overwritten or deleted."
    end
    return table.concat(lines, "\n")
end

function ImportDialog:SetStage(stage)
    self.stage = stage
    MacroStudio:Debug("Import stage", stage)
end

function ImportDialog:GetStage()
    return self.stage
end

function ImportDialog:SetStatus(message, isError)
    self.statusText:SetText(message or "")
    if isError then self.statusText:SetTextColor(1, 0.35, 0.3)
    else self.statusText:SetTextColor(0.68, 0.75, 0.86) end
end

function ImportDialog:SetOutput(text)
    self.outputText = text or ""
    self.settingOutput = true
    self.outputEditBox:SetText(self.outputText)
    self.settingOutput = false
    self.outputEditBox:SetCursorPosition(0)
    MacroStudio.Helpers:ResetNativeScrollingEditBox(self.outputScrollBox)
end

function ImportDialog:SetMode(mode)
    self.mode = mode
    local paste = mode == "paste"
    local preview = mode == "preview"
    local result = mode == "result"
    self.inputPanel:SetShown(paste)
    self.characterCheckbox:SetShown(paste)
    self.characterLabel:SetShown(paste)
    self.outputPanel:SetShown(preview or result)
    self.validateButton:SetShown(paste)
    self.applyButton:SetShown(preview)
    self.backButton:SetShown(preview or result)
    self.closeButton:SetShown(paste or result)
    self.backButton:SetText(result and "Import Another" or "Back")
    self.closeButton:SetText(result and "Done" or "Cancel")
    self.heading:SetText(result and "Import Results" or (preview and "Import Preview" or "Paste Portable Export"))
end

function ImportDialog:Create()
    if self.frame then return self.frame end
    self:SetStage("creating import window")
    local frame = MacroStudio.Helpers:CreatePanel(UIParent)
    frame:SetSize(780, 610)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetPoint("TOPLEFT", 1, -1)
    titleBar:SetPoint("TOPRIGHT", -1, -1)
    titleBar:SetHeight(42)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function() frame:StartMoving() end)
    titleBar:SetScript("OnDragStop", function() frame:StopMovingOrSizing() end)

    local title = MacroStudio.Helpers:CreateLabel(titleBar, "GameFontNormalLarge", "Import MacroStudio Library")
    title:SetPoint("LEFT", 17, 0)

    local windowClose = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    windowClose:SetPoint("TOPRIGHT", -3, -3)

    local explanation = MacroStudio.Helpers:CreateLabel(
        frame, "GameFontHighlightSmall",
        "Paste portable JSON created by MacroStudio Export. Validation and Preview are read-only; native macros change only after Apply Import and confirmation."
    )
    explanation:SetPoint("TOPLEFT", 18, -50)
    explanation:SetPoint("TOPRIGHT", -18, -50)
    explanation:SetHeight(34)
    explanation:SetJustifyH("LEFT")
    explanation:SetJustifyV("TOP")
    explanation:SetWordWrap(true)

    local heading = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Paste Portable Export")
    heading:SetPoint("TOPLEFT", explanation, "BOTTOMLEFT", 0, -8)
    heading:SetTextColor(0.35, 0.75, 1)
    self.heading = heading

    local inputPanel = MacroStudio.Helpers:CreatePanel(frame)
    inputPanel:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    inputPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 122)
    self.inputPanel = inputPanel

    local _, inputEditBox, inputScrollBox = MacroStudio.Helpers:CreateNativeScrollingEditBox(inputPanel, 6)
    inputEditBox:SetFontObject(ChatFontNormal)
    inputEditBox:SetTextColor(0.86, 0.9, 0.96)
    inputEditBox:SetAutoFocus(false)
    inputEditBox:SetMaxLetters(0)
    inputEditBox:SetScript("OnEscapePressed", function() frame:Hide() end)
    inputEditBox:HookScript("OnTextChanged", function(_, userInput)
        if userInput then
            self.plan = nil
            MacroStudio.PortableImport:SetActivePlan(nil)
            self:SetStatus("", false)
        end
    end)
    self.inputEditBox = inputEditBox
    self.inputScrollBox = inputScrollBox

    local outputPanel = MacroStudio.Helpers:CreatePanel(frame)
    outputPanel:SetPoint("TOPLEFT", heading, "BOTTOMLEFT", 0, -8)
    outputPanel:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -18, 52)
    self.outputPanel = outputPanel

    local _, outputEditBox, outputScrollBox = MacroStudio.Helpers:CreateNativeScrollingEditBox(outputPanel, 6)
    outputEditBox:SetFontObject(ChatFontNormal)
    outputEditBox:SetTextColor(0.82, 0.87, 0.94)
    outputEditBox:SetAutoFocus(false)
    outputEditBox:SetMaxLetters(0)
    outputEditBox:HookScript("OnTextChanged", function(owner, userInput)
        if self.settingOutput or not userInput then return end
        self.settingOutput = true
        owner:SetText(self.outputText or "")
        self.settingOutput = false
        owner:ClearFocus()
    end)
    self.outputEditBox = outputEditBox
    self.outputScrollBox = outputScrollBox

    local characterCheckbox = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
    characterCheckbox:SetSize(24, 24)
    characterCheckbox:SetPoint("BOTTOMLEFT", 18, 81)
    characterCheckbox:SetChecked(true)
    self.characterCheckbox = characterCheckbox

    local characterLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    characterLabel:SetPoint("LEFT", characterCheckbox, "RIGHT", 5, 0)
    characterLabel:SetPoint("RIGHT", frame, "RIGHT", -18, 0)
    characterLabel:SetJustifyH("LEFT")
    self.characterLabel = characterLabel

    local status = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    status:SetPoint("BOTTOMLEFT", 18, 47)
    status:SetPoint("BOTTOMRIGHT", -18, 47)
    status:SetHeight(28)
    status:SetJustifyH("LEFT")
    status:SetJustifyV("TOP")
    status:SetWordWrap(true)
    self.statusText = status

    local validate = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    validate:SetSize(150, 26)
    validate:SetPoint("BOTTOMLEFT", 18, 16)
    validate:SetText("Validate & Preview")
    validate:SetScript("OnClick", function() self:ValidateAndPreview() end)
    self.validateButton = validate

    local back = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    back:SetSize(110, 26)
    back:SetPoint("BOTTOMLEFT", 18, 16)
    back:SetScript("OnClick", function() self:BackToPaste() end)
    self.backButton = back

    local apply = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    apply:SetSize(120, 26)
    apply:SetPoint("BOTTOMRIGHT", -116, 16)
    apply:SetText("Apply Import")
    apply:SetScript("OnClick", function() self:RequestApply() end)
    self.applyButton = apply

    local close = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    close:SetSize(90, 26)
    close:SetPoint("BOTTOMRIGHT", -18, 16)
    close:SetScript("OnClick", function() frame:Hide() end)
    self.closeButton = close

    frame:SetScript("OnHide", function()
        inputEditBox:ClearFocus()
        outputEditBox:ClearFocus()
        self.plan = nil
        MacroStudio.PortableImport:SetActivePlan(nil)
        MacroStudio:SetMainWindowModalBlocked(false)
    end)
    self:SetMode("paste")
    self:SetStatus("", false)
    self:SetStage(nil)
    return frame
end

function ImportDialog:RefreshDestination()
    local current = MacroStudio.CharacterMacroLibrary:GetCurrentCharacter()
    local destination = current and ((current.name or "Unknown Character") .. " - " .. (current.realm or "Unknown Realm"))
        or "Current Character"
    self.characterLabel:SetText("Import source Character macros to this character: " .. destination)
end

function ImportDialog:BackToPaste()
    self.plan = nil
    MacroStudio.PortableImport:SetActivePlan(nil)
    self:SetStatus("", false)
    self:SetMode("paste")
    self.inputEditBox:SetFocus()
end

function ImportDialog:ValidateAndPreview()
    self:SetStage("validating pasted JSON")
    local ok, plan = xpcall(function()
        return MacroStudio.PortableImport:Preview(self.inputEditBox:GetText() or "", {
            importCharacterMacros = self.characterCheckbox:GetChecked() == true,
        })
    end, conciseError)
    if not ok then
        self.plan = nil
        MacroStudio.PortableImport:SetActivePlan(nil)
        self:SetStatus(plan, true)
        self:SetStage(nil)
        return false
    end
    self.plan = plan
    MacroStudio.PortableImport:SetActivePlan(plan)
    self:SetOutput(previewText(plan))
    self:SetMode("preview")
    MacroStudio.Helpers:SetButtonEnabled(self.applyButton, plan.capacityOK)
    if plan.capacityOK then
        self:SetStatus("Preview complete. Confirm Apply Import to begin native writes.", false)
    else
        self:SetStatus(table.concat(plan.warnings, " "), true)
    end
    self:SetStage(nil)
    return true
end

function ImportDialog:RequestApply()
    if not self.plan or not self.plan.capacityOK then return false end
    return MacroStudio.Dialogs:ShowConfirmImport(self.plan, function() self:ApplyConfirmed() end)
end

function ImportDialog:ApplyConfirmed()
    local values
    self:SetStage("revalidating and applying import")
    local ok, failure = xpcall(function()
        values = { MacroStudio.PortableImport:Apply(self.plan) }
    end, conciseError)
    if not ok then
        self:SetStatus("Import stopped safely: " .. failure, true)
        self:SetStage(nil)
        return false
    end
    local success, result, message = unpack(values)
    if result then
        self:SetOutput(resultText(success, result))
        self:SetMode("result")
        self:SetStatus(success and "Import finished." or "Import stopped; review the result before retrying.", not success)
    else
        self:SetStatus(message or "Import could not be applied. Run Validate & Preview again if repository state changed.", true)
    end
    self:SetStage(nil)
    return success
end

function ImportDialog:Open(source)
    MacroStudio:Debug("import open invoked", source or "unknown")
    if not MacroStudio.initialized then MacroStudio:Initialize() end
    local frame = self:Create()
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    local settingsShown = settingsFrame and settingsFrame:IsShown() or false
    if MacroStudio:IsMainWindowModalBlocked() and not frame:IsShown() and not settingsShown then
        MacroStudio:Print("Close the current dialog before opening Import.")
        return false
    end
    if not frame:IsShown() then
        self.inputEditBox:SetText("")
        self.characterCheckbox:SetChecked(true)
        self:RefreshDestination()
        self:SetStatus("", false)
        self:SetMode("paste")
        frame:Show()
    end
    frame:Raise()
    if settingsShown then settingsFrame:Hide() end
    MacroStudio:SetMainWindowModalBlocked(true)
    self.inputEditBox:SetFocus()
    return true
end

function ImportDialog:HandleFailure()
    if self.frame then self.frame:Hide() end
    self.plan = nil
    MacroStudio.PortableImport:SetActivePlan(nil)
    local settingsFrame = MacroStudio.Settings and MacroStudio.Settings.frame
    MacroStudio:SetMainWindowModalBlocked(settingsFrame and settingsFrame:IsShown() or false)
end
