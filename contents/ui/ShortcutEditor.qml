// Edits the Mouse Trap shortcut through KDE and shows when a combination is already in use

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kquickcontrols
import org.kde.kirigami as Kirigami
import org.kde.ki18n
import org.kde.plasma.workspace.dbus as DBus

QQC2.Control {
    id: editor
    implicitWidth: 420
    implicitHeight: content.implicitHeight
    width: parent ? Math.max(implicitWidth, parent.width) : implicitWidth
    height: Math.max(72, implicitHeight)
    padding: 0
    palette {
        window: systemPalette.window
        windowText: systemPalette.windowText
        base: systemPalette.base
        text: systemPalette.text
        button: systemPalette.button
        buttonText: systemPalette.buttonText
        highlight: systemPalette.highlight
        highlightedText: systemPalette.highlightedText
    }
    background: Rectangle {
        color: systemPalette.window
    }

    SystemPalette { id: systemPalette }

    readonly property string actionName: "mouse-trap-toggle"
    readonly property list<string> actionId: ["kwin", actionName, "KWin", ""]
    readonly property int keyCode: recorder.keySequence
    property list<int> requestedKeys: []
    property var currentKeys: []
    readonly property int currentKey: currentKeys.length ? currentKeys[0] : 0
    property bool available: false
    property bool busy: false
    property bool reading: false
    property int pendingKey: -1
    property string message: ""

    function call(member, args, success, failure) {
        DBus.SessionBus.asyncCall({
            service: "org.kde.kglobalaccel",
            path: "/kglobalaccel",
            iface: "org.kde.KGlobalAccel",
            member: member,
            arguments: args,
        }, success, failure);
    }

    function unpack(value) {
        try {
            return unwrap(JSON.parse(JSON.stringify(value)));
        } catch (error) {
            return null;
        }
    }

    function unwrap(value) {
        if (Array.isArray(value)) return value.map(unwrap);
        if (value !== null && typeof value === "object" && value.value !== undefined) {
            return unwrap(value.value);
        }
        return value;
    }

    function showCurrent() {
        recorder.keySequence = editor.currentKey;
    }

    function readShortcut(done) {
        if (reading) return;
        reading = true;
        call("allActionsForComponent", [editor.actionId], function(reply) {
            const actions = unpack(reply.value);
            if (!Array.isArray(actions) || !actions.some(action => action[1] === actionName)) {
                reading = false;
                available = false;
                message = _tr.i18n("Enable Mouse Trap to change its shortcut.");
                if (done) done(false);
                return;
            }
            call("shortcutKeys", [editor.actionId], function(reply) {
                reading = false;
                const sequences = unpack(reply.value);
                const keys = [];
                if (!Array.isArray(sequences)) {
                    readFailed(done);
                    return;
                }
                for (let i = 0; i < sequences.length; ++i) {
                    const sequence = sequences[i];
                    if (!Array.isArray(sequence) || !Array.isArray(sequence[0])) {
                        readFailed(done);
                        return;
                    }
                    const steps = sequence[0].filter(key => key !== 0);
                    if (steps.length > 1) {
                        available = false;
                        message = _tr.i18n("Edit multi-step shortcuts in KDE Keyboard Shortcuts.");
                        if (done) done(false);
                        return;
                    }
                    if (steps.length === 1) keys.push(steps[0]);
                }
                if (!available || JSON.stringify(keys) !== JSON.stringify(currentKeys)) {
                    currentKeys = keys;
                    showCurrent();
                }
                if (!available) message = "";
                available = true;
                if (done) done(true);
            }, function() { readFailed(done); });
        }, function() { readFailed(done); });
    }

    function readFailed(done) {
        reading = false;
        available = false;
        message = _tr.i18n("Could not read the shortcut from KDE.");
        if (done) done(false);
    }

    function finishChange(messageText) {
        message = messageText;
        busy = false;
        showCurrent();
    }

    function applyShortcut(code) {
        if (reading && !busy) {
            pendingKey = code;
            return;
        }
        if (!available || busy) {
            showCurrent();
            return;
        }
        busy = true;
        message = "";
        readShortcut(function(ok) {
            if (!ok) {
                busy = false;
                return;
            }
            function assign() {
                const keys = code === 0 ? [] : [code].concat(currentKeys.slice(1).filter(key => key !== code));
                requestedKeys = keys;
                call("setForeignShortcut", [editor.actionId, editor.requestedKeys], function() {
                    readShortcut(function(ok) {
                        if (ok && JSON.stringify(currentKeys.slice().sort()) !== JSON.stringify(keys.slice().sort())) {
                            message = _tr.i18n("KDE could not apply this shortcut.");
                        }
                        busy = false;
                    });
                }, function() { finishChange(_tr.i18n("KDE could not apply this shortcut.")); });
            }
            if (code === 0 || currentKeys.indexOf(code) !== -1) {
                assign();
                return;
            }
            call("isGlobalShortcutAvailable", [new DBus.int32(code), ""], function(reply) {
                if (unpack(reply.value) === true) assign();
                else {
                    finishChange("");
                    conflictToast.showing = true;
                    conflictTimeout.restart();
                }
            }, function() { finishChange(_tr.i18n("Could not check shortcut availability.")); });
        });
    }

    onReadingChanged: {
        if (!reading && pendingKey >= 0) {
            const code = pendingKey;
            pendingKey = -1;
            Qt.callLater(function() { editor.applyShortcut(code); });
        }
    }

    Component.onCompleted: readShortcut()

    KI18nContext {
        id: _tr
        translationDomain: "mouse-trap-config"
    }

    Timer {
        interval: 750
        running: editor.visible && !editor.busy
        repeat: true
        onTriggered: editor.readShortcut()
    }

    Timer {
        id: conflictTimeout
        interval: 4000
        onTriggered: conflictToast.showing = false
    }

    contentItem: Item {
        id: content
        implicitHeight: shortcutCard.implicitHeight + 8 + conflictToast.implicitHeight + 12

        QQC2.Pane {
            id: shortcutCard
            objectName: "shortcutCard"
            anchors.left: parent.left
            anchors.right: parent.right
            y: (content.height - height) / 2
            padding: 12
            background: Rectangle {
                color: Kirigami.Theme.alternateBackgroundColor
            }

            contentItem: ColumnLayout {
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    QQC2.Label {
                        text: _tr.i18n("Lock cursor to screen")
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    KeySequenceItem {
                        id: recorder
                        objectName: "shortcutRecorder"
                        enabled: editor.available && !editor.busy
                        multiKeyShortcutsAllowed: false
                        checkForConflictsAgainst: 0
                        onKeySequenceModified: editor.applyShortcut(editor.keyCode)

                        Component.onCompleted: {
                            for (const button of recorder.children) {
                                if (!(button instanceof QQC2.Button) || !button.checkable) continue;
                                for (const toolTip of button.data) {
                                    if (toolTip instanceof QQC2.ToolTip) toolTip.visible = false;
                                }
                            }
                        }
                    }
                }

                QQC2.Label {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    visible: editor.message !== ""
                    text: editor.message
                }
            }
        }

        Item {
            id: conflictToast
            objectName: "conflictToast"
            anchors.left: parent.left
            anchors.right: parent.right
            y: shortcutCard.height + 8
            implicitHeight: conflictMessage.implicitHeight
            property bool showing: false
            opacity: 0

            Kirigami.InlineMessage {
                id: conflictMessage
                anchors.left: parent.left
                anchors.right: parent.right
                visible: true
                type: Kirigami.MessageType.Error
                text: _tr.i18n("This shortcut is already in use")
                Accessible.ignored: !conflictToast.showing
            }
        }

        states: State {
            name: "conflict"
            when: conflictToast.showing
            PropertyChanges { target: shortcutCard; y: 0 }
            PropertyChanges { target: conflictToast; opacity: 1 }
        }

        transitions: [
            Transition {
                to: "conflict"
                SequentialAnimation {
                    NumberAnimation {
                        target: shortcutCard
                        property: "y"
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: conflictToast
                        property: "opacity"
                        duration: 180
                        easing.type: Easing.InOutQuad
                    }
                }
            },
            Transition {
                from: "conflict"
                SequentialAnimation {
                    NumberAnimation {
                        target: conflictToast
                        property: "opacity"
                        duration: 180
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: shortcutCard
                        property: "y"
                        duration: 200
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        ]
    }
}
