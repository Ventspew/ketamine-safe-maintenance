# Diagnostic guide

Open **Settings → Diagnostics** in the app.

## What you should see after a factory reset

- Phone container cache: `empty`
- Dialer theme: `Missing identifier` (if privileged discovery probe reports available) or `Inaccessible` (if not)
- Recent events after a failed apply should resemble:

```
[INFO] THEME_START: Starting keypad theme operation
[INFO] THEME_ASSETS: Assets validated: …
[INFO] THEME_TARGET: Target: Phone dialer
[WARN] THEME_CACHE: No cached container identifier
[INFO] THEME_RESOLVE: Checking supported resolution methods
[ERROR] THEME_RESOLVE: Container unavailable — …
[INFO] THEME_ABORT: Theme installation aborted safely
```

## Export

Use **Export diagnostic log**. UUIDs and `/var/mobile/Containers/…` paths are redacted.
