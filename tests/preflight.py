"""MacroStudio headless preflight.

Requires Python 3 and lupa. The embedded Lua runtime compiles every addon file,
then WoW API stubs exercise repository mutation, metadata, and section filters.
"""

from pathlib import Path

from lupa.lua51 import LuaRuntime


from ui_smoke import run_ui_smoke

ROOT = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
globals_ = lua.globals()
load = lua.eval("loadstring")


def compile_lua(path: Path):
    result = load(path.read_text(encoding="utf-8"), "@" + path.relative_to(ROOT).as_posix())
    chunk, error = result if isinstance(result, tuple) else (result, None)
    assert chunk is not None, f"{path.name}: {error}"
    return chunk


def load_addon_file(relative_path: str, namespace):
    compile_lua(ROOT / relative_path)("MacroStudio", namespace)


for lua_path in sorted(ROOT.rglob("*.lua")):
    compile_lua(lua_path)

lua.execute(
    r"""
    Constants = { MacroConsts = { MAX_ACCOUNT_MACROS = 3, MAX_CHARACTER_MACROS = 2 } }
    MAX_ACCOUNT_MACROS = 3
    MAX_CHARACTER_MACROS = 2
    SlashCmdList = {}
    CANCEL = "Cancel"
    combat = false
    function InCombatLockdown() return combat end
    function strlenutf8(value) return #value end

    accountMacros = {
        { name = "Twin", icon = 101, body = "/say first" },
        { name = "Twin", icon = 102, body = "/cast SecondSpell", spellID = 2002 },
    }
    characterMacros = {
        { name = "Solo", icon = 103, body = "/use Test Item", itemID = 3004 },
    }
    debugMessages = {}

    function GetNumMacros()
        return #accountMacros, #characterMacros
    end

    function GetMacroInfo(index)
        local macro
        if index <= MAX_ACCOUNT_MACROS then
            macro = accountMacros[index]
        else
            macro = characterMacros[index - MAX_ACCOUNT_MACROS]
        end
        if not macro then return nil end
        return macro.name, macro.icon, macro.body
    end

    local function GetNativeMacro(index)
        if index <= MAX_ACCOUNT_MACROS then
            return accountMacros[index]
        end
        return characterMacros[index - MAX_ACCOUNT_MACROS]
    end

    function GetMacroSpell(index)
        local macro = GetNativeMacro(index)
        return macro and macro.spellID or nil
    end

    function GetMacroItem(index)
        local macro = GetNativeMacro(index)
        if not macro or not macro.itemID then return nil end
        return "Test Item", "item:" .. macro.itemID .. ":0:0:0"
    end

    C_Item = {
        GetItemIDForItemInfo = function(itemInfo)
            return tonumber(type(itemInfo) == "string" and itemInfo:match("item:(%d+)") or itemInfo)
        end,
    }

    function CreateMacro(name, icon, body, perCharacter)
        local target = perCharacter and characterMacros or accountMacros
        local capacity = perCharacter and MAX_CHARACTER_MACROS or MAX_ACCOUNT_MACROS
        if #target >= capacity then return nil end
        target[#target + 1] = { name = name, icon = icon, body = body }
        return perCharacter and (MAX_ACCOUNT_MACROS + #target) or #target
    end

    function EditMacro(index, name, icon, body)
        local target, offset
        if index <= MAX_ACCOUNT_MACROS then
            target, offset = accountMacros, 0
        else
            target, offset = characterMacros, MAX_ACCOUNT_MACROS
        end
        local macro = target[index - offset]
        if not macro then return nil end
        macro.name = name or macro.name
        macro.icon = icon or macro.icon
        macro.body = body or macro.body
        return index
    end

    function DeleteMacro(index)
        if index <= MAX_ACCOUNT_MACROS then
            table.remove(accountMacros, index)
        else
            table.remove(characterMacros, index - MAX_ACCOUNT_MACROS)
        end
    end

    pickedUpMacros = {}
    function PickupMacro(index)
        pickedUpMacros[#pickedUpMacros + 1] = index
    end

    actionSlots = {
        -- Slot 3 contains macro index 1, but its resolved ID collides with macro index 2.
        [3] = { "macro", 2, nil, "Twin", 101 },
        [9] = { "spell", 9001, nil, nil, 9001 },
        [15] = { "macro", 2002, "spell", "Twin", 102 },
        [16] = { "macro", 2002, "spell", "Twin", 102 },
        [25] = { "macro", 3004, "item", "Solo", 103 },
    }
    actionInfoCalls = 0
    function GetActionInfo(slot)
        actionInfoCalls = actionInfoCalls + 1
        local action = actionSlots[slot]
        if not action then return nil end
        return action[1], action[2], action[3]
    end
    C_ActionBar = {
        GetActionText = function(slot) return actionSlots[slot] and actionSlots[slot][4] or nil end,
        GetActionTexture = function(slot) return actionSlots[slot] and actionSlots[slot][5] or nil end,
    }
    """
)

