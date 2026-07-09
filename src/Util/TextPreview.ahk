; Short keycap-friendly label for a binding. Run bindings show as
; "launch_<app>" derived from the target's filename instead of the full path.
ActionPreview(action, maxLen := 60) {
    actionType := action["type"]
    value := Trim(action["value"])

    if (actionType = "Run") {
        target := Trim(value, ' "')
        SplitPath(target, , , , &stem)
        if (stem != "") {
            return PreviewText("launch_" stem, maxLen)
        }
    } else if (actionType = "Function") {
        return PreviewText(value "()", maxLen)
    }

    return PreviewText(value, maxLen)
}

PreviewText(value, maxLen := 60) {
    value := StrReplace(value, "`r", " ")
    value := StrReplace(value, "`n", " ")
    value := RegExReplace(value, "\s+", " ")

    if (StrLen(value) > maxLen) {
        return SubStr(value, 1, maxLen - 3) "..."
    }

    return value
}
