import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Draggable thumbnail of the screenshot just taken, anchored bottom-right.
//
// Dismissal is the load-bearing behaviour here: the surface must never be able
// to strand itself on screen. Three independent paths close it — the lifetime
// timer, a completed drag, and a click — and all of them funnel through
// dismiss() so none can leave the window mapped.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  readonly property string pluginId: (manifest && manifest.id)
    ? String(manifest.id)
    : "io.github.rodrigo-sntg.screenshot-preview"

  property bool opened: false
  property bool showing: false
  property string filePath: ""

  readonly property int lifetimeMs: 5000
  readonly property int fadeMs: 220

  function open(payloadJson) {
    var payload = ({})
    try {
      payload = JSON.parse(payloadJson || "{}")
    } catch (e) {
      payload = ({})
    }

    var path = payload.path ? String(payload.path) : ""
    if (path === "") return

    // A second capture while one thumbnail is still up replaces it rather than
    // stacking: the shell only ever mounts one instance of an overlay plugin.
    root.filePath = path
    root.opened = true
    root.showing = true
    fadeTimer.stop()
    lifetime.restart()
  }

  // Called by the shell on `omarchy-shell shell hide`. Skip the fade and drop
  // the surface immediately, otherwise an explicit hide would appear to hang.
  function close() {
    lifetime.stop()
    fadeTimer.stop()
    root.showing = false
    root.opened = false
  }

  function dismiss() {
    if (!root.showing) return
    lifetime.stop()
    root.showing = false
    fadeTimer.restart()
  }

  function finishClose() {
    root.opened = false
    root.filePath = ""
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide(root.pluginId)
  }

  function openEditor() {
    if (root.filePath === "") return
    var editor = Quickshell.env("OMARCHY_SCREENSHOT_EDITOR") || "tensaku-edit"
    editorProcess.command = [editor, root.filePath]
    editorProcess.running = true
    root.dismiss()
  }

  Process { id: editorProcess }

  // Paused while the pointer is over the card or a drag is in flight, so the
  // thumbnail cannot vanish out from under the gesture that is using it.
  Timer {
    id: lifetime
    interval: root.lifetimeMs
    repeat: false
    running: root.showing && !hover.hovered && !dragArea.drag.active
    onTriggered: root.dismiss()
  }

  Timer {
    id: fadeTimer
    interval: root.fadeMs
    repeat: false
    onTriggered: root.finishClose()
  }

  PanelWindow {
    id: panel
    visible: root.opened
    color: "transparent"

    // Matches the Hyprland layer_rule that slides it in from the bottom edge.
    WlrLayershell.namespace: "screenshot-preview"
    WlrLayershell.layer: WlrLayer.Overlay
    // Never take keyboard focus: a screenshot thumbnail must not steal input
    // from whatever the user is typing into.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    anchors { bottom: true; right: true }
    margins { bottom: 24; right: 24 }
    implicitWidth: 260
    implicitHeight: 170

    Rectangle {
      id: card
      anchors.fill: parent
      radius: 12
      color: "#1e1e2e"
      border.color: dragArea.drag.active ? "#89b4fa" : "#45475a"
      border.width: 2

      opacity: root.showing ? 1 : 0
      Behavior on opacity {
        NumberAnimation { duration: root.fadeMs; easing.type: Easing.OutCubic }
      }

      HoverHandler { id: hover }

      Image {
        id: thumb
        anchors.fill: parent
        anchors.margins: 6
        source: root.filePath !== "" ? "file://" + root.filePath : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false

        Drag.active: dragArea.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.mimeData: ({ "text/uri-list": "file://" + root.filePath })

        // Fires whether the drop landed or was cancelled; either way the
        // gesture is over and the thumbnail has served its purpose.
        Drag.onDragFinished: root.dismiss()
      }

      MouseArea {
        id: dragArea
        anchors.fill: parent
        drag.target: thumb
        onClicked: root.openEditor()
        onReleased: {
          thumb.x = 0
          thumb.y = 0
        }
      }
    }
  }
}
