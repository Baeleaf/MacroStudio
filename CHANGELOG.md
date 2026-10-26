# Changelog

Notable user-facing changes to MacroStudio are documented here.

## 1.4.0

### Added

- One shared MacroStudio macro library available across all characters, independent of Blizzard's native macro slot limits. Existing development-build Account and Character entries are preserved and upgraded automatically.
- Per-character keybindings for MacroStudio macros, with conflict checks and automatic key release in vehicles, pet battles, and override bars.
- A themed Keybind button below Category and Tags shows Not Bound or the assigned key. Left-click to capture a keyboard key, middle/extra mouse button, or scroll direction; Esc cancels and right-click clears. Bindings apply immediately without a separate dialog.
- A Copy to dropdown for read-only snapshots offers Current Character, Account Macros, or MacroStudio Macros. Copies preserve the name, icon and body without changing the source; full native destinations are disabled individually, while shared MacroStudio storage remains available.
- Drag saved macros onto action bars from either a list row or the editor icon. Shared MacroStudio macros create a linked native copy, reuse it on later drags, and keep it updated when saved. Each linked copy needs one free Character or Account macro slot; shared storage and direct keybindings remain independent of those limits.
- One Color Style selector with Warcraft (default), Legacy, Emerald, Violet, and Ember. Legacy includes its original blue/gray design; the separate Appearance section is removed.
- Advisory macro linting while editing saved macros, unsaved drafts, and read-only offline snapshots, in both Warcraft and Legacy appearances.
- Line-specific explanations for malformed leading cast/use/castsequence brackets, commands without action arguments, and repeated `#showtooltip` directives.
- A compact diagnostics summary beside the character count; hover to inspect and click/scroll to browse every finding. Findings never block Save or correct text automatically.

Static checks cannot guarantee gameplay or combat success. Lua syntax validation and broader command support remain follow-up work.

### Changed

- Make the Create Macro type explicit with Account, Character, and MacroStudio (shared) radio choices and a matching submit label.
- Release the shared macro library, inline keybindings, snapshot copy destinations, named color styles and advisory macro checks as `1.4.0`. Style and design changes use the existing explicit Reload UI action and protect unsaved drafts.

## 1.3.1

### Added

- Search the icon picker by raid marker names, icon file ID, full ability name, or partial spellbook ability name in both the editor and New Macro dialog.
- All eight raid target markers are available in the icon picker.

### Fixed

- Normalize numeric icon strings, bare icon names, and texture paths before native writes and save verification, preventing false save failures when WoW returns the chosen icon as a file ID.

## 1.3.0

### Added

- Choose Warcraft (default) or the original blue/gray Legacy appearance in Settings. The choice is saved; Reload UI applies it without resetting macros or organization data.

### Changed

- Redesigned MacroStudio as a Warcraft-native workbench with a sculpted metal frame, textured charcoal interior and recessed editor.
- Integrated an original scroll-and-quill medallion into the title frame and matching launchers.
- Unified Library, Macros and Macro Editor inside one shared inset with subtle engraved column separation.
- Applied native button states, inset search fields, physical scope tabs and full scrollbars with track, thumb and arrows.
- Matched secondary dialogs to the main window and integrated Settings into the bottom frame.
- Refined title emphasis, secondary-text readability and editor depth while preserving the existing macro workflows and saved-data format.
- Updated Retail compatibility to WoW 12.1.5 (Interface `120105`).

### Distribution

- Package only the addon runtime and original emblem, with the MIT license included. Development tools, tests, screenshots and editable artwork are excluded.

## 1.2.0

### Added

- See which macros are currently placed on your action bars.
- Browse Character macros from other characters used with MacroStudio and copy them to the current character.
- Edit existing macro names and icons directly in MacroStudio.
- Use MacroStudio as the default `/m` and `/macro` window, with an opt-out that restores Blizzard's handler.
- Return to Blizzard's original macro window at any time with `/ms blizzard`.
- Configure slash takeover and minimap visibility through persistent Settings.
- Open MacroStudio from an optional minimap button or WoW's AddOn Compartment.

### Fixed

- Keep action-bar usage accurate after native macro creation, updates, deletion, and index changes.
- Prevent resolved spell or item IDs from being mistaken for native macro indices when detecting action-bar usage.
- Recover external macro conflicts through Revert without targeting a shifted or deleted neighbor.
- Present offline character snapshots with an explicitly read-only name and icon.
- Make the title-bar Settings control and minimap right-click use the same reliable Settings controller.

## 1.1.0

### Added

- Drag native macros directly from MacroStudio onto your action bars.

## 1.0.0

Initial public release candidate.

### Added

- A movable, resizable workspace for Blizzard-native Account and Character macros.
- A large multiline editor with native caret placement, selection, keyboard navigation, and scrolling.
- Live case-insensitive search across macro names, complete bodies, assigned categories, and tags.
- Categories, multiple tags, Favorites, and combined navigation/search filtering.
- Native Account and Character macro creation with scope, icon, capacity, and character-limit validation.
- Confirmed native macro deletion that targets the exact selected macro.
- Automatic synchronization with Blizzard macro changes and an explicit `/ms refresh` fallback.
- Saved window geometry, organization metadata, slash-command help, and optional debug logging.

### Safety

- Added live dirty-state and 255-character validation with Save and Revert eligibility.
- Added combat-aware write protection and immediate target revalidation before native mutations.
- Preserved unsaved drafts when external changes or search visibility would otherwise disrupt selection.
- Added modal interaction blocking and reliable cleanup for every macro-creation close path.
- Added conservative metadata reconciliation without guessing between ambiguous native macros.
