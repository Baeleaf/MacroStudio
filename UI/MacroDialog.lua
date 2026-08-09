local _, MacroStudio = ...

local MacroDialog = {
    scope = "ACCOUNT",
    selectedIcon = nil,
}
MacroStudio.MacroDialog = MacroDialog

local NORMAL_COLOR = { 0.82, 0.86, 0.92 }
local WARNING_COLOR = { 1, 0.68, 0.2 }
local ERROR_COLOR = { 1, 0.3, 0.3 }

function MacroDialog:SetScope(scope)
    self.scope = scope == "CHARACTER" and "CHARACTER" or "ACCOUNT"
    self.accountButton:SetText(self.scope == "ACCOUNT" and "Account (selected)" or "Account")
    self.characterButton:SetText(self.scope == "CHARACTER" and "Character (selected)" or "Character")
    self:UpdateState()
end

function MacroDialog:SetIcon(icon)
    self.selectedIcon = icon or MacroStudio.DEFAULT_ICON
    self.iconTexture:SetTexture(self.selectedIcon)
    self:UpdateState()
end

function MacroDialog:GetRequest()
    return {
        name = self.nameBox:GetText() or "",
        body = self.bodyBox:GetText() or "",
        icon = self.selectedIcon or MacroStudio.DEFAULT_ICON,
        scope = self.scope,
    }
end

function MacroDialog:ShowError(message)
    self.errorText:SetText(message or "The macro could not be created.")
    self.errorText:SetTextColor(unpack(ERROR_COLOR))
end

function MacroDialog:ValidateRequest(request)
    local valid, message = MacroStudio.MacroRepository:ValidateCreateRequest(request or self:GetRequest())
    if valid and MacroStudio.Editor and MacroStudio.Editor:IsDirty() then
        return false, "Save or Revert editor changes before creating and selecting a new macro."
    end
    return valid, message
end

function MacroDialog:UpdateState()
    if not self.frame then
        return
    end

    local request = self:GetRequest()
    local valid, message = self:ValidateRequest(request)
    local length = MacroStudio.Helpers:TextLength(request.body)
    self.countText:SetText(string.format("%d / %d", length, MacroStudio.MAX_BODY_LENGTH))
    self.countText:SetTextColor(unpack(length > MacroStudio.MAX_BODY_LENGTH and ERROR_COLOR or NORMAL_COLOR))

    local count, capacity = MacroStudio.MacroRepository:GetCapacity(request.scope)
    self.capacityText:SetText(string.format(
        "%s slots: %d / %d",
        request.scope == "ACCOUNT" and "Account" or "Character",
        count,
        capacity
    ))
    self.capacityText:SetTextColor(unpack(count >= capacity and WARNING_COLOR or NORMAL_COLOR))

    MacroStudio.Helpers:SetButtonEnabled(self.createButton, valid)
    MacroStudio.Helpers:SetButtonTooltip(
        self.createButton,
        "Create Macro",
        valid and "Create this Blizzard-native macro." or message
    )

    if valid then
        self.errorText:SetText("Ready to create. Enter in the body field inserts a new line.")
        self.errorText:SetTextColor(unpack(NORMAL_COLOR))
    else
        self:ShowError(message)
    end
end

function MacroDialog:Submit()
    local valid, message = self:ValidateRequest(self:GetRequest())
    if not valid then
        self:ShowError(message)
        return
    end

    local created, result = MacroStudio:CreateNativeMacro(self:GetRequest())
    if not created then
        self:UpdateState()
        self:ShowError(result)
        return
    end

    self.frame:Hide()
end

