final class MySwiftClass: Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Spatial) {}
    
    var foo: Int = 5
    
    func bar(delegate _: Godot.Unmanaged.Spatial, x: Int) -> Int {
        self.foo * x
    }
}

extension MySwiftClass {
    @Interface static var interface: Interface {
        Interface.properties {
            \.foo <- "foo"
        }
        Interface.methods {
            bar(delegate:x:) <- "bar"
        }
    }
}
