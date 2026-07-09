#Include ../Util/TextPreview.ahk
#Include ../Util/DarkMode.ahk

class MainWindow {
    static COL_WIN_BG     := "16171B"
    static COL_KEY_BG     := "26282E"
    static COL_KEY_TEXT   := "9AA3AF"
    static COL_BOUND_BG   := "2D5A88"
    static COL_BOUND_TEXT := "EAF1F9"
    static COL_SEL_BG     := "A87F1E"
    static COL_SEL_TEXT   := "FFFFFF"
    static COL_EDIT_BG    := "1F2126"
    static COL_TEXT       := "D6DBE3"
    static COL_DIM        := "8A93A0"
    static COL_ACCENT     := "E8B33C"

    __New(app) {
        this.App := app
        this.SelectedKey := ""
        this.KeyCtrls := Map()  ; keyName -> {ctrl, label, w}
        this.Unit := 46         ; grid unit in px (key pitch)
        this.Gap := 4           ; spacing between keycaps
        this.Build()
    }

    Build() {
        u := this.Unit
        margin := 12

        this.Gui := Gui("", "Keyboard Configurator")
        this.Gui.BackColor := MainWindow.COL_WIN_BG
        this.Gui.SetFont("s10 c" MainWindow.COL_TEXT, "Segoe UI")

        ; ---------- top bar ----------
        this.Gui.AddText("x" margin " y" (margin + 5), "Profile")
        this.ProfileDDL := this.Gui.AddDropDownList("x+8 yp-4 w170", [])
        this.ProfileDDL.OnEvent("Change", (*) => this.ProfileChanged())
        UseDarkControlTheme(this.ProfileDDL, "DarkMode_CFD")

        this.NewProfileEdit := this.Gui.AddEdit("x+14 yp w150 Background" MainWindow.COL_EDIT_BG " c" MainWindow.COL_TEXT)
        UseDarkControlTheme(this.NewProfileEdit)

        this.AddProfileBtn := this.Gui.AddButton("x+6 yp-1 w95", "Add Profile")
        this.AddProfileBtn.OnEvent("Click", (*) => this.AddProfile())
        UseDarkControlTheme(this.AddProfileBtn)

        this.EnabledBox := this.Gui.AddCheckbox("x+18 yp+5 c" MainWindow.COL_TEXT, "Profile enabled")
        this.EnabledBox.OnEvent("Click", (*) => this.App.ToggleCurrentProfileEnabled())
        RemoveControlTheme(this.EnabledBox)

        this.StatusText := this.Gui.AddText("x+18 yp+2 w320 c" MainWindow.COL_DIM, "")

        ; ---------- keyboard ----------
        this.KbY := margin + 42
        this.Gui.SetFont("s8", "Segoe UI")

        mainX := margin
        navX := mainX + 15 * u + 10
        padX := navX + 3 * u + 10

        this.AddSection(mainX, this.MainRows())
        this.AddSection(navX, this.NavRows())
        this.AddSection(padX, this.PadRows())

        winW := Round(padX + 4 * u - this.Gap + margin)
        kbBottom := this.KbY + 6 * u + 8

        ; ---------- binding editor ----------
        this.Gui.SetFont("s10 c" MainWindow.COL_TEXT, "Segoe UI")
        edY := kbBottom + 14

        this.Gui.AddText("x" margin " y" (edY + 4), "Key")
        this.Gui.SetFont("s10 Bold c" MainWindow.COL_ACCENT, "Segoe UI")
        this.SelKeyText := this.Gui.AddText("x+8 yp w120", "(none)")
        this.Gui.SetFont("s10 Norm c" MainWindow.COL_TEXT, "Segoe UI")

        this.Gui.AddText("x+10 yp", "Action")
        this.ActionTypeDDL := this.Gui.AddDropDownList("x+8 yp-4 w110", ["Text", "Send", "Run", "Function"])
        this.ActionTypeDDL.Text := "Text"
        UseDarkControlTheme(this.ActionTypeDDL, "DarkMode_CFD")

        this.SaveBtn := this.Gui.AddButton("x+16 yp-1 w90", "Save")
        this.SaveBtn.OnEvent("Click", (*) => this.SaveBinding())
        UseDarkControlTheme(this.SaveBtn)

        this.DeleteBtn := this.Gui.AddButton("x+8 yp w90", "Delete")
        this.DeleteBtn.OnEvent("Click", (*) => this.DeleteBinding())
        UseDarkControlTheme(this.DeleteBtn)

        this.ValueEdit := this.Gui.AddEdit(Format("x{} y{} w{} h84 Multi WantTab Background{} c{}",
            margin, edY + 38, winW - 2 * margin, MainWindow.COL_EDIT_BG, MainWindow.COL_TEXT))
        UseDarkControlTheme(this.ValueEdit)

        this.Gui.SetFont("s9 c" MainWindow.COL_DIM, "Segoe UI")
        this.HelpText := this.Gui.AddText(Format("x{} y{} w{}", margin, edY + 38 + 84 + 10, winW - 2 * margin),
            "Click a key to select it, pick an action, type a value, then Save. "
            . "Blue keys hold macros; the selected key is gold. "
            . "Ctrl+Alt+PageUp / PageDown switches profiles from anywhere; Ctrl+Alt+Home jumps to Default. Default profile never captures keys."
        )

        this.WinW := winW
        this.WinH := edY + 38 + 84 + 10 + 40 + margin

        EnableDarkTitleBar(this.Gui.Hwnd)
        this.Refresh()
    }

