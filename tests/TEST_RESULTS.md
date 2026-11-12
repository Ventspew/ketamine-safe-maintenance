# Test results

## KetamineSafeCore harness (2026-11-12)

Environment: macOS Command Line Tools, Swift 6.4 (`DEVELOPER_DIR=/Library/Developer/CommandLineTools`).  
Xcode.app was not installed on this machine, so XCTest SPM (`swift test`) could not run; a `swiftc` harness was used instead.

```
PASS: empty cache
PASS: invalid format
PASS: valid uuid
PASS: missing cache not ready
PASS: reports inaccessible
PASS: non-zip throws
PASS: 10 images
PASS: 10 keys
PASS: path redaction
PASS: uuid redaction
ALL PASSED
```

Re-run:

```bash
export DEVELOPER_DIR=/Library/Developer/CommandLineTools
cd patches/KetamineSafeCore
# or use scripts/run-safecore-harness.sh from repo root once present
```

## App target

Full iOS app compile requires Xcode. Not executed here (`xcode-select` points at a missing `/Applications/Xcode.app`).
