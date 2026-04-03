import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Widgets
import "./ui"

Item {
    id: root

    property var pluginApi: null
    readonly property var service: pluginApi?.mainInstance.service

    readonly property var geometryPlaceholder: mainLayout
    readonly property bool allowAttach: true

    property real contentPreferredWidth: Math.round(540 * Style.uiScaleRatio)
    property real contentPreferredHeight: Math.round((mainLayout.implicitHeight + 2 * Style.marginL) * Style.uiScaleRatio)

    property int fanModeIndex: fanModeToIndex(root.service.fan.value)

    // ===== MODES =====
    property var fanModesUI: [
        {
            key: 0,
            label: pluginApi?.tr("panel.fan.mode.super_silent"),
            icon: "leaf"
        },
        {
            key: 1,
            label: pluginApi?.tr("panel.fan.mode.standard"),
            icon: "balance"
        },
        {
            key: 4,
            label: pluginApi?.tr("panel.fan.mode.efficient_thermal_dissipation"),
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

    function indexToFanMode(index) {
        return fanModesUI[index].key;
    }

    function indexToLabel(index) {
        return fanModesUI[index].label;
    }

    anchors.fill: parent

    Component.onCompleted: {
        if (pluginApi) {
            root.service.refresh();
            Logger.i("VantageCtl", "Panel initialized");
        }
    }

    onVisibleChanged: {
        if (visible) {
            Logger.i("VantageCtl", "Panel toggled: refereshing service");
            root.service.refresh();
        }
    }

    onPluginApiChanged: {
        // Force re-evaluation of mainInstance binding when pluginApi changes
        if (pluginApi && pluginApi.mainInstance) {
            serviceChanged();
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
                    icon: "letter-v"
                }

                ColumnLayout {
                    spacing: Style.marginXXS
                    Layout.fillWidth: true

                    NText {
                        text: pluginApi?.tr("widget.title")
                        pointSize: Style.fontSizeL
                        font.weight: Style.fontWeightBold
                        color: Color.mOnSurface
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                }

                NIconButton {
                    icon: "close"
                    tooltipText: pluginApi?.tr("panel.close")
                    baseSize: Style.baseWidgetSize * 0.8
                    onClicked: root.pluginApi.closePanel(root.pluginApi.panelOpenScreen)
                }
            }
        }

        Loader {
            Layout.fillWidth: true

            sourceComponent: root.service.available ? mainContent : unavailableContent
        }

        Component {
            id: unavailableContent

            NBox {
                anchors.centerIn: parent
                Layout.fillWidth: true
                implicitHeight: content.implicitHeight + Style.margin2L

                ColumnLayout {
                    id: content
                    anchors.fill: parent
                    anchors.margins: Style.marginL
                    spacing: Style.marginM

                    NIcon {
                        icon: "alert-triangle"
                        pointSize: Style.fontSizeXL
                        color: Color.mError
                        Layout.alignment: Qt.AlignHCenter
                    }

                    NText {
                        text: pluginApi?.tr("panel.unavailable.title")
                        color: Color.mOnSurface
                        font.weight: Style.fontWeightBold
                        horizontalAlignment: Text.AlignHCenter
                        Layout.fillWidth: true
                    }

                    NText {
                        text: pluginApi?.tr("panel.unavailable.description")
                        color: Color.mOnSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }

        Component {
            id: mainContent

            ColumnLayout {
                anchors.fill: parent

                NBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: controlsLayout.implicitHeight + Style.margin2L

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
                                    text: pluginApi?.tr("panel.fan.title")
                                    font.weight: Style.fontWeightBold
                                    color: Color.mOnSurface
                                    Layout.fillWidth: true
                                }

                                NText {
                                    text: root.indexToLabel(root.fanModeIndex)
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
                                value: root.fanModeToIndex(root.service.fan.value)

                                onMoved: v => {
                                    root.fanModeIndex = v;
                                }

                                onPressedChanged: pressed => {
                                    if (!pressed) {
                                        root.service.fan.set(root.indexToFanMode(root.fanModeIndex));
                                    }
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
                                text: pluginApi?.tr("panel.fan.mode.dust_cleaning")
                                pointSize: Style.fontSizeM
                                font.weight: Style.fontWeightBold
                                color: Color.mOnSurface
                                Layout.fillWidth: true
                            }

                            NIconButton {
                                icon: "windmill"
                                onClicked: root.service.fan.set(root.service.fan.modes.DustCleaning)
                            }
                        }
                    }
                }

                NBox {
                    Layout.fillWidth: true
                    Layout.preferredHeight: list.contentHeight

                    NListView {
                        id: list

                        anchors {
                            fill: parent
                            leftMargin: Style.marginL
                        }
                        spacing: Style.marginS

                        model: [
                            {
                                visible: root.service.fnLock.available,
                                key: "panel.toggle.fn_lock",
                                baseIcon: "keyboard",
                                checked: root.service.fnLock.value,
                                onToggled: checked => root.service.fnLock.set(checked)
                            },
                            {
                                visible: root.service.superKey.available,
                                key: "panel.toggle.super_key",
                                baseIcon: "brand-windows",
                                checked: root.service.superKey.value,
                                onToggled: checked => root.service.superKey.set(checked)
                            },
                            {
                                visible: root.service.touchpad.available,
                                key: "panel.toggle.touchpad",
                                baseIcon: "device-laptop",
                                checked: root.service.touchpad.value,
                                onToggled: checked => root.service.touchpad.set(checked)
                            },
                            {
                                visible: root.service.conservation.available,
                                key: "panel.toggle.conservation",
                                baseIcon: "battery-charging",
                                checkedIcon: "battery-eco",
                                checked: root.service.conservation.value,
                                onToggled: checked => root.service.conservation.set(checked)
                            },
                            {
                                visible: root.service.fastCharge.available,
                                key: "panel.toggle.fast_charge",
                                baseIcon: "battery-charging",
                                checked: root.service.fastCharge.value,
                                onToggled: checked => root.service.fastCharge.set(checked)
                            },
                            {
                                visible: root.service.alwaysOnUSB.available,
                                key: "panel.toggle.always_on_usb",
                                baseIcon: "device-usb",
                                checked: root.service.alwaysOnUSB.value,
                                onToggled: checked => root.service.alwaysOnUSB.set(checked)
                            },
                            {
                                visible: root.service.overdrive.available,
                                key: "panel.toggle.overdrive",
                                baseIcon: "bolt",
                                checked: root.service.overdrive.value,
                                onToggled: checked => root.service.overdrive.set(checked)
                            },
                            {
                                visible: root.service.hybrid.available,
                                key: "panel.toggle.hybrid",
                                baseIcon: "cpu",
                                checked: root.service.hybrid.value,
                                onToggled: checked => root.service.hybrid.set(checked)
                            }
                        ].filter(item => item.visible)

                        delegate: SettingsRow {
                            required property var modelData
                            baseIcon: modelData.baseIcon
                            checkedIcon: modelData.checkedIcon ?? ""
                            title: pluginApi.tr(modelData.key + ".title")
                            description: pluginApi.tr(modelData.key + ".description")
                            tooltip: pluginApi.tr(modelData.key + ".tooltip")
                            checked: modelData.checked
                            onToggled: checked => modelData.onToggled(checked)
                        }
                    }
                }
            }
        }
    }
}
