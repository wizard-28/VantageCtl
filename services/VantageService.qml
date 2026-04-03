import QtQuick
import qs.Commons

QtObject {
    id: root

    // defaults to false, we determine it dynamically later in `Component.onCompleted`
    property bool available: false

    readonly property var controls: [fan, conservation, fnLock, alwaysOnUSB, superKey, touchpad, fastCharge, overdrive, hybrid]

    component IdeapadSysfsProperty: SysfsProperty {
        required property string file
        readonly property string basePath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00"

        path: basePath + "/" + file
    }

    component LegionSysfsProperty: SysfsProperty {
        required property string file
        readonly property string basePath: "/sys/bus/platform/drivers/legion/PNP0C09:00"

        path: basePath + "/" + file
    }

    property IdeapadSysfsProperty fan: IdeapadSysfsProperty {
        file: "fan_mode"
        label: "fan mode"

        readonly property var modes: ({
                SuperSilent: 0,
                Standard: 1,
                DustCleaning: 2,
                EfficientThermalDissipation: 4
            })

        function parse(raw) {
            const v = parseInt(raw?.trim());
            if (isNaN(v)) {
                Logger.w("VantageCtl", "Invalid fan value:", raw);
                return undefined;
            }
            const bits = v & 7; // Extract last 3 bits
            if (Object.values(modes).includes(bits)) {
                return bits;
            }

            return modes.SuperSilent;
        }

        function validate(newVal) {
            if (!Object.values(modes).includes(newVal)) {
                Logger.e("VantageCtl", "Invalid fan mode:", newVal);
                return false;
            }

            return true;
        }
    }

    property IdeapadSysfsProperty conservation: IdeapadSysfsProperty {
        file: "conservation_mode"
        label: "conservation mode"
    }

    property IdeapadSysfsProperty fnLock: IdeapadSysfsProperty {
        file: "fn_lock"
        label: "fn lock"
    }

    property IdeapadSysfsProperty alwaysOnUSB: IdeapadSysfsProperty {
        file: "usb_charging"
        label: "always on usb"
    }

    property LegionSysfsProperty superKey: LegionSysfsProperty {
        file: "winKey"
        label: "super key"
    }

    property LegionSysfsProperty touchpad: LegionSysfsProperty {
        file: "touchpad"
        label: "touchpad"
    }

    property LegionSysfsProperty fastCharge: LegionSysfsProperty {
        file: "rapidcharge"
        label: "fast charge"
    }

    property LegionSysfsProperty overdrive: LegionSysfsProperty {
        file: "overdrive"
        label: "overdrive"
    }

    // TODO: reboot after applying changes
    property LegionSysfsProperty hybrid: LegionSysfsProperty {
        file: "gsync"
        label: "hybrid graphics"
    }

    // ===== INIT =====
    Component.onCompleted: {
        Logger.i("VantageCtl", "Service starting...");
        for (let c of controls) {
            c.checkAvailability();

            c.availableChanged.connect(() => {
                if (c.available) {
                    root.available = true;
                }
            });
        }
    }

    function refresh() {
        if (!root.available) {
            Logger.w("VantageCtl", "Refresh skipped: service not available");
            return;
        }
        Logger.i("VantageCtl", "Refreshing values...");
        for (let c of controls) {
            c.reload();
        }
    }
}
