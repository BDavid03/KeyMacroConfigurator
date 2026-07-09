EnableDarkTitleBar(hwnd) {
    static DWMWA_USE_IMMERSIVE_DARK_MODE := 20
    dark := 1
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", DWMWA_USE_IMMERSIVE_DARK_MODE, "int*", &dark, "int", 4)
}

EnableRoundedCorners(hwnd) {
    static DWMWA_WINDOW_CORNER_PREFERENCE := 33, DWMWCP_ROUND := 2
    pref := DWMWCP_ROUND
    try DllCall("dwmapi\DwmSetWindowAttribute", "ptr", hwnd, "int", DWMWA_WINDOW_CORNER_PREFERENCE, "int*", &pref, "int", 4)
}

; Dark visual style for buttons, edits and scrollbars. Use "DarkMode_CFD" for combo boxes.
UseDarkControlTheme(ctrl, subApp := "DarkMode_Explorer") {
    try DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.Hwnd, "wstr", subApp, "ptr", 0)
}

; Strips the visual style so the control honors the Gui's BackColor and font color
; (needed for checkboxes, whose themed painter ignores both).
RemoveControlTheme(ctrl) {
    try DllCall("uxtheme\SetWindowTheme", "ptr", ctrl.Hwnd, "wstr", "", "wstr", "")
}
