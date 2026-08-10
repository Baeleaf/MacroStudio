# MacroStudio

**A modern macro editor and organizer for World of Warcraft.**

MacroStudio provides a larger, safer workspace for creating, editing, organizing, searching, and deleting World of Warcraft Retail macros. It manages Blizzard-native macros rather than replacing the macro system, so saved macros continue to work normally when MacroStudio is disabled. Open it in game with `/ms` or `/macrostudio`.

Version 1.0.0 is the initial public-release candidate.

## Screenshots

### Main macro editor and organization

![MacroStudio main editor with navigation, macro list, and native macro editing workspace](screenshots/main-editor.png)

A resizable workspace for Account and Character navigation, macro editing, categories, tags, Favorites, and live character-limit feedback.

| Live macro search | Native macro creation |
| :--: | :--: |
| <img src="screenshots/search.png" alt="MacroStudio live search showing matching native macros" width="380"> | <img src="screenshots/new-macro.png" alt="MacroStudio native macro creation dialog" width="720"> |
| Search names, complete bodies, categories, and tags while refining the active navigation view. | Create an Account or Character macro with scope, icon, body, capacity, and validation controls. |

## Overview

Blizzard's default macro window is compact and offers limited organization. MacroStudio adds a resizable three-column workspace with Account and Character navigation, live search, categories, tags, Favorites, and a full multiline editor.

Native macro changes are synchronized automatically from Blizzard events. Unsaved drafts are protected from external changes, writes are disabled during combat, and Save, Create, and Delete operations are revalidated immediately before MacroStudio calls the native API.

## Features

- Large, movable, resizable multiline macro editor with native caret placement, selection, keyboard navigation, and scrolling.
- Live, case-insensitive search by macro name, complete body, assigned category name, or tag.
- Combined All, Account, Character, Favorites, and category navigation filters.
- Virtual categories, multiple tags, and Favorites without changing native macro contents.
- Native Account and Character macro creation with name, body, scope, icon, capacity, and character-limit validation.
- Confirmed native macro deletion with dirty-state, conflict, stale-target, and combat protections.
- Live 255-character validation, dirty-state tracking, Save, Revert, and discard confirmation.
- Automatic synchronization when Blizzard macros change; dirty drafts remain visible in a protected conflict state.
- Combat-safe editing behavior that blocks protected writes without discarding the current draft or creation form.
- Window position and size persistence, scope-aware duplicate warnings, and optional debug logging.

Categories, tags, Favorites, and window settings are stored as MacroStudio metadata. Macro bodies themselves remain standard native World of Warcraft macros.

## Installation

1. Download the latest MacroStudio ZIP from [GitHub Releases](https://github.com/Baeleaf/MacroStudio/releases).
2. Extract the ZIP into the WoW Retail AddOns directory:

   ```text
   <World of Warcraft>\_retail_\Interface\AddOns
   ```

3. Confirm the resulting path is:

   ```text
   <World of Warcraft>\_retail_\Interface\AddOns\MacroStudio\MacroStudio.toc
   ```

4. Restart World of Warcraft, or run `/reload` when updating an existing installation. Enable MacroStudio at character selection if needed.
5. Run `/ms` or `/macrostudio` to open the editor.

## Usage

Open MacroStudio with `/ms`, then select All, Account, Character, Favorites, or a category in the left sidebar. Use the search field to refine the current view by name, body text, category, or tag.

Select a macro to edit its body. Save writes the current valid draft to the selected native macro; Revert restores its last synchronized body. New Macro creates an Account or Character macro through a validation dialog. Delete always requires confirmation and targets the exact selected native macro.

Organization controls in the editor assign categories, tags, and Favorite status. These labels are local to MacroStudio and do not alter Blizzard's Macro UI.

## Slash Commands

- `/macrostudio` or `/ms` - toggle the MacroStudio window.
- `/ms help` - show the command summary.
- `/ms debug [on|off]` - inspect or change development logging.
- `/ms refresh` - manually resynchronize native macros and open MacroStudio. Normal synchronization is automatic; use this only as a troubleshooting fallback.

MacroStudio does not override Blizzard's `/macro` command.

## Current Limitations

- Macros cannot yet be dragged directly from MacroStudio onto action bars.
- Profile import/export and selective macro import/export are not implemented.
- History, backups, recoverable Trash, and version restoration are not implemented.
- Advanced macro linting, syntax analysis, and templates/snippets are not implemented.
- There is no minimap or addon-compartment launcher.
- Existing native macros cannot yet be renamed or have their icon/scope changed from MacroStudio, and Duplicate Macro is not implemented.
- Search is plain-text substring matching; advanced field syntax is not available.
- The search query resets on `/reload` or logout, and unsaved in-memory drafts cannot survive a UI reload.

See the [public roadmap](ROADMAP.md) for planned work. Planned features are not promises or release dates.

## Planned Features

High-priority future work includes native action-bar dragging and usage inspection, profile and selective import/export, history/versioning, templates, linting, and an addon-compartment or minimap launcher. Optional `/m` behavior will only be considered if it can coexist safely with Blizzard's `/macro` workflow.

## Reporting Bugs

Use [GitHub Issues](https://github.com/Baeleaf/MacroStudio/issues) for bug reports and feature requests. Include the MacroStudio version, current WoW Retail version, clear reproduction steps, Lua errors, and relevant addon interactions. The repository provides guided issue forms for both report types.

## Development

The repository root is also the addon root. On Windows, the included Junction helper can expose the working tree directly to WoW without copying files:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\scripts\setup-junction.ps1" -AddOnsPath "<Retail AddOns directory>"
```

Run the automated preflight from the repository root with Python 3 and `lupa` installed:

```powershell
py .\tests\preflight.py
```

Build a runtime-only release candidate with:

```powershell
.\scripts\package.ps1 -Version 1.0.0
```

Development architecture and live-client checks are documented in [ARCHITECTURE.md](ARCHITECTURE.md) and [TESTING.md](TESTING.md). See [CONTRIBUTING.md](CONTRIBUTING.md) before submitting a pull request.

## License

MacroStudio is available under the [MIT License](LICENSE). Copyright (c) 2026 Baeleaf.
