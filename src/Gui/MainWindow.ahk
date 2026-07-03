#Include ../Util/TextPreview.ahk

class MainWindow {
    __New(app) {
        this.App := app
        this.IsCapturingKey := false
        this.CapturedKey := ""

        this.Build()
    }

    Build() {
        this.Gui := Gui("+Resize", "Keyboard Configurator")
        this.Gui.SetFont("s10", "Segoe UI")

        this.Gui.AddText("xm ym", "Profile")
        this.ProfileDDL := this.Gui.AddDropDownList("x+10 yp-4 w180", [])
        this.ProfileDDL.OnEvent("Change", (*) => this.ProfileChanged())

        this.NewProfileEdit := this.Gui.AddEdit("x+10 yp w150")
        this.AddProfileBtn := this.Gui.AddButton("x+5 yp-1 w90", "Add Profile")
        this.AddProfileBtn.OnEvent("Click", (*) => this.AddProfile())

        this.EnabledBox := this.Gui.AddCheckbox("xm y+15", "Profile enabled")
        this.EnabledBox.OnEvent("Click", (*) => this.App.ToggleCurrentProfileEnabled())

        this.StatusText := this.Gui.AddText("x+20 yp+2 w420", "")

        this.Gui.AddGroupBox("xm y+15 w740 h180", "Create or edit key action")

        this.Gui.AddText("xm+15 yp+30", "Key")
        this.KeyEdit := this.Gui.AddEdit("x+10 yp-4 w120 ReadOnly")
        this.CaptureBtn := this.Gui.AddButton("x+10 yp-1 w120", "Capture Key")
        this.CaptureBtn.OnEvent("Click", (*) => this.CaptureKey())

        this.Gui.AddText("x+20 yp+4", "Action")
        this.ActionTypeDDL := this.Gui.AddDropDownList("x+10 yp-4 w120", ["Text", "Send", "Run", "Function"])
        this.ActionTypeDDL.Text := "Text"

        this.SaveBtn := this.Gui.AddButton("x+20 yp-1 w100", "Save")
        this.SaveBtn.OnEvent("Click", (*) => this.SaveBinding())

        this.DeleteBtn := this.Gui.AddButton("x+10 yp w100", "Delete")
        this.DeleteBtn.OnEvent("Click", (*) => this.DeleteBinding())

        this.Gui.AddText("xm+15 y+20", "Value")
        this.ValueEdit := this.Gui.AddEdit("xm+15 y+5 w710 h80 Multi WantTab")

        this.Gui.AddText("xm y+20", "Current bindings")
        this.BindingsLV := this.Gui.AddListView("xm y+5 w740 h260", ["Key", "Type", "Value preview"])
        this.BindingsLV.OnEvent("DoubleClick", (*) => this.LoadSelectedBinding())

        this.HelpText := this.Gui.AddText("xm y+10 w740", 
            "Default profile captures no keys. Switch to Python/CSharp/Coding/Gaming or create a profile, then bind a single key like F1, a, b, Space, Numpad1, etc."
        )

        this.Refresh()
    }

    Show() {
        this.Gui.Show("w780 h620")
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
        this.BindingsLV.Delete()

        profile := this.App.ProfileStore.CurrentProfile
        if !IsObject(profile) {
            return
        }

        for keyName, action in profile["bindings"] {
            this.BindingsLV.Add("", keyName, action["type"], PreviewText(action["value"], 80))
        }

        this.BindingsLV.ModifyCol(1, 110)
        this.BindingsLV.ModifyCol(2, 100)
        this.BindingsLV.ModifyCol(3, 500)
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

    CaptureKey() {
        if (this.App.ProfileStore.CurrentProfileName = "Default") {
            MsgBox("Default profile is intentionally a normal keyboard.`n`nSwitch to a macro profile first.")
            return
        }

        this.CaptureBtn.Text := "Press a key..."
        this.KeyEdit.Text := ""

        ih := InputHook("L1 T10")
        ih.KeyOpt("{All}", "E")
        ih.OnEnd := (inputHook) => this.FinishCapture(inputHook)
        ih.Start()
    }

    FinishCapture(inputHook) {
        keyName := ""

        if (inputHook.EndReason = "EndKey") {
            keyName := inputHook.EndKey
        } else if (inputHook.Input != "") {
            keyName := inputHook.Input
        }

        this.CaptureBtn.Text := "Capture Key"

        if (keyName = "") {
            return
        }

        this.KeyEdit.Text := keyName
    }

    SaveBinding() {
        this.App.SaveBinding(this.KeyEdit.Text, this.ActionTypeDDL.Text, this.ValueEdit.Text)
    }

    DeleteBinding() {
        keyName := this.KeyEdit.Text
        if (keyName = "") {
            keyName := this.GetSelectedKey()
        }

        if (keyName != "") {
            this.App.DeleteBinding(keyName)
            this.KeyEdit.Text := ""
            this.ValueEdit.Text := ""
        }
    }

    LoadSelectedBinding() {
        keyName := this.GetSelectedKey()
        if (keyName = "") {
            return
        }

        profile := this.App.ProfileStore.CurrentProfile
        if !profile["bindings"].Has(keyName) {
            return
        }

        action := profile["bindings"][keyName]
        this.KeyEdit.Text := keyName
        this.ActionTypeDDL.Text := action["type"]
        this.ValueEdit.Text := action["value"]
    }

    GetSelectedKey() {
        row := this.BindingsLV.GetNext()
        if (!row) {
            return ""
        }
        return this.BindingsLV.GetText(row, 1)
    }
}
