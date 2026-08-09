local _, MacroStudio = ...

local Dialogs = {}
MacroStudio.Dialogs = Dialogs

local KEYS = {
    DISCARD = "MACROSTUDIO_DISCARD_EDITOR_CHANGES",
    DELETE_CATEGORY = "MACROSTUDIO_DELETE_CATEGORY",
    DELETE_MACRO = "MACROSTUDIO_DELETE_NATIVE_MACRO",
}

local function getData(dialog, data)
    return data or dialog.data
end

if StaticPopupDialogs then
    StaticPopupDialogs[KEYS.DISCARD] = {
        text = "MacroStudio has unsaved changes. Discard them and select %s?",
        button1 = "Discard Changes",
        button2 = CANCEL,
        OnAccept = function(dialog, data)
            data = getData(dialog, data)
            if data and data.macro then
                MacroStudio:SelectMacro(data.macro)
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs[KEYS.DELETE_CATEGORY] = {
        text = "Delete category %s? Assigned macros will become uncategorized. No Blizzard macros will be deleted.",
        button1 = "Delete Category",
        button2 = CANCEL,
        OnAccept = function(dialog, data)
            data = getData(dialog, data)
            if data and data.callback then
                data.callback()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
        preferredIndex = 3,
    }

    StaticPopupDialogs[KEYS.DELETE_MACRO] = {
        text = "Delete the %s macro \"%s\"? This permanently deletes the Blizzard-native macro and its MacroStudio metadata.",
        button1 = "Delete Macro",
        button2 = CANCEL,
        OnAccept = function(dialog, data)
            data = getData(dialog, data)
            if data and data.callback then
                data.callback()
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        showAlert = true,
        preferredIndex = 3,
    }
end

function Dialogs:CreateInputDialog()
    if self.inputFrame then
        return self.inputFrame
    end

    local frame = MacroStudio.Helpers:CreatePanel(UIParent)
    frame:SetSize(440, 205)
    frame:SetPoint("CENTER")
    frame:SetFrameStrata("FULLSCREEN_DIALOG")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:Hide()
    self.inputFrame = frame

    local title = MacroStudio.Helpers:CreateLabel(frame, "GameFontNormalLarge", "MacroStudio")
    title:SetPoint("TOPLEFT", 16, -15)
    self.inputTitle = title

    local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)

    local prompt = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlight", "")
    prompt:SetPoint("TOPLEFT", 18, -54)
    prompt:SetPoint("TOPRIGHT", -18, -54)
    prompt:SetJustifyH("LEFT")
    self.inputPrompt = prompt

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("TOPLEFT", 18, -79)
    editBox:SetPoint("TOPRIGHT", -18, -79)
    editBox:SetHeight(28)
    MacroStudio.Helpers:ConfigureEditBox(editBox)
    self.inputEditBox = editBox

    local errorText = MacroStudio.Helpers:CreateLabel(frame, "GameFontHighlightSmall", "")
    errorText:SetPoint("TOPLEFT", editBox, "BOTTOMLEFT", 0, -10)
    errorText:SetPoint("TOPRIGHT", editBox, "BOTTOMRIGHT", 0, -10)
    errorText:SetTextColor(1, 0.3, 0.3)
    errorText:SetJustifyH("LEFT")
    errorText:SetWordWrap(false)
    self.inputError = errorText

    local submit = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    submit:SetSize(92, 26)
    submit:SetPoint("BOTTOMRIGHT", -18, 14)
    submit:SetText("Save")
    submit:SetScript("OnClick", function()
        self:SubmitInput()
    end)
    self.inputSubmit = submit

    local cancel = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
    cancel:SetSize(82, 26)
    cancel:SetPoint("RIGHT", submit, "LEFT", -8, 0)
    cancel:SetText("Cancel")
    cancel:SetScript("OnClick", function()
        frame:Hide()
    end)

    editBox:SetScript("OnEnterPressed", function()
        self:SubmitInput()
    end)
    editBox:SetScript("OnEscapePressed", function()
        frame:Hide()
    end)
    editBox:SetScript("OnTextChanged", function()
        errorText:SetText("")
    end)
    frame:SetScript("OnHide", function()
        editBox:ClearFocus()
        self.inputCallback = nil
    end)

    return frame
end

function Dialogs:OpenInput(options)
    local frame = self:CreateInputDialog()
    self.inputCallback = options.callback
    self.inputTitle:SetText(options.title or "MacroStudio")
    self.inputPrompt:SetText(options.prompt or "Enter a value:")
    self.inputSubmit:SetText(options.buttonText or "Save")
    self.inputError:SetText("")
    self.inputEditBox:SetMaxLetters(0)
    self.inputEditBox:SetText(options.initialText or "")
    frame:Show()
    frame:Raise()
    self.inputEditBox:SetFocus()
    self.inputEditBox:HighlightText()
end

function Dialogs:SubmitInput()
    local callback = self.inputCallback
    if not callback then
        return
    end

    local success, message = callback(self.inputEditBox:GetText() or "")
    if success then
        self.inputFrame:Hide()
    else
        self.inputError:SetText(message or "Please enter a valid value.")
        self.inputEditBox:SetFocus()
    end
end

function Dialogs:ShowDiscardChanges(macro)
    if StaticPopup_Show then
        local dialog = StaticPopup_Show(KEYS.DISCARD, macro.name or "the selected macro", nil, { macro = macro })
        return dialog ~= nil
    end
    return false
end

function Dialogs:ShowNewCategory(callback)
    self:OpenInput({
        title = "New Category",
        prompt = "Enter a name for the new category:",
        buttonText = "Create",
        maximumLetters = 40,
        callback = callback,
    })
end

function Dialogs:ShowRenameCategory(category, callback)
    self:OpenInput({
        title = "Rename Category",
        prompt = "Rename " .. (category.name or "category") .. ":",
        buttonText = "Rename",
        maximumLetters = 40,
        initialText = category.name or "",
        callback = callback,
    })
end

function Dialogs:ShowDeleteCategory(category, callback)
    StaticPopup_Show(KEYS.DELETE_CATEGORY, category.name, nil, { callback = callback })
end

function Dialogs:ShowAddTag(macro, callback)
    self:OpenInput({
        title = "Create New Tag",
        prompt = "Create and assign a tag to " .. (macro.name or "the selected macro") .. ":",
        buttonText = "Create",
        maximumLetters = 30,
        callback = callback,
    })
end

function Dialogs:ShowDeleteMacro(macro, callback)
    local scope = macro.scope == "CHARACTER" and "Character" or "Account"
    StaticPopup_Show(KEYS.DELETE_MACRO, scope, macro.name or "Unnamed Macro", { callback = callback })
end
