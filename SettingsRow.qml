import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property string baseIcon
    property string checkedIcon: ""
    readonly property string icon: root.checked
    ? (checkedIcon === "" ? root.baseIcon + "-filled" : checkedIcon)
    : baseIcon
    property string title
    property string description
    property bool checked

    signal toggled(bool checked)

    width: ListView.view.width
    height: 64

    RowLayout {
        anchors.fill: parent
        spacing: Style.marginM

        NIcon {
            icon: root.icon
            pointSize: Style.fontSizeXXL
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 2

            NText {
                text: root.title
                font.weight: Style.fontWeightBold
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            NText {
                text: root.description
                color: Color.mOnSurfaceVariant
                pointSize: Style.fontSizeS
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }

        NToggle {
            checked: root.checked
            onToggled: checked => root.toggled(checked)
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
