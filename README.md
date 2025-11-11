# Ditto by RB — Lightweight Clipboard Overlay (AutoHotkey v1)

A lightweight, always-on-top clipboard overlay for Windows that shows recent text clips, lets you paste instantly via click or hotkeys, and toggles between a compact collapsed view and a full list. Non-activating window (does not steal focus) and adjustable transparency. The RB button inserts a constant string without touching the system clipboard, and Clear resets the in-app history and toggles. [web:22][web:21][web:7]

<img width="326" height="326" alt="image" src="https://github.com/user-attachments/assets/e3056833-6432-4a42-be87-5b0bc5a88f76" />


## Download
Get the latest version from Releases:
https://github.com/rmbgits/Ditto.ahk/releases/latest [web:84]

## Shortcuts
| Action                  | Shortcut        |
|-------------------------|-----------------|
| Paste item #1 … #5      | Ctrl+1 … Ctrl+5 |
| Collapse/expand overlay | Click >>> / bar |
| Paste on click          | List item click |

Only Ctrl+1..Ctrl+5 hotkeys are active; all other global hotkeys were removed to avoid conflicts. [web:22]

## Features
- Live text clipboard history (default 10 items), de-duplicated and trimmed to one-line previews for readability. [web:21]
- Instant paste via clicking a list item or with Ctrl+1..Ctrl+5 for the top five items. [web:22]
- RB button inserts a constant value directly at the cursor using SendInput with {Text}, without modifying the system clipboard. [web:7]
- Clear button wipes in-app history and resets Auto-Paste/Hotkeys toggles to defaults, without touching the system clipboard. [web:21]
- Collapsed mini mode shows only the “Ditto” label; expanded mode shows top row buttons (RB, Clear, >>>) and the list with toggles. [web:22][web:18]
- Always-on-top and non-activating (WS_EX_NOACTIVATE) overlay, semi-transparent for minimal disruption. [web:22]
- Robust screen clamping and periodic topmost reinforcement; adapts to monitor/work area changes. [web:22]

## Requirements
- Windows 10/11. [web:22]
- AutoHotkey v1.x (classic). [web:22]

## Quick Start
1. Download and run Ditto-by-RB.ahk (requires AutoHotkey v1). [web:22]
2. Copy any text; it appears at the top of the overlay list (de-duplicated, trimmed). [web:21]
3. Click a list item to copy it into the clipboard and paste automatically if Auto-Paste is enabled. [web:21]
4. Use Ctrl+1 … Ctrl+5 to paste items 1–5 directly into the active window. [web:22]

## Top Row Controls (Expanded Mode)
- RB: Types a constant value directly at the caret using `SendInput, {Text}%RB_VALUE%` (clipboard remains unchanged). [web:7]
- Clear: Resets in-app history and sets toggles to defaults (Auto-Paste ON, Hotkeys ON); the system clipboard is not altered. [web:21]
- >>>: Collapse/expand toggle; when collapsed, only the “Ditto” label is shown, and clicking the panel expands it. [web:22][web:18]

## Collapsed vs Expanded
- Collapsed: Minimal panel with “Ditto” text; no buttons or list visible; single click anywhere expands. [web:22]
- Expanded: Top row shows RB, Clear, and “>>>”; below is the list and two session toggles (Auto-Paste, Hotkeys). [web:22][web:18]

## Configuration (edit in script)
- Constant inserted by RB: `global RB_VALUE := "Your_constant_value"` (typed with SendInput {Text}). [web:7]
- History size: `MaxHistory := 10` (number of recent text entries kept). [web:21]
- GUI width: `GuiWidth := 290` (overall panel width). [web:22]
- Screen margin: `SafeMargin := 14` (keeps the window within the work area). [web:22]
- Poll interval: `SetTimer, CheckClipboard, 500` (clipboard polling in ms). [web:22]
- Defaults: `AutoPasteEnabled := true`, `HotkeysEnabled := true`. [web:22]
- Collapsed size: `NewWidth := 110`, `NewHeight := 60` in `ToggleCollapse`. [web:22]
- Transparency: `WinSet, Transparent, 180` in `ShowClipboardGUI`. [web:22]
- Preview length (truncation): `FormatPreview(txt, maxLen := 27)`. [web:21]

## Behavior Details
- Non-activating: The GUI is set with `WS_EX_NOACTIVATE`, preventing focus theft; interaction with your active app remains smooth. [web:22]
- De-duplication: New clipboard text is inserted only if not equal to the last seen and not already present in history. [web:21]
- Pasting with hotkeys: Ctrl+1..Ctrl+5 set the clipboard to the chosen history entry and send Ctrl+V to the active window (respecting Hotkeys toggle). [web:7][web:22]
- List click: Selecting an item sets the clipboard and optionally pastes (respecting Auto-Paste). [web:21]
- Clear reset: Clears in-app history and resets toggles; does not empty the Windows clipboard. [web:21]
- RB typing: Uses `{Text}` mode to type the constant literally, avoiding interpretation of special characters and leaving the clipboard intact. [web:7]

## Known Limitations
- Text-only history; images/files are not tracked. [web:21]
- Some applications with nonstandard input fields may require adjusting paste delays (e.g., `Sleep, 70`) or using alternative send modes. [web:7]
- Clipboard polling interval balances responsiveness and overhead; tune `CheckClipboard` timer as needed. [web:22]

## Security/Focus Notes
- Always-on-top is reinforced periodically; screen bounds are clamped to the monitor work area to prevent the overlay from drifting off-screen. [web:22]
- The overlay’s transparency and non-activating style are chosen to minimize disruption during typing. [web:22]

## Roadmap Ideas
- Optional history persistence across sessions. [web:22]
- Image/file clipboard support and formatting-aware paste. [web:22]
- Customizable hotkeys beyond Ctrl+1..Ctrl+5 (opt-in). [web:22]

## License
MIT. [web:84]
