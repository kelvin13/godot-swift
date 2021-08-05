final class SwiftAdvancedProperties: Godot.NativeScript {
    var radians: Float64
    
    var degrees: Float64 {
        self.radians * 180.0 / .pi
    }
    
    private var array:[Int]
    
    init(delegate _: Godot.Unmanaged.Spatial) {
        self.radians = 0.5 * .pi
        self.array = [10, 11, 12]
    }
}
extension SwiftAdvancedProperties
{
    @Interface static var interface: Interface {
        Interface.properties {
            \.radians   <- "radians"
            \.degrees   <- "degrees"
            
            \.array[0]  <- "elements_0"
            \.array[1]  <- "elements_1"
            \.array[2]  <- "elements_2"
        }
    }
}