    ; Each row: array of [display label, AHK key name, width in units].
    ; An empty key name is a spacer.
    MainRows() {
        return Map(
            0, [["Esc", "Escape", 1], ["", "", 1],
                ["F1", "F1", 1], ["F2", "F2", 1], ["F3", "F3", 1], ["F4", "F4", 1], ["", "", 0.5],
                ["F5", "F5", 1], ["F6", "F6", 1], ["F7", "F7", 1], ["F8", "F8", 1], ["", "", 0.5],
                ["F9", "F9", 1], ["F10", "F10", 1], ["F11", "F11", 1], ["F12", "F12", 1]],
            1, [["``", "``", 1], ["1", "1", 1], ["2", "2", 1], ["3", "3", 1], ["4", "4", 1], ["5", "5", 1],
                ["6", "6", 1], ["7", "7", 1], ["8", "8", 1], ["9", "9", 1], ["0", "0", 1],
                ["-", "-", 1], ["=", "=", 1], ["Bksp", "Backspace", 2]],
            2, [["Tab", "Tab", 1.5], ["Q", "q", 1], ["W", "w", 1], ["E", "e", 1], ["R", "r", 1], ["T", "t", 1],
                ["Y", "y", 1], ["U", "u", 1], ["I", "i", 1], ["O", "o", 1], ["P", "p", 1],
                ["[", "[", 1], ["]", "]", 1], ["\", "\", 1.5]],
            3, [["Caps", "CapsLock", 1.75], ["A", "a", 1], ["S", "s", 1], ["D", "d", 1], ["F", "f", 1], ["G", "g", 1],
                ["H", "h", 1], ["J", "j", 1], ["K", "k", 1], ["L", "l", 1],
                [";", ";", 1], ["'", "'", 1], ["Enter", "Enter", 2.25]],
            4, [["Shift", "LShift", 2.25], ["Z", "z", 1], ["X", "x", 1], ["C", "c", 1], ["V", "v", 1], ["B", "b", 1],
                ["N", "n", 1], ["M", "m", 1], [",", ",", 1], [".", ".", 1], ["/", "/", 1], ["Shift", "RShift", 2.75]],
            5, [["Ctrl", "LCtrl", 1.25], ["Win", "LWin", 1.25], ["Alt", "LAlt", 1.25], ["Space", "Space", 6.25],
                ["Alt", "RAlt", 1.25], ["Win", "RWin", 1.25], ["Menu", "AppsKey", 1.25], ["Ctrl", "RCtrl", 1.25]]
        )
    }

    NavRows() {
        return Map(
            0, [["PrtSc", "PrintScreen", 1], ["ScrLk", "ScrollLock", 1], ["Pause", "Pause", 1]],
            1, [["Ins", "Insert", 1], ["Home", "Home", 1], ["PgUp", "PgUp", 1]],
            2, [["Del", "Delete", 1], ["End", "End", 1], ["PgDn", "PgDn", 1]],
            4, [["", "", 1], ["▲", "Up", 1]],
            5, [["◄", "Left", 1], ["▼", "Down", 1], ["►", "Right", 1]]
        )
    }

    PadRows() {
        return Map(
            1, [["Num", "NumLock", 1], ["/", "NumpadDiv", 1], ["*", "NumpadMult", 1], ["-", "NumpadSub", 1]],
            2, [["7", "Numpad7", 1], ["8", "Numpad8", 1], ["9", "Numpad9", 1], ["+", "NumpadAdd", 1]],
            3, [["4", "Numpad4", 1], ["5", "Numpad5", 1], ["6", "Numpad6", 1]],
            4, [["1", "Numpad1", 1], ["2", "Numpad2", 1], ["3", "Numpad3", 1], ["Ent", "NumpadEnter", 1]],
            5, [["0", "Numpad0", 2], [".", "NumpadDot", 1]]
        )
    }

    AddSection(xBase, rows) {
        for r, rowKeys in rows {
            x := xBase * 1.0
            y := this.KbY + r * this.Unit + (r > 0 ? 8 : 0)
            for def in rowKeys {
                wPx := Round(def[3] * this.Unit) - this.Gap
                if (def[2] != "") {
                    this.AddKey(def[1], def[2], Round(x), y, wPx)
                }
                x += def[3] * this.Unit
            }
        }
    }

    AddKey(label, keyName, x, y, w) {
        h := this.Unit - this.Gap
        ctrl := this.Gui.AddText(Format("x{} y{} w{} h{} Center Background{} c{}",
            x, y, w, h, MainWindow.COL_KEY_BG, MainWindow.COL_KEY_TEXT), label)
        ctrl.OnEvent("Click", this.MakeKeyClick(keyName))
        this.KeyCtrls[keyName] := {ctrl: ctrl, label: label, w: w}
    }

    MakeKeyClick(keyName) {
        return (*) => this.SelectKey(keyName)
    }

    Show() {
        this.Gui.Show("w" this.WinW " h" this.WinH)
    }

    GetHwnd() {
        return this.Gui.Hwnd
    }

    Refresh() {
        profile := this.App.ProfileStore.CurrentProfile
        this.RefreshProfileList()

        this.EnabledBox.Value := IsObject(profile) && profile["enabled"]
        this.EnabledBox.Enabled := IsObject(profile) && profile["name"] != "Default"

        if IsObject(profile) && profile["name"] = "Default" {
            this.StatusText.Text := "Default profile: normal keyboard, no macro hotkeys."
        } else if IsObject(profile) {
            this.StatusText.Text := profile["enabled"] ? "Macro layer active." : "Profile disabled."
        }

        this.RefreshBindings()
    }

    RefreshProfileList() {
        names := this.App.ProfileStore.GetProfileNames()
        this.ProfileDDL.Delete()

        if (names.Length = 0) {
            return
        }

        this.ProfileDDL.Add(names)

        selectedIndex := 0
        for index, name in names {
            if (name = this.App.ProfileStore.CurrentProfileName) {
                selectedIndex := index
                break
            }
        }

        this.ProfileDDL.Choose(selectedIndex ? selectedIndex : 1)
    }

    RefreshBindings() {
        for keyName, info in this.KeyCtrls {
            this.UpdateKeyVisual(keyName)
        }
        this.LoadSelectedIntoEditor()
    }

    UpdateKeyVisual(keyName) {
        info := this.KeyCtrls[keyName]
        profile := this.App.ProfileStore.CurrentProfile
        bound := IsObject(profile) && profile["bindings"].Has(keyName)

        if (keyName = this.SelectedKey) {
            bg := MainWindow.COL_SEL_BG
            fg := MainWindow.COL_SEL_TEXT
        } else if bound {
            bg := MainWindow.COL_BOUND_BG
            fg := MainWindow.COL_BOUND_TEXT
        } else {
            bg := MainWindow.COL_KEY_BG
            fg := MainWindow.COL_KEY_TEXT
        }

        if bound {
            perLine := Max(3, Round((info.w - 4) / 5.5))
            preview := ActionPreview(profile["bindings"][keyName], perLine * 2)
            if (StrLen(preview) > perLine) {
                preview := SubStr(preview, 1, perLine) "`n" SubStr(preview, perLine + 1)
            }
            text := info.label "`n" preview
        } else {
            ; Leading newline drops the lone label to the second line, roughly centering it.
            text := "`n" info.label
        }

        info.ctrl.Opt("c" fg " Background" bg)
        info.ctrl.Text := text
        info.ctrl.Redraw()
    }

    SelectKey(keyName) {
        prev := this.SelectedKey
        this.SelectedKey := keyName

        if (prev != "" && this.KeyCtrls.Has(prev)) {
            this.UpdateKeyVisual(prev)
        }
        this.UpdateKeyVisual(keyName)
        this.LoadSelectedIntoEditor()
    }

    LoadSelectedIntoEditor() {
        this.SelKeyText.Text := this.SelectedKey = "" ? "(none)" : this.SelectedKey

        profile := this.App.ProfileStore.CurrentProfile
        if (this.SelectedKey != "" && IsObject(profile) && profile["bindings"].Has(this.SelectedKey)) {
            action := profile["bindings"][this.SelectedKey]
            this.ActionTypeDDL.Text := action["type"]
            this.ValueEdit.Text := action["value"]
        } else {
            this.ValueEdit.Text := ""
        }
    }

    ProfileChanged() {
        this.App.SetProfile(this.ProfileDDL.Text)
    }

    AddProfile() {
        name := Trim(this.NewProfileEdit.Text)
        if (name = "") {
            return
        }

        this.App.CreateProfile(name)
        this.NewProfileEdit.Text := ""
    }

    SaveBinding() {
        this.App.SaveBinding(this.SelectedKey, this.ActionTypeDDL.Text, this.ValueEdit.Text)
    }

    DeleteBinding() {
        if (this.SelectedKey != "") {
            this.App.DeleteBinding(this.SelectedKey)
        }
    }
}
