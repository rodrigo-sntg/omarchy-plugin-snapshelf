### Repository URL

https://github.com/rodrigo-sntg/omarchy-plugin-snapshelf

### Category

Desktop

### Tags

hyprland, quickshell

### Suggest a missing tag

screenshot

### Maintainer notes

**Dependencies:** requires `inotify-tools` (for `inotifywait`). No other external dependencies, no network access, no elevated privileges.

**How it works:** a `service` entry point watches the screenshot directory (`$OMARCHY_SCREENSHOT_DIR`, then `$XDG_PICTURES_DIR`, then `~/Pictures`) and summons an `overlay` entry point showing a draggable thumbnail of files matching `screenshot-*.png`. The overlay auto-dismisses after 5 seconds, pauses while hovered or while a drag is in flight, and takes no keyboard focus.

**Configuration:** the plugin writes nothing to user configuration. The README documents two *optional* edits the user may apply themselves (a Print Screen rebind to suppress Omarchy's own notification, and a Hyprland `layer_rule` for the slide-in animation); neither is applied automatically.

**Known limitation:** on a multi-monitor setup the thumbnail always appears on the same output rather than following the focused monitor. Documented in the README.

**Validation:** `omarchy plugin validate` and `qmllint -I "$OMARCHY_PATH/shell"` both pass on `Overlay.qml` and `Service.qml`.

### Submission checklist

- [x] The repository is public and contains installation and removal instructions.
- [x] I have documented the plugin license and any external dependencies.
- [x] I confirm that I own or have permission to submit this plugin and its preview assets.
- [x] The plugin does not overwrite user configuration without explicit consent.
- [x] I understand that approval is for listing and is not a security review.
