#if !canImport(ObjectiveC)
import XCTest

public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(RuntimeIssuesTests.allTests),
    ]
}

#endif
