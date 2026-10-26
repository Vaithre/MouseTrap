import QtQuick
import org.kde.kwin

Item {
    id: root
    visible: false

    readonly property int confinementBarrier: 1000000
    property int savedEdgeBarrier: 0
    property bool savedCornerBarrier: false
    property bool active: false

    function shortcutLabel() {
        const languages = Qt.locale().uiLanguages;
        for (let i = 0; i < languages.length; ++i) {
            const language = languages[i].split(/[-_]/)[0].toLowerCase();
            // TODO: Is this the best way to handle translations in QML? I doubt it
            if (language === "es") return "Activar/desactivar Mouse Trap";
            if (language === "pt") return "Ativar/desativar Mouse Trap";
            if (language === "en") return "Toggle Mouse Trap";
        }
        return "Toggle Mouse Trap";
    }

    function release() {
        if (!active) {
            return;
        }

        // Clear the active state first so restoration signals do not trigger release again
        active = false;
        // Restore the previous settings only where our values are still in effect
        if (Options.edgeBarrier === confinementBarrier) {
            Options.edgeBarrier = savedEdgeBarrier;
        }
        if (Options.cornerBarrier === false || Options.cornerBarrier === 0) {
            Options.cornerBarrier = savedCornerBarrier;
        }
    }

    function toggle() {
        if (active) {
            release();
            return;
        }

        // Save the current settings, then apply the barrier
        savedEdgeBarrier = Options.edgeBarrier;
        savedCornerBarrier = Options.cornerBarrier;
        Options.cornerBarrier = false;
        Options.edgeBarrier = confinementBarrier;

        // Roll back if KWin did not accept the barrier setting
        if (Options.edgeBarrier !== confinementBarrier) {
            Options.edgeBarrier = savedEdgeBarrier;
            Options.cornerBarrier = savedCornerBarrier;
            console.warn("Mouse Trap: KWin rejected the barrier setting");
            return;
        }

        active = true;
    }

    // Restore settings when KWin unloads or disables the script (very, very important)
    Component.onDestruction: release()

    // Release remaining settings if KWin or another script changes either option
    // This fallback may seem unnecessary, but so many things can go wrong when changing settings on the fly!
    Connections {
        target: Options
        function onEdgeBarrierChanged() {
            if (root.active) root.release();
        }
        function onCornerBarrierChanged() {
            if (root.active) root.release();
        }
    }

    ShortcutHandler {
        name: "mouse-trap-toggle"
        text: root.shortcutLabel()
        sequence: "Ctrl+Shift+L"
        onActivated: root.toggle()
    }
}
