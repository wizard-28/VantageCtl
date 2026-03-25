import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    visible: false

    property var pluginApi: null

    // ===== STATE =====
    property bool available: fan.available || conservation.available || fnLock.available

    readonly property string ideapadModPath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00"
    readonly property string fanFile: ideapadModPath + "/fan_mode"
    readonly property string conservationFile: ideapadModPath + "/conservation_mode"
    readonly property string fnLockFile: ideapadModPath + "/fn_lock"
    readonly property string alwaysOnUSBFile: ideapadModPath + "/usb_charging"

    // ===== SYSFS PROPERTIES =====
    readonly property alias fan: _fan
    readonly property alias conservation: _conservation
    readonly property alias fnLock: _fnLock
    readonly property alias alwaysOnUSB: _alwaysOnUSB


    readonly property var controls: [
        fan,
        conservation,
        fnLock,
        alwaysOnUSB
    ]

    readonly property var fanModes: ({
        SuperSilent: 0,
        Standard: 1,
        DustCleaning: 2,
        EfficientThermalDissipation: 4
    })

    SysfsProperty {
        id: _fan
        path: root.fanFile
        label: "fan mode"
        validValues: [root.fanModes.SuperSilent, root.fanModes.Standard, root.fanModes.DustCleaning, root.fanModes.EfficientThermalDissipation]
        parser: function (raw) {
            const v = parseInt(raw?.trim());
            if (isNaN(v)) {
                Logger.w("Vantage", "Invalid fan value:", raw);
                return undefined;
            }
            const bits = v & 7; // Extarct last 3 bits
            if (this.validValues.includes(bits)) {
              return bits;
            }

            return root.fanModes.SuperSilent;
        }
    }

    SysfsProperty {
        id: _conservation
        path: root.conservationFile
        label: "conservation mode"
    }

    SysfsProperty {
        id: _fnLock
        path: root.fnLockFile
        label: "fn lock"
    }

    SysfsProperty {
        id: _alwaysOnUSB
        path: root.alwaysOnUSBFile
        label: "always on usb"
    }

    // ===== INIT =====
    Component.onCompleted: {
        Logger.i("Vantage", "Service starting...");
        for (let c of controls) {
          c.checkAvailability();
        }
    }

    function refresh() {
        if (!available) {
            Logger.w("Vantage", "Refresh skipped: service not available");
            return;
        }
        Logger.i("Vantage", "Refreshing values...");
        for (let c of controls) {
          c.reload();
        }
    }
}
