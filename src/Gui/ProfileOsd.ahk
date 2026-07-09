#Include ../Util/DarkMode.ahk

; Large borderless always-on-top overlay announcing the active profile.
; Click-through and non-activating so it never steals focus.
class ProfileOsd {
    __New() {
        this.Gui := ""
        this.NameText := ""
        this.SubText := ""
        this.HideFn := ObjBindMethod(this, "Hide")
        this.W := 460
        this.H := 150
    }

    ShowProfile(profileName, subtitle := "") {
        this.EnsureGui()
        this.NameText.Text := profileName
        this.SubText.Text := subtitle

        x := (A_ScreenWidth - this.W) // 2
        y := Round(A_ScreenHeight * 0.16)
        this.Gui.Show(Format("NoActivate x{} y{} w{} h{}", x, y, this.W, this.H))

        SetTimer(this.HideFn, -1600)
    }

    Hide(*) {
        if IsObject(this.Gui) {
            this.Gui.Hide()
        }
    }

    EnsureGui() {
        if IsObject(this.Gui) {
            return
        }

        ; WS_EX_NOACTIVATE | WS_EX_TRANSPARENT
        g := Gui("+AlwaysOnTop -Caption +ToolWindow +E0x08000020", "Active Profile")
        g.BackColor := "101114"

        g.AddText("x0 y0 w" this.W " h6 Background3A78C2")

        g.SetFont("s9 c7E8794", "Segoe UI")
        g.AddText("x0 y24 w" this.W " Center", "P R O F I L E")

        g.SetFont("s28 Bold cF2F5F9", "Segoe UI")
        this.NameText := g.AddText("x0 y46 w" this.W " Center", "")

        g.SetFont("s10 Norm c9AA3AF", "Segoe UI")
        this.SubText := g.AddText("x0 y104 w" this.W " Center", "")

        EnableRoundedCorners(g.Hwnd)
        WinSetTransparent(242, g)

        this.Gui := g
    }
}
