# Contributing to MacroStudio

Bug reports and feature requests are welcome through [GitHub Issues](https://github.com/Baeleaf/MacroStudio/issues). Please use the provided issue forms and include enough detail to reproduce or understand the request.

Pull requests are welcome. Keep changes focused, explain user-visible behavior, and preserve MacroStudio's core safety rules:

- Never bypass World of Warcraft combat restrictions or protected-action rules.
- Revalidate the exact native macro immediately before Save, Create, or Delete operations.
- Preserve dirty drafts and avoid guessing when native macro identity is ambiguous.
- Treat imported or user-entered macro content as text, never executable Lua.

Test changes in the current World of Warcraft Retail client. When applicable, run the automated preflight from the repository root:

```powershell
py .\tests\preflight.py
```

Update tests and documentation when behavior changes. Do not include SavedVariables, account data, screenshots containing personal information, generated ZIPs, or local development artifacts in a pull request.
