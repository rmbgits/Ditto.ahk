#NoEnv
#Persistent
#SingleInstance Ignore
SetBatchLines, -1
SetWinDelay, 0

; ---------------------------
; Optional strong singleton (uncomment to enforce across copies)
; global hMutex := DllCall("CreateMutex", "ptr", 0, "int", true, "str", "RB.DittoAHK.Singleton", "ptr")
; if (DllCall("GetLastError") = 183) {
;     if WinExist("Ditto by RB")
;         WinActivate
;     ExitApp
; }
; OnExit("ReleaseMutex")
; ReleaseMutex() {
;     global hMutex
;     if (hMutex)
;         DllCall("CloseHandle", "ptr", hMutex)
; }
; ---------------------------

WindowTitle := "Ditto by RB"

MaxHistory := 10
ClipHistory := []

global IsCollapsed := false
global GuiWidth := 290
global SafeMargin := 14

; Layout
global M := 12
global G := 8
global TitleH := 26
global BtnW := 70, BtnH := 26
global ListH := 186
global CheckH := 24

global ToggleBtn
global MyList
global TitleLbl
global CollapsedLbl
global AutoPasteChk
global HotkeysChk
global LastSeen := ""

global StartX := ""
global StartY := ""
global StartW := ""
global StartH := ""

; Zapamiętana pełna pozycja (referencyjna dla rozwijania)
global FullX := ""
global FullY := ""
global FullW := ""
global FullH := ""

global ToggleBtnAbsX := 0
global ToggleBtnAbsY := 0
global ToggleFullW := 70
global ToggleFullH := 26

global AutoPasteEnabled := true
global HotkeysEnabled := true

Clipboard := ""
LastSeen := ""

; Timers
SetTimer, CheckClipboard, 500
SetTimer, __GuardTopmostAndBounds, 3000
SetTimer, __TrackFullPosition, 800

; Messages
OnMessage(0x007E, "OnDisplayChange")   ; WM_DISPLAYCHANGE

ShowClipboardGUI()
return

; ---------------------------
; Helpers
; ---------------------------

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

; ---------------------------
; Clipboard polling
; ---------------------------

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

        ; Bez Destroy/Recreate — tylko odśwież i wzmocnij topmost
        UpdateList()
        if (WinExist(WindowTitle)) {
            WinSet, AlwaysOnTop, On, %WindowTitle%
            WinSet, Transparent, 180, %WindowTitle%
            WinShow, %WindowTitle%
        }
    }
return

; ---------------------------
; GUI creation
; ---------------------------

