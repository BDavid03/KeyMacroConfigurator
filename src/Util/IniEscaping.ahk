IniEscape(value) {
    value := StrReplace(value, "``", "````")
    value := StrReplace(value, "`r`n", "\n")
    value := StrReplace(value, "`n", "\n")
    value := StrReplace(value, "`r", "\n")
    return value
}

IniUnescape(value) {
    value := StrReplace(value, "\n", "`n")
    value := StrReplace(value, "````", "``")
    return value
}

ExtractIniSections(text) {
    sections := []

    Loop Parse text, "`n", "`r" {
        line := Trim(A_LoopField)
        if RegExMatch(line, "^\[(.+)\]$", &m) {
            sections.Push(m[1])
        }
    }

    return sections
}
