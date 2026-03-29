import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Services.UI
import "./services"

Item {
    id: root
    property var pluginApi: null

    readonly property var toggleMap: ({
            conservation: VantageService.conservation,
            fnLock: VantageService.fnLock,
            alwaysOnUSB: VantageService.alwaysOnUSB,
            superKey: VantageService.superKey,
            touchpad: VantageService.touchpad,
            fastCharge: VantageService.fastCharge,
            overdrive: VantageService.overdrive,
            hybrid: VantageService.hybrid
        })

    readonly property var fanModeMap: ({
            superSilent: VantageService.fan.modes.SuperSilent,
            standard: VantageService.fan.modes.Standard,
            dustCleaning: VantageService.fan.modes.DustCleaning,
            efficientThermalDissipation: VantageService.fan.modes.EfficientThermalDissipation
        })


    function changeToggle(setting: string, transform: var): var {
      if (!pluginApi) return null;
        const toggleInterface = root.toggleMap[setting] ?? null;

        if (!toggleInterface) {
            Logger.e("NoctaliaVantage", `Invalid setting interface received via IPC: ${setting}`);
            ToastService.showError(pluginApi?.tr("ipc.toggle.error", { setting }));
            return null;
        }
        const newVal = transform(toggleInterface.value);
        toggleInterface.set(newVal);
        return newVal;
    }

    Component.onCompleted: {
        VantageService.refresh();
    }

    IpcHandler {
        target: "plugin:noctalia-vantage"

        function on(setting: string) {
            Logger.d("NoctaliaVantage", `IPC command to turn on ${setting} received`);
            const result = changeToggle(setting, v => true);
            if (result === null) {
              return;
            }
            ToastService.showNotice(pluginApi?.tr("ipc.toggle.turned_on", { setting }));
        }

        function off(setting: string) {
            Logger.d("NoctaliaVantage", `IPC command to turn off ${setting} received`);
            const result = changeToggle(setting, v => false);
            if (result === null) {
              return;
            }
            ToastService.showNotice(pluginApi?.tr("ipc.toggle.turned_off", { setting }));
        }

        function toggle(setting: string) {
            Logger.d("NoctaliaVantage", `IPC command to toggle ${setting} received`);

            const newState = changeToggle(setting, v => !v);
            if (newState === null) {
              return;
            }

            ToastService.showNotice(pluginApi?.tr(newState ? "ipc.toggle.turned_on" : "ipc.toggle.turned_off", { setting }));
        }

        function fan(mode: string) {
            Logger.d("NoctaliaVantage", `IPC command to set fan mode to ${mode} received`);

            const fanMode = fanModeMap[mode];

            if (!fanMode) {
              ToastService.showError(pluginApi?.tr("ipc.fan.error", { mode }));
              Logger.e("NoctaliaVantage", `Invalid fan mode switch request received via IPC: ${mode}`);
              return;
            }

            VantageService.fan.set(fanMode);
            ToastService.showNotice(pluginApi.tr("ipc.fan.success", { mode }));
        }
    }
}
