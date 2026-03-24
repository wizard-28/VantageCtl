import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets

Item {
    id: root

    property var pluginApi: null

    readonly property var geometryPlaceholder: mainLayout
    readonly property bool allowAttach: true

    property real contentPreferredWidth: Math.round(540 * Style.uiScaleRatio)
    property real contentPreferredHeight: Math.round(mainLayout.implicitHeight * Style.uiScaleRatio + Style.margin2M)

    property int fanModeIndex: fanModeToIndex(vantage.fan.value)

    // ===== MODES =====
    property var fanModesUI: [
        {
            key: 0,
            label: "Super Silent",
            icon: "leaf"
        },
        {
            key: 1,
            label: "Standard",
            icon: "balance"
        },
        {
            key: 4,
            label: "Efficient Thermal Dissipation",
            icon: "bolt"
        }
    ]

    function fanModeToIndex(mode) {
        for (let i = 0; i < fanModesUI.length; i++) {
            if (fanModesUI[i].key === mode)
                return i;
        }
        return 1;
    }

    function indexToLabel(index) {
        return fanModesUI[index].label;
    }

    anchors.fill: parent

    VantageService {
        id: vantage
        pluginApi: root.pluginApi
    }

    Component.onCompleted: {
        if (pluginApi) {
            vantage.refresh();
            Logger.i("LenovoVantage", "Panel initialized");
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: Style.marginL
        spacing: Style.marginM

        NBox {
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + Style.margin2M

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: Style.marginM
                spacing: Style.marginM

                NIcon {
                    pointSize: Style.fontSizeXXL
                    icon: "heart"
                }

                ColumnLayout {
                    spacing: Style.marginXXS
                    Layout.fillWidth: true

                    NText {
                        text: "Noctalia Vantage"
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                NIconButton {
                    icon: "close"
                    tooltipText: "Close"
                    baseSize: Style.baseWidgetSize * 0.8
                    onClicked: pluginApi.closePanel(pluginApi.panelOpenScreen)
                }
            }
        }

        NBox {
            Layout.fillWidth: true
            height: controlsLayout.implicitHeight + Style.margin2L

            ColumnLayout {
                id: controlsLayout
                anchors.fill: parent
                anchors.margins: Style.marginL
                spacing: Style.marginM

                ColumnLayout {
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NText {
                            text: "Fan Mode"
                            font.weight: Style.fontWeightBold
                            color: Color.mOnSurface
                            Layout.fillWidth: true
                        }

                        NText {
                            text: indexToLabel(root.fanModeIndex)
                            color: Color.mOnSurfaceVariant
                        }
                    }

                    NValueSlider {
                        Layout.fillWidth: true
                        from: 0
                        to: 2
                        stepSize: 1
                        snapAlways: true
                        heightRatio: 0.5
                        value: fanModeToIndex(vantage.fan.value)

                        onMoved: v => {
                            root.fanModeIndex = v;
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Style.marginS

                        NIcon {
                            icon: "moon"
                            pointSize: Style.fontSizeS
                            color: root.fanModeIndex === 0 ? Color.mPrimary : Color.mOnSurfaceVariant
                        }

                        NIcon {
                            icon: "car-fan"
                            pointSize: Style.fontSizeS
                            color: root.fanModeIndex === 1 ? Color.mPrimary : Color.mOnSurfaceVariant
                            Layout.fillWidth: true
                        }

                        NIcon {
                            icon: "flame"
                            pointSize: Style.fontSizeS
                            color: root.fanModeIndex === 2 ? Color.mPrimary : Color.mOnSurfaceVariant
                        }
                    }
                }

                NDivider {
                    Layout.fillWidth: true
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.marginS

                    NText {
                        text: "Dust Cleaning"
                        pointSize: Style.fontSizeM
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                    }

                    NIconButton {
                        icon: "windmill"
                        onClicked: vantage.setFanMode(2)
                    }
                }
            }
        }

        NBox {
            Layout.fillWidth: true
            implicitHeight: list.contentHeight + 2 * Style.marginM 

            NListView {
                id: list

                anchors {
                  fill: parent
                  margins: Style.marginM
                  leftMargin: Style.margin2M
                }
                spacing: Style.marginS

                model: [
                    {
                        visible: vantage.fnLock.available,
                        baseIcon: "keyboard",
                        title: "Fn Lock",
                        description: "Access multimedia keys without holding Fn",
                        checked: vantage.fnLock.value,
                        onToggled: checked => vantage.setFnLockMode(checked)
                    },
                    {
                      visible: true,
                      baseIcon: "brand-windows",
                      title: "Super key",
                      description: "Enables tthe Super/Windows key",
                      checked: false
                    },
                    {
                      visible: true,
                      baseIcon: "device-laptop",
                      title: "Touchpad",
                      description: "Enables the laptop's touchpad",
                      checked: false
                    },
                    {
                        visible: vantage.conservation.available,
                        baseIcon: "battery-charging",
                        checkedIcon: "battery-eco",
                        title: "Battery conservation mode",
                        description: "Limits the charge of the battery to extend its lifespan",
                        checked: vantage.conservation.value,
                        onToggled: checked => vantage.setConservationMode(checked)
                    },
                    {
                        visible: false,
                        baseIcon: "battery-charging",
                        title: "Battery fast charge mode",
                        description: "Allows the battery to charge faster",
                        checked: false
                    },
                    {
                        visible: vantage.alwaysOnUSB.available,
                        baseIcon: "device-usb",
                        title: "Always On USB",
                        description: "Keeps the USB ports always powered on",
                        checked: vantage.alwaysOnUSB.value,
                        onToggled: checked => vantage.setAlwaysOnUSBMode(checked)
                    },
                    {
                      visible: true,
                      baseIcon: "bolt",
                      title: "Display Overdrive",
                      description: "Reduces the laptop's display latency",
                      checked: false
                    },
                    {
                      visible: true,
                      baseIcon: "cpu",
                      title: "Hybrid graphics mode",
                      description: "Enables the laptop's integrated graphics",
                      checked: false
                    }
                ].filter(item => item.visible)


                delegate: SettingsRow {
                    baseIcon: modelData.baseIcon
                    checkedIcon: modelData.checkedIcon ?? ""
                    title: modelData.title
                    description: modelData.description
                    checked: modelData.checked
                    onToggled: checked => modelData.onToggled(checked)
                }
            }
        }
    }
}
