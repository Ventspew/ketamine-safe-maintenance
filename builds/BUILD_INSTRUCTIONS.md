# Build instructions

## SafeCore only (no Xcode.app required)

```bash
export DEVELOPER_DIR=/Library/Developer/CommandLineTools
./scripts/run-safecore-harness.sh
```

## Full Ketamine iOS app

1. Install Xcode and run `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
2. `brew install xcodegen` if needed
3. From `ketamine/`:

```bash
xcodegen generate
open Ketamine.xcodeproj
```

4. Select your Team for signing (`uk.nouvborne.ketamine` or change the bundle id)
5. Build for a physical device (Simulator cannot exercise privileged paths)

Local package path: `patches/KetamineSafeCore` (see `ketamine/project.yml`).

## IPA

No signing identity was available in this environment; IPA was not produced.
