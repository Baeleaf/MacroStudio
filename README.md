# MacroStudio

MacroStudio is a standalone World of Warcraft Retail addon that provides a larger, safer editor for Blizzard-native macros. Its long-term direction is a lightweight macro IDE, but version 0.1.0 deliberately implements only the Milestone 1 proof of concept.

MacroStudio never replaces the macro execution system. Every saved macro remains an ordinary Blizzard macro and continues to work if MacroStudio is disabled or removed.

## Current status

Implemented in Milestone 1:

- `/macrostudio` and `/ms` toggle a movable, resizable editor.
- Account and character macros are displayed in separately labeled sections.
- Each row shows the macro icon, name, body length, and first-line preview.
- The editor supports multiline text, selection, copy, paste, scrolling, Save, and Revert.
- A live counter distinguishes normal (`0–229`), approaching-limit (`230–255`), and invalid (`256+`) states.
- Save is enabled only for a dirty, valid, still-current selection outside combat.
- Switching macros with unsaved text requires confirmation.
- `UPDATE_MACROS` and the Refresh button synchronize changes made in Blizzard's macro UI.
- Combat keeps the window and draft visible while blocking native saves; leaving combat never auto-saves.
- Window position and size are stored in `MacroStudioDB`.
- Optional debug logging is off by default.

Planned organization, search, macro creation/deletion, backups, linting, and templates are documented in [ROADMAP.md](ROADMAP.md) and are intentionally not implemented yet.

## Slash commands

- `/macrostudio` or `/ms` — toggle the MacroStudio window.
- `/ms refresh` — refresh native macro data and open the window.
- `/ms debug` — toggle development logging.
- `/ms debug on` / `/ms debug off` — explicitly set development logging.
- `/ms help` — print the command summary.

MacroStudio does not override Blizzard's `/macro` command.

## Normal installation

For a normal local installation, place the repository/addon directory at:

```text
<World of Warcraft>\_retail_\Interface\AddOns\MacroStudio
```

The directory containing `MacroStudio.toc` must be named `MacroStudio`. Restart WoW if this is the first installation, enable MacroStudio on the character-selection AddOns screen, log in, and run `/macrostudio`.

For active development on Windows, use the Junction workflow below so the Git repository can remain outside the game installation.

## Development Setup — Windows

### 1. Clone or open the repository

```powershell
git clone <repository-url>
cd MacroStudio
```

The repository root is also the addon root: `MacroStudio.toc` is directly inside it.

### 2. Find the Retail AddOns directory

A common path is:

```text
C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns
```

That is only an example. Use the actual location selected in Battle.net if WoW is installed elsewhere.

### 3. Create the development Junction

From the repository root, run:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-junction.ps1" -AddOnsPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
```

The script resolves the repository from its own location and creates:

```text
...\Interface\AddOns\MacroStudio  ->  <this Git repository>
```

It refuses to replace a real directory, file, or unexpected reparse point. It also refuses to retarget an existing Junction. It never recursively deletes an existing addon folder.

### 4. Confirm the Junction

```powershell
Get-Item "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns\MacroStudio" |
    Format-List FullName, LinkType, Target
```

The expected `LinkType` is `Junction`, and `Target` should be this repository.

### 5. Test in WoW

1. Completely restart WoW the first time so it discovers the addon.
2. On the character-selection screen, open **AddOns**.
3. Confirm **MacroStudio** appears and is enabled.
4. Log in and run `/macrostudio`.
5. After changing Lua or TOC files while logged in, use `/reload` when appropriate.

### 6. Remove the Junction

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\remove-junction.ps1" -AddOnsPath "C:\Program Files (x86)\World of Warcraft\_retail_\Interface\AddOns"
```

The removal script verifies that the destination is a Junction before acting. It refuses to delete an ordinary directory and removes only the Junction itself. The Git repository and all files in its target are left untouched.

## Repository modules

- `Core.lua` — addon namespace, constants, events, combat state, and debug logging.
- `Database.lua` — migration-friendly, non-destructive SavedVariables initialization.
- `MacroRepository.lua` — the only native macro enumeration/editing layer.
- `Utils/Helpers.lua` — small UI, string, and snapshot helpers.
- `UI/MainFrame.lua` — window lifecycle, selection flow, Save/Revert orchestration, and slash commands.
- `UI/MacroList.lua` — scope sections and selectable macro rows.
- `UI/Editor.lua` — macro metadata, edit buffer, counter, validation, and controls.
- `scripts/*.ps1` — safe Windows development Junction setup/removal.

## Known limitations

- Milestone 1 edits only macro bodies. Renaming, icon changes, creation, duplication, deletion, and scope changes are postponed.
- Blizzard's native 255-character limit is enforced. Longer drafts remain visible but cannot be saved.
- Macro indexes are treated as current enumeration handles, not durable identities. Ambiguous external changes are blocked instead of guessed.
- No categories, tags, favorites, history, linter, syntax highlighting, or action-bar usage view exist yet.
- UI behavior and protected macro edits still require the in-game checks in [TESTING.md](TESTING.md).

## GitHub remote (optional follow-up)

If this local repository does not yet have a remote and GitHub CLI is installed and authenticated, run from the repository root:

```powershell
gh auth status
gh repo create MacroStudio --private --source . --remote origin --push
```

First confirm that a repository named `MacroStudio` does not already exist in the intended GitHub account. No license is included at this stage.
