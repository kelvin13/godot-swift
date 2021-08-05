final class SwiftAdvancedMethods: Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Spatial) {}
    
    func voidArgument(delegate _: Godot.Unmanaged.Spatial, void _: Void) {
        Godot.print("hello from \(#function)")
    }
    
    func optionalArgument(delegate _: Godot.Unmanaged.Spatial, int: Int?) {
        Godot.print("hello from \(#function), received \(int as Any)")
    }
    func multipleArguments(
        delegate _: Godot.Unmanaged.Spatial,
        bool: Bool,
        int: Int16,
        vector: Vector2<Float64>
    ) {
        Godot.print("hello from \(#function), received \(bool), \(int), \(vector)")
    }
    func tupleArgument(delegate _: Godot.Unmanaged.Spatial, tuple: (String, (String, String))) {
        Godot.print("hello from \(#function), received \(tuple)")
    }
    func listArgument(delegate _: Godot.Unmanaged.Spatial, list: Godot.List) {
        Godot.print("hello from \(#function), received list (\(list.count) elements)")
        for (i, element): (Int, Godot.Variant?) in list.enumerated() {
            Godot.print("[\(i)]: \(element as Any)")
        }
    }
    
    func inoutArgument(delegate _: Godot.Unmanaged.Spatial, int: inout Int)  {
        Godot.print("hello from \(#function)")
        int += 2
    }
    
    func inoutTupleArgument(delegate _: Godot.Unmanaged.Spatial, tuple: inout (String, (String, String))) {
        Godot.print("hello from \(#function), received \(tuple)")
        tuple.1.0 = "new string"
    }
    
    func optionalReturn(delegate _: Godot.Unmanaged.Spatial, int: Int) -> Int? {
        int < 0 ? nil : int
    }
    
    func tupleReturn(delegate _: Godot.Unmanaged.Spatial) -> (Float32, Float64?) {
        return (.pi, nil)
    }
}

extension SwiftAdvancedMethods {
    @Interface static var interface:Interface {
        Interface.methods {
            voidArgument(delegate:void:)                    <- "void_argument"
            optionalArgument(delegate:int:)                 <- "optional_argument"
            multipleArguments(delegate:bool:int:vector:)    <- "multiple_arguments"
            tupleArgument(delegate:tuple:)                  <- "tuple_argument"
            listArgument(delegate:list:)                    <- "list_argument"
            
            inoutArgument(delegate:int:)                    <- "inout_argument"
            inoutTupleArgument(delegate:tuple:)             <- "inout_tuple_argument"
            
            optionalReturn(delegate:int:)                   <- "optional_return"
            tupleReturn(delegate:)                          <- "tuple_return"
        }
    }
}
