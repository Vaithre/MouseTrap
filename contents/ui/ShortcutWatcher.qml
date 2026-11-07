// Listens for shortcut changes from KDE so Mouse Trap can keep its backup up to date

import org.kde.plasma.workspace.dbus as DBus

DBus.SignalWatcher {
    id: watcher
    service: "org.kde.kglobalaccel"
    path: "/kglobalaccel"
    iface: "org.kde.KGlobalAccel"

    signal shortcutChanged(string component, string action)

    function dbusyourShortcutsChanged(actionId, keys) {
        if (actionId.length >= 2) watcher.shortcutChanged(actionId[0], actionId[1]);
    }
}
