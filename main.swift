// SwiftCompilationDatabase
// This program produces a compile_commands.json from the swift compiler.

import Foundation

/// Mark - Parseable output representation
/// https://github.com/apple/swift/blob/master/docs/DriverParseableOutput.rst

enum MessageKind: String, Codable {
    case began
    case finished
    case skipped
    case signalled
}

struct Message: Codable {
    let kind: MessageKind

    /// *May* be:
    /// compile, merge-module, link, generate-dsym
    let name: String
  
    /// This should be non optional for `compile`
    let command: String?

    let inputs: [String]?
}

/// Read either standard input or the first argument
func getLines() -> [String] {
    let standardInput = FileHandle.standardInput
    if fcntl(standardInput.fileDescriptor, F_GETFL) == 0 {
        var lines = [String]()
        repeat {
            if let line = readLine() {
                lines.append(line)
            } else {
                break
            }
        } while true
        return lines
    }

    if CommandLine.arguments.count > 1 {
        let logPath = CommandLine.arguments[1]
        let cwd = FileManager.default.currentDirectoryPath
        let filePath = logPath.hasSuffix("/") ? logPath : cwd + logPath
        let value = try! String(contentsOf: URL(fileURLWithPath: filePath))
        return value.components(separatedBy: "\n")
    }
    return []
}

/// Read each chunk, assuming that Ints split parseable Messages
func readInput() -> [Data] {
    var buffer: Data = Data()
    var maxLen: Int = 0
    var data = [Data]()
    getLines().forEach {
        line in 
        if let offset = Int(line) {
            maxLen = offset
            if buffer.count > 0  {
                data.append(buffer)
            }
            buffer = Data()
            return 
        }
        if maxLen > 0 {
            buffer.append(line.data(using: .utf8)!)
        }
    }

    if buffer.count > 0  {
        data.append(buffer)
    }
    return data
}

func main() {
    let entries = readInput().flatMap {
        data -> String? in
        // Load compile inputs
        guard let msg = try? JSONDecoder().decode(Message.self, from: data),
              msg.name == "compile",
              let cmd = msg.command,
              let inputs = msg.inputs,
              // Assume that the file in question is the input
              let assumedFile = inputs.first else {
            return nil
        }

        // Assume that the cwd is the dir that the user is running the program
        // from. This is not very good.
        let assumedDir = FileManager.default.currentDirectoryPath
        return """
               {
                   \"file\" : \"\(assumedFile)\",
                   \"command\" : \"\(cmd)\",
                   \"directory\" : \"\(assumedDir)\"
               }
               """
    }
    guard entries.count > 0 else {
        print("""
        Usage:
            swiftc ... -parseable-output 2>&1 | swift-compilation-database
            or
            swift-compilation-database parseable-build.log
        """)
        return
    }
    // Build out the DB JSON
    let db = "[" + entries .joined(separator: ",\n") + "]"


    let cwd = FileManager.default.currentDirectoryPath
    let outFile = URL(fileURLWithPath: cwd + "/compile_commands.json")
    try? db.write(to: outFile, atomically: false, encoding: .utf8)
}

main()
