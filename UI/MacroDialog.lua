local _, MacroStudio = ...

local MacroDialog = {
    scope = "ACCOUNT",
    selectedIcon = nil,
}
MacroStudio.MacroDialog = MacroDialog

local NORMAL_COLOR = MacroStudio.Theme.palette.text
local WARNING_COLOR = MacroStudio.Theme.palette.warning
local ERROR_COLOR = MacroStudio.Theme.palette.error

function MacroDialog:SetScope(scope)
    self.scope = scope == "CHARACTER" and "CHARACTER" or "ACCOUNT"
    self.accountButton:SetText("Account")
    self.characterButton:SetText("Character")
    MacroStudio.Theme:Tab(self.accountButton, self.scope == "ACCOUNT")
    MacroStudio.Theme:Tab(self.characterButton, self.scope == "CHARACTER")
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

function MacroDialog:Close()
    if self.frame then
        self.frame:Hide()
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

    self:Close()
end

function MacroDialog:Create()
    if self.frame then
        return self.frame
    end

    local frame = MacroStudio.Helpers:CreateWindow(UIParent)
    frame:SetSize(550, 460)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.frame = frame

    local titleBar = frame.TitleContainer
    titleBar.TitleText:Hide()
    titleBar:SetHeight(MacroStudio.Theme.spacing.title)
    titleBar:EnableMouse(true)
    titleBar:RegisterForDrag("LeftButton")
    titleBar:SetScript("OnDragStart", function()
        frame:StartMoving()
    end)
    titleBar:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
    end)
    self.titleBar = titleBar

    local title = MacroStudio.Helpers:CreateLabel(titleBar, "GameFontNormalLarge", "Create Macro")
    title:SetPoint("LEFT", 15, 0)

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local nameLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Name")
    nameLabel:SetPoint("TOPLEFT", 14, -46)

    local nameBox = MacroStudio.Helpers:CreateInput(frame)
    nameBox:SetSize(310, 24)
    nameBox:SetPoint("TOPLEFT", 14, -64)
    nameBox:SetMaxLetters(0)
    MacroStudio.Helpers:ConfigureEditBox(nameBox)
    self.nameBox = nameBox

    local scopeLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Scope")
    scopeLabel:SetPoint("TOPLEFT", 14, -103)

    local accountButton = MacroStudio.Helpers:CreateTab(frame)
    accountButton:SetSize(MacroStudio.Theme:IsLegacy() and 160 or 120, 24)
    accountButton:SetPoint("TOPLEFT", 14, -123)
    accountButton:SetScript("OnClick", function()
        self:SetScope("ACCOUNT")
    end)
    self.accountButton = accountButton

    local characterButton = MacroStudio.Helpers:CreateTab(frame)
    characterButton:SetSize(MacroStudio.Theme:IsLegacy() and 160 or 120, 24)
    characterButton:SetPoint("LEFT", accountButton, "RIGHT", 10, 0)
    characterButton:SetScript("OnClick", function()
        self:SetScope("CHARACTER")
    end)
    self.characterButton = characterButton

    local capacityText = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    capacityText:SetPoint("LEFT", characterButton, "RIGHT", 12, 0)
    self.capacityText = capacityText

    local iconLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Icon")
    iconLabel:SetPoint("TOPLEFT", 350, -46)

    local iconButton = CreateFrame("Button", nil, frame)
    iconButton:SetSize(38, 38)
    iconButton:SetPoint("TOPLEFT", 350, -64)

    local iconTexture = iconButton:CreateTexture(nil, "ARTWORK")
    iconTexture:SetPoint("TOPLEFT", 4, -4)
    iconTexture:SetPoint("BOTTOMRIGHT", -4, 4)
    iconTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    self.iconTexture = iconTexture
    MacroStudio.Theme:IconBorder(iconButton, iconTexture)

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

    local chooseIcon = MacroStudio.Helpers:CreateButton(frame)
    chooseIcon:SetSize(126, 24)
    chooseIcon:SetPoint("LEFT", iconButton, "RIGHT", 10, 0)
    chooseIcon:SetText("Choose Icon")
    chooseIcon:SetScript("OnClick", function()
        iconButton:GetScript("OnClick")()
    end)

    local bodyLabel = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "Body")
    bodyLabel:SetPoint("TOPLEFT", 14, -157)

    local bodyBorder = MacroStudio.Helpers:CreateEditorInset(frame)
    bodyBorder:SetPoint("TOPLEFT", 14, -177)
    bodyBorder:SetPoint("BOTTOMRIGHT", -14, 76)

    local bodyHost, bodyBox, bodyScrollBox, bodyScrollBar =
        MacroStudio.Helpers:CreateNativeScrollingEditBox(bodyBorder, 5)
    self.bodyHost = bodyHost
    self.bodyScrollBox = bodyScrollBox
    self.bodyScrollBar = bodyScrollBar
    self.bodyBox = bodyBox

    bodyBox:SetFontObject(ChatFontNormal)
    bodyBox:SetTextColor(unpack(NORMAL_COLOR))
    local _, focusEdges = MacroStudio.Helpers:CreateOverlayBorder(bodyBorder, bodyScrollBar, 2)
    MacroStudio.Helpers:SetOverlayBorderColor(focusEdges, unpack(MacroStudio.Theme.palette.border))
    bodyBox:HookScript("OnEditFocusGained", function()
        MacroStudio.Helpers:SetOverlayBorderColor(focusEdges, unpack(MacroStudio.Theme.palette.focus))
    end)
    bodyBox:HookScript("OnEditFocusLost", function()
        MacroStudio.Helpers:SetOverlayBorderColor(focusEdges, unpack(MacroStudio.Theme.palette.border))
    end)
    bodyBox:SetTextInsets(6, 6, 6, 6)
    bodyBox:SetJustifyH("LEFT")
    bodyBox:SetJustifyV("TOP")
    bodyBox:HookScript("OnTextChanged", function()
        self:UpdateState()
    end)

    local countText = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormal", "0 / 255")
    countText:SetPoint("BOTTOMLEFT", 14, 54)
    self.countText = countText

    local errorText = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    errorText:SetPoint("BOTTOMLEFT", 14, 36)
    errorText:SetPoint("BOTTOMRIGHT", -14, 36)
    errorText:SetJustifyH("LEFT")
    errorText:SetWordWrap(false)
    self.errorText = errorText

    local createButton = MacroStudio.Helpers:CreateButton(frame)
    createButton:SetSize(104, 26)
    createButton:SetPoint("BOTTOMRIGHT", -18, 10)
    createButton:SetText("Create Macro")
    createButton:SetScript("OnClick", function()
        self:Submit()
    end)
    self.createButton = createButton

    local cancelButton = MacroStudio.Helpers:CreateButton(frame)
    cancelButton:SetSize(86, 26)
    cancelButton:SetPoint("RIGHT", createButton, "LEFT", -8, 0)
    cancelButton:SetText("Cancel")
    cancelButton:SetScript("OnClick", function()
        self:Close()
    end)
    self.cancelButton = cancelButton

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
        self:Close()
    end)
    bodyBox:HookScript("OnEscapePressed", function()
        self:Close()
    end)

    frame:SetScript("OnShow", function()
        MacroStudio:SetMainWindowModalBlocked(true)
        frame:Raise()
    end)
    frame:SetScript("OnHide", function()
        nameBox:ClearFocus()
        bodyBox:ClearFocus()
        if MacroStudio.IconPicker and MacroStudio.IconPicker.frame then
            MacroStudio.IconPicker.frame:Hide()
        end
        MacroStudio:SetMainWindowModalBlocked(false)
        if MacroStudio.frame
            and MacroStudio.frame:IsShown()
            and MacroStudio.Editor
            and MacroStudio.Editor.editBox
            and MacroStudio.Editor.editBox:IsEnabled() then
            MacroStudio.Editor.editBox:SetFocus()
        end
    end)

    self:SetIcon(MacroStudio.DEFAULT_ICON)
    self:SetScope("ACCOUNT")
    return frame
end

function MacroDialog:Open(preset)
    local frame = self:Create()
    if frame:IsShown() then
        frame:Raise()
        self.nameBox:SetFocus()
        return
    end

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
