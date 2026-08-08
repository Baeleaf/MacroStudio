local _, MacroStudio = ...

local Dialogs = {}
MacroStudio.Dialogs = Dialogs

local KEYS = {
    DISCARD = "MACROSTUDIO_DISCARD_EDITOR_CHANGES",
    NEW_CATEGORY = "MACROSTUDIO_NEW_CATEGORY",
    RENAME_CATEGORY = "MACROSTUDIO_RENAME_CATEGORY",
    DELETE_CATEGORY = "MACROSTUDIO_DELETE_CATEGORY",
    ADD_TAG = "MACROSTUDIO_ADD_TAG",
}

local function getData(dialog, data)
    return data or dialog.data
end

local function getEditBox(dialog)
    return dialog.EditBox or dialog.editBox
end

local function defineInputDialog(key, text, buttonText, maximumLetters)
    StaticPopupDialogs[key] = {
        text = text,
        button1 = buttonText,
        button2 = CANCEL,
        hasEditBox = true,
        OnShow = function(dialog, data)
            data = getData(dialog, data)
            local editBox = getEditBox(dialog)
            if editBox then
                editBox:SetMaxLetters(maximumLetters)
                editBox:SetText(data and data.initialText or "")
                editBox:SetFocus()
                editBox:HighlightText()
            end
        end,
        OnAccept = function(dialog, data)
            local editBox = getEditBox(dialog)
            data = getData(dialog, data)
            if data and data.callback and editBox then
                data.callback(editBox:GetText())
            end
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }
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

    defineInputDialog(KEYS.NEW_CATEGORY, "Enter a name for the new category:", "Create", 40)
    defineInputDialog(KEYS.RENAME_CATEGORY, "Rename category %s:", "Rename", 40)
    defineInputDialog(KEYS.ADD_TAG, "Add a tag to %s:", "Add", 30)

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
end

function Dialogs:ShowDiscardChanges(macro)
    if StaticPopup_Show then
        local dialog = StaticPopup_Show(KEYS.DISCARD, macro.name or "the selected macro", nil, { macro = macro })
        return dialog ~= nil
    end
    return false
end

function Dialogs:ShowNewCategory(callback)
    StaticPopup_Show(KEYS.NEW_CATEGORY, nil, nil, {
        initialText = "",
        callback = callback,
    })
end

function Dialogs:ShowRenameCategory(category, callback)
    StaticPopup_Show(KEYS.RENAME_CATEGORY, category.name, nil, {
        initialText = category.name,
        callback = callback,
    })
end

function Dialogs:ShowDeleteCategory(category, callback)
    StaticPopup_Show(KEYS.DELETE_CATEGORY, category.name, nil, {
        callback = callback,
    })
end

function Dialogs:ShowAddTag(macro, callback)
    StaticPopup_Show(KEYS.ADD_TAG, macro.name or "the selected macro", nil, {
        initialText = "",
        callback = callback,
    })
end