namespace = lua.table()
namespace.VERSION = "1.1.0"
namespace.MAX_BODY_LENGTH = 255
namespace.MAX_NAME_LENGTH = 16
namespace.DEFAULT_ICON = 134400
namespace.BODY_WARNING_LENGTH = 230
namespace.debug = False
namespace.Debug = lua.eval(
    r"""
    function(self, ...)
        if not self.debug then return end
        local parts = {}
        for index = 1, select("#", ...) do
            parts[index] = tostring(select(index, ...))
        end
        debugMessages[#debugMessages + 1] = table.concat(parts, " ")
    end
    """
)
namespace.Print = lua.eval("function() end")
globals_.MacroStudioDB = None

load_addon_file("Utils/Helpers.lua", namespace)
load_addon_file("MacroRepository.lua", namespace)
load_addon_file("ActionBarRepository.lua", namespace)
load_addon_file("MetadataRepository.lua", namespace)
load_addon_file("Search.lua", namespace)
load_addon_file("UI/MacroList.lua", namespace)
load_addon_file("UI/MainFrame.lua", namespace)

setup_namespace = load(
    r"""
    local _, ms = ...
    ms.db = {
        metadata = { records = {}, nextId = 1 },
        categories = { byId = {}, order = {}, nextId = 1 },
        settings = { window = {} },
    }
    """,
    "@preflight-setup",
)
setup_namespace("MacroStudio", namespace)

