; Named functions available to "Function" bindings.
; To add one, register it here — no other code needs to change.
; The name is what users type as the binding value; the callable runs on keypress.
RegisterBuiltinFunctions(registry) {
    registry.Register("ShowDate", () => registry.PasteText(FormatTime(A_Now, "yyyy-MM-dd")))
    registry.Register("ShowDateTime", () => registry.PasteText(FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss")))
    registry.Register("ReloadScript", () => Reload())
    registry.Register("SuspendHotkeys", () => Suspend(-1))
    registry.Register("OpenScriptFolder", () => Run(A_ScriptDir))

    ; Snippet buffers — capture a value, then buffered snippets splice it in.
    registry.Register("BufferCaptureSelection", BufferCaptureSelection)
    registry.Register("BufferCaptureClipboard", BufferCaptureClipboard)
    registry.Register("BufferPasteActiveSlot", BufferPasteActiveSlot)
    registry.Register("BufferShowAllSlots", BufferShowAllSlots)
    registry.Register("BufferClearActiveSlot", BufferClearActiveSlot)
    registry.Register("BufferActivateNextSlot", BufferActivateNextSlot)
    registry.Register("BufferActivatePrevSlot", BufferActivatePrevSlot)
    registry.Register("BufferActivateSlot1", () => BufferActivateSlot(1))
    registry.Register("BufferActivateSlot2", () => BufferActivateSlot(2))
    registry.Register("BufferActivateSlot3", () => BufferActivateSlot(3))
    registry.Register("BufferPickSlotFromMenu", BufferPickSlotFromMenu)

    ; Python snippets, buffered — the active buffer's text is spliced into
    ; the template where {BUFFER} appears.
    registry.Register("WritePythonPrintBuffered", WritePythonPrintBuffered)
    registry.Register("WritePythonEnumerateBuffered", WritePythonEnumerateBuffered)
    registry.Register("WritePythonForBuffered", WritePythonForBuffered)
    registry.Register("WritePythonForEnumerateBuffered", WritePythonForEnumerateBuffered)
    registry.Register("WritePythonWhileBuffered", WritePythonWhileBuffered)
    registry.Register("WritePythonIfBuffered", WritePythonIfBuffered)
    registry.Register("WritePythonFStringBuffered", WritePythonFStringBuffered)

    ; Python snippets, non-buffered — buffers are ignored even when they hold
    ; text: the snippet is typed with the blank empty and the caret parked in it.
    registry.Register("WritePythonPrintNonBuffered", WritePythonPrintNonBuffered)
    registry.Register("WritePythonEnumerateNonBuffered", WritePythonEnumerateNonBuffered)
    registry.Register("WritePythonForNonBuffered", WritePythonForNonBuffered)
    registry.Register("WritePythonForEnumerateNonBuffered", WritePythonForEnumerateNonBuffered)
    registry.Register("WritePythonWhileNonBuffered", WritePythonWhileNonBuffered)
    registry.Register("WritePythonIfNonBuffered", WritePythonIfNonBuffered)
    registry.Register("WritePythonFStringNonBuffered", WritePythonFStringNonBuffered)

    ; No blank to fill, so this one has no buffered/non-buffered pair.
    registry.Register("WritePythonIfMain", WritePythonIfMain)

    ; Selection transforms — act on the currently selected text in place.
    registry.Register("SelectionToUpperCase", SelectionToUpperCase)
    registry.Register("SelectionToLowerCase", SelectionToLowerCase)
    registry.Register("SelectionToSnakeCase", SelectionToSnakeCase)

    ; Misc paste helpers.
    registry.Register("PasteGuid", () => SendText(NewGuid()))
    registry.Register("PasteEpoch", () => SendText(String(DateDiff(A_NowUTC, "19700101000000", "Seconds"))))
    registry.Register("PastePlainText", PastePlainText)

    ; Legacy names from before the buffered/non-buffered split, kept so
    ; profile bindings saved under the old names keep working.
    registry.Register("WritePythonPrint", WritePythonPrintBuffered)
    registry.Register("WritePythonIfTrue", WritePythonIfBuffered)
    registry.Register("OpenTerminal", OpenTerminal)
}

; =============================================================================
; Snippet buffers
;
; Three numbered slots hold captured text. Buffered snippet templates
; reference them with {BUFFER} (the active slot) or {BUFFER1}/{BUFFER2}/
; {BUFFER3} (a specific slot). If a referenced slot is empty the placeholder
; collapses and the caret is left at the first empty spot, so buffered
; snippets degrade to fill-in-the-blank.
;
; Typical flow: select a variable name, hit BufferCaptureSelection, then hit
; the WritePythonForBuffered key elsewhere → "for itm in my_list:".
; =============================================================================

global SnippetBuffers := Map(1, "`n", 2, "", 3, "")
global BufferActiveSlot := 1

; Fills the active slot from the current selection.
; Empties the clipboard, sends Ctrl+C, and waits up to half a second for the
; copy to arrive; the trimmed text goes into the active slot and the previous
; clipboard contents are restored either way. Notifies with a preview of what
; was captured, or with "nothing selected" if the copy produced nothing.
BufferCaptureSelection() {
    saved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.5) {
        A_Clipboard := saved
        Notify("Buffer " BufferActiveSlot ": nothing selected")
        return
    }
    SnippetBuffers[BufferActiveSlot] := Trim(A_Clipboard, " `t`r`n")
    A_Clipboard := saved
    Notify("Buffer " BufferActiveSlot " ← " BufferPreview(SnippetBuffers[BufferActiveSlot]))
}

; Fills the active slot from whatever the clipboard already holds.
; Sends no keystrokes — the clipboard text is trimmed and stored directly —
; so use this when the value was copied earlier or by another program.
BufferCaptureClipboard() {
    SnippetBuffers[BufferActiveSlot] := Trim(A_Clipboard, " `t`r`n")
    Notify("Buffer " BufferActiveSlot " ← " BufferPreview(SnippetBuffers[BufferActiveSlot]))
}

; Types the active slot's text at the caret.
; Uses SendText so the value comes out literally (special characters are not
; interpreted as keys); notifies instead of typing if the slot is empty.
BufferPasteActiveSlot() {
    val := BufferGetText()
    if (val = "") {
        Notify("Buffer " BufferActiveSlot " is empty")
        return
    }
    SendText(val)
}

; Shows a notification listing which slot is active and a one-line preview of
; every slot's contents. Purely informational — nothing is modified.
BufferShowAllSlots() {
    msg := "Active slot: " BufferActiveSlot
    for slot, val in SnippetBuffers {
        msg .= "`n" slot ": " BufferPreview(val)
    }
    Notify(msg, 2500)
}

; Empties the active slot and confirms with a notification.
BufferClearActiveSlot() {
    SnippetBuffers[BufferActiveSlot] := ""
    Notify("Buffer " BufferActiveSlot " cleared")
}

; Makes the given slot the active one — the slot that {BUFFER} resolves to
; and that the capture/paste/clear functions operate on.
; Extra variadic params so this can double as a Menu item callback.
BufferActivateSlot(slot, *) {
    global BufferActiveSlot
    BufferActiveSlot := slot
    Notify("Buffer slot " slot " → " BufferPreview(BufferGetText()))
}

; Cycle the active slot forward (1→2→3→1) or backward (1→3→2→1).
BufferActivateNextSlot() => BufferActivateSlot(BufferActiveSlot >= 3 ? 1 : BufferActiveSlot + 1)
BufferActivatePrevSlot() => BufferActivateSlot(BufferActiveSlot <= 1 ? 3 : BufferActiveSlot - 1)

; Pops up a menu at the mouse listing each slot's contents so one can be
; activated by clicking it. Each item is bound to BufferActivateSlot with its
; slot number, and the currently active slot is shown checkmarked.
BufferPickSlotFromMenu() {
    picker := Menu()
    for slot, val in SnippetBuffers {
        label := slot ": " BufferPreview(val)
        picker.Add(label, BufferActivateSlot.Bind(slot))
        if (slot = BufferActiveSlot) {
            picker.Check(label)
        }
    }
    picker.Show()
}

; Returns the text stored in a slot: the active slot when called with no
; argument (or ""), a specific slot when given its number. A slot that was
; never written reads as empty.
BufferGetText(slot := "") {
    slot := (slot = "") ? BufferActiveSlot : Integer(slot)
    return SnippetBuffers.Get(slot, "")
}

; Renders a slot value for notifications and menu labels: newlines flattened
; to spaces, text over 40 chars truncated with "...", empty shown as "(empty)".
BufferPreview(val) {
    val := StrReplace(val, "`n", " ")
    return val = "" ? "(empty)" : (StrLen(val) > 40 ? SubStr(val, 1, 37) "..." : val)
}

; Core writer behind every snippet function: types a template, splicing in
; buffer values. {BUFFER} = active slot, {BUFFER1}..{BUFFER3} = specific slots.
; Scans the template for placeholder tokens with a regex and replaces each
; with its slot's text — or with nothing when the slot is empty or useBuffers
; is false. After typing, if any placeholder came out empty, the caret is
; stepped back to the first blank with Left presses so the user can fill it in.
TypeSnippetTemplate(template, useBuffers := true) {
    out := ""
    firstEmptyPos := -1
    i := 1
    while (pos := RegExMatch(template, "\{BUFFER([1-3]?)\}", &m, i)) {
        out .= SubStr(template, i, pos - i)
        val := useBuffers ? BufferGetText(m[1]) : ""
        if (val = "" && firstEmptyPos = -1) {
            firstEmptyPos := StrLen(out)
        }
        out .= val
        i := pos + m.Len
    }
    out .= SubStr(template, i)
    SendText(out)
    if (firstEmptyPos >= 0) {
        back := StrLen(out) - firstEmptyPos
        if (back > 0) {
            Send("{Left " back "}")
        }
    }
}

; =============================================================================
; Python snippets (buffered)
;
; Each types its template through TypeSnippetTemplate with buffers enabled,
; so {BUFFER} becomes the active slot's text (buffer "xs" → "print(xs)").
; When the buffer is empty they behave like their non-buffered twins.
; =============================================================================

; Types print(<buffer>).
WritePythonPrintBuffered() => TypeSnippetTemplate("print({BUFFER})")

; Types enumerate(<buffer>).
WritePythonEnumerateBuffered() => TypeSnippetTemplate("enumerate({BUFFER})")

; Types a for loop over the buffer: "for itm in <buffer>:".
WritePythonForBuffered() => TypeSnippetTemplate("for itm in {BUFFER}:")

; Types an index-aware for loop: "for idx, itm in enumerate(<buffer>):".
WritePythonForEnumerateBuffered() => TypeSnippetTemplate("for idx, itm in enumerate({BUFFER}):")

; Types "while <buffer>:".
WritePythonWhileBuffered() => TypeSnippetTemplate("while {BUFFER}:")

; Types "if <buffer>:".
WritePythonIfBuffered() => TypeSnippetTemplate("if {BUFFER}:")

; Types f"{<buffer>}" via the shared f-string writer below.
WritePythonFStringBuffered() => WritePythonFString(BufferGetText())

; Types the standard script entry-point guard: if __name__ == "__main__":
; The template has no placeholder, so buffers never come into play.
WritePythonIfMain() => TypeSnippetTemplate('if __name__ == "__main__":')

; =============================================================================
; Python snippets (non-buffered)
;
; Same templates, but TypeSnippetTemplate is called with useBuffers false so
; the buffers are never consulted: the placeholder is always left blank and
; the caret parked there, fill-in-the-blank style.
; =============================================================================

; Types print() with the caret between the parentheses.
WritePythonPrintNonBuffered() => TypeSnippetTemplate("print({BUFFER})", false)

; Types enumerate() with the caret between the parentheses.
WritePythonEnumerateNonBuffered() => TypeSnippetTemplate("enumerate({BUFFER})", false)

; Types "for itm in :" with the caret before the colon.
WritePythonForNonBuffered() => TypeSnippetTemplate("for itm in {BUFFER}:", false)

; Types "for idx, itm in enumerate():" with the caret in the parentheses.
WritePythonForEnumerateNonBuffered() => TypeSnippetTemplate("for idx, itm in enumerate({BUFFER}):", false)

; Types "while :" with the caret before the colon.
WritePythonWhileNonBuffered() => TypeSnippetTemplate("while {BUFFER}:", false)

; Types "if :" with the caret before the colon.
WritePythonIfNonBuffered() => TypeSnippetTemplate("if {BUFFER}:", false)

; Types f"{}" with the caret between the braces.
WritePythonFStringNonBuffered() => WritePythonFString("")

; Shared writer for the f-string pair — built by hand because the output's
; literal braces would collide with the {BUFFER} token syntax inside a
; template string. Types f"{val}", and when val is empty steps the caret two
; characters left to sit between the braces.
WritePythonFString(val) {
    SendText('f"{' val '}"')
    if (val = "") {
        Send("{Left 2}")
    }
}

; =============================================================================
; Selection transforms
; =============================================================================

; Shared engine for the Selection* functions: copies the current selection,
; runs fn over the text, and pastes the result back over the selection. The
; clipboard is saved up front and restored at the end; if no selection
; arrives within half a second it notifies and leaves everything untouched.
TransformSelection(fn) {
    saved := ClipboardAll()
    A_Clipboard := ""
    Send("^c")
    if !ClipWait(0.5) {
        A_Clipboard := saved
        Notify("Nothing selected")
        return
    }
    A_Clipboard := fn(A_Clipboard)
    Send("^v")
    Sleep(60)
    A_Clipboard := saved
}

; Replace the selection with its UPPERCASE form.
SelectionToUpperCase() => TransformSelection(StrUpper)

; Replace the selection with its lowercase form.
SelectionToLowerCase() => TransformSelection(StrLower)

; Replace the selection with its snake_case form.
SelectionToSnakeCase() => TransformSelection(ToSnakeCase)

; Converts text to snake_case: inserts an underscore at each camelCase
; boundary, turns runs of spaces and hyphens into underscores, and lowercases
; the result.
ToSnakeCase(text) {
    text := RegExReplace(Trim(text), "([a-z0-9])([A-Z])", "$1_$2")
    text := RegExReplace(text, "[ \-]+", "_")
    return StrLower(text)
}

; =============================================================================
; Misc helpers
; =============================================================================

; Types the clipboard as raw text, stripping any rich formatting. SendText
; re-types the characters instead of pasting, so fonts/colors/links from the
; source never come along.
PastePlainText() {
    if (A_Clipboard != "") {
        SendText(A_Clipboard)
    }
}

; Builds a random version-4 GUID string, e.g. 3f2b8c1a-9d4e-4a7b-8c2d-1e5f6a7b8c9d.
; Draws 16 random bytes, forces the version nibble to 4 and the variant bits
; to 10 per RFC 4122, then hex-formats them with dashes in the standard
; 8-4-4-4-12 grouping.
NewGuid() {
    bytes := []
    Loop 16 {
        bytes.Push(Random(0, 255))
    }
    bytes[7] := (bytes[7] & 0x0F) | 0x40
    bytes[9] := (bytes[9] & 0x3F) | 0x80
    guid := ""
    for i, b in bytes {
        guid .= Format("{:02x}", b)
        if (i = 4 || i = 6 || i = 8 || i = 10) {
            guid .= "-"
        }
    }
    return guid
}


; Opens search and Opens Terminal App
OpenTerminal() {
    Send "{LWin}"
    Sleep 25
    Send "Terminal"
    Sleep 25
    Send "{Enter}"
}