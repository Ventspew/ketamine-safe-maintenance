# Ketamine safe maintenance (iOS 27 diagnostics)

GPL-3.0 maintenance fork of [Nouvborne/Ketamine](https://github.com/Nouvborne/Ketamine) focused on **application-level** fixes:

- Theme package validation / preview summaries
- Cached container UUID classification (empty / invalid / present)
- Diagnostics screen + redacted logs
- Unit/harness tests that do **not** require privileged filesystem access

## Important

The **2.1 beta** distributed at [withered.live/ketamine](https://withered.live/ketamine) (AirLift / worse_query) is **not** published in the public GitHub tree. This repo cannot patch that binary’s exact sources. See `research/REPOSITORY_AUDIT.md`.

This project does **not** implement sandbox escapes or container scanning.

## Layout

```
ketamine/                 # App sources (based on Nouvborne 1.x)
patches/KetamineSafeCore/ # Testable safe module
research/                 # Audits and comparisons
diagnostics/              # Diagnostic guide
tests/                    # Test result notes
builds/                   # Build / changelog
scripts/                  # SafeCore harness
```

## Quick test

```bash
chmod +x scripts/run-safecore-harness.sh
./scripts/run-safecore-harness.sh
```

## Build the iOS app

See `builds/BUILD_INSTRUCTIONS.md` (requires Xcode).
