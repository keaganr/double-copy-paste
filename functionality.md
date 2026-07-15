# double-copy-paste

## Overview

Double Copy Paste is a tool which keeps a running history of the macOS
clipboard so that copying something new never silently and permanently
overwrites what was there before.

## Requirements

- Runs only on macOS
- Displays in the menu bar at the top of the screen
- Clicking the menu bar icon shows a dropdown list of recently copied
  clipboard contents, most recent first
- Selecting an item from that list "rolls back" the system clipboard to
  that item's content, overwriting whatever is currently on the clipboard
- Supports plain text and rich text (RTF/HTML) content for v1; the
  underlying model is built so image support can be added later without
  restructuring
- History is capped at a fixed number of recent entries and lives only in
  memory — it resets when the app quits or the Mac restarts (no history
  file on disk)
- Content copied by password managers (marked with the standard
  `org.nspasteboard.ConcealedType` / `TransientType` pasteboard types) is
  never captured into history

### Development

- Written as a native macOS app
- Swift
- Use common best practices: README.md updated with dev instructions,
  tests written, compartmentalization of code for ease of development
  organization, etc.
