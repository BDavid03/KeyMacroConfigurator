Notify(message, durationMs := 1200) {
    ToolTip(message)
    SetTimer(() => ToolTip(), -durationMs)
}
