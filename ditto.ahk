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
#SingleInstance Force
SetBatchLines, -1

WindowTitle := "Ditto by RB"
MaxHistory := 10
ClipHistory := Object()  ; Zamiast stringa!
IsCollapsed := false
AutoPasteEnabled := true
HotkeysEnabled := true
LastSeen := ""
FullX := 0, FullY := 0, FullW := 0, FullH := 0
SavedX := 0, SavedY := 0
S1_VALUE := "Rafał Bobrowski"
S2_VALUE := "Stała wartość 2"
SafeMargin := 14
REF_W := 1920
REF_H := 1080
BASE_GuiWidth := 290
BASE_M := 12
BASE_G := 8
BASE_TitleH := 26
BASE_BtnH := 26
BASE_ListH := 186
BASE_CheckH := 24
BASE_CollapsedW := 110
BASE_CollapsedH := 60
BASE_ToggleFullW := 46

CoordMode, Mouse, Screen
SetTimer, CheckClipboard, 500
SetTimer, __GuardTopmostAndBounds, 3000
OnMessage(0x0201, "WM_LBUTTONDOWN")
OnMessage(0x007E, "OnDisplayChange")
Gosub, ShowClipboardGUI
return

FormatPreview:
txt := param_txt
StringReplace, txt, txt, `r`n, %A_Space%, All
StringReplace, txt, txt, `n, %A_Space%, All
StringReplace, txt, txt, `r, %A_Space%, All
Loop {
    StringReplace, txt, txt, %A_Space%%A_Space%, %A_Space%, UseErrorLevel
    if ErrorLevel = 0
        break
}
StringLen, len, txt
maxLen := 27
if (param_maxLen > 0)
    maxLen := param_maxLen
if (len > maxLen) {
    StringLeft, txt, txt, %maxLen%
    txt := txt . "..."
}
preview_txt := txt
Return

BuildListItems:
s := ""
colcount := 0
Loop % MaxHistory {
    idx := A_Index
    if (!ClipHistory.HasKey(idx) || ClipHistory[idx] = "")
        continue
    param_txt := ClipHistory[idx]
    param_maxLen := 27
    Gosub, FormatPreview
    preview := preview_txt
    if (idx <= 5)
        label := idx . ". "
    else
        label := ""
    s .= (colcount = 0 ? "" : "|") . label . preview
    colcount++
}
list_items := s
Return

UpdateList:
Gosub, BuildListItems
GuiControl,, MyList, |
GuiControl,, MyList, %list_items%
Return

InHistory:
param_txt := param_Search
found := 0
Loop % MaxHistory {
    idx := A_Index
    if ClipHistory.HasKey(idx)
        if (ClipHistory[idx] = param_txt) {
            found := 1
            break
        }
}
in_hist := found
Return

AddToHistory:
param_txt := param_AddHist
if (param_txt = "" or param_txt = LastSeen)
    Return
param_Search := param_txt
Gosub, InHistory
if (in_hist or param_txt = "")
    Return
; Przesuń historię w dół i wpisz jako pierwszą pozycję
Loop % MaxHistory-1
    ClipHistory[MaxHistory - A_Index + 1] := ClipHistory[MaxHistory - A_Index]
ClipHistory[1] := param_txt
LastSeen := param_txt
Gosub, UpdateList
Return

ClampToWorkArea:
x := param_x, y := param_y, w := param_w, h := param_h
SysGet, m, MonitorWorkArea
if (x + w > mRight - SafeMargin)
    x := mRight - w - SafeMargin
if (x < mLeft + SafeMargin)
    x := mLeft + SafeMargin
if (y < mTop + SafeMargin)
    y := mTop + SafeMargin
if (y + h > mBottom - SafeMargin)
    y := mBottom - h - SafeMargin
clamp_x := x
clamp_y := y
Return

