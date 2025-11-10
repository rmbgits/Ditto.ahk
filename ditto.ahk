#NoEnv
#Persistent
#SingleInstance Force
SetBatchLines, -1
SetWinDelay, 0

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

global ToggleBtnAbsX := 0
global ToggleBtnAbsY := 0
global ToggleFullW := 70
global ToggleFullH := 26

global AutoPasteEnabled := true
global HotkeysEnabled := true

Clipboard := ""
LastSeen := ""

SetTimer, CheckClipboard, 500
ShowClipboardGUI()
return

FormatPreview(txt, maxLen := 27)
{
    txt := StrReplace(txt, "`r", "")
    txt := StrReplace(txt, "`n", " ")
    txt := RegExReplace(txt, "\s+", " ")
    if (StrLen(txt) > maxLen)
        return SubStr(txt, 1, maxLen) . "..."
    return txt
}

BuildListItems()
{
    global ClipHistory
    if (ClipHistory.Length() = 0)
        return ""
    s := ""
    maxNum := 5
    Loop % ClipHistory.Length()
    {
        itemNum := A_Index <= maxNum ? A_Index ". " : ""
        s .= (A_Index=1 ? "" : "|") . itemNum . FormatPreview(ClipHistory[A_Index])
    }
    return s
}

UpdateList()
{
    global MyList, ClipHistory, WindowTitle
    if (WinExist(WindowTitle))
    {
        GuiControl,, MyList, |
        GuiControl,, MyList, % BuildListItems()
    }
}

InHistory(txt)
{
    global ClipHistory
    for idx, item in ClipHistory
        if (item = txt)
            return true
    return false
}

CheckClipboard:
    global IsCollapsed, LastSeen, WindowTitle, MaxHistory
    ClipWait, 1
    clipText := Clipboard
    clipText := Trim(clipText)
    if (clipText != "" && clipText != LastSeen && !InHistory(clipText))
    {
        ClipHistory.InsertAt(1, clipText)
        LastSeen := clipText
        if (ClipHistory.Length() > MaxHistory)
            ClipHistory.RemoveAt(MaxHistory + 1)

        if (IsCollapsed)
            UpdateList()
        else
        {
            Gui, Destroy
            ShowClipboardGUI()
        }
    }
return

ShowClipboardGUI()
{
    global ClipHistory, GuiWidth, SafeMargin, IsCollapsed
    global ToggleBtn, MyList, TitleLbl, CollapsedLbl, AutoPasteChk, HotkeysChk
    global StartX, StartY, StartW, StartH, WindowTitle
    global ToggleBtnAbsX, ToggleBtnAbsY, ToggleFullW, ToggleFullH
    global AutoPasteEnabled, HotkeysEnabled
    global M, G, TitleH, BtnW, BtnH, ListH, CheckH

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

    WinGetPos, wx, wy, ww, wh, %WindowTitle%
    changed := false
    if (wx + ww > MonitorWorkAreaRight - 1)
        wx := MonitorWorkAreaRight - ww - SafeMargin, changed := true
    if (wx < MonitorWorkAreaLeft + SafeMargin)
        wx := MonitorWorkAreaLeft + SafeMargin, changed := true
    if (wy < MonitorWorkAreaTop + SafeMargin)
        wy := MonitorWorkAreaTop + SafeMargin, changed := true
    if (wy + wh > MonitorWorkAreaBottom - SafeMargin)
        wy := MonitorWorkAreaBottom - wh - SafeMargin, changed := true
    if (changed)
    {
        WinMove, %WindowTitle%,, wx, wy
        WinGetPos, wx, wy, ww, wh, %WindowTitle%
    }

    StartX := wx
    StartY := wy
    StartW := ww
    StartH := wh

    IsCollapsed := false
    GuiControl,, ToggleBtn, >>>
    GuiControl, Show, TitleLbl
    GuiControl, Hide, CollapsedLbl
}

ToggleCollapse:
    global IsCollapsed, ToggleBtn, WindowTitle, TitleLbl, CollapsedLbl
    global StartX, StartY, StartW, StartH
    global ToggleBtnAbsX, ToggleBtnAbsY, ToggleFullW, ToggleFullH
    global M
    SysGet, MonitorWorkArea, MonitorWorkArea

    if (!IsCollapsed)
    {
        NewWidth := 110
        NewHeight := 60
        x := MonitorWorkAreaRight - NewWidth - 12

        GuiControl, Hide, TitleLbl
        GuiControl, Hide, MyList
        GuiControl,, ToggleBtn,
        GuiControl, Move, ToggleBtn, x%M% y%M% w1 h1
        GuiControl, Show, CollapsedLbl

        WinGetPos, wx, wy,,, %WindowTitle%
        WinMove, %WindowTitle%,, x, wy, NewWidth, NewHeight
        Gui, Show, w%NewWidth% h%NewHeight% NA

        IsCollapsed := true
        OnMessage(0x201, "CollapsedClick")
    }
    else
    {
        WinMove, %WindowTitle%,, StartX, StartY, StartW, StartH

        GuiControl, Show, TitleLbl
        GuiControl, Show, MyList
        GuiControl,, ToggleBtn, >>>
        GuiControl, Move, ToggleBtn, x%ToggleBtnAbsX% y%ToggleBtnAbsY% w%ToggleFullW% h%ToggleFullH%
        GuiControl, Hide, CollapsedLbl

        UpdateList()
        Gui, Show, w%StartW% h%StartH% NA

        IsCollapsed := false
        OnMessage(0x201, "")
    }
return

CollapsedClick(wParam, lParam, msg, hwnd)
{
    SetTimer, __ExpandFromClick, -1
}

__ExpandFromClick:
    Gosub, ToggleCollapse
return

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
    if (selected > 0 && selected <= ClipHistory.Length())
    {
        Clipboard := ClipHistory[selected]
        if (AutoPasteEnabled)
        {
            WinGet, activeWinID, ID, A
            Sleep, 70
            SendInput, ^v
        }
    }
return

GuiClose:
    Gui, Hide
return

^1::PasteByNumber(1)
^2::PasteByNumber(2)
^3::PasteByNumber(3)
^4::PasteByNumber(4)
^5::PasteByNumber(5)

PasteByNumber(n)
{
    global ClipHistory, HotkeysEnabled
    if (n > 0 && n <= ClipHistory.Length())
    {
        Clipboard := ClipHistory[n]
        if (HotkeysEnabled)
        {
            WinGet, activeWinID, ID, A
            Sleep, 70
            SendInput, ^v
        }
    }
    else
    {
        MsgBox, 48, Clipboard Manager, Brak wpisu numer %n% w historii.
    }
}
