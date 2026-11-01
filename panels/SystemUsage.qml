// Used by: 1 file(s)
import Quickshell.Io
import QtQuick
import "../components"
import "../theme"

Row {
    id: root

    property real cpuUsage: 0
    property real previousCpuTotal: 0
    property real previousCpuIdle: 0
    property real memoryUsed: 0
    property real memoryTotal: 0
    property real swapUsed: 0
    property real swapTotal: 0
    property real uptimeSeconds: 0
    property real loadAverage1: 0
    property real loadAverage5: 0
    property real loadAverage15: 0
    property real networkReceiveRate: 0
    property real networkTransmitRate: 0
    property real previousNetworkReceiveBytes: -1
    property real previousNetworkTransmitBytes: -1
    property double previousNetworkSampleTime: 0
    property real temperatureCelsius: 0
    property bool temperatureKnown: false
    property var topProcesses: []
    property int activeCoreCount: 0
    property bool hasCpuSample: false

    function formatMemory(kibibytes) {
        if (kibibytes >= 1024 * 1024)
            return `${(kibibytes / (1024 * 1024)).toFixed(1)} Go`;

        return `${Math.round(kibibytes / 1024)} Mo`;
    }

    function formatUptime(seconds) {
        const totalMinutes = Math.floor(seconds / 60);
        const days = Math.floor(totalMinutes / 1440);
        const hours = Math.floor((totalMinutes % 1440) / 60);
        const minutes = totalMinutes % 60;
        if (days > 0)
            return `${days} j ${hours} h`;

        if (hours > 0)
            return `${hours} h ${minutes} min`;

        return `${minutes} min`;
    }

    function formatRate(bytesPerSecond) {
        if (bytesPerSecond >= 1024 * 1024)
            return `${(bytesPerSecond / (1024 * 1024)).toFixed(1)} Mo/s`;
        if (bytesPerSecond >= 1024)
            return `${(bytesPerSecond / 1024).toFixed(0)} Ko/s`;
        return `${Math.round(bytesPerSecond)} o/s`;
    }

    function updateNetwork(lines) {
        let received = 0;
        let transmitted = 0;
        for (const line of lines) {
            const separator = line.indexOf(":");
            if (separator < 0)
                continue;
            const interfaceName = line.slice(0, separator).trim();
            if (!interfaceName || interfaceName === "lo")
                continue;
            const fields = line.slice(separator + 1).trim().split(/\s+/).map(Number);
            if (fields.length < 9 || !fields.every(Number.isFinite))
                continue;
            received += fields[0];
            transmitted += fields[8];
        }

        const now = Date.now();
        if (previousNetworkSampleTime > 0) {
            const elapsed = (now - previousNetworkSampleTime) / 1000;
            if (elapsed > 0 && received >= previousNetworkReceiveBytes
                    && transmitted >= previousNetworkTransmitBytes) {
                networkReceiveRate = (received - previousNetworkReceiveBytes) / elapsed;
                networkTransmitRate = (transmitted - previousNetworkTransmitBytes) / elapsed;
            }
        }
        previousNetworkReceiveBytes = received;
        previousNetworkTransmitBytes = transmitted;
        previousNetworkSampleTime = now;
    }

    function parseTopProcesses(output) {
        const groupedProcesses = new Map();
        for (const line of output.trim().split("\n")) {
            const match = line.match(/^\s*(\d+(?:\.\d+)?)\s+(\d+)\s+(.+?)\s*$/);
            if (!match)
                continue;
            const [, cpuText, memoryText, name] = match;
            const cpu = Number(cpuText);
            const memory = Number(memoryText);
            if (!name || !Number.isFinite(cpu) || !Number.isFinite(memory))
                continue;

            const process = groupedProcesses.get(name) || {
                name,
                cpu: 0,
                memory: 0,
                count: 0
            };
            process.cpu += cpu / 100;
            process.memory += memory;
            process.count++;
            groupedProcesses.set(name, process);
        }
        topProcesses = Array.from(groupedProcesses.values())
            .sort((a, b) => b.cpu - a.cpu)
            .slice(0, 5);
    }

    function updateStats(output) {
        const lines = output.trim().split("\n");
        updateNetwork(lines);
        activeCoreCount = lines.filter((line) => {
            return /^\s*cpu\d+\s/.test(line);
        }).length;
        const cpuFields = lines[0].trim().split(/\s+/).slice(1, 9).map(Number);
        if (cpuFields.length === 8 && cpuFields.every(Number.isFinite)) {
            const total = cpuFields.reduce((sum, value) => {
                return sum + value;
            }, 0);
            const idle = cpuFields[3] + cpuFields[4];
            if (hasCpuSample) {
                const totalDelta = total - previousCpuTotal;
                const idleDelta = idle - previousCpuIdle;
                if (totalDelta > 0)
                    cpuUsage = Math.max(0, Math.min(100, (totalDelta - idleDelta) / totalDelta * 100));

            }
            previousCpuTotal = total;
            previousCpuIdle = idle;
            hasCpuSample = true;
        }
        let totalMemory = 0;
        let availableMemory = 0;
        let totalSwap = 0;
        let freeSwap = 0;
        for (const line of lines) {
            if (line.startsWith("MemTotal:"))
                totalMemory = Number(line.split(/\s+/)[1]);
            else if (line.startsWith("MemAvailable:"))
                availableMemory = Number(line.split(/\s+/)[1]);
            else if (line.startsWith("SwapTotal:"))
                totalSwap = Number(line.split(/\s+/)[1]);
            else if (line.startsWith("SwapFree:"))
                freeSwap = Number(line.split(/\s+/)[1]);
        }
        if (totalMemory > 0 && Number.isFinite(availableMemory)) {
            memoryTotal = totalMemory;
            memoryUsed = Math.max(0, totalMemory - availableMemory);
        }
        if (Number.isFinite(totalSwap) && Number.isFinite(freeSwap)) {
            swapTotal = totalSwap;
            swapUsed = Math.max(0, totalSwap - freeSwap);
        }
        const uptimeLine = lines.find((line) => {
            return /^\d+(?:\.\d+)?\s/.test(line);
        });
        if (uptimeLine)
            uptimeSeconds = Number(uptimeLine.trim().split(/\s+/)[0]);

        const loadLine = lines.find((line) => {
            return /^\d+(?:\.\d+)?\s+\d+(?:\.\d+)?\s+\d+(?:\.\d+)?\s+\d+\/\d+\s+\d+/.test(line);
        });
        if (loadLine) {
            const averages = loadLine.trim().split(/\s+/).slice(0, 3).map(Number);
            if (averages.every(Number.isFinite)) {
                loadAverage1 = averages[0];
                loadAverage5 = averages[1];
                loadAverage15 = averages[2];
            }
        }
    }

    height: Theme.buttonSize
    spacing: Theme.spacing
    Process {
        id: statsProcess

        command: ["cat", "/proc/stat", "/proc/meminfo", "/proc/uptime", "/proc/loadavg", "/proc/net/dev"]

        stdout: StdioCollector {
            onStreamFinished: root.updateStats(text)
        }

    }

    Process {
        id: temperatureProcess
        command: [
            "sh",
            "-c",
            "for f in /sys/class/thermal/thermal_zone*/temp; do if [ -r \"$f\" ]; then cat \"$f\"; exit 0; fi; done"
        ]
        stdout: StdioCollector {
            onStreamFinished: {
                const rawTemperature = Number(text.trim());
                if (Number.isFinite(rawTemperature) && rawTemperature > 0) {
                    root.temperatureCelsius = rawTemperature > 1000
                        ? rawTemperature / 1000 : rawTemperature;
                    root.temperatureKnown = true;
                }
            }
        }
    }

    Process {
        id: processListProcess
        command: ["ps", "-eo", "pcpu=,rss=,comm=", "--sort=-pcpu", "--no-headers"]
        stdout: StdioCollector {
            onStreamFinished: root.parseTopProcesses(text)
        }
        stderr: SplitParser {
            onRead: line => console.warn("Processus les plus actifs:", line)
        }
    }

    Component.onCompleted: {
        statsProcess.running = true;
        temperatureProcess.running = true;
        processListProcess.running = true;
    }

    Timer {
        interval: Theme.performanceStatsRefreshSeconds * 1000
        repeat: true
        running: true
        onTriggered: {
            if (!statsProcess.running)
                statsProcess.running = true;

        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            text: "CPU"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }

        Text {
            text: root.hasCpuSample ? `${Math.round(root.cpuUsage).toString().padStart(2, "0")}%` : "--"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }

    }

    Timer {
        interval: Theme.performanceTemperatureRefreshSeconds * 1000
        repeat: true
        running: true
        onTriggered: {
            if (!temperatureProcess.running)
                temperatureProcess.running = true;
        }
    }

    Timer {
        interval: Theme.performanceProcessRefreshSeconds * 1000
        repeat: true
        running: true
        onTriggered: {
            if (!processListProcess.running)
                processListProcess.running = true;
        }
    }

    Row {
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Text {
            text: "RAM"
            color: Theme.text
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }

        Text {
            text: root.memoryTotal > 0 ? `${Math.round(root.memoryUsed / root.memoryTotal * 100)}%` : "--"
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSize - 1
        }

    }


}
