local _, ms = ...
local repository, keybind, editor = ms.StudioMacroRepository, ms.KeybindButton, ms.Editor
local oldAlt, oldControl, oldShift = IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown
local oldAction = GetBindingAction
local alt, control, shift = false, false, false
IsAltKeyDown = function() return alt end
IsControlKeyDown = function() return control end
IsShiftKeyDown = function() return shift end
GetBindingAction = function(key) return key == "ALT-1" and "TOGGLEGAMEMENU" or "" end
local create, edit, delete, pickup = CreateMacro, EditMacro, DeleteMacro, PickupMacro
local function forbidden() error("Inline keybinding must not allocate or edit native macro slots") end
CreateMacro, EditMacro, DeleteMacro, PickupMacro = forbidden, forbidden, forbidden, forbidden

local ok, macro = repository:Create({name="Inline Keys",icon=134400,body="/say inline"})
assert(ok)
ms:SelectMacro(macro)
local button, capture = editor.keybindButton, keybind.captureFrame
assert(button == keybind.button and button:IsShown() and editor.keybindLabel:IsShown()
    and button:GetText() == "Not Bound" and not editor.usageButton:IsShown())
assert(editor.keybindLabel.points[1][3] == -148 and editor.tagsLabel.points[1][3] == -120
    and editor.editBorder.points[1][3] == -192, "keybind row must sit below Tags and above the body")
button:TriggerScript("OnEnter")
assert(GameTooltip.tooltipOwner == button and GameTooltip.tooltipTitle == "Keybind"
    and GameTooltip.tooltipBody:find("Left-click to set",1,true)
    and GameTooltip.tooltipBody:find("Right-click to clear",1,true))
button:TriggerScript("OnLeave")

editor.nameBox:SetFocus()
button:TriggerScript("OnClick", "LeftButton")
assert(capture:IsShown() and capture.keyboardEnabled and capture.mouseEnabled and capture.mouseWheelEnabled
    and not capture.propagatesKeyboard and not editor.nameBox:HasFocus() and not editor.editBox:HasFocus()
    and button:GetText() == "Press a key, click, or scroll..." and not ms:IsMainWindowModalBlocked())
assert(not repository:GetBinding(macro), "starting capture must not change the existing binding")
capture:TriggerScript("OnKeyDown", "LALT")
assert(keybind.captureMacro and not repository:GetBinding(macro), "a modifier alone must keep listening")
alt = true
capture:TriggerScript("OnKeyDown", "1")
alt = false
assert(repository:GetBinding(macro) == "ALT-1" and button:GetText() == "Alt + 1"
    and not capture:IsShown() and not keybind.captureMacro)
GetBindingAction = function(key, checkOverride)
    if key ~= "ALT-1" then return "" end
    return checkOverride and ("CLICK MacroStudioAction" .. macro.studioId .. ":LeftButton") or "TOGGLEGAMEMENU"
end
keybind:Refresh()
assert(button.macroStudioTooltipText:find("Overrides",1,true), "the saved binding must disclose the existing game action")
assert(repository.bindingOwner.secureBindings["ALT-1"].button == repository.buttons[macro.studioId]:GetName())
capture:TriggerScript("OnKeyDown", "F12")
assert(repository:GetBinding(macro) == "ALT-1", "inactive listeners must never change a binding")

button:TriggerScript("OnClick", "LeftButton")
capture:TriggerScript("OnKeyDown", "LSHIFT")
shift = true
capture:TriggerScript("OnKeyDown", "ESCAPE")
shift = false
assert(repository:GetBinding(macro) == "ALT-1" and button:GetText() == "Alt + 1" and not capture:IsShown(),
    "Escape must cancel even with modifiers and retain the saved label")
button:TriggerScript("OnClick", "RightButton")
assert(not repository:GetBinding(macro) and button:GetText() == "Not Bound"
    and not repository.bindingOwner.secureBindings["ALT-1"], "right-click must clear and release the override immediately")

