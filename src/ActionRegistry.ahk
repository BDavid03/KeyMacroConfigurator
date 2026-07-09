#Include Functions.ahk

class ActionRegistry {
    __New(profileStore) {
        this.ProfileStore := profileStore
        this.Functions := Map()
        this.Functions.CaseSense := "Off"
        RegisterBuiltinFunctions(this)
    }

    Register(name, fn) {
        this.Functions[name] := fn
    }

    GetFunctionNames() {
        names := []
        for name in this.Functions { 
            names.Push(name) 
        }
        return names
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
            case "Text": this.PasteText(value)
            case "Send": Send(value)
            case "Run": Run(value)
            case "Function": this.RunNamedFunction(value)
            default: this.PasteText(value)
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

        if this.Functions.Has(functionName) {
            this.Functions[functionName]()
            return
        }

        ; Fall back to any global function with this name, so functions
        ; defined in Functions.ahk work without an explicit Register call.
        try {
            fn := %functionName%
            if HasMethod(fn) {
                fn()
                return
            }
        }

        MsgBox("Unknown function: " functionName)
    }
}