tests = load(
    r"""
    local _, ms = ...
    local repo = ms.MacroRepository
    local actionBars = ms.ActionBarRepository
    local metadata = ms.MetadataRepository
    local search = ms.Search

    local macros = repo:Refresh()
    assert(#macros == 3, "refresh should enumerate both scopes")
    assert(repo.accountCount == 2 and repo.characterCount == 1, "scope counts")
    assert(macros[1].duplicateName and macros[2].duplicateName, "duplicate detection")
    assert(macros[3].scope == "CHARACTER" and macros[3].index == 4, "character index offset")

    actionBars:Refresh()
    assert(actionBars:GetScanCount() == 1 and actionInfoCalls == actionBars.MAX_ACTION_SLOTS,
        "one refresh should scan the bounded native action-slot range once")
    local plainCount, plainSlots = actionBars:GetUsage(macros[1])
    local spellCount, spellSlots = actionBars:GetUsage(macros[2])
    local characterCount, characterSlots = actionBars:GetUsage(macros[3])
    assert(plainCount == 1 and plainSlots[1] == 3,
        "a plain macro should resolve by name plus fixed action texture")
    assert(spellCount == 2 and spellSlots[1] == 15 and spellSlots[2] == 16,
        "a spell-resolving macro should use its resolved spell ID, not treat it as an index")
    assert(characterCount == 1 and characterSlots[1] == 25,
        "an item-resolving Character macro should use exact item resolution")
    assert(spellSlots[1] ~= 3,
        "an action ID equal to macro index 2 must not falsely mark macro index 2")

    debugMessages = {}
    actionBars:Refresh()
    assert(#debugMessages == 0, "action scanning should stay quiet while debug mode is off")
    ms.debug = true
    actionBars:Refresh()
    local structuralLog
    for _, message in ipairs(debugMessages) do
        if message:find("action%-bar macro") and message:find("slot 3") then
            structuralLog = message
            break
        end
    end
    assert(structuralLog
            and structuralLog:find("type macro")
            and structuralLog:find("id 2")
            and structuralLog:find("subType nil")
            and structuralLog:find("text Twin")
            and structuralLog:find("resolvedIndex 1")
            and structuralLog:find("identity exact"),
        "debug mode should log non-sensitive structural identity diagnostics")
    assert(not structuralLog:find("/say") and not structuralLog:find("/cast"),
        "action diagnostics must never include macro bodies")
    ms.debug = false

    actionSlots[15] = { "spell", 9002 }
    actionSlots[16] = nil
    actionBars:Refresh()
    spellCount = actionBars:GetUsage(macros[2])
    assert(spellCount == 0, "removed and replaced spell-macro actions should disappear")
    plainCount = actionBars:GetUsage(macros[1])
    assert(plainCount == 1, "replacing another action must not affect the exact plain macro")

    actionSlots[15] = { "macro", 2002, "spell", "Twin", 102 }
    actionSlots[16] = { "macro", 2002, "spell", "Twin", 102 }
    actionBars:Refresh()
    spellCount, spellSlots = actionBars:GetUsage(macros[2])
    assert(spellCount == 2 and spellSlots[1] == 15 and spellSlots[2] == 16,
        "restored resolved macro actions should reappear after one refresh")

    accountMacros[2].icon = 101
    accountMacros[2].spellID = nil
    repo:Refresh()
    actionSlots[15] = { "macro", 2, nil, "Twin", 101 }
    actionSlots[16] = nil
    actionBars:Refresh()
    assert(actionBars:GetUsage(repo:FindByIndex(1)) == 0
            and actionBars:GetUsage(repo:FindByIndex(2)) == 0,
        "same-name macros with identical observable identity must remain ambiguous")
    accountMacros[2].icon = 102
    accountMacros[2].spellID = 2002
    actionSlots[15] = { "macro", 2002, "spell", "Twin", 102 }
    actionSlots[16] = { "macro", 2002, "spell", "Twin", 102 }
    macros = repo:Refresh()
    actionBars:Refresh()

    local firstTwin = ms.Helpers:CopyMacro(macros[1])
    local secondTwin = ms.Helpers:CopyMacro(macros[2])
    local solo = ms.Helpers:CopyMacro(macros[3])
    local picked, pickupTarget, pickupReason = repo:Pickup(firstTwin)
    assert(picked and pickupTarget.index == 1 and pickedUpMacros[#pickedUpMacros] == 1,
        "Account pickup should use the exact native index")
    picked, pickupTarget = repo:Pickup(secondTwin)
    assert(picked and pickupTarget.index == 2 and pickedUpMacros[#pickedUpMacros] == 2,
        "duplicate names should pick up the exact requested macro index")
    picked, pickupTarget = repo:Pickup(solo)
    assert(picked and pickupTarget.index == 4 and pickedUpMacros[#pickedUpMacros] == 4,
        "Character pickup should use the account-capacity offset index")

    local pickupCount = #pickedUpMacros
    combat = true
    picked, pickupTarget, pickupReason = repo:Pickup(secondTwin)
    assert(not picked and not pickupTarget and pickupReason:find("combat")
            and #pickedUpMacros == pickupCount,
        "combat should refuse pickup without changing the cursor payload")
    combat = false

    accountMacros[2].body = "/say externally changed"
    actionBars:Refresh()
    spellCount = actionBars:GetUsage(secondTwin)
    assert(spellCount == 0,
        "usage should be omitted when the cached macro identity no longer matches its native index")
    picked, pickupTarget, pickupReason = repo:Pickup(secondTwin)
    assert(not picked and not pickupTarget and pickupReason:find("changed")
            and #pickedUpMacros == pickupCount,
        "stale snapshots should refuse pickup instead of targeting the current index occupant")
    accountMacros[2].body = "/cast SecondSpell"
    repo:Refresh()
    actionBars:Refresh()
    spellCount = actionBars:GetUsage(secondTwin)
    assert(spellCount == 2, "usage should return after exact native identity reconciliation")

    local valid, reason = repo:ValidateCreateRequest({
        name = "", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid and reason:find("name"), "blank names should fail")
    valid = repo:ValidateCreateRequest({
        name = "ThisNameIsFarTooLong", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid, "long names should fail")
    combat = true
    valid, reason = repo:ValidateCreateRequest({
        name = "Blocked", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid and reason:find("Combat"), "combat should block creation")
    combat = false

    local created, createdMacro = repo:Create({
        name = "New", body = "/say new", icon = 104, scope = "ACCOUNT",
    })
    assert(created and createdMacro and createdMacro.index == 3, "create should return exact new macro")
    actionSlots[40] = { "macro", 2, nil, "New", 104 }
    actionBars:Refresh()
    local createdCount = actionBars:GetUsage(createdMacro)
    assert(createdCount == 1, "plain macros should resolve without using the returned ID as an index")
    valid, reason = repo:ValidateCreateRequest({
        name = "Full", body = "", icon = 134400, scope = "ACCOUNT",
    })
    assert(not valid and reason:find("full"), "capacity should block creation")

    local deleted, deleteReason = repo:Delete(secondTwin)
    assert(deleted, deleteReason)
    assert(accountMacros[1].body == firstTwin.body, "delete should preserve first duplicate")
    assert(accountMacros[2].name == "New", "delete should target duplicate by exact index")
    actionSlots[3] = nil
    actionSlots[15] = nil
    actionSlots[16] = nil
    actionSlots[40] = { "macro", 1, nil, "New", 104 }
    actionBars:Refresh()
    local shiftedMacro = repo:FindByIndex(2)
    local shiftedCount, shiftedSlots = actionBars:GetUsage(shiftedMacro)
    spellCount = actionBars:GetUsage(secondTwin)
    assert(shiftedCount == 1 and shiftedSlots[1] == 40 and spellCount == 0,
        "index changes should reconcile to the exact current snapshot without retaining stale usage")
    deleted = repo:Delete(secondTwin)
    assert(not deleted, "stale snapshot should not delete shifted neighbor")
    assert(accountMacros[2].name == "New", "stale delete must leave neighbor intact")

    combat = true
    deleted, deleteReason = repo:Delete(ms.Helpers:CopyMacro(repo:GetAll()[1]))
    assert(not deleted and deleteReason:find("Combat"), "combat should block deletion")
    combat = false

    metadata:Reconcile(repo:GetAll())
    local first = repo:GetAll()[1]
    local second = repo:GetAll()[2]
    metadata:ToggleFavorite(first)
    local ok, tag = metadata:AddTag(first, "Raid")
    assert(ok and tag == "Raid", "new tag")
    ok = metadata:AddTag(first, "raid")
    assert(not ok, "assigned tags should be rejected case-insensitively")
    ok, tag = metadata:AddTag(second, "raid")
    assert(ok and tag == "Raid", "existing tag spelling should be canonical")
    assert(#metadata:GetAllTags() == 1, "tag choices should be unique")
    local category = metadata:CreateCategory("Mythic+")
    assert(category and metadata:SetCategory(first, category.id), "search category setup")
    local metadataBeforePickup = metadata:GetPresentation(first)
    pickupCount = #pickedUpMacros
    picked, pickupTarget, pickupReason = repo:Pickup(first)
    local metadataAfterPickup = metadata:GetPresentation(first)
    assert(picked and pickupTarget.index == first.index and #pickedUpMacros == pickupCount + 1,
        pickupReason or "metadata pickup should succeed")
    assert(metadataAfterPickup.favorite == metadataBeforePickup.favorite
            and metadataAfterPickup.categoryId == metadataBeforePickup.categoryId
            and table.concat(metadataAfterPickup.tags, "\031")
                == table.concat(metadataBeforePickup.tags, "\031"),
        "pickup must not change categories, tags, or Favorites")

    assert(search:Matches(first, "TWIN"), "search should match names case-insensitively")
    assert(search:Matches(first, "say first"), "search should match the complete body")
    assert(search:Matches(first, "RAID"), "search should match tags case-insensitively")
    assert(search:Matches(first, "mythic+"), "search should match assigned category names")
    assert(not search:Matches(first, "missing"), "unmatched search should reject the macro")

    ms.activeFilter = { kind = "favorites" }
    ms.searchQuery = "twin"
    local filtered = ms:GetFilteredMacros()
    assert(#filtered == 1 and filtered[1].name == "Twin",
        "navigation and search should combine against the in-memory repository")
    ms.activeFilter = { kind = "account" }
    ms.searchQuery = "new"
    filtered = ms:GetFilteredMacros()
    assert(#filtered == 1 and filtered[1].name == "New", "Account plus search")
    ms.activeFilter = { kind = "all" }
    ms.searchQuery = ""

    local _, firstRecordId = metadata:GetRecordForMacro(first)
    metadata:OnMacroDeleted(first, firstRecordId)
    assert(metadata:GetRecords()[firstRecordId] == nil, "deleted macro metadata should be removed")
    metadata:Reconcile({ second })
    assert(not metadata:IsFavorite(second), "neighbor must not inherit deleted favorite metadata")

    local list = ms.MacroList
    local sectionTitles = {}
    local emptyMessage
    list.ReleaseVisibleItems = function(self)
        self.visibleRows, self.visibleHeaders, self.visibleEmptyLabels = {}, {}, {}
    end
    list.AddSection = function(self, title, sectionMacros, y, showEmpty)
        if #sectionMacros == 0 and not showEmpty then return y, false end
        sectionTitles[#sectionTitles + 1] = title
        return y + 1, true
    end
    list.AddEmptyMessage = function(self, message, y)
        emptyMessage = message
        return y + 1
    end
    list.SetSelected = function() end
    list.scrollChild = { SetHeight = function() end }
    list.scrollFrame = { GetHeight = function() return 100 end }

    sectionTitles = {}
    list:Rebuild({ first, second }, nil, { kind = "all" })
    assert(#sectionTitles == 2, "All should render both scope headers")
    sectionTitles = {}
    list:Rebuild({ first }, nil, { kind = "account" })
    assert(#sectionTitles == 1 and sectionTitles[1] == "ACCOUNT MACROS", "Account filter header")
    sectionTitles = {}
    list:Rebuild({ second }, nil, { kind = "favorites" })
    assert(#sectionTitles == 1, "organization filters should omit empty scope headers")
    sectionTitles = {}
    list:Rebuild({ first }, nil, { kind = "all" }, "twin")
    assert(#sectionTitles == 1 and sectionTitles[1] == "ACCOUNT MACROS",
        "active search should suppress empty scope sections")
    sectionTitles = {}
    emptyMessage = nil
    list:Rebuild({}, nil, { kind = "all" }, "mouseover")
    assert(#sectionTitles == 0 and emptyMessage == 'No macros match "mouseover".',
        "empty search should show one query-specific message")
    """,
    "@preflight-tests",
)
tests("MacroStudio", namespace)

