#Include Util/IniEscaping.ahk

class ProfileStore {
    __New(profileDir) {
        this.ProfileDir := profileDir
        this.Profiles := Map()
        this.CurrentProfileName := "Default"
        this.CurrentProfile := ""
    }

    ProfilePath(name) {
        return this.ProfileDir "\" name ".ini"
    }

    EnsureDefaultProfiles() {
        DirCreate(this.ProfileDir)
        this.MigrateLegacyProfiles()
        this.MigrateBindingSections()

        for name in ["Default", "Python", "CSharp", "Coding", "Gaming"] {
            filePath := this.ProfilePath(name)
            if !FileExist(filePath) {
                IniWrite(name, filePath, "Profile", "name")
                IniWrite(name = "Default" ? "0" : "1", filePath, "Profile", "enabled")
            }
        }

        ; Seed example bindings only if empty. Default remains blank.
        pyFile := this.ProfilePath("Python")
        if !IniRead(pyFile, "Bindings", "F1", "") {
            IniWrite(FormatBindingValue("Text", "print()"), pyFile, "Bindings", "F1")
            IniWrite(FormatBindingValue("Text", "import pandas as pd"), pyFile, "Bindings", "F2")
        }

        csFile := this.ProfilePath("CSharp")
        if !IniRead(csFile, "Bindings", "F1", "") {
            IniWrite(FormatBindingValue("Text", "Console.WriteLine();"), csFile, "Bindings", "F1")
        }
    }

    ; Old layout stored each profile as profiles\<Name>\profile.ini.
    ; Move those files to profiles\<Name>.ini and drop the empty folders.
    MigrateLegacyProfiles() {
        Loop Files, this.ProfileDir "\*", "D" {
            legacyFile := A_LoopFileFullPath "\profile.ini"
            targetFile := this.ProfilePath(A_LoopFileName)

            if FileExist(legacyFile) && !FileExist(targetFile) {
                FileMove(legacyFile, targetFile)
            }

            ; Fails (harmlessly) if the folder still holds anything else.
            try DirDelete(A_LoopFileFullPath)
        }
    }

    ; Old layout stored each binding as its own [Binding.<key>] section.
    ; Rewrite those files as one <key>=<type>|<value> line under [Bindings].
    MigrateBindingSections() {
        Loop Files, this.ProfileDir "\*.ini" {
            if !InStr(FileRead(A_LoopFileFullPath), "[Binding.") {
                continue
            }
            SplitPath(A_LoopFileName, , , , &name)
            this.SaveProfile(this.LoadProfile(name))
        }
    }

    LoadProfiles() {
        this.Profiles := Map()

        Loop Files, this.ProfileDir "\*.ini" {
            SplitPath(A_LoopFileName, , , , &name)
            this.Profiles[name] := this.LoadProfile(name)
        }
    }

    LoadProfile(name) {
        filePath := this.ProfilePath(name)
        bindings := Map()

        profileName := IniRead(filePath, "Profile", "name", name)
        enabled := IniRead(filePath, "Profile", "enabled", "1") = "1"

        ; One line per binding: <key>=<type>|<escaped value>
        bindingLines := ""
        try bindingLines := IniRead(filePath, "Bindings")
        Loop Parse bindingLines, "`n", "`r" {
            pos := InStr(A_LoopField, "=")
            if !pos {
                continue
            }
            bindings[SubStr(A_LoopField, 1, pos - 1)] := ParseBindingValue(SubStr(A_LoopField, pos + 1))
        }

        ; Legacy layout: one [Binding.<key>] section per binding.
        sectionsText := FileExist(filePath) ? FileRead(filePath, "UTF-8") : ""
        for section in ExtractIniSections(sectionsText) {
            if RegExMatch(section, "^Binding\.(.+)$", &m) && !bindings.Has(m[1]) {
                bindings[m[1]] := Map(
                    "type", IniRead(filePath, section, "type", "Text"),
                    "value", IniUnescape(IniRead(filePath, section, "value", ""))
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
        DirCreate(this.ProfileDir)

        filePath := this.ProfilePath(name)

        ; Rebuild the file to avoid stale deleted bindings.
        try FileDelete(filePath)

        IniWrite(name, filePath, "Profile", "name")
        IniWrite(profile["enabled"] ? "1" : "0", filePath, "Profile", "enabled")

        pairs := ""
        for keyName, action in profile["bindings"] {
            pairs .= keyName "=" FormatBindingValue(action["type"], action["value"]) "`n"
        }
        if (pairs != "") {
            IniWrite(RTrim(pairs, "`n"), filePath, "Bindings")
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
        DirCreate(this.ProfileDir)
        filePath := this.ProfilePath(name)

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
