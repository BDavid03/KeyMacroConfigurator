#Include ProfileStore.ahk
#Include ActionRegistry.ahk
#Include HotkeyLayer.ahk
#Include Gui/MainWindow.ahk
#Include Gui/ProfileOsd.ahk
#Include Util/Tooltips.ahk

class App {
    __New() {
        this.RootDir := A_ScriptDir
        this.ProfileStore := ProfileStore(this.RootDir "\profiles")
        this.Actions := ActionRegistry(this.ProfileStore)
        this.Hotkeys := HotkeyLayer(this.ProfileStore, this.Actions)
        this.MainWindow := ""
        this.Osd := ProfileOsd()
    }

    Start() {
        this.ProfileStore.EnsureDefaultProfiles()
        this.ProfileStore.LoadProfiles()
        this.ProfileStore.SetCurrentProfile("Default")

        this.MainWindow := MainWindow(this)
        this.Hotkeys.SetIgnoredWindow(this.MainWindow.GetHwnd())

        ; Default profile intentionally registers no macro hotkeys.
        this.Hotkeys.ApplyCurrentProfile()

        ; Global profile switching, works in any window.
        Hotkey("^!PgUp", (*) => this.CycleProfile(-1))
        Hotkey("^!PgDn", (*) => this.CycleProfile(1))
        Hotkey("^!Home", (*) => this.SetProfile("Default"))

        this.MainWindow.Show()
        this.Osd.ShowProfile("Default", "Normal keyboard — no macros")
        TrayTip "Keyboard Configurator", "Started in Default profile. Ctrl+Alt+PageUp/PageDown switches profiles.", 1
    }

    SetProfile(profileName) {
        this.ProfileStore.SaveCurrentProfile()
        this.Hotkeys.DisableAll()

        this.ProfileStore.SetCurrentProfile(profileName)
        this.Hotkeys.ApplyCurrentProfile()

        if IsObject(this.MainWindow) {
            this.MainWindow.Refresh()
        }

        profile := this.ProfileStore.CurrentProfile
        if (profileName = "Default") {
            subtitle := "Normal keyboard — no macros"
        } else {
            subtitle := profile["enabled"] ? "Macro layer active" : "Profile is disabled"
        }
        this.Osd.ShowProfile(profileName, subtitle)
    }

    CycleProfile(direction) {
        names := this.ProfileStore.GetProfileNames()
        if (names.Length = 0) {
            return
        }

        current := 1
        for index, name in names {
            if (name = this.ProfileStore.CurrentProfileName) {
                current := index
                break
            }
        }

        next := Mod(current - 1 + direction + names.Length, names.Length) + 1
        this.SetProfile(names[next])
    }

    ToggleCurrentProfileEnabled() {
        profile := this.ProfileStore.CurrentProfile
        profile["enabled"] := !profile["enabled"]
        this.ProfileStore.SaveCurrentProfile()
        this.Hotkeys.ApplyCurrentProfile()
        this.MainWindow.Refresh()

        Notify(profile["name"] " enabled: " (profile["enabled"] ? "Yes" : "No"))
    }

    SaveBinding(keyName, actionType, value) {
        profile := this.ProfileStore.CurrentProfile

        if (profile["name"] = "Default") {
            Notify("Default profile cannot capture keys. Switch to a macro profile first.")
            return
        }

        if (Trim(keyName) = "") {
            Notify("Click a key on the keyboard first.")
            return
        }

        if (Trim(actionType) = "") {
            actionType := "Text"
        }

        bindings := profile["bindings"]
        bindings[keyName] := Map(
            "type", actionType,
            "value", value
        )

        this.ProfileStore.SaveCurrentProfile()
        this.Hotkeys.ApplyCurrentProfile()
        this.MainWindow.RefreshBindings()
        Notify("Saved " keyName " -> " actionType)
    }

    DeleteBinding(keyName) {
        profile := this.ProfileStore.CurrentProfile
        if profile["bindings"].Has(keyName) {
            profile["bindings"].Delete(keyName)
            this.ProfileStore.SaveCurrentProfile()
            this.Hotkeys.ApplyCurrentProfile()
            this.MainWindow.RefreshBindings()
            Notify("Deleted binding: " keyName)
        }
    }

    CreateProfile(profileName) {
        profileName := Trim(profileName)
        if (profileName = "") {
            Notify("Profile name required.")
            return
        }

        this.ProfileStore.CreateProfile(profileName)
        this.ProfileStore.LoadProfiles()
        this.MainWindow.RefreshProfileList()
        Notify("Created profile: " profileName)
    }
}
