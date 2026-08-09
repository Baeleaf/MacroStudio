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
        function Frame:Show() self.shown = true end
        function Frame:Hide() self.shown = false end
        function Frame:IsShown() return rawget(self, "shown") == true end
        function Frame:SetShown(shown) self.shown = shown and true or false end
        function Frame:SetFocus() self.focused = true; RunHandlers(self, "OnEditFocusGained") end
        function Frame:ClearFocus() self.focused = false; RunHandlers(self, "OnEditFocusLost") end
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
            return setmetatable({ scripts = {}, hooks = {}, shown = true }, Frame)
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
        assert(ms.Editor.editBox:IsEnabled(), "selected macro editor should be enabled")
        assert(ms.Editor.editorHost.template == "ScrollingEditBoxTemplate",
            "main editor should use Blizzard's native scrolling edit box")
        ms.MacroDialog:Open({ scope = "ACCOUNT", icon = ms.DEFAULT_ICON })
        assert(ms.MacroDialog:IsShown(), "new macro dialog should construct and open")
        assert(ms.MacroDialog.bodyHost.template == "ScrollingEditBoxTemplate",
            "macro dialog should use Blizzard's native scrolling edit box")
        ms.MacroDialog.nameBox:SetText("Smoke")
        assert(ms.MacroDialog.createButton:IsEnabled(), "valid dialog should enable Create")
        ms.Editor.editBox:SetText("/say dirty")
        assert(not ms.MacroDialog.createButton:IsEnabled(), "dirty editor should disable dialog Create")
        ms.Editor:SetEditorText(ms.Editor.savedBody)
        assert(ms.MacroDialog.createButton:IsEnabled(), "clean editor should restore valid dialog Create")
        ms.IconPicker:Open(ms.DEFAULT_ICON, function() end)
        assert(ms.IconPicker.frame:IsShown(), "icon picker should construct and open")
        ms.Dialogs:ShowNewCategory(function() return false, "Visible validation" end)
        ms.Dialogs.inputEditBox:SetText("")
        ms.Dialogs:SubmitInput()
        assert(ms.Dialogs.inputError:GetText() == "Visible validation", "input errors should stay visible")
        """,
        "@ui-smoke",
    )
    smoke("MacroStudio", namespace)
