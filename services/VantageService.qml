pragma Singleton

import QtQuick
import qs.Commons

QtObject {
    id: root

    readonly property var controls: [fan, conservation, fnLock, alwaysOnUSB, superKey, touchpad, fastCharge, overdrive, hybrid]

    readonly property var fanModes: ({
            SuperSilent: 0,
            Standard: 1,
            DustCleaning: 2,
            EfficientThermalDissipation: 4
        })

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
        validValues: [root.fanModes.SuperSilent, root.fanModes.Standard, root.fanModes.DustCleaning, root.fanModes.EfficientThermalDissipation]
        parser: function (raw) {
            const v = parseInt(raw?.trim());
            if (isNaN(v)) {
                Logger.w("NoctaliaVantage", "Invalid fan value:", raw);
                return undefined;
            }
            const bits = v & 7; // Extarct last 3 bits
            if (this.validValues.includes(bits)) {
                return bits;
            }

            return root.fanModes.SuperSilent;
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
        Logger.i("NoctaliaVantage", "Service starting...");
        for (let c of controls) {
            c.checkAvailability();
        }
    }

    function refresh() {
        if (!available) {
            Logger.w("NoctaliaVantage", "Refresh skipped: service not available");
            return;
        }
        Logger.i("NoctaliaVantage", "Refreshing values...");
        for (let c of controls) {
            c.reload();
        }
    }
}
