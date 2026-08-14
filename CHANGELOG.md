# Changelog

Notable user-facing changes to MacroStudio are documented here.

## Unreleased

### Added

- Export saved native macros, cross-character snapshots, and organization data as a portable, copyable library backup.
- Import portable MacroStudio libraries through validation, preview, capacity checks, explicit confirmation, and non-destructive merge safeguards.

### Fixed

- Accept archival offline snapshot names and bodies during portable Import without applying current native macro limits.

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
