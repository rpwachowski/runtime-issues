import Foundation
import os.log

@_transparent public func runtimeIssue(_ warningFormat: StaticString, file: StaticString = #file, line: UInt = #line, _ arguments: CVarArg...) {
    // @_transparent inlines the function call and causes Xcode's stack trace for the
    // runtime issue to show only the callee for the stack frames above the call to
    // raise (e.g. withVaList, the closures in the body of raise, etc.)
#if DEBUG
    withVaList(arguments) { RuntimeIssueLogger.default.raise(warningFormat, file: file, line: line, vaList: $0) }
#endif
}

private var hasLoggedUnavailable = false

func RTI_RUNTIME_ISSUES_UNAVAILABLE() {
    if hasLoggedUnavailable { return }
    os_log(.fault, "Warn only once: a runtime issue logging expectation was violated. Runtime issues will not be logged. Set a symbolic breakpoint on 'RTI_RUNTIME_ISSUES_UNAVAILABLE' to trace.")
    hasLoggedUnavailable = true
}