ShowClipboardGUI() {
    global ClipHistory, GuiWidth, SafeMargin, IsCollapsed
    global ToggleBtn, MyList, TitleLbl, CollapsedLbl, AutoPasteChk, HotkeysChk
    global StartX, StartY, StartW, StartH, WindowTitle
    global ToggleBtnAbsX, ToggleBtnAbsY, ToggleFullW, ToggleFullH
    global AutoPasteEnabled, HotkeysEnabled
    global M, G, TitleH, BtnW, BtnH, ListH, CheckH
    global FullX, FullY, FullW, FullH

    SysGet, MonitorWorkArea, MonitorWorkArea

    InnerW := GuiWidth - 2*M

    totalH := M + TitleH + G + ListH + G + CheckH + M
    x := MonitorWorkAreaRight - GuiWidth - SafeMargin
    y := MonitorWorkAreaTop + ((MonitorWorkAreaBottom - MonitorWorkAreaTop) // 2) - (totalH // 2)

    TitleX := M, TitleY := M, TitleW := InnerW
    BtnX := M + InnerW - BtnW
    BtnY := M + ((TitleH - BtnH) // 2)
    ListX := M, ListY := M + TitleH + G, ListW := InnerW
    CheckY := ListY + ListH + G
    HalfW := (InnerW - G) // 2
    AutoX := M, AutoW := HalfW
    KeysX := M + HalfW + G, KeysW := HalfW
    CollX := M, CollY := M

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

    Gui, Add, Text, vTitleLbl x%TitleX% y%TitleY% w%TitleW% h%TitleH% Center, % WindowTitle
    Gui, Add, Button, vToggleBtn gToggleCollapse x%BtnX% y%BtnY% w%BtnW% h%BtnH%, >>>
    ToggleBtnAbsX := BtnX
    ToggleBtnAbsY := BtnY

    Gui, Add, ListBox, vMyList gListClick x%ListX% y%ListY% w%ListW% h%ListH% AltSubmit, % BuildListItems()

    Gui, Add, Checkbox, vAutoPasteChk gToggleAutoPaste x%AutoX% y%CheckY% w%AutoW% h%CheckH% Checked%AutoPasteEnabled%, Auto-Paste
    Gui, Add, Checkbox, vHotkeysChk gToggleHotkeys x%KeysX% y%CheckY% w%KeysW% h%CheckH% Checked%HotkeysEnabled%, Keys(Ctrl+1)

    Gui, Add, Text, vCollapsedLbl x%CollX% y%CollY% w64 h%TitleH% Center, Ditto
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

    ; Ustal pełną pozycję referencyjną
    FullX := wx
    FullY := wy
    FullW := ww
    FullH := wh

    StartX := wx
    StartY := wy
    StartW := ww
    StartH := wh

    IsCollapsed := false
    GuiControl,, ToggleBtn, >>>
    GuiControl, Show, TitleLbl
    GuiControl, Hide, CollapsedLbl
}

; ---------------------------
; Collapse / Expand
; ---------------------------

ToggleCollapse:
    global IsCollapsed, ToggleBtn, WindowTitle, TitleLbl, CollapsedLbl
    global StartX, StartY, StartW, StartH
    global ToggleBtnAbsX, ToggleBtnAbsY, ToggleFullW, ToggleFullH
    global M, SafeMargin
    global FullX, FullY, FullW, FullH

    SysGet, m, MonitorWorkArea

    if (!IsCollapsed) {
        NewWidth := 110
        NewHeight := 60

        ; Zachowaj Y z pełnego trybu, X do prawej krawędzi
        cx := mRight - NewWidth - SafeMargin
        cy := FullY
        if (cy < mTop + SafeMargin)
            cy := mTop + SafeMargin
        if (cy + NewHeight > mBottom - SafeMargin)
            cy := mBottom - NewHeight - SafeMargin

        GuiControl, Hide, TitleLbl
        GuiControl, Hide, MyList
        GuiControl,, ToggleBtn,
        GuiControl, Move, ToggleBtn, x%M% y%M% w1 h1
        GuiControl, Show, CollapsedLbl

        WinMove, %WindowTitle%,, cx, cy, NewWidth, NewHeight
        Gui, Show, w%NewWidth% h%NewHeight% NA

        IsCollapsed := true
        OnMessage(0x201, "CollapsedClick")
        WinSet, AlwaysOnTop, On, %WindowTitle%
    } else {
        ; Przywróć pełną pozycję
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

        GuiControl, Show, TitleLbl
        GuiControl, Show, MyList
        GuiControl,, ToggleBtn, >>>
        GuiControl, Move, ToggleBtn, x%ToggleBtnAbsX% y%ToggleBtnAbsY% w%ToggleFullW% h%ToggleFullH%
        GuiControl, Hide, CollapsedLbl

        UpdateList()
        Gui, Show, w%rw% h%rh% NA

        IsCollapsed := false
        OnMessage(0x201, "")
        WinSet, AlwaysOnTop, On, %WindowTitle%

        ; Zaktualizuj bazę pełnej pozycji
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

; ---------------------------
; Toggles
; ---------------------------

ToggleAutoPaste:
    Gui, Submit, NoHide
    AutoPasteEnabled := AutoPasteChk
return

ToggleHotkeys:
    Gui, Submit, NoHide
    HotkeysEnabled := HotkeysChk
return

; ---------------------------
; List click paste
; ---------------------------

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

; ---------------------------
; Hotkeys
; ---------------------------

^1::PasteByNumber(1)
^2::PasteByNumber(2)
^3::PasteByNumber(3)
^4::PasteByNumber(4)
^5::PasteByNumber(5)

; Rescue: bring overlay to front
^!d::
    if WinExist(WindowTitle) {
        WinShow, %WindowTitle%
        WinSet, AlwaysOnTop, On, %WindowTitle%
    }
return

; Save current full position (manual)
^!s::
    if (!IsCollapsed && WinExist(WindowTitle)) {
        WinGetPos, tx, ty, tw, th, %WindowTitle%
        FullX := tx, FullY := ty, FullW := tw, FullH := th
        ToolTip, Saved position: %FullX%x%FullY% %FullW%x%FullH%, 20, 20
        SetTimer, __HideTip, -1200
    }
return
__HideTip:
    ToolTip
return

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

; ---------------------------
; Guards & utilities
; ---------------------------

OnDisplayChange(wParam, lParam, msg, hwnd) {
    ; natychmiastowa kontrola po zmianie ekranu/DPI
    SetTimer, __GuardTopmostAndBounds, -1
}

__GuardTopmostAndBounds:
    global WindowTitle, SafeMargin
    if WinExist(WindowTitle) {
        ; Reinforce TopMost
        WinSet, AlwaysOnTop, On, %WindowTitle%

        ; Clamp tylko gdy realnie poza ekranem
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
