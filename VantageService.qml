import QtQuick
import Quickshell.Io
import qs.Commons

Item {
    id: root
    visible: false

    property var pluginApi: null

    // ===== STATE =====
    property bool available: fan.available || conservation.available || fnLock.available

    readonly property string basePath: "/sys/bus/platform/drivers/ideapad_acpi/VPC2004:00"
    readonly property string fanFile: basePath + "/fan_mode"
    readonly property string conservationFile: basePath + "/conservation_mode"
    readonly property string fnLockFile: basePath + "/fn_lock"
    readonly property string alwaysOnUSBFile: basePath + "/usb_charging"

    readonly property var fanModes: [0, 1, 2, 4]

    // ===== SYSFS PROPERTIES =====
    readonly property alias fan: _fan
    readonly property alias conservation: _conservation
    readonly property alias fnLock: _fnLock
    readonly property alias alwaysOnUSB: _alwaysOnUSB

    SysfsProperty {
        id: _fan
        path: root.fanFile
        label: "fan mode"
        parser: function(raw) {
            const v = parseInt(raw?.trim());
            if (isNaN(v)) {
                Logger.w("Vantage", "Invalid fan value:", raw);
                return undefined;
            }
            const bits = v & 7;
            if (bits & 4) return 4;
            if (bits & 2) return 2;
            if (bits & 1) return 1;
            return 0;
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
        fan.checkAvailability();
        conservation.checkAvailability();
        fnLock.checkAvailability();
        alwaysOnUSB.checkAvailability();
    }

    function refresh() {
        if (!available) {
            Logger.w("Vantage", "Refresh skipped: service not available");
            return;
        }
        Logger.i("Vantage", "Refreshing values...");
        fan.reload();
        conservation.reload();
        fnLock.reload();
        alwaysOnUSB.reload();
    }

    function setFanMode(mode) {
        if (!fanModes.includes(mode)) {
            Logger.e("Vantage", "Invalid fan mode:", mode);
            return;
        }
        Logger.i("Vantage", "Setting fan mode →", mode);
        fan.write(mode);
    }

    function setConservationMode(enabled) {
        Logger.i("Vantage", "Setting conservation mode →", enabled);
        conservation.write(enabled ? 1 : 0);
    }

    function setFnLockMode(enabled) {
      Logger.i("Vantage", "Setting fnLock mode ->", enabled);
      fnLock.write(enabled ? 1 : 0);
    }


    function setAlwaysOnUSBMode(enabled) {
      Logger.i("Vantage", "Setting alwaysOnUSB mode ->", enabled);
      alwaysOnUSB.write(enabled ? 1 : 0);
    }
}
