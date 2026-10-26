local _, ms = ...
local repository = ms.StudioMacroRepository
ms.Settings.frame:Hide()
ms.MacroDialog:Close()
ms.IconPicker.frame:Hide()
ms.Editor:SetEditorText(ms.Editor.savedBody)
combat, shiftDown = false, false
ms:SetSearchQuery("")
ms:SetFilter("studio")
assert(#ms.MacroList.visibleHeaders == 1 and ms.MacroList.visibleHeaders[1]:GetText() == "MACROSTUDIO MACROS"
    and #ms.MacroList.visibleRows == 0, "an empty shared library must not show native scope sections")

-- Upgrade both old scopes into one shared library without losing IDs or keys.
ms.db.studioMacros = {nextId=3, records={
    ["1"]={id="1", scope="ACCOUNT", name="Old Shared", icon=134400, body="/say shared", revision=4},
    ["2"]={id="2", scope="CHARACTER", owner="guid:Player-2-OTHER", name="Old Character", icon=134400, body="/say previous", revision=7},
}}
ms.db.studioBindings[repository:GetCharacterKey()] = {["1"]="F10"}
ms.db.studioBindings["guid:Player-2-OTHER"] = {["2"]="F11"}
ms.db.metadata.records["metadata-studio-upgrade"] = {
    id="metadata-studio-upgrade", favorite=true, tags={"Migrated"},
    snapshot={source="STUDIO", studioId="2", scope="CHARACTER", lastKnownIndex="studio:2",
        name="Old Character", icon=134400, body="/say previous"},
}
local bindingsBeforeMigration = ms.db.studioBindings
local store = repository:GetStore()
local oldShared, oldCharacter = repository:GetById("1"), repository:GetById("2")
assert(oldShared.scope == "STUDIO" and oldCharacter.scope == "STUDIO" and not oldCharacter.owner)
assert(oldShared.name == "Old Shared" and oldCharacter.body == "/say previous" and oldCharacter.revision == 7)
assert(ms.db.studioBindings == bindingsBeforeMigration and ms.db.studioBindings["guid:Player-2-OTHER"]["2"] == "F11")
assert(repository:GetStore() == store and repository:GetById("2").revision == 7, "migration must be idempotent")
repository:Refresh()
ms.MetadataRepository:Reconcile(ms.MacroRepository:GetAll())
assert(ms.MetadataRepository:IsFavorite(oldCharacter)
    and ms.MetadataRepository:GetPresentation(oldCharacter).tags[1] == "Migrated",
    "previous character-owned metadata must remain attached to the same shared ID")

-- Native slot exhaustion must not disable creation of addon-owned macros.
ms.MacroRepository.accountCount, ms.MacroRepository.characterCount = 3, 2
ms:SetFilter("studio")
ms:UpdateActionControls()
assert(ms.MacroList.newMacroButton:IsEnabled(), "full native lists must still permit MacroStudio creation")
ms:ShowNewMacroDialog()
assert(ms.MacroDialog.source == "STUDIO", "MacroStudio filter should default to MacroStudio storage")
assert(ms.MacroDialog.accountButton:IsShown() and ms.MacroDialog.characterButton:IsShown()
    and ms.MacroDialog.studioButton:IsShown() and ms.MacroDialog.studioButton:GetChecked(),
    "Create Macro must show all three macro types with the shared type selected")
local formName, formBody = "Keep draft", "/say keep draft"
ms.MacroDialog.nameBox:SetText(formName)
ms.MacroDialog.bodyBox:SetText(formBody)
ms.MacroDialog.accountButton:TriggerScript("OnClick")
assert(ms.MacroDialog:GetRequest().scope == "ACCOUNT" and not ms.MacroDialog:GetRequest().source)
ms.MacroDialog.characterButton:TriggerScript("OnClick")
assert(ms.MacroDialog:GetRequest().scope == "CHARACTER" and ms.MacroDialog.characterButton:GetChecked())
ms.MacroDialog.studioButton:TriggerScript("OnClick")
assert(ms.MacroDialog:GetRequest().source == "STUDIO" and ms.MacroDialog:GetRequest().scope == "STUDIO"
    and ms.MacroDialog.studioButton:GetChecked() and not ms.MacroDialog.characterButton:GetChecked()
    and not ms.MacroDialog.accountButton:GetChecked(), "choosing MacroStudio must select shared storage exclusively")
assert(ms.MacroDialog.nameBox:GetText() == formName and ms.MacroDialog.bodyBox:GetText() == formBody,
    "choosing a macro type must retain the form draft")
assert(ms.MacroDialog.createButton:GetText() == "Create MacroStudio Macro",
    "the submit button must explicitly name the macro type being created")
ms.MacroDialog.nameBox:SetText("Studio Account")
ms.MacroDialog.bodyBox:SetText("/say studio account")
assert(ms.MacroDialog.createButton:IsEnabled(), "MacroStudio creation must ignore native capacity")
local nativeCreate, nativeEdit, nativeDelete, nativePickup = CreateMacro, EditMacro, DeleteMacro, PickupMacro
local function forbiddenNativeWrite() error("MacroStudio macros must never mutate native macro slots") end
CreateMacro, EditMacro, DeleteMacro, PickupMacro = forbiddenNativeWrite, forbiddenNativeWrite, forbiddenNativeWrite, forbiddenNativeWrite
ms.MacroDialog:Submit()
local account = ms.Helpers:CopyMacro(ms.selectedMacro)
assert(account.source == "STUDIO" and account.scope == "STUDIO" and ms.Editor.state.targetSafe)
assert(ms.Editor.scopeText:GetText():find("MacroStudio", 1, true)
    and ms.Editor.keybindButton:GetText() == "Not Bound" and not ms.Editor.usageButton:IsShown())

-- CRUD, search and stable metadata identity all use the existing UI.
ms:ToggleSelectedFavorite()
local category = assert(ms.MetadataRepository:CreateCategory("Studio category"))
ms:AssignSelectedCategory(category.id)
assert(ms.MetadataRepository:AddTag(account, "Studio tag"))
ms.Editor.editBox:SetUserText("/say studio edited")
assert(ms.Editor.state.canSave and not ms.KeybindButton:StartCapture(), "dirty drafts cannot change keybindings")
ms:SaveSelectedMacro()
assert(ms.Editor:GetBody() == "/say studio edited" and not ms.Editor:IsDirty())
local current = ms.Helpers:CopyMacro(ms.selectedMacro)
assert(not repository:Update(account, {name=account.name, icon=account.icon, body="stale"}), "stale managed snapshots must fail")
local metadata = ms.MetadataRepository:GetPresentation(current)
assert(metadata.favorite and metadata.categoryId == category.id and metadata.tags[1] == "Studio tag")
ms:SetFilter("favorites")
ms:SetSearchQuery("Studio tag")
local filtered = ms:GetFilteredMacros()
assert(#filtered == 1 and filtered[1].studioId == account.studioId, "managed tags must be searchable in Favorites")
ms:SetSearchQuery("")
ms.Editor.editBox:SetUserText("/say discard")
ms:OnMacrosChanged("test native event")
assert(ms.Editor:IsDirty() and not ms.Editor.externalConflict and ms.Editor:GetBody() == "/say discard",
    "native refresh events must preserve a managed draft without inventing a conflict")
ms:RevertSelectedMacro()
assert(ms.Editor:GetBody() == current.body and not ms.Editor:IsDirty())

-- The inline button commits a captured input directly and discloses overrides.
GetBindingAction = function(key) return key == "F6" and "TOGGLEGAMEMENU" or "" end
assert(ms.KeybindButton:StartCapture())
ms.KeybindButton:Capture("F6")
assert(ms.Editor.keybindButton:GetText() == "F6"
    and ms.Editor.keybindButton.macroStudioTooltipText:find("Overrides",1,true))
assert(repository:GetBinding(current) == "F6" and not ms:IsMainWindowModalBlocked())
local owner = repository.bindingOwner
local action = repository.buttons[current.studioId]
assert(action:GetAttribute("type") == "macro" and action:GetAttribute("macrotext") == current.body)
assert(owner.secureBindings.F6.button == action:GetName(), "key must target the managed secure action directly")

-- Simulate state-driver transitions using the same restricted snippet strings.
owner:SetAttribute("state-context", "blocked")
owner:RunAttribute("_onstate-context")
assert(next(owner.secureBindings) == nil, "vehicle/pet battle/override context must release keys")
owner:SetAttribute("state-context", "ready")
owner:RunAttribute("_onstate-context")
assert(owner.secureBindings.F6, "normal context must restore configured keys")

local ok, character = repository:Create({name="Studio Character", icon=134400, body="/say character", scope="CHARACTER"})
assert(ok and character.scope == "STUDIO" and not character.owner, "old creation requests must still produce a shared macro")
local bound, reason = repository:SetBinding(character, "F6")
assert(not bound and reason:find("already assigned",1,true), "duplicate active keybindings must be rejected")
assert(repository:SetBinding(character,"CTRL-F7"))
assert(repository:ValidateBinding(character,"ALT-CTRL-SHIFT-;") and repository:ValidateBinding(character,"CTRL--"),
    "punctuation and modifier combinations must be bindable")
assert(not repository:ValidateBinding(character,"INVALID-KEY") and not repository:ValidateBinding(character,"ESCAPE"),
    "unsupported keys must never reach the secure binding API")
assert(ms.KeybindButton:StartCapture())
ms.KeybindButton:Capture("LSHIFT")
ms.KeybindButton:Capture("ESCAPE")
assert(repository:GetBinding(current) == "F6", "cancel must retain the saved key")
ms.Editor.keybindButton:TriggerScript("OnClick", "RightButton")
assert(not repository:GetBinding(current) and not owner.secureBindings.F6, "clear must release the override")
assert(repository:SetBinding(current,"F6"))

combat = true
ms:UpdateCombatState()
assert(not repository:SetBinding(current,"F8") and not repository:Create({name="Blocked",icon=134400,body="",scope="ACCOUNT"}))
assert(not repository:Update(current,{name=current.name,icon=current.icon,body="/say blocked"}) and not repository:Delete(current))
assert(not ms.KeybindButton:StartCapture(), "combat must prevent binding capture and saved-data changes")
assert(action:GetAttribute("macrotext") == current.body and repository:GetBinding(current) == "F6")
combat = false
ms:UpdateCombatState()

-- Every definition is shared; assignments remain independent per character.
local originalCharacter = ms.CharacterMacroLibrary.currentCharacter
ms.CharacterMacroLibrary.currentCharacter = {
    id="guid:Player-2-OTHER", name="Other", realm="Test Realm", displayName="Other - Test Realm", macros={}
}
repository:RebuildBindings()
assert(repository:GetById(current.studioId) and repository:GetById(character.studioId))
assert(not repository:GetBinding(current) and not owner.secureBindings.F6 and not owner.secureBindings["CTRL-F7"],
    "an alt must not inherit another character's keys")
assert(repository:SetBinding(repository:GetById(current.studioId),"F9"))
ms.MetadataRepository:Reconcile(ms.MacroRepository:GetAll())
assert(ms.MetadataRepository:IsFavorite(repository:GetById(current.studioId)), "account metadata must follow the stable managed ID")
ms.CharacterMacroLibrary.currentCharacter = originalCharacter
repository:RebuildBindings()
assert(repository:GetBinding(current) == "F6" and owner.secureBindings.F6 and owner.secureBindings["CTRL-F7"]
    and not owner.secureBindings.F9, "returning to a character must restore only its own assignments")

-- More than the real native limits, without any slot API writes.
for i=1,125 do assert(repository:Create({name="Extra "..i, icon=134400, body="/say extra", scope="ACCOUNT"})) end
for i=1,35 do assert(repository:Create({name="Char "..i, icon=134400, body="/say extra", scope="CHARACTER"})) end
assert(#repository:GetAll() > 150, "the shared library must exceed native storage limits")
ms:SetFilter("studio")
assert(#ms.MacroList.visibleHeaders == 1 and ms.MacroList.visibleHeaders[1]:GetText() == "MACROSTUDIO MACROS",
    "shared library must have one section without Account/Character headings")
for _,macro in ipairs(repository:GetAll()) do assert(macro.scope == "STUDIO" and not macro.owner) end
ms:SetFilter("account")
for _,macro in ipairs(ms:GetFilteredMacros()) do assert(macro.source ~= "STUDIO") end
ms:SetFilter("character")
for _,macro in ipairs(ms:GetFilteredMacros()) do assert(macro.source ~= "STUDIO") end
ms:SetFilter("all")
local foundShared = false
for _,macro in ipairs(ms:GetFilteredMacros()) do if macro.studioId == current.studioId then foundShared = true end end
assert(foundShared, "All Macros must still include the shared library")
assert(not repository:Create({name="Too Long",icon=134400,body=string.rep("x",256),scope="ACCOUNT"}),
    "extra storage must not bypass the executable body length limit")
repository.macros = {}
repository:RebuildBindings()
assert(repository:GetById(current.studioId) and owner.secureBindings.F6, "saved definitions and keys must survive repository reconstruction")
ms:SelectMacro(repository:GetById(current.studioId))
ms:RequestDeleteSelectedMacro()
assert(lastStaticPopup.key == "MACROSTUDIO_DELETE_STUDIO_MACRO", "delete confirmation must identify the correct storage type")
StaticPopupDialogs[lastStaticPopup.key].OnAccept(lastStaticPopup,lastStaticPopup.data)
assert(not repository:GetById(current.studioId) and not owner.secureBindings.F6 and action:GetAttribute("macrotext") == nil)
assert(not ms.db.studioBindings["guid:Player-2-OTHER"][current.studioId], "account deletion must remove bindings on every character")
CreateMacro, EditMacro, DeleteMacro, PickupMacro = nativeCreate, nativeEdit, nativeDelete, nativePickup

-- One style selector combines the base design with its colors.
ms.Settings:Open()
local radioCount = 0
for _, radio in pairs(ms.Settings.styleButtons) do assert(radio:IsShown()); radioCount = radioCount + 1 end
assert(radioCount == 5, "all five style choices must be visible together")
assert(not ms.Settings.warcraftButton and not ms.Settings.legacyButton, "there must be no separate appearance controls")
assert(ms.Settings.styleButtons.warcraft.label:GetText() == "Warcraft (default)"
    and ms.Settings.styleButtons.legacy.label:GetText() == "Legacy" and not ms.Settings.styleButtons.frost)
local activeAppearance, activeStyle = ms.Theme.activeAppearance, ms.Theme.activeColorStyle
ms.Settings.styleButtons.emerald:TriggerScript("OnClick")
assert(ms.Theme:GetColorStyle().id == "emerald" and ms.Settings.styleButtons.emerald:GetChecked())
assert(ms.Theme.activeAppearance == activeAppearance and ms.Theme.activeColorStyle == activeStyle
    and ms.Theme:HasPendingAppearance(), "selection must not rebuild live frames or discard drafts")
ms.Settings.styleButtons.legacy:TriggerScript("OnClick")
assert(ms.db.settings.style == "legacy" and ms.db.settings.appearance == "legacy"
    and not ms.Settings.styleButtons.emerald:GetChecked(), "Legacy must select both its design and original colors")
ms.Settings.styleButtons.ember:TriggerScript("OnClick")
assert(ms.db.settings.appearance == "warcraft" and ms.db.settings.style == "ember")
ms.Settings.frame:Hide()
ms.Settings:Open()
assert(ms.Settings.styleButtons.ember:GetChecked(), "reopening Settings must retain the single saved selection")
ms:SelectMacro(repository:GetById(character.studioId))
ms.Editor.editBox:SetUserText("/say keep style draft")
ms.Settings:Refresh()
assert(not ms.Settings:ApplyAppearance() and ms.Editor:GetBody() == "/say keep style draft",
    "style reloads must protect a managed draft")
ms:RevertSelectedMacro()
ms.Settings.styleButtons[activeStyle]:TriggerScript("OnClick")
assert(ms.Theme:GetColorStyle().id == activeStyle and not ms.Theme:HasPendingAppearance())
local checked = 0
for _, radio in pairs(ms.Settings.styleButtons) do if radio:GetChecked() then checked = checked + 1 end end
assert(checked == 1, "exactly one radio option must remain selected")
ms.Settings.frame:Hide()
print("PASS MacroStudio library, keybinding isolation, secure snippets, and unified styles")
