class HotkeyLayer {
    __New(profileStore, actionRegistry) {
        this.ProfileStore := profileStore
        this.Actions := actionRegistry
        this.RegisteredKeys := Map()
        this.IgnoredWindowTitle := ""
    }

    SetIgnoredWindow(hwnd) {
        this.IgnoredWindowTitle := hwnd ? "ahk_id " hwnd : ""
    }

    ApplyCurrentProfile() {
        this.DisableAll()

        profile := this.ProfileStore.CurrentProfile
        if !IsObject(profile) {
            return
        }

        ; Default profile is explicitly a normal keyboard.
        if (profile["name"] = "Default") {
            return
        }

        if !profile["enabled"] {
            return
        }

        for keyName, action in profile["bindings"] {
            this.EnableKey(keyName)
        }
    }

    EnableKey(keyName) {
        if (Trim(keyName) = "") {
            return
        }

        cb := this.MakeCallback(keyName)

        try {
            this.UseHotkeyContext()
            Hotkey(keyName, cb, "On")
            this.RegisteredKeys[keyName] := cb
        } catch Error as e {
            MsgBox("Could not register key: " keyName "`n`n" e.Message)
        }

        HotIf()
    }

    DisableAll() {
        this.UseHotkeyContext()

        for keyName, cb in this.RegisteredKeys {
            try Hotkey(keyName, cb, "Off")
        }

        HotIf()
        this.RegisteredKeys := Map()
    }

    MakeCallback(keyName) {
        return (*) => this.Actions.Execute(keyName)
    }

    UseHotkeyContext() {
        if (this.IgnoredWindowTitle != "") {
            HotIfWinNotActive(this.IgnoredWindowTitle)
        } else {
            HotIf()
        }
    }
}