-- Capture actual mouse/wheel events through the input shield, including modifiers.
button:TriggerScript("OnClick", "LeftButton")
capture:TriggerScript("OnMouseUp", "MiddleButton")
assert(repository:GetBinding(macro) == "BUTTON3" and button:GetText() == "Middle Mouse")
button:TriggerScript("OnClick", "LeftButton")
control = true
capture:TriggerScript("OnMouseUp", "Button4")
control = false
assert(repository:GetBinding(macro) == "CTRL-BUTTON4" and button:GetText() == "Ctrl + Mouse 4")
button:TriggerScript("OnClick", "LeftButton")
capture:TriggerScript("OnMouseWheel", 0)
assert(keybind.captureMacro and repository:GetBinding(macro) == "CTRL-BUTTON4")
shift = true
capture:TriggerScript("OnMouseWheel", 1)
shift = false
assert(repository:GetBinding(macro) == "SHIFT-MOUSEWHEELUP" and button:GetText() == "Shift + Mouse Wheel Up")
button:TriggerScript("OnClick", "LeftButton")
capture:TriggerScript("OnMouseWheel", -1)
assert(repository:GetBinding(macro) == "MOUSEWHEELDOWN" and button:GetText() == "Mouse Wheel Down")
button:TriggerScript("OnClick", "LeftButton")
capture:TriggerScript("OnMouseUp", "LeftButton")
capture:TriggerScript("OnMouseUp", "RightButton")
assert(keybind.captureMacro and repository:GetBinding(macro) == "MOUSEWHEELDOWN",
    "primary mouse clicks must not replace the binding or reach the underlying UI")
capture:TriggerScript("OnKeyDown", "ESCAPE")
assert(not repository:ValidateBinding(macro, "BUTTON2") and not repository:ValidateBinding(macro,"ALT-BUTTON1")
    and not repository:ValidateBinding(macro,"BUTTON32"))

-- A conflicting managed key leaves the previous key active and allows a retry.
local _, other = repository:Create({name="Inline Conflict",icon=134400,body="/say other"})
assert(repository:SetBinding(other,"F8"))
button:TriggerScript("OnClick", "LeftButton")
capture:TriggerScript("OnKeyDown", "F8")
assert(capture:IsShown() and keybind.captureMacro and repository:GetBinding(macro) == "MOUSEWHEELDOWN"
    and button.macroStudioTooltipText:find("already assigned",1,true))
capture:TriggerScript("OnKeyDown", "F9")
assert(repository:GetBinding(macro) == "F9" and not capture:IsShown() and button:GetText() == "F9")

-- Capture ends on draft changes, combat, selection, dialogs and window closure.
button:TriggerScript("OnClick", "LeftButton")
editor.editBox:SetUserText("/say keep draft")
assert(not capture:IsShown() and not button:IsEnabled() and repository:GetBinding(macro) == "F9"
    and editor:GetBody() == "/say keep draft")
button:TriggerScript("OnClick", "RightButton")
assert(repository:GetBinding(macro) == "F9", "dirty drafts must block clearing too")
ms:RevertSelectedMacro()
button:TriggerScript("OnClick", "LeftButton")
combat = true
ms:UpdateCombatState()
assert(not capture:IsShown() and not keybind.captureMacro and not button:IsEnabled())
button:TriggerScript("OnClick", "RightButton")
assert(repository:GetBinding(macro) == "F9")
combat = false
ms:UpdateCombatState()
assert(button:IsEnabled() and not capture:IsShown(), "ending combat must not resume a canceled capture")
button:TriggerScript("OnClick", "LeftButton")
ms:SetMainWindowModalBlocked(true)
assert(not capture:IsShown() and not keybind:StartCapture())
ms:SetMainWindowModalBlocked(false)
assert(button:IsEnabled(), "closing a dialog must re-enable the inline button")
editor:RefreshState()
button:TriggerScript("OnClick", "LeftButton")
ms:SelectMacro(other)
assert(not capture:IsShown() and button:GetText() == "F8")
ms:SelectMacro(macro)
ms.frame:Show()
button:TriggerScript("OnClick", "LeftButton")
ms.frame:Hide()
assert(not capture:IsShown() and repository:GetBinding(macro) == "F9")

button:TriggerScript("OnClick", "LeftButton")
repository:GetStore().records[macro.studioId].revision = macro.revision + 1
capture:TriggerScript("OnKeyDown", "F10")
assert(not capture:IsShown() and repository:GetBinding(macro) == "F9",
    "a stale capture must never bind another revision")
ms:SelectMacro(repository:GetById(macro.studioId))
ms:SelectMacro(ms.MacroRepository:GetAll()[1])
assert(not button:IsShown() and not editor.keybindLabel:IsShown() and editor.editBorder.points[1][3] == -164,
    "native macros must retain their layout without a managed keybind row")
editor:Clear()
assert(not button:IsShown() and not capture:IsShown())

assert(repository:Delete(repository:GetById(macro.studioId)))
assert(repository:Delete(other))
IsAltKeyDown, IsControlKeyDown, IsShiftKeyDown = oldAlt, oldControl, oldShift
GetBindingAction = oldAction
CreateMacro, EditMacro, DeleteMacro, PickupMacro = create, edit, delete, pickup
print("PASS inline keybind: themed placement, tooltip, immediate capture, modifiers, mouse/wheel, clear, cancel and lifecycle guards")
