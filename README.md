# Snapshelf

macOS-style screenshot thumbnail for Omarchy. After any capture, a draggable
thumbnail slides in from the bottom-right corner.

- **Drag** it into any application to share the image
- **Click** to open it in your screenshot editor
- **Hover** to keep it on screen
- Auto-dismisses after 5 seconds

No keybinding changes and no wrapper script: a headless service watches the
screenshot directory, so the thumbnail appears for every capture path — the
Print Screen binding, the Omarchy menu entries, or any other tool that writes
there.

## Install

```bash
omarchy plugin add https://github.com/rodrigo-sntg/omarchy-plugin-snapshelf.git --enable
```

## Requirements

- Omarchy 4 (Quattro) or newer
- `inotify-tools` (provides `inotifywait`)

## Configuration

The screenshot directory is resolved in this order:

1. `$OMARCHY_SCREENSHOT_DIR`
2. `$XDG_PICTURES_DIR` (from `~/.config/user-dirs.dirs`)
3. `~/Pictures`

Only files named `screenshot-*.png` — the pattern Omarchy's capture pipeline
uses — trigger the thumbnail.

The click action opens `$OMARCHY_SCREENSHOT_EDITOR`, falling back to
`tensaku-edit`.

## Optional: suppress the stock notification

Omarchy still posts its own "Screenshot saved" notification. To have only the
thumbnail, bind Print Screen to a capture that skips the notification:

```lua
-- ~/.config/hypr/bindings.lua
hl.unbind("PRINT")
o.bind("PRINT", "Screenshot", "omarchy-capture-screenshot smart save")
```

Note that `save` mode does not copy to the clipboard; add a wrapper if you want
both.

## Optional: slide-in animation

```lua
-- ~/.config/hypr/looknfeel.lua
hl.layer_rule({ match = { namespace = "snapshelf" }, animation = "slide bottom" })
```

## Privileges and network

None. The plugin reads image files from the screenshot directory and spawns
`inotifywait` and your configured editor. It makes no network requests.

## Remove

```bash
omarchy plugin remove io.github.rodrigo-sntg.snapshelf
```

## License

MIT
