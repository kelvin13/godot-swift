final class SwiftSignals: Godot.NativeScript {
    enum MySignal: Godot.Signal {
        typealias Value = (foo: Int, bar: Float64)
        
        @Interface static var interface: Interface {
            \.foo <- "foo"
            \.bar <- "bar"
        }
        static var name:String {
            "my_signal"
        }
    }
    
    @Interface static var interface: Interface {
        Interface.signals {
            MySignal.self 
        }
        Interface.methods {
            baz(delegate:) <- "baz"
        }
    }
    
    init(delegate _: Godot.Unmanaged.Spatial) {}
    
    func baz(delegate: Godot.Unmanaged.Spatial) {
        delegate.emit(signal: (6, 5.55), as: MySignal.self)
    }
}
