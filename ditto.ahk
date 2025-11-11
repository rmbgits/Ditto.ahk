/*
Ditto by Rafał Bobrowski
---------------------------------------------------------
Otwarta, lekka alternatywa dla klasycznego Ditto — overlay schowka w stylu Ditto, napisany w AutoHotkey v1. 
Zawsze‑on‑top, obsługa historii, hotkeye, zwijany tryb. 
Autor: Rafał Bobrowski
GitHub: https://github.com/rmbgits/Ditto.ahk
Zapisz plik po edycji jako UTF-8 with BOM
---------------------------------------------------------
*/
#NoEnv
#Persistent
#SingleInstance Ignore
SetBatchLines, -1
SetWinDelay, 0

WindowTitle := "Ditto by RB"
ScriptPath := A_ScriptFullPath
; Ustaw na true, jeśli chcesz wrócić do pliku INI
USE_INI := false
IniPath := A_ScriptDir . "\DittoRB.ini"

MaxHistory := 10
ClipHistory := []

global IsCollapsed := false
global GuiWidth := 290
global SafeMargin := 14

; Layout
global M := 12
global G := 8
global TitleH := 26
global BtnH := 26
global ListH := 186
global CheckH := 24

; GUI controls
global MyList
global CollapsedLbl
global AutoPasteChk
global HotkeysChk
global ClearBtn
global RbBtn
global ToggleBtn
global RbValBtn

; collapsed size
global CollapsedW := 110
global CollapsedH := 60

; Toggle geometry
global ToggleBtnAbsX := 0
global ToggleBtnAbsY := 0
global ToggleFullW := 46
global ToggleFullH := 26

global LastSeen := ""

; Restore size
global FullX := ""
global FullY := ""
global FullW := ""
global FullH := ""

global AutoPasteEnabled := true
global HotkeysEnabled := true

; RB value
global RB_VALUE := "Rafał Bobrowski"
if (USE_INI && FileExist(IniPath)) {
    IniRead, RB_VALUE, %IniPath%, RB, Value, %RB_VALUE%
}

Clipboard := ""
LastSeen := ""

; Timers
SetTimer, CheckClipboard, 500
SetTimer, __GuardTopmostAndBounds, 3000
SetTimer, __TrackFullPosition, 800

OnMessage(0x007E, "OnDisplayChange")

ShowClipboardGUI()
return

; --------------------------- Helpers ---------------------------

FormatPreview(txt, maxLen := 27) {
    txt := StrReplace(txt, "`r", "")
    txt := StrReplace(txt, "`n", " ")
    txt := RegExReplace(txt, "\s+", " ")
    if (StrLen(txt) > maxLen)
        return SubStr(txt, 1, maxLen) . "..."
    return txt
}

BuildListItems() {
    global ClipHistory
    if (ClipHistory.Length() = 0)
        return ""
    s := ""
    maxNum := 5
    Loop % ClipHistory.Length() {
        itemNum := A_Index <= maxNum ? A_Index ". " : ""
        s .= (A_Index=1 ? "" : "|") . itemNum . FormatPreview(ClipHistory[A_Index])
    }
    return s
}

UpdateList() {
    global MyList, ClipHistory, WindowTitle
    if (WinExist(WindowTitle)) {
        GuiControl,, MyList, |
        GuiControl,, MyList, % BuildListItems()
    }
}

InHistory(txt) {
    global ClipHistory
    for idx, item in ClipHistory
        if (item = txt)
            return true
    return false
}

; --------------------------- Clipboard polling ---------------------------

CheckClipboard:
    global IsCollapsed, LastSeen, WindowTitle, MaxHistory
    ClipWait, 1
    clipText := Clipboard
    clipText := Trim(clipText)
    if (clipText != "" && clipText != LastSeen && !InHistory(clipText)) {
        ClipHistory.InsertAt(1, clipText)
        LastSeen := clipText
        if (ClipHistory.Length() > MaxHistory)
            ClipHistory.RemoveAt(MaxHistory + 1)
        UpdateList()
        if (WinExist(WindowTitle)) {
            WinSet, AlwaysOnTop, On, %WindowTitle%
            WinSet, Transparent, 180, %WindowTitle%
            WinShow, %WindowTitle%
        }
    }
return

; --------------------------- GUI creation ---------------------------

