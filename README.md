# Keyboard Configurator

A profile-based AutoHotkey v2 single-key macro layer.

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

## Profiles

Profiles live in:

```text
profiles/
```

Each profile has:

```text
profile.ini
```

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

## GUI workflow

1. Open `KeyboardConfigurator.ahk`.
2. Select a non-Default profile, such as `Python`.
3. Click `Capture Key`.
4. Press one key, such as `F1`.
5. Choose action type.
6. Enter the value.
7. Click `Save`.
8. Press that key anywhere.

## Action types

### Text

Pastes text using the clipboard temporarily.

Example:

```text
print()
```

### Send

Sends AutoHotkey send syntax.

Example:

```text
^s
```

That sends Ctrl+S.

### Run

Runs a file, folder, program, or URL.

Example:

```text
notepad.exe
```

### Function

Runs a named built-in function.

Available names:

```text
ShowDate
ShowDateTime
ReloadScript
SuspendHotkeys
OpenScriptFolder
```

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

Switch back to `Default` to restore normal keyboard behavior.
