final class SwiftUnmanaged: Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Node) {
        Godot.print("initialized instance of '\(Self.self)'")
    }
    deinit {
        Godot.print("deinitialized instance of '\(Self.self)'")
    }
}

final class SwiftManaged: Godot.NativeScript {
    init(delegate _: Godot.AnyObject) {
        Godot.print("initialized instance of '\(Self.self)'")
    }
    deinit {
        Godot.print("deinitialized instance of '\(Self.self)'")
    }
}
