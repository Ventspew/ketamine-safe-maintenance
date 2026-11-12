# Changelog — safe maintenance fork

## 1.2.2-safe.1

- Added `KetamineSafeCore` (container identity classification, theme ZIP inspect, wallpaper descriptor inspect, diagnostics log)
- Dialer flow validates packages and cached UUID **before** install attempts
- Refuses path construction from empty/invalid hashes
- Diagnostics screen with exportable redacted logs
- Documented 2.1b1 source mismatch and iOS 27 limitations
- **No** AirLift / worse_query / sandbox-escape changes
