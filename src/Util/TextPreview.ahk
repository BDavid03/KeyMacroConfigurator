PreviewText(value, maxLen := 60) {
    value := StrReplace(value, "`r", " ")
    value := StrReplace(value, "`n", " ")
    value := RegExReplace(value, "\s+", " ")

    if (StrLen(value) > maxLen) {
        return SubStr(value, 1, maxLen - 3) "..."
    }

    return value
}
