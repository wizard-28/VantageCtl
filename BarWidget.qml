import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.Commons
import qs.Widgets
import qs.Services.UI
import qs.Services.System

Rectangle {
    id: root

    // Plugin API (injected by PluginService)
    property var pluginApi: null

    // Required properties for bar widgets
    property ShellScreen screen
    property string widgetId: ""
    property string section: ""

    implicitWidth: row.implicitWidth + Style.marginM * 2
    implicitHeight: Style.barHeight

    color: Style.capsuleColor
    radius: Style.radiusM

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: Style.marginS

        NIcon {
            icon: "letter-v"
            color: Color.mPrimary
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: {
            TooltipService.show(root, "Widget tooltip text", BarService.getTooltipDirection());
        }

        onExited: {
            TooltipService.hide();
        }

        onClicked: {
            if (pluginApi) {
                pluginApi.openPanel(root.screen, root);
            }
        }
    }
}
