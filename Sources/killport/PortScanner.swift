import Foundation

/// A process found holding a port.
struct PortProcess: Hashable {
    let pid: pid_t
    let command: String
}

enum PortScanner {
    /// Returns the processes listening on (or bound to) the given port.
    ///
    /// TCP is restricted to `LISTEN` state so we don't kill a client that merely
    /// has an outbound connection to that remote port. UDP has no listen state,
    /// so any bound socket counts.
    static func processes(onPort port: Int) -> [PortProcess] {
        let tcp = lsofPIDs(["-nP", "-iTCP:\(port)", "-sTCP:LISTEN", "-t"])
        let udp = lsofPIDs(["-nP", "-iUDP:\(port)", "-t"])
        let pids = Set(tcp + udp).sorted()
        return pids.map { PortProcess(pid: $0, command: commandName(for: $0)) }
    }

    /// Sends `signal` to `pid`. Returns nil on success, or a human-readable error.
    static func kill(_ pid: pid_t, signal: Int32) -> String? {
        if Foundation.kill(pid, signal) == 0 { return nil }
        switch errno {
        case EPERM: return "permission denied (try sudo)"
        case ESRCH: return "already gone"
        default: return String(cString: strerror(errno))
        }
    }

    // MARK: - Helpers

    private static func lsofPIDs(_ args: [String]) -> [pid_t] {
        // lsof exits non-zero when nothing matches; that is not an error for us.
        let output = run("/usr/sbin/lsof", args) ?? run("/usr/bin/lsof", args) ?? ""
        return output
            .split(separator: "\n")
            .compactMap { pid_t($0.trimmingCharacters(in: .whitespaces)) }
    }

    private static func commandName(for pid: pid_t) -> String {
        let comm = run("/bin/ps", ["-p", "\(pid)", "-o", "comm="])?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !comm.isEmpty else { return "?" }
        return (comm as NSString).lastPathComponent
    }

    private static func run(_ launchPath: String, _ args: [String]) -> String? {
        guard FileManager.default.isExecutableFile(atPath: launchPath) else { return nil }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: launchPath)
        process.arguments = args
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return String(data: data, encoding: .utf8)
    }
}
