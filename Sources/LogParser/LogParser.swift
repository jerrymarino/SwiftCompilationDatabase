/// Read Swift Parseable output representation
/// https://github.com/apple/swift/blob/master/docs/DriverParseableOutput.rst
import Foundation

public enum MessageKind: String, Codable {
    case began
    case finished
    case skipped
    case signalled
}

public struct Message: Codable {
    public let kind: MessageKind

    /// *May* be:
    /// compile, merge-module, link, generate-dsym
    public let name: String
  
    /// This should be non optional for `compile`
    public let command: String?

    public let inputs: [String]?
}

/// Read mesages from a log path or stdin
/// Try `logPath` first, and fallback to stdin
public func readMessages(logPath: String?) -> [Message] {
    return LogParser
        .readInput(logPath: logPath)
        .flatMap { try? JSONDecoder().decode(Message.self, from: $0 ) }
}

/// Render compile_commands.json from messages
public func renderCompileCommands(messages: [Message],
    dir: String = FileManager.default.currentDirectoryPath) -> String {
    let entries = messages.flatMap {
        msg -> String? in
        // Load compile inputs
        guard msg.name == "compile",
              let cmd = msg.command,
              let inputs = msg.inputs,
              // Assume that the file in question is the input
              let assumedFile = inputs.first else {
            return nil
        }
        return """
               {
                   \"file\" : \"\(assumedFile)\",
                   \"command\" : \"\(cmd)\",
                   \"directory\" : \"\(dir)\"
               }
               """
    }
    // Build out the DB JSON
    return "[" + entries .joined(separator: ",\n") + "]"
}

// MARK - Private

/// Read lines from standard input or the `logPath`
func getLines(logPath: String?) -> [String] {
    if let logPath = logPath,
       let value = try? String(contentsOf: URL(fileURLWithPath: logPath)) {
       return value.components(separatedBy: "\n")
    }

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
    return []
}

func readInput(logPath: String?) -> [Data] {
    var buffer: Data = Data()
    var maxLen: Int = 0
    var data = [Data]()
    getLines(logPath: logPath).forEach {
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

