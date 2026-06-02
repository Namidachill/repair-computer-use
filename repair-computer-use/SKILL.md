---
name: repair-computer-use
description: Diagnose and repair Codex Desktop Computer Use on Windows after an app update, especially when Settings shows "Computer Use plugin is unavailable", the Computer Use toggles disappear, or setup fails with "Computer Use native pipe path is unavailable". Use when Codex should inspect or restore the bundled openai-bundled marketplace registration without editing project files.
---

# Repair Computer Use

Use this Windows recovery workflow after a Codex Desktop update breaks Computer Use.

## Safety

- Keep project files untouched.
- Use `scripts/repair-computer-use.ps1 -Mode Inspect` before any repair.
- Explain the repair, its impact, and its rollback procedure. Ask for approval before running `-Mode Repair`.
- Do not publish command output without checking for local paths.
- Do not delete caches, edit secrets, or manually launch `codex-computer-use.exe`.
- Prefer the formal CLI marketplace registration over copying staging folders.
- If Codex Desktop shows a blank or white left sidebar after restart, inspect `%USERPROFILE%\.codex\config.toml` for malformed TOML first. In particular, keep `[desktop]` values like `dictationDictionary` syntactically valid before rerunning marketplace repair.

## Diagnosis

Run:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-root>\scripts\repair-computer-use.ps1" -Mode Inspect
```

Treat these together as the known recurrence:

- Settings shows `Computer Use plugin is unavailable`.
- `computer-use@openai-bundled` is enabled in `%USERPROFILE%\.codex\config.toml`.
- The installed Codex Desktop package contains a complete `app\resources\plugins\openai-bundled`.
- `codex plugin marketplace list` does not list `openai-bundled`, or the registered root is wrong.
- Computer Use bootstrap reports `Computer Use native pipe path is unavailable`.

The `%USERPROFILE%\.codex\.tmp\bundled-marketplaces\openai-bundled` staging area may be incomplete. Do not treat that alone as the durable repair target: a Desktop restart can recreate it.

If the left sidebar turns blank or white after a repair attempt, treat it as a possible `config.toml` parse or rewrite problem before reinstalling Codex Desktop. Check the `[desktop]` block first, especially `dictationDictionary`, because malformed quotes there can leave Desktop UI settings in a bad state while the main chat still renders.

## Repair

Explain:

- The script backs up `%USERPROFILE%\.codex\config.toml`.
- It registers the current Codex Desktop package's `openai-bundled` folder through `codex plugin marketplace add`.
- It does not delete files or modify project content.
- Rollback is restoring the timestamped config backup and removing the registered marketplace with `codex plugin marketplace remove openai-bundled` if needed.

After approval, run:

```powershell
powershell -ExecutionPolicy Bypass -File "<skill-root>\scripts\repair-computer-use.ps1" -Mode Repair
```

Then ask the user to restart Codex Desktop.

The repair script reports `ConfigProblems` during `Inspect` and refuses `Repair` when it detects a malformed `dictationDictionary` line. Fix the config or restore a known-good config backup before continuing marketplace repair.

## Verify

After restart:

1. Ask the user to confirm that `Settings > Computer Use` shows app toggles instead of the unavailable message.
2. Run `Inspect` again.
3. For actual runtime validation, use the bundled Computer Use skill bootstrap and call `sky.list_apps()` in a fresh chat. An older chat may retain a stale Windows connection environment.

If the UI recovers but the current chat still reports `Computer Use native pipe path is unavailable`, ask the user to validate from a new chat before changing more files.

## Legacy Fallback

Do not use the legacy cache-copy fallback automatically. If formal marketplace registration fails, stop and explain that Desktop internals may have changed. Only investigate a manual fallback after the user explicitly asks to continue.
