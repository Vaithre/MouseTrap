// Shows the project links in the settings menu and opens them in the browser

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.ki18n

Rectangle {
    implicitWidth: links.implicitWidth
    implicitHeight: links.implicitHeight
    color: systemPalette.window

    SystemPalette { id: systemPalette }

    KI18nContext {
        id: _tr
        translationDomain: "mouse-trap-config"
    }

    component ProjectButton: QQC2.Button {
        id: action
        required property url destination
        required property url imageSource
        required property color baseColor
        required property color activeColor
        required property color borderColor
        required property color activeBorderColor

        padding: 8
        leftPadding: 12
        rightPadding: 12
        hoverEnabled: true

        onClicked: Qt.openUrlExternally(destination)

        HoverHandler { cursorShape: Qt.PointingHandCursor }

        background: Rectangle {
            radius: 5
            color: action.hovered || action.visualFocus ? action.activeColor : action.baseColor
            border.color: action.hovered || action.visualFocus ? action.activeBorderColor : action.borderColor
        }

        contentItem: RowLayout {
            spacing: 8

            Image {
                source: action.imageSource
                Layout.preferredWidth: 16
                Layout.preferredHeight: 16
            }

            QQC2.Label {
                text: action.text
                color: "#ffffff"
                font.bold: true
                textFormat: Text.PlainText
            }
        }
    }

    RowLayout {
        id: links
        anchors.fill: parent
        spacing: 10

        ProjectButton {
            objectName: "githubLink"
            text: _tr.i18n("View project on GitHub")
            destination: "https://github.com/Vaithre/MouseTrap"
            imageSource: "@MOUSE_TRAP_GITHUB_ICON@"
            baseColor: "#373b4d"
            activeColor: "#444b64"
            borderColor: "#50566b"
            activeBorderColor: "#50566b"
        }

        ProjectButton {
            objectName: "storeLink"
            text: _tr.i18n("Leave a like on KDE Store")
            destination: "https://store.kde.org/p/2380379/"
            imageSource: "@MOUSE_TRAP_STORE_ICON@"
            baseColor: "#1769AA"
            activeColor: baseColor
            borderColor: "#1a77bd"
            activeBorderColor: "#8dcef9"
        }
    }
}
