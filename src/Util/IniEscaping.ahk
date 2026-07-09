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

; A binding is stored as one ini value: <type>|<escaped value>.
; The type never contains "|", so the value may.
FormatBindingValue(actionType, value) {
    return actionType "|" IniEscape(value)
}

ParseBindingValue(raw) {
    pos := InStr(raw, "|")
    actionType := pos ? SubStr(raw, 1, pos - 1) : "Text"
    value := pos ? SubStr(raw, pos + 1) : raw
    return Map("type", actionType, "value", IniUnescape(value))
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
