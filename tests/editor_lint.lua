-- Run against the existing full-TOC UI harness for each appearance.
return function(ms)
    local checks = 0
    local function check(value, message)
        assert(value, message)
        checks = checks + 1
    end
    local function copy(value)
        if type(value) ~= "table" then return value end
        local result = {}
        for key, item in pairs(value) do result[key] = copy(item) end
        return result
    end
    local function equal(left, right)
        if type(left) ~= type(right) then return false end
        if type(left) ~= "table" then return left == right end
        for key, item in pairs(left) do
            if not equal(item, right[key]) then return false end
        end
        for key in pairs(right) do if left[key] == nil then return false end end
        return true
    end

    local editor = ms.Editor
    local originalBody = editor:GetBody()
    local nativeBefore, dbBefore = copy(baseAccountMacro), copy(MacroStudioDB)
    local editsBefore = editCalls
    check(editor.lintButton:IsShown() and editor.lintButton.Text:GetText() == "No issues detected",
        "saved valid macro should show the diagnostic summary")
    editor.editBox:SetFocus()
    editor.editBox:SetCursorPosition(3)
    editor.editBox:HighlightText(1, 3)
    editor.editBox:SetUserText("#showtooltip\n#showtooltip\n/cast [\n/use")
    check(#editor.diagnostics == 3 and editor.lintButton.Text:GetText() == "1 error · 2 warnings",
        "unsaved draft should show accurate severity counts")
    check(editor.state.canSave and editor.saveButton:IsEnabled() and editor.state.canRevert,
        "syntax errors and warnings must never become Save blockers")
    check(editor.editBox:HasFocus() and editor.editBox.cursorPosition == 3
            and editor.editBox.selectionStart == 1 and editor.editBox.selectionEnd == 3,
        "lint updates must preserve focus, caret and selection")
    editor.lintButton:TriggerScript("OnEnter")
    check(GameTooltip.tooltipBody:find("Warning %- Line 2, column 1")
            and GameTooltip.tooltipBody:find("Finding 1 of 3")
            and GameTooltip.tooltipBody:find("DUPLICATE_SHOWTOOLTIP")
            and GameTooltip.tooltipBody:find("does not guarantee"),
        "tooltip should explain severity, location, rule, navigation and limitations")
    editor.lintButton:TriggerScript("OnClick", "LeftButton")
    check(GameTooltip.tooltipBody:find("UNCLOSED_CONDITIONAL")
            and GameTooltip.tooltipBody:find("Finding 2 of 3"),
        "click should expose the next finding")
    editor.lintButton:TriggerScript("OnMouseWheel", -1)
    check(GameTooltip.tooltipBody:find("MISSING_ARGUMENT")
            and GameTooltip.tooltipBody:find("Finding 3 of 3"),
        "scroll should expose every finding")
    editor.lintButton:TriggerScript("OnClick", "RightButton")
    check(editor.lintFinding == 2 and editor.editBox:HasFocus(),
        "previous finding should preserve editing focus")
    editor.lintButton:TriggerScript("OnMouseWheel", 1)
    editor.lintButton:TriggerScript("OnMouseWheel", 1)
    check(editor.lintFinding == 3, "diagnostic navigation must wrap backward to the last finding")
    editor.lintButton:TriggerScript("OnClick", "LeftButton")
    check(editor.lintFinding == 1, "diagnostic navigation must wrap forward to the first finding")
    editor.editBox:SetUserText("/cast [] Moonfire")
    check(#editor.diagnostics == 0 and editor.lintFinding == 1
            and GameTooltip.tooltipBody:find("Advisory static checks only"),
        "correcting a hovered diagnostic must refresh the tooltip and reset paging")
    editor.lintButton:TriggerScript("OnLeave")
    check(not GameTooltip:IsShown(), "leaving diagnostics should close its tooltip")
    for _ = 1, 10 do
        editor.editBox:SetUserText("/cast [")
        check(#editor.diagnostics == 1, "repeated edits must not accumulate diagnostics")
        editor.editBox:SetUserText("/cast [] Moonfire")
        check(#editor.diagnostics == 0, "repeated corrections must clear diagnostics")
    end
    check(editCalls == editsBefore and equal(baseAccountMacro, nativeBefore) and equal(MacroStudioDB, dbBefore),
        "typing and inspecting diagnostics must not mutate native macros or SavedVariables")
    editor.editBox:SetUserText("/cast [")
    ms:SetSearchQuery("Account")
    check(editor:GetBody() == "/cast [" and #editor.diagnostics == 1,
        "search refresh must preserve the unsaved draft and its findings")
    ms:SetSearchQuery("")
    combat = true
    ms:UpdateCombatState()
    ms:SaveSelectedMacro()
    check(not editor.state.canSave and editCalls == editsBefore and #editor.diagnostics == 1,
        "combat protection must remain active with lint findings")
    combat = false
    ms:UpdateCombatState()
    editor:SetExternalConflict(true)
    ms:SaveSelectedMacro()
    check(not editor.state.canSave and editCalls == editsBefore and editor:GetBody() == "/cast [",
        "external conflict protection must preserve the linted draft")
    editor:SetExternalConflict(false)
    editor.editBox:SetUserText(string.rep("x", 256) .. "\n/cast [")
    check(not editor.state.canSave and #editor.diagnostics == 1,
        "oversized drafts should still lint while native length validation blocks Save")
    ms:RevertSelectedMacro()
    check(editor:GetBody() == originalBody and #editor.diagnostics == 0 and not editor:IsDirty(),
        "Revert should restore saved text and diagnostics")

    editor.editBox:SetUserText("/cast [")
    ms:SaveSelectedMacro()
    check(editCalls == editsBefore + 1 and baseAccountMacro.body == "/cast ["
            and #editor.diagnostics == 1 and not editor:IsDirty(),
        "explicit Save must write malformed-but-saveable text exactly once without correction")
    ms:SelectMacro(ms.MacroRepository:FindByIndex(4))
    check(#editor.diagnostics == 0, "switching macros must not retain previous diagnostics")
    ms:SelectMacro(ms.MacroRepository:FindByIndex(1))
    check(#editor.diagnostics == 1, "selecting a saved malformed macro must recompute findings")
    editor.editBox:SetUserText(originalBody)
    ms:SaveSelectedMacro()
    check(baseAccountMacro.body == originalBody and #editor.diagnostics == 0,
        "saving the corrected draft should clear diagnostics")

    local offline = { source = "SNAPSHOT", name = "Lint Snapshot", icon = 777, body = "/use ] 13" }
    editor:SetMacro(offline)
    check(#editor.diagnostics == 1 and editor.state.offline and not editor.state.canSave,
        "offline read-only snapshot must receive diagnostics")
    editor.editBox:SetUserText("/cast Moonfire")
    check(editor:GetBody() == offline.body and #editor.diagnostics == 1 and not editor:IsDirty(),
        "offline edit rejection must retain diagnostics for the restored snapshot")
    editor:Clear()
    check(#editor.diagnostics == 0 and not editor.lintButton:IsShown(),
        "empty selection must clear findings and hide the summary")
    editor:SetMacro(ms.selectedMacro)
    editor.editBox:ClearFocus()
    return checks
end
