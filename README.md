# MacroStudio

MacroStudio is a standalone World of Warcraft Retail addon that provides a larger, safer editor and organization workspace for Blizzard-native macros. Version 0.2.1 completes the reactive editor update (Milestone 1.1), the first organization milestone (Milestone 2), and a Retail multiline-editor compatibility fix.

MacroStudio never replaces the macro execution system. Every saved macro remains an ordinary Blizzard macro and continues to work if MacroStudio is disabled or removed. Categories, favorites, and tags are virtual organization data stored only by MacroStudio.

## Current features

- `/macrostudio` and `/ms` toggle a movable, resizable three-column workspace.
- The left sidebar filters Favorites, All, Account, Character, and user-created categories.
- Account and character macros remain clearly separated in the macro list.
- Each row shows the icon, name, favorite state, body length, first-line preview, and duplicate-name warning.
- The editor supports multiline text, selection, copy, paste, scrolling, Save, and Revert.
- Typing immediately updates the character count, dirty indicator, Save state, and Revert state. Refresh is not part of the editing workflow.
- Programmatic loads and refreshes do not falsely mark the editor dirty.
- The 255-character limit is enforced without truncating an over-limit draft.
- Switching macros with unsaved text requires confirmation.
- Clean external changes reload automatically on `UPDATE_MACROS`; dirty buffers are preserved and placed in a conflict state.
- Combat keeps the window and draft usable while blocking native saves. Leaving combat never auto-saves.
- Create, rename, and delete virtual categories without modifying or deleting Blizzard macros.
- Assign one optional category, toggle Favorite, and add or remove multiple tags per macro.
- SavedVariables schema 2 stores organization records under opaque IDs and reconciles them conservatively after index movement.
- Ambiguous duplicate macros are reported rather than guessed.
- Window position and size are remembered.
- Optional debug logging is off by default.

Search, macro creation/deletion, history, linting, templates, and action-bar awareness are later milestones. See [ROADMAP.md](ROADMAP.md).

## Slash commands

- `/macrostudio` or `/ms` - toggle the MacroStudio window.
- `/ms refresh` - force a fallback native macro refresh and open the window.
- `/ms debug` - toggle development logging.
- `/ms debug on` / `/ms debug off` - explicitly set development logging.
- `/ms help` - print the command summary.

MacroStudio does not override Blizzard's `/macro` command.

## Normal installation

Place the repository/addon directory at:

```text
<World of Warcraft>\_retail_\Interface\AddOns\MacroStudio
```

The directory containing `MacroStudio.toc` must be named `MacroStudio`. Restart WoW if this is the first installation, enable MacroStudio on the character-selection AddOns screen, log in, and run `/macrostudio`.

## Development setup on Windows

Clone or open the repository. The repository root is also the addon root: `MacroStudio.toc` is directly inside it.

A common Retail AddOns directory is:

```text
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns
```

Use the actual Battle.net installation location when it differs. From the repository root, create a development Junction:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-junction.ps1" -AddOnsPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
```

This creates:

```text
...\Interface\AddOns\MacroStudio  ->  <this Git repository>
```

The script refuses to replace a real directory, file, unexpected reparse point, or differently targeted Junction. It never recursively deletes an existing addon folder.

Confirm the Junction with:

```powershell
Get-Item "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\MacroStudio" |
    Format-List FullName, LinkType, Target
```

The expected `LinkType` is `Junction`, and `Target` should be this repository. Restart WoW the first time so it discovers the addon. After changing Lua or TOC files, use `/reload` when appropriate.

Remove only the Junction with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\remove-junction.ps1" -AddOnsPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
```

The removal script verifies the destination before acting and leaves the Git repository and target files untouched.

## Repository modules

- `Core.lua` - namespace, constants, events, combat state, and debug logging.
- `Database.lua` - non-destructive SavedVariables schema initialization and migration.
- `MacroRepository.lua` - the only native macro enumeration/editing layer, including duplicate detection.
- `MetadataRepository.lua` - categories, favorites, tags, opaque metadata records, and conservative reconciliation.
- `Utils/Helpers.lua` - small UI, string, and snapshot helpers.
- `UI/Dialogs.lua` - discard and organization confirmation/input dialogs.
- `UI/Sidebar.lua` - scope, favorites, and category navigation.
- `UI/MacroList.lua` - scoped macro sections and selectable rows.
- `UI/Editor.lua` - edit buffer, reactive state, validation, and per-macro organization controls.
- `UI/MainFrame.lua` - window lifecycle, filters, selection, refresh, Save, and Revert orchestration.
- `scripts/*.ps1` - safe Windows development Junction setup/removal.

## Known limitations

- Version 0.2.1 edits only macro bodies. Renaming, icon changes, creation, duplication, deletion, and scope changes are postponed.
- Blizzard's native 255-character limit is enforced. Longer drafts remain visible but cannot be saved.
- Macro indexes are current enumeration handles, not durable identities. Unresolved metadata stays preserved but unattached when reconciliation is ambiguous.
- Categories, favorites, and tags are local SavedVariables metadata. They do not change Blizzard's Macro UI or sync through Blizzard's macro storage.
- Search is not part of Milestone 2.
- Reloading the UI cannot preserve an unsaved in-memory draft.
- Protected API behavior and visual layout still require the in-game checks in [TESTING.md](TESTING.md).
