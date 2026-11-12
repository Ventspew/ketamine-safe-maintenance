# Security and limitations

## Out of scope (intentionally)

This repository does **not**:

- Implement or improve sandbox escapes
- Integrate AirLift, worse_query, or bad_query enhancements
- Guess or hardcode device container UUIDs
- Scan `/var/mobile/Containers` from ordinary app entitlements

Upstream Ketamine still vendors historical `bad_query` sources under `Ketamine/Exploit/` for the public 1.x app. Those files are **unchanged** in this maintenance work. Do not treat their presence as endorsement of use on patched firmware.

## Safe changes

- Typed cache / feature-access states
- Theme and wallpaper **read-only** inspectors
- Diagnostics with path/UUID redaction
- Unit/harness tests with mocked ZIP bytes and fake filesystem trees

## Residual risk

Building and running the full Ketamine app target still links historical privileged code paths. Prefer exercising `KetamineSafeCore` tests when evaluating this maintenance layer alone.
