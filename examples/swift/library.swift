extension Godot.Library {
    @Interface static var interface: Interface {
        MySwiftClass.self               <- "MyExportedSwiftClass"
        SwiftAdvancedMethods.self       <- "SwiftAdvancedMethods"
        SwiftAdvancedProperties.self    <- "SwiftAdvancedProperties"
        SwiftSignals.self               <- "SwiftSignals"
        SwiftUnmanaged.self             <- "SwiftUnmanaged"
        SwiftManaged.self               <- "SwiftManaged"
        SwiftCustomTypes.self           <- "SwiftCustomTypes"
    }
}
