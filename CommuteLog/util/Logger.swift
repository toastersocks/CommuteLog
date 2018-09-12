//
//  Logger.swift
//  CommuteLog
//
//  Created by Ryan Arana on 9/10/18.
//  Copyright © 2018 Aranasaurus. All rights reserved.
//

import Foundation

enum LogLevel: Int {
    case verbose
    case debug
    case info
    case warning
    case error
}

extension LogLevel: CustomStringConvertible {
    var description: String {
        switch self {
        case .verbose: return "VERBOSE"
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}

extension LogLevel: Comparable {
    static func <(lhs: LogLevel, rhs: LogLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

private let logQueue = DispatchQueue(label: "com.aranasaurus.logging", qos: .utility)

class Logger {
    static var instance: Logger = Logger()

    static func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        instance.verbose(message, file, function, line)
    }
    static func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        instance.debug(message, file, function, line)
    }
    static func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        instance.info(message, file, function, line)
    }
    static func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        instance.warning(message, file, function, line)
    }
    static func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        instance.error(message, file, function, line)
    }

    private let formatter = ISO8601DateFormatter()

    var minLevel: LogLevel
    var fileHandle: FileHandle?

    init(minLevel: LogLevel = .verbose) {
        self.minLevel = minLevel
        formatter.formatOptions = [
            .withFullDate,
            .withSpaceBetweenDateAndTime,
            .withColonSeparatorInTime,
            .withTime
        ]
        if #available(iOS 11.2, *) {
            formatter.formatOptions.insert(.withFractionalSeconds)
        }
        formatter.timeZone = Calendar.current.timeZone

        let fileManager = FileManager.default
        do {
            let url = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .allDomainsMask,
                appropriateFor: nil,
                create: true
            ).appendingPathComponent("CommuteLog").appendingPathComponent("debug.log")
            try fileManager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

            let data = try? Data(contentsOf: url)
            if fileManager.createFile(atPath: url.path, contents: data, attributes: nil) {
                if data == nil {
                    print("Logger created log file \(url.path)")
                } else {
                    print("Logger opened log file \(url.path)")
                }
                fileHandle = try FileHandle(forUpdating: url)
            } else {
                print("Logger failed to create log file!")
            }
        } catch {
            print("Logger failed to create directory: \(error)")
        }

        info("Logger initialized with minLevel: \(minLevel)")
    }

    deinit {
        fileHandle?.closeFile()
    }

    func verbose(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        log(message, for: .verbose, file, function, line)
    }
    func debug(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        log(message, for: .debug, file, function, line)
    }
    func info(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        log(message, for: .info, file, function, line)
    }
    func warning(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        log(message, for: .warning, file, function, line)
    }
    func error(_ message: @autoclosure () -> Any, _ file: String = #file, _ function: String = #function, _ line: Int = #line) {
        log(message, for: .error, file, function, line)
    }

    private func log(_ message: @autoclosure () -> Any, for level: LogLevel, _ file: String, _ function: String, _ line: Int) {
        let printToConsole = level >= minLevel
        let msg = message()

        logQueue.async {
            if msg is [String: Any] || msg is [[String: Any]] {
                let lines = String.prettyPrint(msg).split(separator: Character("\n")).map {
                    self.format(String($0), level, file, function, line) + "\n"
                }
                for line in lines {
                    self.write(line, printToConsole)
                }
            } else {
                let formattedMessage = self.format("\(msg)", level, file, function, line)
                self.write(formattedMessage, printToConsole)
            }
        }
    }

    private func format(_ message: String, _ level: LogLevel, _ file: String, _ function: String, _ line: Int) -> String {
        return "[\(level)][\(formatter.string(from: Date())) \(className(from: file)).\(function):\(line)]: \(message)"
    }

    private func className(from filePath: String) -> String {
        return URL(fileURLWithPath: filePath).deletingPathExtension().lastPathComponent
    }

    private func write(_ message: String, _ printToConsole: Bool) {
        if printToConsole {
            // give it a prefix so you can filter for it
            print("[CommuteLog]\(message)", terminator: message.last == Character("\n") ? "" : "\n")
        }

        guard let file = fileHandle else { return }

        file.seekToEndOfFile()
        file.write("\(message)\n".data(using: .utf8)!)
    }
}

extension String {
    static func prettyPrint(_ json: Any) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted]) else { return "\(json)" }
        return String(data: data, encoding: .utf8) ?? "\(json)"
    }
}

