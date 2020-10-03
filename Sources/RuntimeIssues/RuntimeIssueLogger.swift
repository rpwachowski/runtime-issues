import Foundation
import os.log
import _SwiftOSOverlayShims

public struct RuntimeIssueLogger {

    private class CallsiteCache {

        private struct Invocation: Hashable {
            var file: HashedStaticString
            var line: UInt
        }

        private var invocations = Set<Invocation>()

        /// Returns whether to raise a runtime issue in a file on a particular line.
        ///
        /// A notification of a runtime issue will only arise once, so only the first call will return true.
        func shouldRaiseIssue(in file: StaticString, on line: UInt) -> Bool {
            invocations.insert(Invocation(file: HashedStaticString(file), line: line)).inserted
        }

    }

    /// Returns the shared default runtime issue logger with a generic category.
    public static let `default` = RuntimeIssueLogger(category: "Runtime issues")

    private static let commonSubsystem = "com.apple.runtime-issues"

    private let log: OSLog
    private let callsiteCache = CallsiteCache()

#if DEBUG
    /// Controls whether calls to `raise` are executed. Logging is enabled by default.
    public var isEnabled = true
#else
    /// Controls whether calls to `raise` are executed. Logging is enabled by default.
    public let isEnabled = false
#endif

    /// Initializes a custom runtime issue logger with a custom category.
    public init(category: StaticString) {
        let categoryName = category.withUTF8Buffer { String(decoding: $0, as: UTF8.self) }
        self.log = OSLog(subsystem: Self.commonSubsystem, category: categoryName)
    }

    /// Log a runtime issue to the console.
    ///
    /// When executed while attached to Xcode's debugger, this will have the additional effect
    /// of highlighting the issue and providing heads-up information regarding the issue.
    @_transparent public func raise(_ warningFormat: StaticString, file: StaticString = #file, line: UInt = #line, _ arguments: CVarArg...) {
        // @_transparent inlines the function call and causes Xcode's stack trace for the
        // runtime issue to show only the callee for the stack frames above the call to
        // raise (e.g. withVaList, the closures in the body of raise, etc.)
#if DEBUG
        withVaList(arguments) { raise(warningFormat, file: file, line: line, vaList: $0) }
#endif
    }

    /// Log a runtime issue to the console.
    ///
    /// When executed while attached to Xcode's debugger, this will have the additional effect
    /// of highlighting the issue and providing heads-up information regarding the issue.
    @usableFromInline func raise(_ warningFormat: StaticString, file: StaticString = #file, line: UInt = #line, vaList: CVaListPointer) {
#if DEBUG
        let ra = _swift_os_log_return_address()
        guard isEnabled, log.isEnabled(type: .fault), callsiteCache.shouldRaiseIssue(in: file, on: line) else { return }
        guard let handle = systemFrameworkHandle else { return RTI_RUNTIME_ISSUES_UNAVAILABLE() }
        warningFormat.withUTF8Buffer { buffer in
            guard let base = buffer.baseAddress else { return }
            base.withMemoryRebound(to: CChar.self, capacity: buffer.count) { cString in
                // Xcode reveals generic runtime issues which match the following criteria:
                //
                // 1. the dso is a system framework
                // 2. the subsystem is "com.apple.runtime-issues"
                // 3. the level is a fault
                //
                // Hijacking the handle for a system framework doesn't appear to have any negative side-effects.
                // Given that this is for interfacing with Xcode to bring to attention a category of failures
                // which are specifically to be fixed during the development/debugging cycle, this is _probably_ ok.
                _swift_os_log(handle, ra, log, .fault, cString, vaList)
            }
        }
#endif
    }

}
