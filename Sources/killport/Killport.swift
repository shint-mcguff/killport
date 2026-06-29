import ArgumentParser
import Foundation

@main
struct Killport: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "killport",
        abstract: "Free up a port by killing whatever is listening on it.",
        version: "0.1.0"
    )

    @Argument(help: "One or more ports to free up (e.g. 3000 8080).")
    var ports: [Int]

    @Flag(name: [.short, .long], help: "Use SIGKILL (-9) instead of a graceful SIGTERM.")
    var force = false

    @Flag(name: [.customShort("n"), .long], help: "Show what holds each port without killing.")
    var dryRun = false

    @Flag(name: [.short, .long], help: "Only print errors.")
    var quiet = false

    func validate() throws {
        guard !ports.isEmpty else {
            throw ValidationError("Specify at least one port.")
        }
        for port in ports where !(1...65535).contains(port) {
            throw ValidationError("Port \(port) is out of range (1–65535).")
        }
    }

    func run() throws {
        let signal: Int32 = force ? SIGKILL : SIGTERM
        var freedSomething = false
        var hadError = false

        for port in Set(ports).sorted() {
            let procs = PortScanner.processes(onPort: port)

            guard !procs.isEmpty else {
                if !quiet { print("port \(port): nothing listening") }
                continue
            }

            for proc in procs {
                if dryRun {
                    if !quiet { print("port \(port): \(proc.command) (pid \(proc.pid)) — would \(force ? "SIGKILL" : "SIGTERM")") }
                    freedSomething = true
                    continue
                }
                if let error = PortScanner.kill(proc.pid, signal: signal) {
                    FileHandle.standardError.write(
                        Data("port \(port): failed to kill \(proc.command) (pid \(proc.pid)): \(error)\n".utf8))
                    hadError = true
                } else {
                    freedSomething = true
                    if !quiet { print("port \(port): killed \(proc.command) (pid \(proc.pid))") }
                }
            }
        }

        if hadError { throw ExitCode.failure }
        if !freedSomething { throw ExitCode(2) } // nothing was listening on any port
    }
}