macro_list_source = (ROOT / "UI" / "MacroList.lua").read_text(encoding="utf-8")
sidebar_source = (ROOT / "UI" / "Sidebar.lua").read_text(encoding="utf-8")
editor_source = (ROOT / "UI" / "Editor.lua").read_text(encoding="utf-8")
macro_dialog_source = (ROOT / "UI" / "MacroDialog.lua").read_text(encoding="utf-8")
main_frame_source = (ROOT / "UI" / "MainFrame.lua").read_text(encoding="utf-8")
icon_picker_source = (ROOT / "UI" / "IconPicker.lua").read_text(encoding="utf-8")
search_source = (ROOT / "Search.lua").read_text(encoding="utf-8")
helpers_source = (ROOT / "Utils" / "Helpers.lua").read_text(encoding="utf-8")
dialogs_source = (ROOT / "UI" / "Dialogs.lua").read_text(encoding="utf-8")
repository_source = (ROOT / "MacroRepository.lua").read_text(encoding="utf-8")
action_bar_source = (ROOT / "ActionBarRepository.lua").read_text(encoding="utf-8")
core_source = (ROOT / "Core.lua").read_text(encoding="utf-8")

assert 'SetAtlas("PetJournal-FavoritesIcon")' in macro_list_source
assert 'atlas = "PetJournal-FavoritesIcon"' in sidebar_source and "SetAtlas(atlas)" in sidebar_source
assert 'SetAtlas("PetJournal-FavoritesIcon")' in editor_source
assert "favoritePrefix" not in macro_list_source
assert '"ScrollingEditBoxTemplate"' in helpers_source
assert "SetMouseClickEnabled(true)" in helpers_source
assert "SetMouseMotionEnabled(true)" in helpers_source
assert "CreateNativeScrollingEditBox(editBorder, 5)" in editor_source
assert "CreateNativeScrollingEditBox(bodyBorder, 5)" in macro_dialog_source
assert '"OnCursorChanged"' not in helpers_source
assert "CreateOverlayBorder(editBorder, scrollBar, 2)" in editor_source
assert "#ms.Editor.editorFocusBorderEdges == 4" in (ROOT / "tests" / "ui_smoke.py").read_text(encoding="utf-8")
assert "modalOverlay:EnableMouse(true)" in main_frame_source
assert "modalOverlay:EnableMouseWheel(true)" in main_frame_source
assert "SetMainWindowModalBlocked(true)" in macro_dialog_source
assert "SetMainWindowModalBlocked(false)" in macro_dialog_source
assert 'titleBar:RegisterForDrag("LeftButton")' in macro_dialog_source
assert "getIconIdentity" in icon_picker_source and "GetFileIDFromPath" in icon_picker_source
assert 'basename == "inv_misc_questionmark"' in icon_picker_source
assert "macro.name" in search_source and "macro.body" in search_source
assert "presentation.categoryName" in search_source and "presentation.tags" in search_source
assert "MacroRepository" not in search_source and "SavedVariables" not in search_source
assert 'searchBox:HookScript("OnTextChanged"' in macro_list_source
assert 'searchBox:HookScript("OnEscapePressed"' in macro_list_source
assert "self:RefreshMacroList()" in main_frame_source
assert 'self.activeFilter = { kind = "all" }\n    if macro then' not in main_frame_source
assert '"OnEnterPressed"' in dialogs_source and '"OnEscapePressed"' in dialogs_source
assert 'button:RegisterForDrag("LeftButton")' in macro_list_source
assert 'button:SetScript("OnDragStart"' in macro_list_source
assert "PickupMacro(current.index)" in repository_source
assert "ClearCursor" not in repository_source and "PlaceAction" not in repository_source
assert "RequestPickupMacro" in main_frame_source
assert 'GetActionInfo(slot)' in action_bar_source and 'actionType == "macro"' in action_bar_source
assert "FindByIndex(actionID)" not in action_bar_source
assert "GetMacroSpell" in action_bar_source and "GetMacroItem" in action_bar_source
assert "GetActionText" in action_bar_source and "GetActionTexture" in action_bar_source
assert '"resolvedIndex"' in action_bar_source and '"identity"' in action_bar_source
assert "GetActionInfo" not in macro_list_source and "GetActionInfo" not in editor_source
assert "GetMacroSpell" not in macro_list_source and "GetMacroItem" not in editor_source
assert 'SetScript("OnUpdate"' not in action_bar_source and 'SetScript("OnUpdate"' not in main_frame_source
assert 'ACTIONBAR_SLOT_CHANGED = true' in core_source
assert 'PLAYER_ENTERING_WORLD = true' in core_source
assert 'UPDATE_BONUS_ACTIONBAR = true' in core_source
assert 'UPDATE_VEHICLE_ACTIONBAR = true' in core_source
assert 'UPDATE_OVERRIDE_ACTIONBAR = true' in core_source
assert 'C_Timer.After(0, refresh)' in main_frame_source

run_ui_smoke(ROOT)
print("PASS MacroStudio 1.1.0 preflight")
