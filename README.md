# MacroStudio

MacroStudio is a standalone World of Warcraft Retail addon for editing, organizing, creating, and deleting Blizzard-native macros. Version 0.2.2 completes Milestone 2.1: UX polish and safe native macro management.

MacroStudio does not replace WoW's macro execution system. Saved and created macros remain ordinary Blizzard macros that work when MacroStudio is disabled. Categories, Favorites, and tags are local MacroStudio organization metadata.

## Current features

- `/macrostudio` and `/ms` toggle a movable, resizable three-column workspace. The window stays closed after login and `/reload` until explicitly opened.
- Account and Character filters show only their relevant section. All shows both; Favorites and category filters omit empty sections.
- Macro rows show native icons, names, body lengths, first-line previews, duplicate warnings, and an atlas-based Favorite marker.
- The multiline editor uses native mouse caret placement, drag selection, keyboard navigation, copy/paste, and scrolling.
- Dirty, character-limit, Save, Revert, Delete, conflict, and combat eligibility update from the current editor buffer.
- Save is permitted only for a selected, dirty, current target at or below 255 characters and outside combat. Every write revalidates immediately before using the native API.
- Create a native Account or Character macro with a name, body, icon picker, scope, capacity feedback, and visible validation.
- Delete the exact selected native macro after explicit scope/name confirmation. Dirty, conflicted, stale, or combat-locked targets cannot be deleted.
- Create, rename, delete, assign, and remove virtual categories with inline validation and Enter/Escape keyboard flow.
- Toggle Favorites using Blizzard's reliable Favorite atlas.
- Select existing tags or choose **Create New Tag...**; assigned tags are hidden and invalid input stays visible for correction.
- Clean external changes reload on `UPDATE_MACROS`; dirty buffers are preserved in a blocked conflict state.
- Metadata uses opaque record IDs and conservative reconciliation. Deleting a macro through MacroStudio removes only that macro's metadata before indexes can be reconciled.
- Window position and size are remembered. Debug logging is optional and off by default.

Search is intentionally not part of Milestone 2.1. Duplicate Macro was optional and remains deferred. See [ROADMAP.md](ROADMAP.md).

## Slash commands

- `/macrostudio` or `/ms` - toggle MacroStudio.
- `/ms refresh` - force a fallback native macro refresh and open the window.
- `/ms debug [on|off]` - toggle or set development logging.
- `/ms help` - print the command summary.

There is no visible Refresh button, because normal updates are event-driven. MacroStudio does not override Blizzard's `/macro` command.

## Installation

Place the addon directory at:

```text
<World of Warcraft>\_retail_\Interface\AddOns\MacroStudio
```

The directory containing `MacroStudio.toc` must be named `MacroStudio`. Restart WoW if this is the first installation, enable MacroStudio at character selection, log in, and run `/macrostudio`.

## Development setup on Windows

The repository root is also the addon root. A common Retail AddOns directory is:

```text
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns
```

From the repository root, create a development Junction:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-junction.ps1" -AddOnsPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
```

The script refuses to replace a real directory, file, unexpected reparse point, or differently targeted Junction. Confirm the link with:

```powershell
Get-Item "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\MacroStudio" |
    Format-List FullName, LinkType, Target
```

Remove only the Junction with:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\remove-junction.ps1" -AddOnsPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
```

## Repository modules

- `Core.lua` - namespace, constants, events, combat state, and logging.
- `Database.lua` - non-destructive SavedVariables initialization and migration.
- `MacroRepository.lua` - native enumeration, exact snapshots, capacity, validation, Save, Create, and Delete.
- `MetadataRepository.lua` - categories, Favorites, tags, opaque records, cleanup, and reconciliation.
- `Utils/Helpers.lua` - string/UI helpers and shared native EditBox behavior.
- `UI/Dialogs.lua` - validated category/tag input and destructive confirmations.
- `UI/IconPicker.lua` - virtualized native macro icon chooser.
- `UI/MacroDialog.lua` - native macro creation form.
- `UI/Sidebar.lua` - built-in and category navigation.
- `UI/MacroList.lua` - filter-aware scope sections and rows.
- `UI/Editor.lua` - draft buffer, derived action eligibility, and metadata controls.
- `UI/MainFrame.lua` - lifecycle, filters, native mutation coordination, and slash commands.
- `tests/preflight.py` - Lua compilation plus stubbed macro/metadata/filter regression tests.

## Known limitations

- Renaming an existing native macro, changing its icon/scope, and duplicating it are not implemented.
- Blizzard's 255-character limit is enforced. Longer drafts remain visible but cannot be saved.
- Macro indexes are transient handles. Ambiguous unresolved metadata is preserved without guessing.
- Organization metadata does not alter Blizzard's Macro UI or sync through Blizzard macro storage.
- Search, history/Trash, linting, templates, and action-bar awareness remain future work.
- Reloading the UI cannot preserve an unsaved in-memory draft.
- Native caret/selection feel, protected API behavior, and final layout require the in-game checks in [TESTING.md](TESTING.md).
