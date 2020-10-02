import Foundation

struct HashedStaticString: Hashable {

    static func == (lhs: HashedStaticString, rhs: HashedStaticString) -> Bool {
        lhs.base.withUTF8Buffer { lhs in
            rhs.base.withUTF8Buffer { rhs in
                zip(lhs, rhs).first { $0.0 != $0.1 } == nil
            }
        }
    }

    private var base: StaticString

    init(_ base: StaticString) {
        self.base = base
    }

    func hash(into hasher: inout Hasher) {
        base.withUTF8Buffer { buffer in
            hasher.combine(bytes: UnsafeRawBufferPointer(buffer))
        }
    }

}
