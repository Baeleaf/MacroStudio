# MacroStudio Roadmap

The roadmap records shipped capabilities and likely future directions; unchecked items are not commitments or release dates.

## Shipped in 1.0.0

### Native macro editor and safety

- [x] Movable, resizable Account and Character macro workspace.
- [x] Native multiline caret, selection, keyboard navigation, copy/paste, and scrolling.
- [x] Live 255-character validation, dirty state, Save, Revert, and discard confirmation.
- [x] Combat-aware native writes with action-time target and eligibility revalidation.
- [x] Automatic event synchronization, clean external reloads, and protected dirty conflicts.
- [x] Native Account and Character macro creation and confirmed exact-target deletion.

### Organization and search

- [x] Virtual categories with create, rename, delete, assign, and remove workflows.
- [x] Multiple tags and Favorites.
- [x] All, Account, Character, Favorites, and category navigation.
- [x] Case-insensitive live search across names, complete bodies, assigned categories, and tags.
- [x] Search/navigation combinations that preserve the selected macro and dirty draft.
- [x] Opaque metadata records with conservative reconciliation against Blizzard macros.

### User experience

- [x] Movable modal macro creation with native icon selection and capacity feedback.
- [x] Complete modal input blocking, Escape cleanup, combat preservation, and focus restoration.
- [x] Window position and size persistence.
- [x] Event-driven synchronization with `/ms refresh` retained only as a fallback.

## Public release checklist

- [x] Public-facing README, changelog, contributing guide, and issue forms.
- [x] Runtime-only release packaging script and local 1.0.0 release candidate.
- [ ] Choose and add a project license.
- [ ] Add privacy-reviewed screenshots.
- [ ] Complete final live-client regression checks using the packaged addon.
- [ ] Review commit-author metadata and repository settings.
- [ ] Make the repository public, create the v1.0.0 tag/release, and publish packages only after owner approval.

## High priority: native action-bar workflows

- [x] Investigate current Retail macro pickup, cursor, drop, and secure-action restrictions.
- [x] Drag Blizzard-native macros from MacroStudio onto action bars outside combat.
- [x] Preserve protected-action rules and hand off a native macro cursor payload without hardcoded action-bar frames.
- [ ] Validate third-party action-bar compatibility with public testers.
- [x] Inspect native action slots and show exact saved-macro usage counts and raw slot locations.
- [ ] Report associated keybinds only when the result is reliable.

## Shipped in 1.2.0: cross-character macro library

- [x] Store complete account-wide, GUID-keyed snapshots of Character macros for characters seen by MacroStudio.
- [x] Browse all known characters or one character with live current-character data and read-only offline snapshots.
- [x] Copy an offline snapshot into the current character through the existing native creation safeguards.
- [x] Search offline macro names, complete bodies, character names, and realms without native rescans.
- [x] Forget one offline snapshot with confirmation while preserving Blizzard macros and unrelated MacroStudio data.

## Portability, backups, and history

- [ ] Full-profile import/export.
- [ ] Selective macro and metadata import/export.
- [ ] Categories-only import/export.
- [ ] Preview incoming changes and conflicts before writing native macros.
- [ ] Treat imported content as untrusted text and never execute it as Lua.
- [ ] Snapshot/version history, backups, and recoverable deletion with sensible retention.

## Editing assistance

- [ ] Previewable templates and cursor-position snippets.
- [ ] Advisory tokenizer, linter, and maintainable syntax highlighting.
- [ ] Explained, opt-in character-count reduction suggestions.
- [ ] Advanced search fields such as scope, tag, category, Favorite, body, and name.

Editing assistance must never silently rewrite a working macro or claim semantic equivalence without sufficient certainty.

## Shipped in 1.2.0: native macro identity editing

- [x] Edit an existing native macro's name and icon after creation through one safely revalidated `EditMacro` operation.
- [x] Treat name, saved icon, and body as one draft with unified Save and Revert behavior.
- [x] Preserve duplicate-name and action-bar identity safety through native identity edits.
- [x] Recover external conflicts conservatively and clear selection after external deletion rather than target a neighbor.
- [x] Present offline snapshot names and icons as display-only while keeping body text selectable and copyable.

## Native macro management

- [ ] Change an existing macro's scope.
- [ ] Duplicate a native macro.
- [ ] Warn when destructive changes affect macros currently placed on action slots.

## Shipped in 1.2.0: default macro window and access settings

- [x] Route `/m` and `/macro` to MacroStudio by default while preserving `/ms` and `/macrostudio`.
- [x] Restore the exact captured Blizzard handler immediately when takeover is disabled.
- [x] Keep Blizzard's native Macro UI available through `/ms blizzard`.
- [x] Provide a compact settings panel with persistent access and launcher preferences.
- [x] Route the title-bar button, `/ms settings`, and minimap right-click through one frame-state-aware Settings controller.
- [x] Add an optional draggable minimap launcher with remembered radial position.
- [x] Register through the supported AddOn Compartment TOC metadata without manipulating Blizzard frames.
- [x] Detect pre-existing slash ownership conservatively and retain `/ms` instead of entering a command conflict.
