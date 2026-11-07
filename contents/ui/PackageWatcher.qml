// Requests a KWin unload when the installed script directory disappears
// I couldn't find a better way to ensure the script unloads when uninstalled
// This should avoid unnecessary periodic checks

import QtQuick
import Qt.labs.folderlistmodel
import org.kde.kwin

Item {
    id: watcher
    required property string pluginId
    property bool seenPackage: false
    property bool packagePresent: false

    function checkPackage() {
        if (packages.status !== FolderListModel.Ready) return;
        for (let i = 0; i < packages.count; ++i) {
            if (packages.get(i, "fileName") === pluginId) {
                packagePresent = true;
                seenPackage = true;
                return;
            }
        }
        packagePresent = false;
    }

    FolderListModel {
        id: packages
        folder: Qt.resolvedUrl("../../../")
        showFiles: false
        onStatusChanged: watcher.checkPackage()
        onCountChanged: watcher.checkPackage()
    }

    Timer {
        interval: 500
        running: watcher.seenPackage && !watcher.packagePresent && packages.status === FolderListModel.Ready
        onTriggered: unload.call()
    }

    DBusCall {
        id: unload
        service: "org.kde.KWin"
        path: "/Scripting"
        dbusInterface: "org.kde.kwin.Scripting"
        method: "unloadScript"
        arguments: [watcher.pluginId]
    }
}
