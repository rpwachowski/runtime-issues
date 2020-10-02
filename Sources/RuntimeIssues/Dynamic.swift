import MachO

let systemFrameworkHandle: UnsafeRawPointer? = {
    for i in 0..<_dyld_image_count() {
        // Technically any system framework would work, but this was inspired by SwiftUI's use
        // of runtime issues to report non-fatal but unexpected behavior.
        guard let name = _dyld_get_image_name(i).flatMap(String.init(utf8String:)), name.contains("SwiftUI") else { continue }
        return UnsafeRawPointer(_dyld_get_image_header(i))
    }
    return nil
}()
