"""Headless construction smoke test for MacroStudio's full TOC load path."""

from lupa.lua51 import LuaRuntime


def run_ui_smoke(root):
    lua = LuaRuntime(unpack_returned_tuples=True)
    load = lua.eval("loadstring")
    lua.execute(
        r"""
        Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 3, MAX_CHARACTER_MACROS = 2 } }
        MAX_ACCOUNT_MACROS = 3
        MAX_CHARACTER_MACROS = 2
        MAX_MACRO_NAME_LENGTH = 16
        CANCEL = "Cancel"
        SlashCmdList = {}
        UISpecialFrames = {}
        StaticPopupDialogs = {}
        MacroStudioDB = nil
        combat = false

        local Frame = {}
        local focusedFrame = nil
        Frame.__index = function(_, key)
            return Frame[key] or function() end
        end

        local function RunHandlers(frame, event, ...)
            if frame.scripts[event] then
                frame.scripts[event](frame, ...)
            end
            for _, handler in ipairs(frame.hooks[event] or {}) do
                handler(frame, ...)
            end
        end

        function Frame:SetSize(width, height) self.width, self.height = width, height end
        function Frame:SetWidth(width) self.width = width end
        function Frame:SetHeight(height) self.height = height end
        function Frame:SetFrameLevel(level) self.frameLevel = level end
        function Frame:SetFrameStrata(strata) self.frameStrata = strata end
        function Frame:SetAllPoints() self.allPoints = true end
        function Frame:SetMovable(movable) self.movable = movable and true or false end
        function Frame:SetClampedToScreen(clamped) self.clamped = clamped and true or false end
        function Frame:EnableMouse(enabled) self.mouseEnabled = enabled and true or false end
        function Frame:EnableMouseWheel(enabled) self.mouseWheelEnabled = enabled and true or false end
        function Frame:RegisterForDrag(button) self.dragButton = button end
        function Frame:StartMoving() self.moving = true end
        function Frame:StopMovingOrSizing() self.moving = false end
        function Frame:GetWidth() return rawget(self, "width") or 500 end
        function Frame:GetHeight() return rawget(self, "height") or 300 end
        function Frame:GetStringHeight()
            local lines = 1
            for _ in string.gmatch(rawget(self, "text") or "", "\n") do lines = lines + 1 end
            return lines * 14
        end
        function Frame:GetPoint() return "CENTER", UIParent, "CENTER", 0, 0 end
        function Frame:GetName() return rawget(self, "name") end
        function Frame:GetFrameLevel() return rawget(self, "frameLevel") or 1 end
        function Frame:SetText(value)
            self.text = tostring(value or "")
            RunHandlers(self, "OnTextChanged", false)
        end
        function Frame:GetText() return rawget(self, "text") or "" end
        function Frame:GetNumLetters() return #(rawget(self, "text") or "") end
        function Frame:SetScript(event, handler) self.scripts[event] = handler end
        function Frame:HookScript(event, handler)
            self.hooks[event] = self.hooks[event] or {}
            table.insert(self.hooks[event], handler)
        end
        function Frame:GetScript(event) return self.scripts[event] end
        function Frame:Show()
            local wasShown = rawget(self, "shown") == true
            self.shown = true
            if not wasShown then RunHandlers(self, "OnShow") end
        end
        function Frame:Hide()
            local wasShown = rawget(self, "shown") == true
            self.shown = false
            if wasShown then RunHandlers(self, "OnHide") end
        end
        function Frame:IsShown() return rawget(self, "shown") == true end
        function Frame:SetShown(shown)
            if shown then self:Show() else self:Hide() end
        end
        function Frame:SetFocus()
            if focusedFrame == self then return end
            if focusedFrame then
                local previous = focusedFrame
                focusedFrame = nil
                previous.focused = false
                RunHandlers(previous, "OnEditFocusLost")
            end
            focusedFrame = self
            self.focused = true
            RunHandlers(self, "OnEditFocusGained")
        end
        function Frame:ClearFocus()
            if focusedFrame ~= self then return end
            focusedFrame = nil
            self.focused = false
            RunHandlers(self, "OnEditFocusLost")
        end
        function Frame:HasFocus() return self.focused == true end
        function Frame:SetEnabled(enabled) self.enabled = enabled and true or false end
        function Frame:IsEnabled() return rawget(self, "enabled") ~= false end
        function Frame:SetVerticalScroll(value) self.verticalScroll = value end
        function Frame:GetVerticalScroll() return rawget(self, "verticalScroll") or 0 end
        function Frame:SetMinMaxValues(minimum, maximum) self.minimum, self.maximum = minimum, maximum end
        function Frame:SetValue(value)
            self.value = value
            if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
        end
        function Frame:CreateTexture()
            local texture = setmetatable({ scripts = {}, hooks = {}, shown = true }, Frame)
            local textures = rawget(self, "textures")
            if not textures then
                textures = {}
                self.textures = textures
            end
            table.insert(textures, texture)
            return texture
        end
        function Frame:SetColorTexture(red, green, blue, alpha)
            self.color = { red, green, blue, alpha }
        end
        function Frame:CreateFontString()
            return setmetatable({ scripts = {}, hooks = {}, shown = true, text = "" }, Frame)
        end

        function CreateFrame(_, name, parent, template)
            local frame = setmetatable({
                name = name,
                parent = parent,
                template = template,
                scripts = {},
                hooks = {},
                shown = true,
                enabled = true,
                text = "",
            }, Frame)
            frame.Text = frame:CreateFontString()
            if template == "ScrollingEditBoxTemplate" then
                local editBox = CreateFrame("EditBox", nil, frame)
                local scrollBox = CreateFrame("Frame", nil, frame)
                frame.GetEditBox = function() return editBox end
                frame.GetScrollBox = function() return scrollBox end
            end
            return frame
        end

        ScrollUtil = {
            RegisterScrollBoxWithScrollBar = function() end,
        }

        UIParent = CreateFrame("Frame", "UIParent")
        UIParent:SetSize(1920, 1080)
        GameTooltip = CreateFrame("Frame", "GameTooltip")

        function StaticPopup_Show(key, text1, text2, data)
            local dialog = CreateFrame("Frame")
            dialog.data = data
            dialog.key, dialog.text1, dialog.text2 = key, text1, text2
            return dialog
        end

        function InCombatLockdown() return combat end
        function strlenutf8(value) return #value end
        function GetNumMacros() return 1, 1 end
        function GetMacroInfo(index)
            if index == 1 then return "Account", 101, "/say account" end
            if index == 4 then return "Character", 102, "/say character" end
            return nil
        end
        function GetMacroIcons(list)
            list[#list + 1] = 134400
            list[#list + 1] = 135000
        end
        function GetMacroItemIcons() end
        function EditMacro(index, _, _, body) return index end
        function CreateMacro() return 2 end
        function DeleteMacro() end
        """
    )

    namespace = lua.table()
    toc_order = [
        "Core.lua",
        "Utils/Helpers.lua",
        "Database.lua",
        "MacroRepository.lua",
        "MetadataRepository.lua",
        "UI/Dialogs.lua",
        "UI/IconPicker.lua",
        "UI/MacroDialog.lua",
        "UI/Editor.lua",
        "UI/MacroList.lua",
        "UI/Sidebar.lua",
        "UI/MainFrame.lua",
    ]
    for relative_path in toc_order:
        source = (root / relative_path).read_text(encoding="utf-8")
        result = load(source, "@" + relative_path)
        chunk, error = result if isinstance(result, tuple) else (result, None)
        assert chunk is not None, error
        chunk("MacroStudio", namespace)

    smoke = load(
        r"""
        local _, ms = ...
        ms:OnAddonLoaded()
        ms:OnPlayerLogin()
        assert(ms.initialized, "full UI should initialize")
        assert(ms.frame and not ms.frame:IsShown(), "main window should remain hidden on login")
        assert(ms.selectedMacro and ms.selectedMacro.name == "Account", "initial refresh should select a macro")
        ms.frame:Show()
        assert(ms.Editor.editBox:IsEnabled(), "selected macro editor should be enabled")
        assert(ms.Editor.editorHost.template == "ScrollingEditBoxTemplate",
            "main editor should use Blizzard's native scrolling edit box")
        assert(#ms.Editor.editorFocusBorderEdges == 4,
            "editor focus border should use four explicit edge regions")
        assert(ms.Editor.editorFocusBorder:GetFrameLevel() > ms.Editor.scrollBar:GetFrameLevel(),
            "editor focus border should render above the scrolling controls")
        ms.Editor.editBox:SetFocus()
        assert(ms.Editor.editorFocusBorderActive,
            "editor focus should activate the complete border")
        for _, edge in ipairs(ms.Editor.editorFocusBorderEdges) do
            assert(edge.color[1] == 0.25 and edge.color[2] == 0.62 and edge.color[3] == 1,
                "every editor edge should receive the focused color")
        end
        ms.Editor.editBox:ClearFocus()
        assert(not ms.Editor.editorFocusBorderActive,
            "editor blur should restore the normal border")
        for _, edge in ipairs(ms.Editor.editorFocusBorderEdges) do
            assert(edge.color[1] == 0.18 and edge.color[2] == 0.22 and edge.color[3] == 0.28,
                "every editor edge should receive the normal color")
        end

        ms.Dialogs:ShowNewCategory(function() return true end)
        assert(ms.Dialogs.inputFrame:IsShown(), "category input should open before modal test")
        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        assert(not ms.Dialogs.inputFrame:IsShown(),
            "entering Create Macro modal state should close other main-window input")
        assert(ms.MacroDialog:IsShown(), "new macro dialog should construct and open")
        assert(ms:IsMainWindowModalBlocked(), "new macro dialog should enter modal state")
        assert(ms.modalOverlay:IsShown() and ms.modalOverlay.mouseEnabled and ms.modalOverlay.mouseWheelEnabled,
            "modal overlay should consume main-window mouse and wheel interaction")
        assert(ms.modalOverlay.allPoints and ms.modalOverlay:GetFrameLevel() > ms.Editor.panel:GetFrameLevel(),
            "modal overlay should cover the complete main window above its controls")
        assert(ms.MacroDialog.bodyHost.template == "ScrollingEditBoxTemplate",
            "macro dialog should use Blizzard's native scrolling edit box")
        assert(ms.MacroDialog.frame.movable and ms.MacroDialog.titleBar.dragButton == "LeftButton",
            "new macro dialog should be movable only through its title bar")
        assert(ms.MacroDialog.frame.clamped, "movable dialog should remain clamped on-screen")
        assert(rawget(ms.MacroDialog.nameBox, "dragButton") == nil and rawget(ms.MacroDialog.bodyBox, "dragButton") == nil,
            "text fields should never initiate dialog dragging")
        ms.MacroDialog.titleBar:GetScript("OnDragStart")(ms.MacroDialog.titleBar)
        assert(ms.MacroDialog.frame.moving, "title drag should start dialog movement")
        ms.MacroDialog.titleBar:GetScript("OnDragStop")(ms.MacroDialog.titleBar)
        assert(not ms.MacroDialog.frame.moving, "title drag stop should end dialog movement")

        ms.MacroDialog.nameBox:SetText("Smoke")
        assert(ms.MacroDialog.createButton:IsEnabled(), "valid dialog should enable Create")
        ms.MacroDialog.bodyBox:SetText("/say preserved")
        combat = true
        ms:UpdateCombatState()
        assert(ms.MacroDialog.nameBox:GetText() == "Smoke"
            and ms.MacroDialog.bodyBox:GetText() == "/say preserved",
            "combat transitions should preserve the modal form")
        assert(ms.MacroDialog:IsShown() and ms:IsMainWindowModalBlocked(),
            "combat should not close or unblock the modal")
        assert(not ms.MacroDialog.createButton:IsEnabled(),
            "combat should block Create without auto-submitting")
        combat = false
        ms:UpdateCombatState()
        assert(ms.MacroDialog.createButton:IsEnabled(),
            "leaving combat should only re-enable valid manual creation")

        ms.Editor.editBox:SetText("/say dirty")
        assert(not ms.MacroDialog.createButton:IsEnabled(), "dirty editor should disable dialog Create")
        ms.Editor:SetEditorText(ms.Editor.savedBody)
        assert(ms.MacroDialog.createButton:IsEnabled(), "clean editor should restore valid dialog Create")
        ms.IconPicker:Open(ms.DEFAULT_ICON, function() end)
        assert(ms.IconPicker.frame:IsShown(), "icon picker should construct and open")
        ms.MacroDialog:Close()
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "closing the dialog should completely clear modal state")
        assert(not ms.modalOverlay:IsShown() and not ms.IconPicker.frame:IsShown(),
            "closing the dialog should leave no overlay or child picker behind")
        assert(ms.Editor.editBox:HasFocus(),
            "closing the modal should restore focus to the selected editor")

        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        ms.MacroDialog.nameBox:GetScript("OnEscapePressed")(ms.MacroDialog.nameBox)
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "Escape should close the dialog and clear modal state")

        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        ms.MacroDialog.cancelButton:GetScript("OnClick")(ms.MacroDialog.cancelButton)
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "Cancel should close the dialog and clear modal state")

        local realCreateNativeMacro = ms.CreateNativeMacro
        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        ms.MacroDialog.nameBox:SetText("Created")
        ms.CreateNativeMacro = function()
            return true, ms.selectedMacro
        end
        ms.MacroDialog:Submit()
        ms.CreateNativeMacro = realCreateNativeMacro
        assert(not ms.MacroDialog:IsShown() and not ms:IsMainWindowModalBlocked(),
            "successful Create should close the dialog and clear modal state")
        assert(not ms.modalOverlay:IsShown() and ms.Editor.editBox:HasFocus(),
            "successful Create cleanup should restore normal editor interaction")

        ms.Dialogs:ShowNewCategory(function() return false, "Visible validation" end)
        ms.Dialogs.inputEditBox:SetText("")
        ms.Dialogs:SubmitInput()
        assert(ms.Dialogs.inputError:GetText() == "Visible validation", "input errors should stay visible")
        """,
        "@ui-smoke",
    )
    smoke("MacroStudio", namespace)
