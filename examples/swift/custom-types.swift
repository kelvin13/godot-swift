struct InputEvents: Godot.VariantRepresentable {
    let events: (mouse: Godot.InputEventMouseButton, key: Godot.InputEventKey)
    
    static var variantType: Godot.VariantType {
        .list
    }
    
    static func takeUnretained(_ value: Godot.Unmanaged.Variant) -> Self? {
        guard   let list:Godot.List = value.take(unretained: Godot.List.self), 
                    list.count == 2, 
                let mouse:Godot.InputEventMouseButton   = 
                    list[0] as? Godot.InputEventMouseButton,
                let key:Godot.InputEventKey             = 
                    list[1] as? Godot.InputEventKey
        else {
            return nil 
        }
        
        return .init(events: (mouse, key))
    }
    
    func passRetained() -> Godot.Unmanaged.Variant {
        .pass(retaining: [self.events.mouse, self.events.key] as Godot.List)
    }
}

struct UnitRangeElement<T>: Godot.VariantRepresentable where T:BinaryFloatingPoint {
    let value: T
    
    static var variantType: Godot.VariantType {
        .void 
    }
    
    static func takeUnretained(_ value:Godot.Unmanaged.Variant) -> Self? {
        switch value.take(unretained: Godot.Variant?.self) {
        case 0 as Int64: 
            return .init(value: 0)
        case 1 as Int64:
            return .init(value: 1)
        case let value as Float64:
            guard 0 ... 1 ~= value else {
                fallthrough 
            }
            return .init(value: .init(value))
        default:
            return nil 
        }
    }
    func passRetained() -> Godot.Unmanaged.Variant {
        switch self.value {
        case 0:         return .pass(retaining: 0 as Int64)
        case 1:         return .pass(retaining: 1 as Int64)
        case let value: return .pass(retaining: Float64.init(value))
        }
    }
}

final class SwiftCustomTypes: Godot.NativeScript {
    @Interface static var interface:Interface {
        Interface.methods {
            push(delegate:inputs:) <- "push_inputs"
        }
        Interface.properties {
            \.x <- "x"
        }
    }
    
    var x: UnitRangeElement<Float32> {
        didSet {
            Godot.print("set `x` to \(self.x.value)")
        }
    }
    
    init(delegate _: Godot.Unmanaged.Spatial) {
        self.x = .init(value: 0.5)
    }
    
    func push(delegate _: Godot.Unmanaged.Spatial, inputs: InputEvents) {
        Godot.print("\(#function) received inputs \(inputs)")
    }
}
