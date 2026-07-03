#Include ProfileStore.ahk
#Include ActionRegistry.ahk
#Include HotkeyLayer.ahk
#Include Gui/MainWindow.ahk
#Include Util/Tooltips.ahk

class App {
    __New() {
        this.RootDir := A_ScriptDir
        this.ProfileStore := ProfileStore(this.RootDir "\profiles")
        this.Actions := ActionRegistry(this.ProfileStore)
        this.Hotkeys := HotkeyLayer(this.ProfileStore, this.Actions)
        this.MainWindow := ""
    }

    Start() {
        this.ProfileStore.EnsureDefaultProfiles()
        this.ProfileStore.LoadProfiles()
        this.ProfileStore.SetCurrentProfile("Default")

        this.MainWindow := MainWindow(this)
        this.Hotkeys.SetIgnoredWindow(this.MainWindow.GetHwnd())

        ; Default profile intentionally registers no macro hotkeys.
        this.Hotkeys.ApplyCurrentProfile()

        this.MainWindow.Show()
        TrayTip "Keyboard Configurator", "Started in Default profile. No keys are captured.", 1
    }

    SetProfile(profileName) {
        this.ProfileStore.SaveCurrentProfile()
        this.Hotkeys.DisableAll()

        this.ProfileStore.SetCurrentProfile(profileName)
        this.Hotkeys.ApplyCurrentProfile()
        this.MainWindow.Refresh()

        if (profileName = "Default") {
            Notify("Default profile active: keyboard is normal.")
        } else {
            Notify("Profile active: " profileName)
        }
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
            Notify("Pick a key first.")
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
