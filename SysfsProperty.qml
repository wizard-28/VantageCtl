import QtQuick
import qs.Commons
import Quickshell.Io

QtObject {
    id: root

    required property string path
    required property string label

    property var parser: function (raw) {
        const v = parseInt(raw?.trim());

        if (isNaN(v)) {
            Logger.w("Vantage", root.label + ": invalid value:", raw);
            return undefined;
        }

        return v === 1;
    }

    property bool available: false
    property bool writable: false

    function checkAvailability() {
      availabilityChecker.running = true;
    }

    property var _availabilityChecker: Process {
      id: availabilityChecker
      running: false
      command: ["/bin/bash", "-c", `test -f ${root.path} && (test -w ${root.path} && echo "2" || echo "1") || echo "0"`]
      stdout: StdioCollector {
        onStreamFinished: {
          const r = parseInt(text)
          root.available = r >= 1;
          root.writable = r === 2;
          Logger.i("Vantage", root.label, "available:", root.available, "writable:", root.writable);
          if (root.available) root.reload();
        }
      }
    }

    property var value: null
    signal writeFinished(bool success)
    onWriteFinished: success => { if (success) reload() }

    property var writeCommand: (val) =>["pkexec", "bash", "-c", `echo ${val} > ${root.path}`] 

    function write(newVal) {
      if (!writeCommand) {
        Logger.e("Vantage", `${root.label}: no writeCommand set`);
        return;
      }

      writer.pending = newVal;
      writer.command = root.writeCommand(newVal);
      writer.running = true;
    }

    function reload() {
        reader.path = ""; // Force QML to recognize the refresh
        reader.path = root.path;
    }

    property var _reader: FileView {
        id: reader
        path: root.path
        printErrors: false

        onLoaded: {
            const parsed = root.parser(text());
            if (parsed === undefined)
                return;
            if (parsed !== root.value) {
                root.value = parsed;
                Logger.i("Vantage", `${root.label} ->`, parsed);
            } else {
                Logger.d("Vantage", `${root.label} unchanged:`, parsed);
            }
        }
    }

    property var _writer: Process {
        id: writer
        running: false
        property var pending: null

        onStarted: Logger.i("Vantage", `Writing ${root.label}:`, pending)

        onExited: code => {
            if (code === 0) {
                Logger.i("Vantage", `${root.label} write success:`, pending);
                root.value = pending;
                root.writeFinished(true);
              } else {
                Logger.e("Vantage", `${root.label} write failed, code: `, code);
                root.writeFinished(false);
              }
        }
    }
}
