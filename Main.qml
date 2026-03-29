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

    enum ToggleAction {
        On,
        Off,
        Flip
    }

    function waitForWriteResult(obj, successValue = undefined) {
        return new Promise((resolve, reject) => {
            const handler = success => {
                obj.writeFinished.disconnect(handler);
                success ? resolve(successValue) : reject({
                    type: "write_failed"
                });
            };
            obj.writeFinished.connect(handler);
        });
    }

    function setToggle(setting, action) {
        const toggleInterface = toggleMap[setting];
        if (toggleInterface === undefined) {
            Logger.e("NoctaliaVantage", `Invalid toggle setting: ${setting}`);
            return Promise.reject({
                type: "invalid_setting"
            });
        }

        let newVal;

        if (action === Main.ToggleAction.Flip) {
            newVal = !toggleInterface.value;
        } else if (action === Main.ToggleAction.On) {
            newVal = true;
        } else {
            newVal = false;
        }

        toggleInterface.set(newVal);
        return waitForWriteResult(toggleInterface, newVal);
    }

    function setFanMode(mode) {
        const fanMode = fanModeMap[mode];
        if (fanMode === undefined) {
            Logger.e("NoctaliaVantage", `Invalid fan mode: ${mode}`);
            return Promise.reject({
                type: "invalid_mode"
            });
        }

        VantageService.fan.set(fanMode);
        return waitForWriteResult(VantageService.fan);
    }

    function applyToggle(setting, action, messages) {
        root.setToggle(setting, action).then(newState => {
            const key = typeof messages.success === "function" ? messages.success(newState) : messages.success;

            ToastService.showNotice(pluginApi?.tr(key, {
                setting
            }));
        }).catch(err => {
            Logger.e("NoctaliaVantage", `Toggle failed: ${setting}: ${err.type}`);

            if (err.type === "invalid_setting") {
                ToastService.showError(pluginApi?.tr("ipc.toggle.invalid_setting", {
                    setting
                }));
                return;
            }

            ToastService.showError(pluginApi?.tr(messages.error, {
                setting
            }));
        });
    }

    Component.onCompleted: {
        VantageService.refresh();
    }

    IpcHandler {
        target: "plugin:noctalia-vantage"

        function on(setting: string) {
            Logger.d("NoctaliaVantage", `IPC ON ${setting}`);
            root.applyToggle(setting, Main.ToggleAction.On, {
                success: "ipc.toggle.on.success",
                error: "ipc.toggle.on.error"
            });
        }

        function off(setting: string) {
            Logger.d("NoctaliaVantage", `IPC OFF ${setting}`);
            root.applyToggle(setting, Main.ToggleAction.Off, {
                success: "ipc.toggle.off.success",
                error: "ipc.toggle.off.error"
            });
        }

        function toggle(setting: string) {
            Logger.d("NoctaliaVantage", `IPC TOGGLE ${setting}`);
            root.applyToggle(setting, Main.ToggleAction.Flip, {
                success: newState => newState ? "ipc.toggle.on.success" : "ipc.toggle.off.success",
                error: "ipc.toggle.flip.error"
            });
        }

        function fan(mode: string) {
            Logger.d("NoctaliaVantage", `IPC fan ${mode}`);

            root.setFanMode(mode).then(() => {
                ToastService.showNotice(pluginApi?.tr("ipc.fan.set.success", {
                    mode
                }));
            }).catch(err => {
                Logger.e("NoctaliaVantage", `Fan failed: ${mode}: ${err.type}`);

                if (err.type === "invalid_mode") {
                    ToastService.showError(pluginApi?.tr("ipc.fan.invalid_mode", {
                        mode
                    }));
                } else {
                    ToastService.showError(pluginApi?.tr("ipc.fan.set.error", {
                        mode
                    }));
                }
            });
        }
    }
}
