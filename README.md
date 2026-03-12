# BeerEr
counting beers from a keg at a party

# Debug

## Running on two emulators with hot reload

Each device gets its own `flutter run` session in a **separate terminal**. Hot reload (`r`) and hot restart (`R`) work independently in each.

### Step 1 — Create and Start emulators

```zsh
# Create two Android AVDs
.fvm/flutter_sdk/bin/flutter emulators --create --name pixel_8A
.fvm/flutter_sdk/bin/flutter emulators --create --name pixel_8B

# Launch both
.fvm/flutter_sdk/bin/flutter emulators --launch pixel_8A
.fvm/flutter_sdk/bin/flutter emulators --launch pixel_8B
```

Or use the **iOS Simulator** as the second device (no extra AVD needed on macOS):

```zsh
open -a Simulator
```

### Step 2 — Confirm both devices are listed

```zsh
.fvm/flutter_sdk/bin/flutter devices
```

### Step 3 — Run on each device in a separate terminal

**Terminal 1:**
```zsh
.fvm/flutter_sdk/bin/flutter run -d emulator-5554
```

**Terminal 2:**
```zsh
.fvm/flutter_sdk/bin/flutter run -d emulator-5556   # or iOS Simulator ID
```

Each session has its own REPL:
- `r` → hot reload
- `R` → hot restart
- `q` → quit

### VS Code alternative

Use a `compounds` launch config in `.vscode/launch.json` to start both devices at once, each as a separate configuration with a different `-d` flag.
