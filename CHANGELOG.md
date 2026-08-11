# Changelog

Notable user-facing changes to MacroStudio are documented here.

## Unreleased

### Added

- See which macros are currently placed on your action bars.
- Browse Character macros from other characters used with MacroStudio and copy them to the current character.

### Fixed

- Keep action-bar usage accurate after native macro creation, updates, deletion, and index changes.
- Prevent resolved spell or item IDs from being mistaken for native macro indices when detecting action-bar usage.

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