ShowClipboardGUI() {
    global GuiWidth, SafeMargin, M, G, TitleH, BtnH, ListH, CheckH, WindowTitle
    global MyList, CollapsedLbl, AutoPasteChk, HotkeysChk, ClearBtn, RbBtn, ToggleBtn, RbValBtn
    global ToggleBtnAbsX, ToggleBtnAbsY, ToggleFullW, ToggleFullH

    SysGet, MonitorWorkArea, MonitorWorkArea

    InnerW := GuiWidth - 2*M
    totalH := M + TitleH + G + ListH + G + CheckH + M

    x := MonitorWorkAreaRight - GuiWidth - SafeMargin
    y := MonitorWorkAreaTop + ((MonitorWorkAreaBottom - MonitorWorkAreaTop) // 2) - (totalH // 2)

    BtnY := M + ((TitleH - BtnH) // 2)

    ; Top row: RB value | RB | Clear | >>>
    ValW := 84
    RbW  := 44
    ClrW := 56
    TglW := ToggleFullW

    TglX := M + InnerW - TglW
    ClrX := TglX - G - ClrW
    RbX  := ClrX - G - RbW
    ValX := RbX - G - ValW
    if (ValX < M) {
        ValX := M
        RbX := ValX + ValW + G
        ClrX := RbX + RbW + G
        TglX := ClrX + ClrW + G
    }

    Gui, -DPIScale
    Gui, +AlwaysOnTop -Caption +Border
    Gui, Color, F0F0F0
    Gui, Margin, %M%, %M%
    Gui, Font, s10, Segoe UI

    Gui, +LastFound
    hwnd := WinExist()
    exStyle := DllCall("GetWindowLong", "Ptr", hwnd, "Int", -20, "UInt")
    WS_EX_NOACTIVATE := 0x08000000
    DllCall("SetWindowLong", "Ptr", hwnd, "Int", -20, "UInt", exStyle | WS_EX_NOACTIVATE)

    Gui, Add, Button, vRbValBtn gOpenRbValue x%ValX% y%BtnY% w%ValW% h%BtnH%, RB value
    Gui, Add, Button, vRbBtn     gPasteRB     x%RbX%  y%BtnY% w%RbW%  h%BtnH%, RB
    Gui, Add, Button, vClearBtn  gClearClipboard x%ClrX% y%BtnY% w%ClrW% h%BtnH%, Clear
    Gui, Add, Button, vToggleBtn gToggleCollapse x%TglX% y%BtnY% w%TglW% h%BtnH%, >>>

    ToggleBtnAbsX := TglX
    ToggleBtnAbsY := BtnY

    ListX := M, ListY := M + TitleH + G, ListW := InnerW
    Gui, Add, ListBox, vMyList gListClick x%ListX% y%ListY% w%ListW% h%ListH% AltSubmit, % BuildListItems()

    CheckY := ListY + ListH + G
    HalfW := (InnerW - G) // 2
    AutoX := M, AutoW := HalfW
    KeysX := M + HalfW + G, KeysW := HalfW
    Gui, Add, Checkbox, vAutoPasteChk gToggleAutoPaste x%AutoX% y%CheckY% w%AutoW% h%CheckH% Checked1, Auto-Paste
    Gui, Add, Checkbox, vHotkeysChk gToggleHotkeys x%KeysX% y%CheckY% w%KeysW% h%CheckH% Checked1, Keys(Ctrl+1)

    Gui, Add, Text, vCollapsedLbl x%M% y%M% w64 h%TitleH% Center, Ditto
    GuiControl, Hide, CollapsedLbl

    Gui, Show, x%x% y%y% w%GuiWidth% h%totalH% NA, %WindowTitle%
    WinSet, Transparent, 180, %WindowTitle%
    WinSet, AlwaysOnTop, On, %WindowTitle%

    WinGetPos, wx, wy, ww, wh, %WindowTitle%
    __ClampToWorkArea(wx, wy, ww, wh)
    if (wx != x || wy != y) {
        WinMove, %WindowTitle%,, wx, wy
        WinGetPos, wx, wy, ww, wh, %WindowTitle%
    }

    FullX := wx
    FullY := wy
    FullW := ww
    FullH := wh

    IsCollapsed := false
    GuiControl, Hide, CollapsedLbl
}

; --------------------------- RB value modal ---------------------------

OpenRbValue:
    global RB_VALUE, USE_INI, IniPath
    Gui, RB: New, +AlwaysOnTop +Border +Owner +Caption, RB value
    Gui, RB: Font, s10, Segoe UI
    Gui, RB: Margin, 10, 10
    Gui, RB: Add, Text, w320, type value u want to paste by RB button
    Gui, RB: Add, Edit, vRBValEdit w320 h26, %RB_VALUE%
    Gui, RB: Add, Button, gRB_Save w80 h26, Save
    Gui, RB: Add, Button, gRB_Cancel w80 h26 x+8, Cancel
    Gui, RB: Show, AutoSize Center
    Gui, RB: Default
    ControlFocus, Edit1, RB value
return

RB_Save:
    global RB_VALUE, USE_INI, IniPath
    Gui, RB: Submit
    if (RBValEdit != "")
        RB_VALUE := RBValEdit
    if (USE_INI) {
        IniWrite, %RB_VALUE%, %IniPath%, RB, Value
        Gui, RB: Destroy
    } else {
        __UpdateSelfRBValue(RB_VALUE)
        Gui, RB: Destroy
        Reload
    }
return

RB_Cancel:
    Gui, RB: Destroy
return

; --------------------------- Collapse / Expand ---------------------------

ToggleCollapse:
    global IsCollapsed, WindowTitle
    global M, SafeMargin, CollapsedW, CollapsedH
    global FullX, FullY, FullW, FullH
    global MyList, AutoPasteChk, HotkeysChk, ClearBtn, RbBtn, ToggleBtn, CollapsedLbl, RbValBtn

    SysGet, m, MonitorWorkArea

    if (!IsCollapsed) {
        NewWidth := CollapsedW
        NewHeight := CollapsedH

        cx := mRight - NewWidth - SafeMargin
        cy := FullY
        if (cy < mTop + SafeMargin)
            cy := mTop + SafeMargin
        if (cy + NewHeight > mBottom - SafeMargin)
            cy := mBottom - NewHeight - SafeMargin

        GuiControl, Hide, MyList
        GuiControl, Hide, AutoPasteChk
        GuiControl, Hide, HotkeysChk
        GuiControl, Hide, ClearBtn
        GuiControl, Hide, RbBtn
        GuiControl, Hide, ToggleBtn
        GuiControl, Hide, RbValBtn
        GuiControl, Show, CollapsedLbl

        WinMove, %WindowTitle%,, cx, cy, NewWidth, NewHeight
        Gui, Show, w%NewWidth% h%NewHeight% NA

        IsCollapsed := true
        OnMessage(0x201, "CollapsedClick")
        WinSet, AlwaysOnTop, On, %WindowTitle%
    } else {
        rx := FullX, ry := FullY, rw := FullW, rh := FullH

        changed := false
        if (rx + rw > mRight - 1) {
            rx := mRight - rw - SafeMargin, changed := true
        }
        if (rx < mLeft + SafeMargin) {
            rx := mLeft + SafeMargin, changed := true
        }
        if (ry < mTop + SafeMargin) {
            ry := mTop + SafeMargin, changed := true
        }
        if (ry + rh > mBottom - SafeMargin) {
            ry := mBottom - rh - SafeMargin, changed := true
        }

        WinMove, %WindowTitle%,, rx, ry, rw, rh

        GuiControl, Show, MyList
        GuiControl, Show, AutoPasteChk
        GuiControl, Show, HotkeysChk
        GuiControl, Show, ClearBtn
        GuiControl, Show, RbBtn
        GuiControl, Show, ToggleBtn
        GuiControl, Show, RbValBtn
        GuiControl, Hide, CollapsedLbl

        UpdateList()
        Gui, Show, w%rw% h%rh% NA

        IsCollapsed := false
        OnMessage(0x201, "")
        WinSet, AlwaysOnTop, On, %WindowTitle%

        FullX := rx
        FullY := ry
        FullW := rw
        FullH := rh
    }
return

CollapsedClick(wParam, lParam, msg, hwnd) {
    SetTimer, __ExpandFromClick, -1
}
__ExpandFromClick:
    Gosub, ToggleCollapse
return

; --------------------------- Toggles & list ---------------------------

ToggleAutoPaste:
    Gui, Submit, NoHide
    AutoPasteEnabled := AutoPasteChk
return

ToggleHotkeys:
    Gui, Submit, NoHide
    HotkeysEnabled := HotkeysChk
return

ListClick:
    global MyList, ClipHistory, AutoPasteEnabled
    Gui, Submit, NoHide
    selected := MyList
    if (selected > 0 && selected <= ClipHistory.Length()) {
        Clipboard := ClipHistory[selected]
        if (AutoPasteEnabled) {
            WinGet, activeWinID, ID, A
            Sleep, 70
            SendInput, ^v
        }
    }
return

GuiClose:
    Gui, Hide
return

; --------------------------- Hotkeys historii ---------------------------

^1::PasteByNumber(1)
^2::PasteByNumber(2)
^3::PasteByNumber(3)
^4::PasteByNumber(4)
^5::PasteByNumber(5)

PasteByNumber(n) {
    global ClipHistory, HotkeysEnabled
    if (n > 0 && n <= ClipHistory.Length()) {
        Clipboard := ClipHistory[n]
        if (HotkeysEnabled) {
            WinGet, activeWinID, ID, A
            Sleep, 70
            SendInput, ^v
        }
    } else {
        MsgBox, 48, Clipboard Manager, Brak wpisu numer %n% w historii.
    }
}

; --------------------------- Buttons logic ---------------------------

ClearClipboard:
    global ClipHistory, LastSeen, AutoPasteEnabled, HotkeysEnabled
    ClipHistory := []
    LastSeen := ""
    AutoPasteEnabled := true
    HotkeysEnabled := true
    GuiControl,, MyList, |
    GuiControl,, AutoPasteChk, 1
    GuiControl,, HotkeysChk, 1
return

; RB: wstawia stały tekst przez SendInput
PasteRB:
    global RB_VALUE
    Sleep, 40
    SendInput, %RB_VALUE%
return

; --------------------------- Guards & utilities ---------------------------

OnDisplayChange(wParam, lParam, msg, hwnd) {
    SetTimer, __GuardTopmostAndBounds, -1
}

__GuardTopmostAndBounds:
    global WindowTitle, SafeMargin
    if WinExist(WindowTitle) {
        WinSet, AlwaysOnTop, On, %WindowTitle%
        SysGet, m, MonitorWorkArea
        WinGetPos, gx, gy, gw, gh, %WindowTitle%
        changed := false
        if (gx + gw > mRight - 1) {
            gx := mRight - gw - SafeMargin, changed := true
        }
        if (gx < mLeft + SafeMargin) {
            gx := mLeft + SafeMargin, changed := true
        }
        if (gy < mTop + SafeMargin) {
            gy := mTop + SafeMargin, changed := true
        }
        if (gy + gh > mBottom - SafeMargin) {
            gy := mBottom - gh - SafeMargin, changed := true
        }
        if (changed) {
            WinMove, %WindowTitle%,, gx, gy
        }
    }
return

__TrackFullPosition:
    global IsCollapsed, WindowTitle, FullX, FullY, FullW, FullH
    if (!IsCollapsed && WinExist(WindowTitle)) {
        WinGetPos, tx, ty, tw, th, %WindowTitle%
        if (tx != FullX || ty != FullY || tw != FullW || th != FullH) {
            FullX := tx
            FullY := ty
            FullW := tw
            FullH := th
        }
    }
return

__ClampToWorkArea(ByRef x, ByRef y, ByRef w, ByRef h) {
    global SafeMargin
    SysGet, m, MonitorWorkArea
    __ClampRect(mLeft, mTop, mRight, mBottom, x, y, w, h, SafeMargin)
}

__ClampRect(mLeft, mTop, mRight, mBottom, ByRef x, ByRef y, ByRef w, ByRef h, margin) {
    if (x + w > mRight - 1)
        x := mRight - w - margin
    if (x < mLeft + margin)
        x := mLeft + margin
    if (y < mTop + margin)
        y := mTop + margin
    if (y + h > mBottom - margin)
        y := mBottom - h - margin
}

; --------------------------- Self-update RB_VALUE ---------------------------

__UpdateSelfRBValue(newVal) {
    global ScriptPath
    FileRead, src, %ScriptPath%
    if (ErrorLevel) {
        MsgBox, 16, RB, Nie udało się odczytać pliku skryptu: %ScriptPath%
        return
    }
    newValEsc := StrReplace(newVal, """", """""")
    newSrc := ""
    replaced := false
    Loop, Parse, src, `n, `r
    {
        line := A_LoopField
        if (!replaced && RegExMatch(line, "i)^\s*global\s+RB_VALUE\s*:=")) {
            newSrc .= "global RB_VALUE := """ newValEsc """" "`r`n"
            replaced := true
        } else {
            newSrc .= line "`r`n"
        }
    }
    if (!replaced) {
        MsgBox, 48, RB, Nie znaleziono linii 'global RB_VALUE := "...' do podmiany.
        return
    }
    FileDelete, %ScriptPath%
    FileAppend, %newSrc%, %ScriptPath%, UTF-8
}



