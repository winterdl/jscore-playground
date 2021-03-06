import Combine
import Dispatch
import JavaScriptCoreWrapper
import Models

public enum LogLevel: String, CaseIterable {
    case all
    case debug
    case log
    case info
    case warn
    case error

    func canShow(type: MessageType) -> Bool {
        switch (self, type) {
        case (_, .input), (_, .value): return true
        case (.all, _): return true
        case (.debug, .debug), (.debug, .log), (.debug, .info), (.debug, .warn), (.debug, .error):
            return true
        case (.log, .log), (.log, .info), (.log, .warn), (.log, .error):
            return true
        case (.log, _):
            return false
        case (.info, .info), (.info, .warn), (.info, .error):
            return true
        case (.info, _):
            return false
        case (.warn, .warn), (.warn, .error):
            return true
        case (.warn, _):
            return false
        case (.error, .error):
            return true
        case (.error, _):
            return false
        }
    }
}

public final class ConsoleViewModel {
    @Published public var input = ""
    @Published public var messages = [ConsoleMessage]()
    @Published public var logLevel = LogLevel.all

    let context = JSContext()

    public var filteredReversedMessages: [ConsoleMessage] {
        self.messages
            .lazy
            .filter { self.logLevel.canShow(type: $0.type) }
            .reversed()
    }

    public init() {
        self.context.exceptionHandler = { _, exception in
            let string = exception!.toString()
            self.messages.append(ConsoleMessage(text: string, type: .error))
        }

        let log = { type in
            {
                self.messages
                    .append(
                        ConsoleMessage(
                            text: $0,
                            type: type
                        )
                    )
            } as @convention(block) (String) -> Void
        }
        let console = self.context
            .objectForKeyedSubscript("console")

        [
            "log": MessageType.log,
            "debug": .debug,
            "error": .error,
            "info": .info,
            "table": .log,
            "warn": .warn,
        ]
        .forEach { (k, v) in
            console.setObject(log(v), forKeyedSubscript: k)
        }
        console.setObject(
            self.clear as @convention(block) () -> Void,
            forKeyedSubscript: "clear"
        )
    }

    public func run() {
        self.messages.append(ConsoleMessage(text: self.input, type: .input))

        let result = self.context.evaluateScript(self.input).toString()
        self.messages.append(ConsoleMessage(text: result, type: .value))

        self.input = ""
    }

    public func clear() {
        self.messages.removeAll()
    }
}

extension ConsoleViewModel: ObservableObject {}
