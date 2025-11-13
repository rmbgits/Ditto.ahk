/*
Ditto by Rafał Bobrowski
---------------------------------------------------------
Otwarta, lekka alternatywa dla klasycznego Ditto — overlay schowka w stylu Ditto, napisany w AutoHotkey v1. 
Zawsze‑on‑top, obsługa historii, hotkeye, zwijany tryb. 
Autor: Rafał Bobrowski
GitHub: [https://github.com/rmbgits/Ditto.ahk](https://github.com/rmbgits/Ditto.ahk)
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
global ToggleBtn

; NEW: S1/S2 controls
global S1ValBtn
global S1BtnTop
global S2ValBtn
global S2BtnBottom

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

; Stałe do wklejania
global S1_VALUE := "Stała 1"
global S2_VALUE := "Stała 2"
if (USE_INI && FileExist(IniPath)) {
    IniRead, S1_VALUE, %IniPath%, S1, Value, %S1_VALUE%
    IniRead, S2_VALUE, %IniPath%, S2, Value, %S2_VALUE%
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
    global MyList, CollapsedLbl, AutoPasteChk, HotkeysChk, ClearBtn, ToggleBtn
    global ToggleBtnAbsX, ToggleBtnAbsY, ToggleFullW, ToggleFullH
    global S1ValBtn, S1BtnTop, S2ValBtn, S2BtnBottom

    SysGet, MonitorWorkArea, MonitorWorkArea

    InnerW := GuiWidth - 2*M
    ; totalH ulegnie korekcie po dodaniu dolnych przycisków S2
    totalH := M + TitleH + G + ListH + G + CheckH + G + BtnH + M

    x := MonitorWorkAreaRight - GuiWidth - SafeMargin
    y := MonitorWorkAreaTop + ((MonitorWorkAreaBottom - MonitorWorkAreaTop) // 2) - (totalH // 2)

    BtnY := M + ((TitleH - BtnH) // 2)

    ; Top row: S1 value | S1 | Clear | >>>
    ValW := 84
    S1W  := 44
    ClrW := 56
    TglW := ToggleFullW

    TglX := M + InnerW - TglW
    ClrX := TglX - G - ClrW
    S1X  := ClrX - G - S1W
    ValX := S1X - G - ValW
    if (ValX < M) {
        ValX := M
        S1X := ValX + ValW + G
        ClrX := S1X + S1W + G
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

    ; TOP: S1 value + S1, Clear, >>>
    Gui, Add, Button, vS1ValBtn gOpenS1Value x%ValX% y%BtnY% w%ValW% h%BtnH%, S1 value
    Gui, Add, Button, vS1BtnTop  gPasteS1    x%S1X%  y%BtnY% w%S1W%  h%BtnH%, S1
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

    ; Bottom row: S2 value | S2 (pełna szerokość/połowy jak checkboxy)
    BottomY := CheckY + CheckH + G
    S2ValW := AutoW
    S2W := AutoW
    S2ValX := AutoX
    S2X    := KeysX

    Gui, Add, Button, vS2ValBtn gOpenS2Value x%S2ValX% y%BottomY% w%S2ValW% h%BtnH%, S2 value
    Gui, Add, Button, vS2BtnBottom gPasteS2   x%S2X%    y%BottomY% w%S2W%    h%BtnH%, S2

    ; Collapsed label
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

; --------------------------- S1/S2 value modals ---------------------------

OpenS1Value:
    global S1_VALUE, USE_INI, IniPath
    Gui, S1: New, +AlwaysOnTop +Border +Owner +Caption, S1 value
    Gui, S1: Font, s10, Segoe UI
    Gui, S1: Margin, 10, 10
    Gui, S1: Add, Text, w320, type value for S1
    Gui, S1: Add, Edit, vS1ValEdit w320 h26, %S1_VALUE%
    Gui, S1: Add, Button, gS1_Save w80 h26, Save
    Gui, S1: Add, Button, gS1_Cancel w80 h26 x+8, Cancel
    Gui, S1: Show, AutoSize Center
    Gui, S1: Default
    ControlFocus, Edit1, S1 value
return

S1_Save:
    global S1_VALUE, USE_INI, IniPath
    Gui, S1: Submit
    if (S1ValEdit != "")
        S1_VALUE := S1ValEdit
    if (USE_INI) {
        IniWrite, %S1_VALUE%, %IniPath%, S1, Value
        Gui, S1: Destroy
    } else {
        __UpdateSelfConstValue("S1_VALUE", S1_VALUE)
        Gui, S1: Destroy
        Reload
    }
return

S1_Cancel:
    Gui, S1: Destroy
return

OpenS2Value:
    global S2_VALUE, USE_INI, IniPath
    Gui, S2: New, +AlwaysOnTop +Border +Owner +Caption, S2 value
    Gui, S2: Font, s10, Segoe UI
    Gui, S2: Margin, 10, 10
    Gui, S2: Add, Text, w320, type value for S2
    Gui, S2: Add, Edit, vS2ValEdit w320 h26, %S2_VALUE%
    Gui, S2: Add, Button, gS2_Save w80 h26, Save
    Gui, S2: Add, Button, gS2_Cancel w80 h26 x+8, Cancel
    Gui, S2: Show, AutoSize Center
    Gui, S2: Default
    ControlFocus, Edit1, S2 value
return

S2_Save:
    global S2_VALUE, USE_INI, IniPath
    Gui, S2: Submit
    if (S2ValEdit != "")
        S2_VALUE := S2ValEdit
    if (USE_INI) {
        IniWrite, %S2_VALUE%, %IniPath%, S2, Value
        Gui, S2: Destroy
    } else {
        __UpdateSelfConstValue("S2_VALUE", S2_VALUE)
        Gui, S2: Destroy
        Reload
    }
return

S2_Cancel:
    Gui, S2: Destroy
return

; --------------------------- Collapse / Expand ---------------------------

ToggleCollapse:
    global IsCollapsed, WindowTitle
    global M, SafeMargin, CollapsedW, CollapsedH
    global FullX, FullY, FullW, FullH
    global MyList, AutoPasteChk, HotkeysChk, ClearBtn, ToggleBtn, CollapsedLbl
    global S1ValBtn, S1BtnTop, S2ValBtn, S2BtnBottom

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
        GuiControl, Hide, ToggleBtn
        GuiControl, Hide, S1ValBtn
        GuiControl, Hide, S1BtnTop
        GuiControl, Hide, S2ValBtn
        GuiControl, Hide, S2BtnBottom
        GuiControl, Show, CollapsedLbl

        WinMove, %WindowTitle%,, cx, cy, NewWidth, NewHeight
        Gui, Show, w%NewWidth% h%NewHeight% NA

        IsCollapsed := true
        OnMessage(0x201, "CollapsedClick")
        WinSet, AlwaysOnTop, On, %WindowTitle%
    } else {
        ; Re-anchor based on collapsed position
        WinGetPos, cX, cY, cW, cH, %WindowTitle%
        __GetWorkAreaFromPos(cX + cW//2, cY + cH//2, monL, monT, monR, monB)
        rw := (FullW ? FullW : GuiWidth)
        rh := (FullH ? FullH : (M + TitleH + G + ListH + G + CheckH + G + BtnH + M))
        rx := monR - rw - SafeMargin
        ry := cY

        if (rx < monL + SafeMargin)
            rx := monL + SafeMargin
        if (ry < monT + SafeMargin)
            ry := monT + SafeMargin
        if (ry + rh > monB - SafeMargin)
            ry := monB - rh - SafeMargin

        WinMove, %WindowTitle%,, rx, ry, rw, rh

        GuiControl, Show, MyList
        GuiControl, Show, AutoPasteChk
        GuiControl, Show, HotkeysChk
        GuiControl, Show, ClearBtn
        GuiControl, Show, ToggleBtn
        GuiControl, Show, S1ValBtn
        GuiControl, Show, S1BtnTop
        GuiControl, Show, S2ValBtn
        GuiControl, Show, S2BtnBottom
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

; Wklejanie stałych S1/S2
PasteS1:
    global S1_VALUE
    Sleep, 40
    SendInput, %S1_VALUE%
return

PasteS2:
    global S2_VALUE
    Sleep, 40
    SendInput, %S2_VALUE%
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

; Zwraca obszar roboczy monitora, w którym leży dany punkt (px,py)
__GetWorkAreaFromPos(px, py, ByRef L, ByRef T, ByRef R, ByRef B) {
    SysGet, monCount, MonitorCount
    bestIdx := 0
    Loop %monCount% {
        SysGet, mA, MonitorWorkArea, %A_Index%
        if (px >= mALeft && px <= mARight && py >= mATop && py <= mABottom) {
            bestIdx := A_Index
            break
        }
    }
    if (bestIdx = 0) {
        SysGet, mP, MonitorWorkArea
        L := mPLeft, T := mPTop, R := mPRight, B := mPBottom
    } else {
        SysGet, mSel, MonitorWorkArea, %bestIdx%
        L := mSelLeft, T := mSelTop, R := mSelRight, B := mSelBottom
    }
}

; Podmiana stałej w pliku skryptu
__UpdateSelfConstValue(constName, newVal) {
    global ScriptPath
    FileRead, src, %ScriptPath%
    if (ErrorLevel) {
        MsgBox, 16, Const, Nie udało się odczytać pliku skryptu: %ScriptPath%
        return
    }
    newValEsc := StrReplace(newVal, """", """""")
    newSrc := ""
    replaced := false
    pattern := "i)^\s*global\s+" constName "\s*:="
    Loop, Parse, src, `n, `r
    {
        line := A_LoopField
        if (!replaced && RegExMatch(line, pattern)) {
            newSrc .= "global " constName " := """ newValEsc """" "`r`n"
            replaced := true
        } else {
            newSrc .= line "`r`n"
        }
    }
    if (!replaced) {
        MsgBox, 48, Const, Nie znaleziono linii 'global %constName% := "...' do podmiany.
        return
    }
    FileDelete, %ScriptPath%
    FileAppend, %newSrc%, %ScriptPath%, UTF-8
}
