import QtQuick
import Quickshell
import Quickshell.Io

// Headless watcher over the screenshot directory.
//
// Watching the directory rather than wrapping the capture command means the
// thumbnail appears for every capture path — the Print Screen binding, the
// Omarchy menu entries, or any other tool writing there — with no keybinding
// override and no fork of omarchy-capture-screenshot to keep in sync.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property string pluginId: (manifest && manifest.id)
    ? String(manifest.id)
    : "io.github.rodrigo-sntg.snapshelf"

  property string lastPath: ""

  // XDG_PICTURES_DIR lives in user-dirs.dirs rather than the environment, so
  // resolve the directory in the shell that starts the watch.
  readonly property string watchCommand:
    '[ -f "$HOME/.config/user-dirs.dirs" ] && . "$HOME/.config/user-dirs.dirs";' +
    'DIR="${OMARCHY_SCREENSHOT_DIR:-${XDG_PICTURES_DIR:-$HOME/Pictures}}";' +
    'mkdir -p "$DIR";' +
    'exec inotifywait -q -m -e close_write -e moved_to --format "%w%f" "$DIR"'

  function handleLine(line) {
    var path = String(line).trim()
    if (path === "") return
    // Only files the capture pipeline names; ignore anything else landing in
    // the pictures directory.
    if (!/screenshot-[^/]*\.png$/.test(path)) return
    if (path === root.lastPath) return

    root.lastPath = path
    if (root.shell && typeof root.shell.summon === "function")
      root.shell.summon(root.pluginId, JSON.stringify({ path: path }))
  }

  Process {
    id: watcher
    running: true
    command: ["bash", "-c", root.watchCommand]
    stdout: SplitParser { onRead: function(line) { root.handleLine(line) } }
    // inotifywait dying (a directory replaced wholesale, say) would silently
    // end the feature, so bring the watch back up.
    onExited: restartWatch.restart()
  }

  Timer {
    id: restartWatch
    interval: 2000
    repeat: false
    onTriggered: watcher.running = true
  }
}
