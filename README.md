# Keyboard Configurator

A profile-based AutoHotkey v2 single-key macro layer with a visual keyboard GUI.

The important rule:

> `Default` profile captures no keys.  
> Any other enabled profile can turn normal keys into paste/function actions.

This means your normal keyboard is untouched until you switch into a macro profile.

## Requirements

- Windows
- AutoHotkey v2

## Run

Double-click:

```text
KeyboardConfigurator.ahk
```

## GUI

The main window is a dark-themed visual keyboard (main block, nav cluster, and numpad):

- **Blue keys** hold a macro and show a short preview of the saved value on the keycap.
- **The gold key** is the currently selected key.
- `Run` bindings display as `launch_<app>` (derived from the target filename) instead of the full path.
- `Function` bindings display as `Name()`.

Workflow:

1. Select a non-Default profile, or create one.
2. Click a key on the keyboard.
3. Choose action type, enter the value.
4. Click `Save`.
5. Press that key anywhere.

## Switching profiles

- Use the dropdown in the GUI, or
- Press `Ctrl+Alt+PageUp` / `Ctrl+Alt+PageDown` anywhere to cycle profiles, or
- Press `Ctrl+Alt+Home` anywhere to jump straight to `Default` (normal keyboard).

Every switch shows a large on-screen popup announcing the active profile.

## Profiles

Each profile is a single file:

```text
profiles/<Name>.ini
```

(Old-style `profiles/<Name>/profile.ini` folders are migrated automatically on startup.)

Example:

```ini
[Profile]
name=Python
enabled=1

[Binding.F1]
type=Text
value=print()

[Binding.F2]
type=Text
value=import pandas as pd
```

## Action types

### Text

Pastes text using the clipboard temporarily.

```text
print()
```

### Send

Sends AutoHotkey send syntax. Example — `^s` sends Ctrl+S.

### Run

Runs a file, folder, program, or URL.

```text
notepad.exe
```

### Function

Runs a named function by its name, e.g. `ShowDate`.

Built-ins live in `src/Functions.ahk`:

```text
ShowDate
ShowDateTime
ReloadScript
WritePythonPrintBuffered
WritePythonPrintNonBuffered
SuspendHotkeys
OpenScriptFolder
```

Python snippet functions come in pairs: a `...Buffered` variant that splices the
active snippet buffer into the blank (e.g. `WritePythonForBuffered` types
`for itm in my_list:`), and a `...NonBuffered` variant that ignores the buffers,
leaves the blank empty, and parks the caret there.

To add your own, either:

- define a plain global function in `src/Functions.ahk` — it is callable by its name with no further wiring, or
- add a `registry.Register("Name", callable)` line inside `RegisterBuiltinFunctions` when you need a closure or a different display name.

## Default profile

The `Default` profile intentionally registers no macro hotkeys.

Use it when you want normal keyboard behavior.

## Included example bindings

Python profile:

```text
F1 -> print()
F2 -> import pandas as pd
```

CSharp profile:

```text
F1 -> Console.WriteLine();
```

## Important note about single-key binds

Binding normal letter keys like `a`, `b`, `c`, etc. will intercept that key while the profile is active.

For example:

```text
Python profile active
a -> import pandas as pd
```

Now pressing `a` will paste that text instead of typing `a`.

Switch back to `Default` (or press `Ctrl+Alt+PageUp/PageDown`) to restore normal keyboard behavior.
