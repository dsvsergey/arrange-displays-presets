import AppKit

let arguments = Array(CommandLine.arguments.dropFirst())
if !arguments.isEmpty {
    exit(CLI.run(arguments))
}

let app = NSApplication.shared
app.setActivationPolicy(.accessory)
let controller = MenuBarController()
app.run()