ShowClipboardGUI:
SysGet, MonitorWorkArea, MonitorWorkArea
screenW := MonitorWorkAreaRight - MonitorWorkAreaLeft
screenH := MonitorWorkAreaBottom - MonitorWorkAreaTop
scaleW := screenW / REF_W
scaleH := screenH / REF_H
GuiWidth := Round(BASE_GuiWidth * scaleW)
M := Round(BASE_M * scaleW)
G := Round(BASE_G * scaleW)
TitleH := Round(BASE_TitleH * scaleH)
BtnH := Round(BASE_BtnH * scaleH)
ListH := Round(BASE_ListH * scaleH)
CheckH := Round(BASE_CheckH * scaleH)
CollapsedW := Round(BASE_CollapsedW * scaleW)
CollapsedH := Round(BASE_CollapsedH * scaleH)
ToggleFullW := Round(BASE_ToggleFullW * scaleW)
InnerW := GuiWidth - 2*M
totalH := M + TitleH + G + ListH + G + CheckH + G + BtnH + M
x := MonitorWorkAreaRight - GuiWidth - SafeMargin
y := MonitorWorkAreaTop + (screenH // 4)
BtnY := M + ((TitleH - BtnH) // 2)
ValW := Round(84 * scaleW)
S1W := Round(44 * scaleW)
ClrW := Round(56 * scaleW)
TglW := ToggleFullW
TglX := M + InnerW - TglW
ClrX := TglX - G - ClrW
S1X := ClrX - G - S1W
ValX := S1X - G - ValW
if (ValX < M) {
    ValX := M
    S1X := ValX + ValW + G
    ClrX := S1X + S1W + G
    TglX := ClrX + ClrW + G
}
Gui, Destroy
Gui, -DPIScale +AlwaysOnTop -Caption +Border +ToolWindow
Gui, Color, F0F0F0
Gui, Margin, %M%, %M%
Gui, Font, s10, Segoe UI
Gui, +LastFound
hwnd := WinExist()
exStyle := DllCall("GetWindowLong", "Ptr", hwnd, "Int", -20, "UInt")
DllCall("SetWindowLong", "Ptr", hwnd, "Int", -20, "UInt", exStyle | 0x08000000)
Gui, Add, Button, vS1ValBtn gOpenS1Value x%ValX% y%BtnY% w%ValW% h%BtnH%, S1 value
Gui, Add, Button, vS1BtnTop gPasteS1 x%S1X% y%BtnY% w%S1W% h%BtnH%, S1
Gui, Add, Button, vClearBtn gClearClipboard x%ClrX% y%BtnY% w%ClrW% h%BtnH%, Clear
Gui, Add, Button, vToggleBtn gToggleCollapse x%TglX% y%BtnY% w%TglW% h%BtnH%, >>>
ListX := M, ListY := M + TitleH + G, ListW := InnerW
Gosub, BuildListItems
Gui, Add, ListBox, vMyList gListClick x%ListX% y%ListY% w%ListW% h%ListH% AltSubmit, %list_items%
CheckY := ListY + ListH + G
HalfW := (InnerW - G) // 2
AutoX := M, AutoW := HalfW
KeysX := M + HalfW + G, KeysW := HalfW
Gui, Add, Checkbox, vAutoPasteChk gToggleAutoPaste x%AutoX% y%CheckY% w%AutoW% h%CheckH% Checked1, Auto-Paste
Gui, Add, Checkbox, vHotkeysChk gToggleHotkeys x%KeysX% y%CheckY% w%KeysW% h%CheckH% Checked1, Keys(Ctrl+1)
BottomY := CheckY + CheckH + G
S2ValW := AutoW
S2W := AutoW
S2ValX := AutoX
S2X := KeysX
Gui, Add, Button, vS2ValBtn gOpenS2Value x%S2ValX% y%BottomY% w%S2ValW% h%BtnH%, S2 value
Gui, Add, Button, vS2BtnBottom gPasteS2 x%S2X% y%BottomY% w%S2W% h%BtnH%, S2
Gui, Add, Text, vCollapsedLbl x%M% y%M% w%CollapsedW% h%TitleH% Center BackgroundTrans, Ditto
GuiControl, Hide, CollapsedLbl
Gui, Show, x%x% y%y% w%GuiWidth% h%totalH% NA, %WindowTitle%
WinSet, Transparent, 180, %WindowTitle%
WinSet, AlwaysOnTop, On, %WindowTitle%
WinGetPos, wx, wy, ww, wh, %WindowTitle%
FullX := wx, FullY := wy, FullW := ww, FullH := wh
IsCollapsed := false
Return

CheckClipboard:
ClipWait, 1
clipText := Clipboard
if (clipText = "")
    Return
if (clipText != "" && clipText != LastSeen) {
    param_AddHist := clipText
    Gosub, AddToHistory
    if WinExist(WindowTitle) {
        WinSet, AlwaysOnTop, On, %WindowTitle%
        WinSet, Transparent, 180, %WindowTitle%
        WinShow, %WindowTitle%
    }
}
return

WM_LBUTTONDOWN(wParam, lParam, msg, hwnd) {
    MouseGetPos,,, , OutputVarControl
    if (hwnd != WinExist(WindowTitle))
        return
    if (OutputVarControl != "")
        return
    PostMessage, 0xA1, 2, , , ahk_id %hwnd%
}

ToggleCollapse:
SysGet, m, MonitorWorkArea
if (!IsCollapsed) {
    SavedX := FullX
    SavedY := FullY
    NewWidth := CollapsedW, NewHeight := CollapsedH
    cx := mRight - NewWidth - SafeMargin
    cy := SavedY
    param_x := cx, param_y := cy, param_w := NewWidth, param_h := NewHeight
    Gosub, ClampToWorkArea
    cx := clamp_x, cy := clamp_y
    WinMove, %WindowTitle%, , cx, cy, NewWidth, NewHeight
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
    Gui, Show, w%NewWidth% h%NewHeight% NA
    IsCollapsed := true
    OnMessage(0x0201, "CollapsedClick")
} else {
    cx := SavedX
    cy := SavedY
    NewWidth := FullW
    NewHeight := FullH
    param_x := cx, param_y := cy, param_w := NewWidth, param_h := NewHeight
    Gosub, ClampToWorkArea
    cx := clamp_x, cy := clamp_y
    WinMove, %WindowTitle%, , cx, cy, NewWidth, NewHeight
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
    Gosub, UpdateList
    Gui, Show, w%NewWidth% h%NewHeight% NA
    IsCollapsed := false
    OnMessage(0x0201, "WM_LBUTTONDOWN")
    FullX := cx
    FullY := cy
}
WinSet, AlwaysOnTop, On, %WindowTitle%
return

CollapsedClick(wParam, lParam, msg, hwnd) {
    SetTimer, __ExpandFromClick, -10
}
__ExpandFromClick:
Gosub, ToggleCollapse
return

ListClick:
Gui, Submit, NoHide
selected := MyList
if (selected > 0 && selected <= MaxHistory) {
    if (!ClipHistory.HasKey(selected) || ClipHistory[selected] = "")
        Return
    Clipboard := ClipHistory[selected]
    if (AutoPasteEnabled) {
        Sleep, 70
        SendInput, ^v
    }
}
return

ToggleAutoPaste:
Gui, Submit, NoHide
AutoPasteEnabled := AutoPasteChk
return

ToggleHotkeys:
Gui, Submit, NoHide
HotkeysEnabled := HotkeysChk
return

ClearClipboard:
ClipHistory := Object()
LastSeen := ""
Clipboard := ""
Gosub, UpdateList
AutoPasteEnabled := true
HotkeysEnabled := true
GuiControl,, MyList, |
GuiControl,, AutoPasteChk, 1
GuiControl,, HotkeysChk, 1
return

PasteS1:
SendInput, %S1_VALUE%
return

PasteS2:
SendInput, %S2_VALUE%
return

OpenS1Value:
Gui, S1:Destroy
Gui, S1:New, +AlwaysOnTop +Border +Owner +Caption, S1 value
Gui, S1:Font, s10, Segoe UI
Gui, S1:Margin, 10, 10
Gui, S1:Add, Text,, Podaj wartość dla S1:
Gui, S1:Add, Edit, vS1ValEdit w320 h26, %S1_VALUE%
Gui, S1:Add, Button, gS1_Save w80 h26 x+10 yp+5, Save
Gui, S1:Add, Button, gS1_Cancel w80 h26 x+10, Cancel
Gui, S1:Show, AutoSize Center
return

S1_Save:
Gui, S1:Submit
if (S1ValEdit != "") {
S1_VALUE := "Rafał Bobrowski"
    scriptFile := A_ScriptFullPath
    FileRead, src, %scriptFile%
    out := ""
    Loop, Parse, src, `n, `r
    {
        If RegExMatch(A_LoopField, "^\s*S1_VALUE := ") {
            out .= "S1_VALUE := """ . S1ValEdit . """`r`n"
        } else {
            out .= A_LoopField . "`r`n"
        }
    }
    FileDelete, %scriptFile%
    FileAppend, %out%, %scriptFile%, UTF-8
    Reload
}
Gui, S1:Destroy
return

S1_Cancel:
Gui, S1:Destroy
return

OpenS2Value:
Gui, S2:Destroy
Gui, S2:New, +AlwaysOnTop +Border +Owner +Caption, S2 value
Gui, S2:Font, s10, Segoe UI
Gui, S2:Margin, 10, 10
Gui, S2:Add, Text,, Podaj wartość dla S2:
Gui, S2:Add, Edit, vS2ValEdit w320 h26, %S2_VALUE%
Gui, S2:Add, Button, gS2_Save w80 h26 x+10 yp+5, Save
Gui, S2:Add, Button, gS2_Cancel w80 h26 x+10, Cancel
Gui, S2:Show, AutoSize Center
return

S2_Save:
Gui, S2:Submit
if (S2ValEdit != "") {
    S2_VALUE := S2ValEdit
    scriptFile := A_ScriptFullPath
    FileRead, src, %scriptFile%
    out := ""
    Loop, Parse, src, `n, `r
    {
        If RegExMatch(A_LoopField, "^\s*S2_VALUE := ") {
            out .= "S2_VALUE := """ . S2ValEdit . """`r`n"
        } else {
            out .= A_LoopField . "`r`n"
        }
    }
    FileDelete, %scriptFile%
    FileAppend, %out%, %scriptFile%, UTF-8
    Reload
}
Gui, S2:Destroy
return

S2_Cancel:
Gui, S2:Destroy
return

^1::
^2::
^3::
^4::
^5::
if (!HotkeysEnabled)
    return
n := SubStr(A_ThisHotkey, 2)
if (n > MaxHistory)
    return
if (!ClipHistory.HasKey(n) || ClipHistory[n] = "")
    return
Clipboard := ClipHistory[n]
Sleep, 70
SendInput, ^v
return

OnDisplayChange(wParam, lParam, msg, hwnd) {
    SetTimer, __GuardTopmostAndBounds, -100
}

__GuardTopmostAndBounds:
if WinExist(WindowTitle) {
    WinSet, AlwaysOnTop, On, %WindowTitle%
    WinGetPos, gx, gy, gw, gh, %WindowTitle%
    param_x := gx, param_y := gy, param_w := gw, param_h := gh
    Gosub, ClampToWorkArea
    WinMove, %WindowTitle%, , %clamp_x%, %clamp_y%
}
return

GuiClose:
ExitApp