function MacroDialog:Create()
    if self.frame then
        return self.frame
    end

    local frame = MacroStudio.Helpers:CreatePanel(UIParent)
    frame:SetSize(570, 555)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local title = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalLarge", "Create New Native Macro")
    title:SetPoint("TOPLEFT", 16, -15)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local nameLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Name")
    nameLabel:SetPoint("TOPLEFT", 18, -53)

    local nameBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    nameBox:SetSize(310, 28)
    nameBox:SetPoint("TOPLEFT", 18, -72)
    nameBox:SetMaxLetters(0)
    MacroStudio.Helpers:ConfigureEditBox(nameBox)
    self.nameBox = nameBox

    local scopeLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Scope")
    scopeLabel:SetPoint("TOPLEFT", 18, -114)

    local accountButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    accountButton:SetSize(160, 24)
    accountButton:SetPoint("TOPLEFT", 18, -134)
    accountButton:SetScript("OnClick", function()
        self:SetScope("ACCOUNT")
    end)
    self.accountButton = accountButton

    local characterButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    characterButton:SetSize(160, 24)
    characterButton:SetPoint("LEFT", accountButton, "RIGHT", 8, 0)
    characterButton:SetScript("OnClick", function()
        self:SetScope("CHARACTER")
    end)
    self.characterButton = characterButton

    local capacityText = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    capacityText:SetPoint("LEFT", characterButton, "RIGHT", 12, 0)
    self.capacityText = capacityText

    local iconLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Icon")
    iconLabel:SetPoint("TOPLEFT", 18, -176)

    local iconButton = CreateFrame("Button", nil, frame, "BackdropTemplate")
    iconButton:SetSize(50, 50)
    iconButton:SetPoint("TOPLEFT", 18, -196)
    iconButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    iconButton:SetBackdropColor(0.04, 0.05, 0.07, 1)
    iconButton:SetBackdropBorderColor(0.3, 0.55, 0.8, 1)

    local iconTexture = iconButton:CreateTexture(nil, "ARTWORK")
    iconTexture:SetPoint("TOPLEFT", 4, -4)
    iconTexture:SetPoint("BOTTOMRIGHT", -4, 4)
    iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    self.iconTexture = iconTexture

    iconButton:SetScript("OnClick", function()
        MacroStudio.IconPicker:Open(self.selectedIcon, function(icon)
            self:SetIcon(icon)
        end)
    end)
    MacroStudio.Helpers:SetButtonTooltip(
        iconButton,
        "Choose Icon",
        "The question-mark icon supports normal #showtooltip behavior."
    )

    local chooseIcon = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    chooseIcon:SetSize(126, 24)
    chooseIcon:SetPoint("LEFT", iconButton, "RIGHT", 10, 0)
    chooseIcon:SetText("Choose Icon")
    chooseIcon:SetScript("OnClick", function()
        iconButton:GetScript("OnClick")()
    end)

    local bodyLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Body")
    bodyLabel:SetPoint("TOPLEFT", 18, -266)

    local bodyBorder = MacroStudio.Helpers:CreatePanel(frame)
    bodyBorder:SetPoint("TOPLEFT", 18, -287)
    bodyBorder:SetPoint("BOTTOMRIGHT", -18, 90)
    bodyBorder:SetBackdropColor(0.018, 0.024, 0.035, 1)

    local bodyHost, bodyBox, bodyScrollBox, bodyScrollBar =
        MacroStudio.Helpers:CreateNativeScrollingEditBox(bodyBorder, 5)
    self.bodyHost = bodyHost
    self.bodyScrollBox = bodyScrollBox
    self.bodyScrollBar = bodyScrollBar
    self.bodyBox = bodyBox

    bodyBox:SetFontObject(ChatFontNormal)
    bodyBox:SetTextInsets(6, 6, 6, 6)
    bodyBox:SetJustifyH("LEFT")
    bodyBox:SetJustifyV("TOP")
    bodyBox:HookScript("OnTextChanged", function()
        self:UpdateState()
    end)

    local countText = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "0 / 255")
    countText:SetPoint("BOTTOMLEFT", 18, 63)
    self.countText = countText

    local errorText = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    errorText:SetPoint("BOTTOMLEFT", 18, 39)
    errorText:SetPoint("BOTTOMRIGHT", -18, 39)
    errorText:SetJustifyH("LEFT")
    errorText:SetWordWrap(false)
    self.errorText = errorText

    local createButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    createButton:SetSize(104, 26)
    createButton:SetPoint("BOTTOMRIGHT", -18, 10)
    createButton:SetText("Create Macro")
    createButton:SetScript("OnClick", function()
        self:Submit()
    end)
    self.createButton = createButton

    local cancelButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancelButton:SetSize(86, 26)
    cancelButton:SetPoint("RIGHT", createButton, "LEFT", -8, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        frame:Hide()
    end)

    nameBox:SetScript("OnTextChanged", function()
        self:UpdateState()
    end)
    nameBox:SetScript("OnEnterPressed", function()
        bodyBox:SetFocus()
        bodyBox:SetCursorPosition(bodyBox:GetNumLetters())
    end)
    nameBox:SetScript("OnTabPressed", function()
        bodyBox:SetFocus()
    end)
    nameBox:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    bodyBox:HookScript("OnEscapePressed", function()
        frame:Hide()
    end)

    frame:SetScript("OnHide", function()
        nameBox:ClearFocus()
        bodyBox:ClearFocus()
    end)

    self:SetIcon(MacroStudio.DEFAULT_ICON)
    self:SetScope("ACCOUNT")
    return frame
end

function MacroDialog:Open(preset)
    local frame = self:Create()
    preset = type(preset) == "table" and preset or {}

    self.nameBox:SetText(type(preset.name) == "string" and preset.name or "")
    self.bodyBox:SetText(type(preset.body) == "string" and preset.body or "")
    self:SetScope(preset.scope)
    self:SetIcon(preset.icon or MacroStudio.DEFAULT_ICON)
    MacroStudio.Helpers:ResetNativeScrollingEditBox(self.bodyScrollBox)
    self:UpdateState()

    frame:Show()
    frame:Raise()
    self.nameBox:SetFocus()
    self.nameBox:HighlightText()
end

function MacroDialog:IsShown()
    return self.frame and self.frame:IsShown() or false
end
