#Include Util/IniEscaping.ahk

class ProfileStore {
    __New(profileDir) {
        this.ProfileDir := profileDir
        this.Profiles := Map()
        this.CurrentProfileName := "Default"
        this.CurrentProfile := ""
    }

    EnsureDefaultProfiles() {
        DirCreate(this.ProfileDir)

        for name in ["Default", "Python", "CSharp", "Coding", "Gaming"] {
            DirCreate(this.ProfileDir "\" name)
            filePath := this.ProfileDir "\" name "\profile.ini"
            if !FileExist(filePath) {
                IniWrite(name, filePath, "Profile", "name")
                IniWrite(name = "Default" ? "0" : "1", filePath, "Profile", "enabled")
            }
        }

        ; Seed example bindings only if empty. Default remains blank.
        pyFile := this.ProfileDir "\Python\profile.ini"
        if !IniRead(pyFile, "Binding.F1", "type", "") {
            IniWrite("Text", pyFile, "Binding.F1", "type")
            IniWrite(IniEscape("print()"), pyFile, "Binding.F1", "value")

            IniWrite("Text", pyFile, "Binding.F2", "type")
            IniWrite(IniEscape("import pandas as pd"), pyFile, "Binding.F2", "value")
        }

        csFile := this.ProfileDir "\CSharp\profile.ini"
        if !IniRead(csFile, "Binding.F1", "type", "") {
            IniWrite("Text", csFile, "Binding.F1", "type")
            IniWrite(IniEscape("Console.WriteLine();"), csFile, "Binding.F1", "value")
        }
    }

    LoadProfiles() {
        this.Profiles := Map()

        Loop Files, this.ProfileDir "\*", "D" {
            name := A_LoopFileName
            profile := this.LoadProfile(name)
            this.Profiles[name] := profile
        }
    }

    LoadProfile(name) {
        filePath := this.ProfileDir "\" name "\profile.ini"
        bindings := Map()

        profileName := IniRead(filePath, "Profile", "name", name)
        enabled := IniRead(filePath, "Profile", "enabled", "1") = "1"

        sectionsText := FileExist(filePath) ? FileRead(filePath, "UTF-8") : ""
        for section in ExtractIniSections(sectionsText) {
            if RegExMatch(section, "^Binding\.(.+)$", &m) {
                keyName := m[1]
                actionType := IniRead(filePath, section, "type", "Text")
                value := IniUnescape(IniRead(filePath, section, "value", ""))
                bindings[keyName] := Map(
                    "type", actionType,
                    "value", value
                )
            }
        }

        return Map(
            "name", profileName,
            "enabled", enabled,
            "bindings", bindings
        )
    }

    SaveCurrentProfile() {
        if !IsObject(this.CurrentProfile) {
            return
        }
        this.SaveProfile(this.CurrentProfile)
    }

    SaveProfile(profile) {
        name := profile["name"]
        DirCreate(this.ProfileDir "\" name)

        filePath := this.ProfileDir "\" name "\profile.ini"

        ; Rebuild the file to avoid stale deleted bindings.
        try FileDelete(filePath)

        IniWrite(name, filePath, "Profile", "name")
        IniWrite(profile["enabled"] ? "1" : "0", filePath, "Profile", "enabled")

        for keyName, action in profile["bindings"] {
            section := "Binding." keyName
            IniWrite(action["type"], filePath, section, "type")
            IniWrite(IniEscape(action["value"]), filePath, section, "value")
        }
    }

    SetCurrentProfile(name) {
        if !this.Profiles.Has(name) {
            this.CreateProfile(name)
            this.LoadProfiles()
        }

        this.CurrentProfileName := name
        this.CurrentProfile := this.Profiles[name]
    }

    CreateProfile(name) {
        DirCreate(this.ProfileDir "\" name)
        filePath := this.ProfileDir "\" name "\profile.ini"

        if !FileExist(filePath) {
            IniWrite(name, filePath, "Profile", "name")
            IniWrite(name = "Default" ? "0" : "1", filePath, "Profile", "enabled")
        }
    }

    GetProfileNames() {
        names := []
        for name, profile in this.Profiles {
            names.Push(name)
        }
        return names
    }
}
