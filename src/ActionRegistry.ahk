class ActionRegistry {
    __New(profileStore) {
        this.ProfileStore := profileStore
    }

    Execute(keyName) {
        profile := this.ProfileStore.CurrentProfile

        if !IsObject(profile) {
            return
        }

        if (profile["name"] = "Default") {
            return
        }

        if !profile["enabled"] {
            return
        }

        bindings := profile["bindings"]
        if !bindings.Has(keyName) {
            return
        }

        action := bindings[keyName]
        actionType := action["type"]
        value := action["value"]

        switch actionType {
            case "Text":
                this.PasteText(value)
            case "Send":
                Send(value)
            case "Run":
                Run(value)
            case "Function":
                this.RunNamedFunction(value)
            default:
                this.PasteText(value)
        }
    }

    PasteText(text) {
        oldClipboard := A_Clipboard
        A_Clipboard := text

        if !ClipWait(0.5) {
            A_Clipboard := oldClipboard
            return
        }

        Send("^v")
        Sleep(60)
        A_Clipboard := oldClipboard
    }


    RunNamedFunction(functionName) {
        functionName := Trim(functionName)

        switch functionName {
            case "ShowDate":
                this.PasteText(FormatTime(A_Now, "yyyy-MM-dd"))
            case "ShowDateTime":
                this.PasteText(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss"))
            case "ReloadScript":
                Reload()
            case "WritePythonPrint":
                WritePythonPrint()
            case "SuspendHotkeys":
                Suspend(-1)
            case "OpenScriptFolder":
                Run(A_ScriptDir)
            default:
                MsgBox("Unknown function: " functionName)
        }
    }
}

WritePythonPrint() {
    SendText "print('')"
    Send "{Left 2}"
}