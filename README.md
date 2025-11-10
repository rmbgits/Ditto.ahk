# Ditto by RB — Lightweight Clipboard Overlay (AutoHotkey v1)
<img width="324" height="347" alt="image" src="https://github.com/user-attachments/assets/0e234ac5-bcbd-4218-9c0d-5f4b57ae7664" />

A lightweight always-on-top clipboard overlay for Windows that shows recent text clips, lets you paste instantly via click or hotkeys, and toggles between a compact collapsed view and a full list. Non-activating window and adjustable transparency.

## Features
- Live text clipboard history (default 10 items), de-duplicated and trimmed.
- Instant paste by click or hotkeys Ctrl+1 … Ctrl+5 (top five items).
- Collapsed mini mode and full mode with list and toggles.
- Always-on-top, non-activating (WS_EX_NOACTIVATE), semi-transparent GUI.
- Session toggles: Auto-Paste and Hotkeys.

## Requirements
- Windows 10/11.
- AutoHotkey v1.x.

## Quick Start
- Download and run Ditto-by-RB.ahk (requires AutoHotkey v1).
- Copy any text; entries appear in the overlay.
- Click a list item to copy and paste (if Auto-Paste is enabled).
- Use Ctrl+1 … Ctrl+5 to paste items 1–5 directly.

## Configuration (edit in script)
- History size: `MaxHistory := 10`
- GUI width: `GuiWidth := 290`
- Screen margin: `SafeMargin := 14`
- Poll interval: `SetTimer, CheckClipboard, 500`
- Defaults: `AutoPasteEnabled := true`, `HotkeysEnabled := true`
- Collapsed size (ToggleCollapse): `NewWidth := 110`, `NewHeight := 60`
- Transparency (ShowClipboardGUI): `WinSet, Transparent, 180`
- Preview length: `FormatPreview(txt, maxLen := 27)`

## Where to change behavior
- Window title: `WindowTitle := "Ditto by RB"`
- Positioning/clamping: in `ShowClipboardGUI()` (uses `MonitorWorkArea`)
- Paste delay: `Sleep, 70` in `ListClick` / `PasteByNumber`
- Hotkeys: `^1` … `^5` and `PasteByNumber(n)`
- List building: `BuildListItems()` and `UpdateList()`

## Notes
- Text-only history; images/files not handled.
- Some apps may need a longer paste delay (increase `Sleep`).
- Overlay shouldn’t steal focus; stays on top by design.

## License
MIT (recommended). Add a LICENSE file in the repository root.
