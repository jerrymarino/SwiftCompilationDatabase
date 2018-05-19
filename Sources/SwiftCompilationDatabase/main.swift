// SwiftCompilationDatabase
// This program produces a compile_commands.json from the swift compiler.
import Foundation
import LogParser

func getPath(path: String, relativeTo: String) -> String {
    return path.hasSuffix("/") ?
        path : relativeTo + "/" + path
}

func main() {
    let assumedDir = FileManager.default.currentDirectoryPath
    let logPath = CommandLine.arguments.count > 1 ?
        getPath(path: CommandLine.arguments[1], relativeTo: assumedDir) : nil
    if fcntl(FileHandle.standardInput.fileDescriptor, F_GETFL) != 0 
      && logPath == nil {
        print("""
        Usage:
            swiftc ... -parseable-output 2>&1 | swift-compilation-database
            or
            swift-compilation-database parseable-build.log
        """)
        return
    }
    let messages = LogParser.readMessages(logPath: logPath)
    let db = LogParser.renderCompileCommands(messages: messages, dir:
        assumedDir)
    let outFile = URL(fileURLWithPath: assumedDir + "/compile_commands.json")
    try? db.write(to: outFile, atomically: false, encoding: .utf8)
}

main()
