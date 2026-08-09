# MacroStudio Roadmap

MacroStudio 1.0.0 is the initial public-release candidate. The roadmap records shipped capabilities and likely future directions; unchecked items are not commitments or release dates.

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

- [ ] Investigate current Retail macro pickup, cursor, drop, and secure-action restrictions.
- [ ] Drag Blizzard-native macros from MacroStudio onto action bars outside combat.
- [ ] Preserve protected-action rules and interoperability with popular action-bar addons.
- [ ] Inspect which action slots use a selected macro, including paging and override caveats.
- [ ] Report associated keybinds only when the result is reliable.

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

## Native macro management

- [ ] Rename existing native macros.
- [ ] Change an existing macro's icon or scope.
- [ ] Duplicate a native macro.
- [ ] Warn when destructive changes affect macros currently placed on action slots.

## Discoverability

- [ ] Add a minimap or addon-compartment launcher.
- [ ] Consider optional `/m` behavior only if it can safely coexist with Blizzard's `/macro` command.
