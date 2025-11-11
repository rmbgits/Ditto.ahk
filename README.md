<img width="310" height="303" alt="image" src="https://github.com/user-attachments/assets/adca4e67-e42c-497b-ae86-548baf30a989" />
# Ditto by RB — Lightweight Clipboard Overlay (AutoHotkey v1)

A lightweight, always-on-top clipboard overlay for Windows that shows recent text clips, lets you paste instantly via click or hotkeys, and toggles between a compact collapsed view and a full list. The window does not steal focus (non-activating) and is semi-transparent. The RB button types a constant string directly at the caret (without touching the system clipboard). The Clear button resets the in-app history and toggles.


<img width="310" height="303" alt="image" src="https://github.com/user-attachments/assets/99291bb4-5956-4c0e-8ff8-6c9ef67b2bfc" />

## Download
Get the latest version from Releases:
https://github.com/rmbgits/Ditto.ahk/releases/latest

## Shortcuts
| Action                  | Shortcut        |
|-------------------------|-----------------|
| Paste item #1 … #5      | Ctrl+1 … Ctrl+5 |
| Collapse/expand overlay | Click >>> / bar |
| Paste on click          | List item click |

Only Ctrl+1..Ctrl+5 hotkeys are active to avoid conflicts.

## Features
- Live text clipboard history (default 10 items), de-duplicated and trimmed to one-line previews.
- Instant paste via clicking a list item or with Ctrl+1..Ctrl+5 (top five items).
- RB button types a constant value at the caret using “SendInput {Text}” (clipboard remains unchanged).
- Clear button wipes in-app history and resets toggles (Auto-Paste ON, Hotkeys ON) without altering the system clipboard.
- Collapsed mini mode shows only the “Ditto” label; expanded mode shows top-row buttons (RB, Clear, >>>), the list, and toggles.
- Always-on-top, non-activating (WS_EX_NOACTIVATE) overlay with adjustable transparency.
- Screen clamping and periodic topmost reinforcement; adapts to monitor/work area changes.

## Requirements
- Windows 10/11
- AutoHotkey v1.x

## Quick Start
1. Download and run Ditto-by-RB.ahk (requires AutoHotkey v1).
2. Copy any text; it appears at the top of the overlay list (de-duplicated, trimmed).
3. Click a list item to set it as the clipboard and paste automatically if Auto-Paste is enabled.
4. Use Ctrl+1 … Ctrl+5 to paste items 1–5 directly into the active window.

## Top Row Controls (Expanded Mode)
- RB: Types a constant value directly at the caret using `SendInput, {Text}%RB_VALUE%` (clipboard stays intact).
- Clear: Resets in-app history and sets toggles to defaults (Auto-Paste ON, Hotkeys ON); the Windows clipboard is not changed.
- >>>: Collapse/expand toggle; when collapsed, only the “Ditto” label is shown. Clicking the collapsed panel expands it.

## Collapsed vs Expanded
- Collapsed: Minimal panel with “Ditto” text; no buttons or list visible; click anywhere on the panel to expand.
- Expanded: Top row shows RB, Clear, and “>>>”; below is the list and two session toggles (Auto-Paste, Hotkeys).

## Configuration (edit in script)
- Constant used by RB: `global RB_VALUE := "Your_constant_value"`
- History size: `MaxHistory := 10`
- GUI width: `GuiWidth := 290`
- Screen margin: `SafeMargin := 14`
- Clipboard polling interval: `SetTimer, CheckClipboard, 500` (ms)
- Defaults: `AutoPasteEnabled := true`, `HotkeysEnabled := true`
- Collapsed size: `NewWidth := 110`, `NewHeight := 60` (in `ToggleCollapse`)
- Transparency: `WinSet, Transparent, 180` (in `ShowClipboardGUI`)
- Preview length: `FormatPreview(txt, maxLen := 27)`

## Behavior Details
- Non-activating overlay: Uses WS_EX_NOACTIVATE so the overlay stays on top without stealing focus.
- De-duplication: New clipboard text is added only if different from the last seen and not already in history.
- Hotkey paste (Ctrl+1..Ctrl+5): Sets the clipboard to the chosen history entry and sends Ctrl+V (if Hotkeys toggle is ON).
- List click: Selecting an item sets the clipboard and optionally pastes (if Auto-Paste toggle is ON).
- Clear reset: Clears in-app history and resets toggles; does not empty the Windows clipboard.
- RB typing: Uses `{Text}` mode to type the constant literally, avoiding interpretation of special characters and leaving the clipboard intact.

## Known Limitations
- Text-only history; images/files are not handled.
- Some apps with nonstandard input fields may require adjusting the paste delay (e.g., `Sleep, 70`) or an alternative send mode.
- Clipboard polling interval trades responsiveness for overhead; tweak `CheckClipboard` timer as needed.

## Security/Focus Notes
- Always-on-top is reinforced periodically; window position is clamped to the monitor work area to keep the overlay visible.
- Transparency and non-activating style aim to minimize disruption while typing.

## Roadmap Ideas
- Optional history persistence across sessions.
- Image/file clipboard support; formatting-aware paste.
- Customizable hotkeys beyond Ctrl+1..Ctrl+5 (opt-in).

## License
MIT
