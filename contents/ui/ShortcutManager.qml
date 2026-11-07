// KDE can leave shortcut entries behind after a script is removed.
// This code backs up the user shortcut (only the Mouse Trap shortcut, don't worry!) so it can clean up
// the entry on unload and restore their settings when the script is enabled again.

import QtQuick
import QtCore
import org.kde.kwin

Item {
    id: manager
    visible: false

    required property string name
    required property string text
    required property string settingsFile
    property string defaultSequence: "Ctrl+Shift+L"
    readonly property list<string> actionId: ["kwin", name, "KWin", text]
    property list<int> restoredKeys: []
    property var handler: null
    property bool queryPending: false
    property bool canCleanUp: false
    property bool restoring: false
    property bool watchingShortcuts: false

    signal activated()

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

    function savedKeys() {
        try {
            const keys = JSON.parse(backup.value("shortcutKeys", ""));
            if (!Array.isArray(keys)) return null;
            for (let i = 0; i < keys.length; ++i) {
                if (!Number.isInteger(keys[i]) || keys[i] <= 0) return null;
            }
            return keys;
        } catch (error) {
            return null;
        }
    }

    function start(exists) {
        const keys = savedKeys();
        restoring = exists === false && keys !== null;
        handler = shortcutComponent.createObject(manager, {
            "name": name,
            "text": text,
            "sequence": restoring ? "" : defaultSequence,
        });
        if (!handler) {
            return;
        }
        if (restoring) {
            restoredKeys = keys;
            restoreShortcut.call();
        } else {
            captureShortcut();
        }
    }

    function captureShortcut() {
        if (!handler || queryPending) return;
        canCleanUp = false;
        queryPending = true;
        readShortcut.call();
    }

    function capture(returnValue) {
        if (!queryPending) return;
        queryPending = false;
        captureSequences(unpack(returnValue[0]));
    }

    function captureSequences(sequences) {
        canCleanUp = false;
        const wasRestoring = restoring;
        restoring = false;
        if (!Array.isArray(sequences)) {
            return;
        }
        const keys = [];
        for (let i = 0; i < sequences.length; ++i) {
            const sequence = sequences[i];
            if (!Array.isArray(sequence) || sequence.length !== 1 || !Array.isArray(sequence[0])) return;
            const steps = sequence[0].filter(function(key) { return key !== 0; });
            if (steps.length > 1) return;
            if (steps.length === 1) {
                const key = steps[0];
                if (!Number.isInteger(key) || key <= 0) return;
                keys.push(key);
            }
        }
        keys.sort(function(a, b) { return a - b; });
        const serialized = JSON.stringify(keys);
        if (wasRestoring) {
            const expected = Array.from(restoredKeys).sort(function(a, b) { return a - b; });
            if (serialized !== JSON.stringify(expected)) return;
        }
        if (backup.value("shortcutKeys", "") !== serialized) {
            backup.setValue("shortcutKeys", serialized);
            backup.sync();
        }
        canCleanUp = true;
    }

    function cleanUp() {
        // Keep KDE record if the last query failed, is still pending, or is stale
        if (!canCleanUp || queryPending || !watchingShortcuts) return;
        backup.sync();
        removeShortcut.call();
    }

    Component.onCompleted: findShortcut.call()
    Component.onDestruction: cleanUp()

    Settings {
        id: backup
        location: StandardPaths.writableLocation(StandardPaths.GenericConfigLocation) + "/" + manager.settingsFile
    }

    Component {
        id: shortcutComponent
        ShortcutHandler {
            onActivated: manager.activated()
        }
    }

    Loader {
        id: watcher
        source: "ShortcutWatcher.qml"
        onLoaded: manager.watchingShortcuts = true
    }

    Connections {
        target: watcher.item
        function onShortcutChanged(component, action, sequences) {
            if (!manager.handler || component !== "kwin" || action !== manager.name) return;
            manager.queryPending = false;
            manager.captureSequences(manager.unpack(sequences));
        }
    }

    DBusCall {
        id: findShortcut
        service: "org.kde.kglobalaccel"
        path: "/kglobalaccel"
        dbusInterface: "org.kde.KGlobalAccel"
        method: "allActionsForComponent"
        arguments: [manager.actionId]
        onFinished: function(returnValue) {
            const actions = manager.unpack(returnValue[0]);
            if (!Array.isArray(actions)) {
                manager.start(null);
                return;
            }
            let exists = false;
            for (let i = 0; i < actions.length; ++i) {
                if (actions[i][1] === manager.name) exists = true;
            }
            manager.start(exists);
        }
        onFailed: {
            manager.start(null);
        }
    }

    DBusCall {
        id: readShortcut
        service: "org.kde.kglobalaccel"
        path: "/kglobalaccel"
        dbusInterface: "org.kde.KGlobalAccel"
        method: "shortcutKeys"
        arguments: [manager.actionId]
        onFinished: function(returnValue) { manager.capture(returnValue); }
        onFailed: manager.capture([])
    }

    DBusCall {
        id: restoreShortcut
        service: "org.kde.kglobalaccel"
        path: "/kglobalaccel"
        dbusInterface: "org.kde.KGlobalAccel"
        method: "setForeignShortcut"
        arguments: [manager.actionId, manager.restoredKeys]
        onFinished: {
            if (manager.restoring) manager.captureShortcut();
        }
        onFailed: manager.restoring = false
    }

    DBusCall {
        id: removeShortcut
        service: "org.kde.kglobalaccel"
        path: "/kglobalaccel"
        dbusInterface: "org.kde.KGlobalAccel"
        method: "unregister"
        arguments: ["kwin", manager.name]
    }
}
