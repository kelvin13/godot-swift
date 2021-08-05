# *Godot Swift* tutorials

*jump to:*

1. [basic usage](#basic-usage) ([sources](swift/basic-usage.swift))
2. [advanced methods](#advanced-methods) ([sources](swift/advanced-methods.swift))
3. [advanced properties](#advanced-properties) ([sources](swift/advanced-properties.swift))
4. [signals](#signals) ([sources](swift/signals.swift))
5. [life cycle management](#life-cycle-management) ([sources](swift/life-cycle-management.swift))
6. [using custom types](#using-custom-types) ([sources](swift/custom-types.swift))

## basic usage

[`sources`](swift/basic-usage.swift)

> **Key terms:** 
> - **library interface**
> - **nativescript interface**
> - **binding operator**
> - **delegate**

#### getting started 

Start by creating two directories: `game`, which contains a Godot project, and `swift`, which will contain the Swift-language sources for a GDNative Swift library. Inside the `swift` folder, create an empty file named `library.swift`. The folder structure should look like this:

```text 
.
├── Package.swift
├── game/
│   ├── project.godot 
│   └── ...
└── swift/
    └── library.swift
```

> **Note:** There is no requirement that the Godot project directory be adjacent to the Swift sources directory. There are also no restrictions on the layout of the Swift sources, as long as the [PackageDescription API](https://developer.apple.com/documentation/swift_packages/package) can understand it.

The `Godot` package (this repository) provides two targets, [`GodotNative`](../sources/godot-native), and [`GodotNativeScript`](../sources/godot-nativescript).

Declare a target, and a product, for the Swift library as follows:

```swift 
products: 
[
    ... 
    
    .library(name: "godot-swift-examples", type: .dynamic, targets: ["Examples"]),
],

...

targets: 
[
    ...
    
    .target(name:        "Examples", 
        dependencies:   ["GodotNative"], 
        path:            "swift", 
        plugins:        ["GodotNativeScript"])
]
```

The library target depends on `GodotNative`, and of course, uses the `GodotNativeScript` plugin. The `GodotNative` dependency is only used by code generated from the `GodotNativeScript` plugin; you should never need to `import` it in code you write yourself.

The library product *must* be marked as a `dynamic` library product. This will direct the Swift Package Manager to build a shared library which can be loaded by the Godot engine as a [`GDNativeLibrary`](https://docs.godotengine.org/en/stable/tutorials/plugins/gdnative/gdnative-c-example.html#creating-the-gdnativelibrary-gdnlib-file).

Let’s try to compile our empty library project, using the following `swift build` invocation:

```bash 
$ SWIFTPM_ENABLE_PLUGINS=1 swift build --product godot-swift-examples -c debug
```

> **Note:** Because Swift package plugins are still an experimental feature, we must explicitly enable it by setting the `SWIFTPM_ENABLE_PLUGINS=1` environment variable. In future toolchains, this will not be necessary.

The initial build may take a while, since *Godot Swift* needs to generate and compile a large number of API bindings for Godot’s built-in classes. However, we can see that the build ultimately fails with the following errors:

```text 
(sub-build) common.swift:437:12: error: type 'Godot.Library' does not conform to protocol 'Godot.NativeLibrary'
(sub-build)     struct Library:NativeLibrary 
(sub-build)            ^
(sub-build) common.swift:381:9: note: protocol requires property 'interface' with type 'Godot.Library.Interface'; 
            do you want to add a stub?
(sub-build)     var interface:Godot.Library.Interface 
(sub-build)         ^
```

This is because the `GodotNativeScript` plugin expects you to define a **library interface** for your Swift library. A library interface specifies the Swift types available to Godot, and the nativescripts they are exported as.

We have not yet written any nativescripts, so let’s create one now. Create a new Swift file `basic-usage.swift`.

```text 
.
├── Package.swift
├── game/
│   ├── project.godot 
│   └── ...
└── swift/
    ├── library.swift
    └── basic-usage.swift
```

Declare a class `MySwiftClass` in `basic-usage.swift`, and conform it to the [`Godot.NativeScript`](https://kelvin13.github.io/godot-swift/Godot/NativeScript) protocol. The [`Godot.NativeScript`](https://kelvin13.github.io/godot-swift/Godot/NativeScript) protocol requires you to define an initializer which takes a single **delegate object** parameter. The static type of the delegate object satisfies the `associatedtype` requirement [`Delegate`](https://kelvin13.github.io/godot-swift/Godot/NativeScript/Delegate) in the [`Godot.NativeScript`](https://kelvin13.github.io/godot-swift/Godot/NativeScript) protocol, and specifies the GDScript class that this nativescript should be attached to. For this example, we will assume our `MySwiftClass` nativescript will be attached to a [`Godot.Unmanaged.Spatial`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Spatial) node ([`Godot::Spatial`](https://docs.godotengine.org/en/stable/classes/class_spatial.html)), or one of its subclasses.

We will explore delegate objects in more detail in a later tutorial. For now, we will simply ignore the delegate parameter, and define an empty initializer.

```swift 
// basic-usage.swift

final class MySwiftClass: Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Spatial) {}
}
```

> **Note:** Any named Swift type (`class`, `struct`, `enum`, etc.) can be used as a nativescript, but nativescripts are immutable, so any nativescript with internal state should be defined as a `class`.

Next, we define the library interface in `library.swift` by extending the [`Godot.Library`](https://kelvin13.github.io/godot-swift/Godot/Library) type. (This structure is generated by *Godot Swift*.) The static [`interface`](https://kelvin13.github.io/godot-swift/Godot/NativeLibrary/interface) variable can be written as a [result builder](https://github.com/apple/swift-evolution/blob/main/proposals/0289-result-builders.md), and we can add our `MySwiftClass` type to the interface by using the **binding operator** ‘`<-`’. The nativescript type object goes on the left side of this operator, and a string containing its exported GDScript name goes on the right side.

```swift 
// library.swift 

extension Godot.Library {
    @Interface static var interface: Interface {
        MySwiftClass.self <- "MyExportedSwiftClass"
    }
}
```

> **Note:** It is possible to bind the same Swift type to more than one GDScript symbol. Godot will see the bindings as separate nativescript types, but they will share the same interfaces and implementation.

Finally, let’s give it a mutable property `foo:Int`, and a method `bar(delegate:x:)`, which multiplies its `Int` parameter by `self.foo`. 

```swift
// basic-usage.swift

final class MySwiftClass: Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Spatial) {}
    
    var foo: Int = 5

    func bar(delegate _: Godot.Unmanaged.Spatial, x: Int) -> Int {
        self.foo * x
    }
}
```

If we try to recompile it, we will see that the build now succeeds:

```bash 
$ SWIFTPM_ENABLE_PLUGINS=1 swift build --product godot-swift-examples -c debug
```
```text
starting two-stage build...
note: searching for dynamic library products containing the target 'Examples'
note: found product 'godot-swift-examples'
note: using product 'godot-swift-examples'
...
inspecting sub-build product 'libgodot-swift-examples.so'
found 1 nativescript interface(s):
[0]: Examples.MySwiftClass <- (Godot::MyExportedSwiftClass)
{
    (0 properties)
    (0 methods)
    (0 signals)
}
synthesizing variadic templates (0 signatures)
synthesizing Godot.NativeScript conformances (1 types)
[0]: Examples.MySwiftClass
...
Build complete!
```

The *Godot Swift* plugin will log a large amount of information reporting what it detected, generated, and compiled, which we will explore in more detail in a later tutorial. For now, we can observe that it picked up the `MySwiftClass` type from the `Examples` module, and is binding it to the GDScript symbol `Godot::MyExportedSwiftClass`.

> **Warning:** *Godot Swift* will only synthesize [`Godot.NativeScript`](https://kelvin13.github.io/godot-swift/Godot/NativeScript) conformances for types that are declared in the library interface. If you do not declare a nativescript type in the library interface, its [`Godot.NativeScript`](https://kelvin13.github.io/godot-swift/Godot/NativeScript) conformance will be incomplete, and the build will fail.

We can also observe that even though we gave `MySwiftClass` a property and a method, *Godot Swift* generated no bindings for them. To make them usable from GDScript, we need to add them to the **nativescript interface** for `MySwiftClass`.

Nativescript interfaces look a lot like library interfaces. Bind properties through [`KeyPath`](https://developer.apple.com/documentation/swift/keypath)s using the `<-` operator. If the nativescript is a `class`, the keypath will instead be inferred as a [`ReferenceWritableKeyPath`](https://developer.apple.com/documentation/swift/referencewritablekeypath), which supports mutation.

You can also use the `<-` operator to bind functions to GDScript methods. The first parameter of the bound function *must* be a delegate object of the same static type as the nativescript’s associated [`Delegate`](https://kelvin13.github.io/godot-swift/Godot/NativeScript/Delegate) type. 

A bound function can take any number of additional (strongly-typed) parameters; *Godot Swift* will generate the necessary generic templates. Any type that conforms to [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) can be used as a parameter or return type. In this example, we are using `Int`, which *Godot Swift* already provides a built-in conformance for. We will learn how to define [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) conformances for custom types in a later tutorial.

> **Note:** A method bound by the `<-` does not need to be a member function of the nativescript type. The only requirement is that it has the signature `(T) -> (T.Delegate, U0, U1, ... ) -> V`, where `T` is the nativescript type (in this case, `MySwiftClass`), `T.Delegate` is its associated delegate type (in this case, [`Godot.Unmanaged.Spatial`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Spatial)), and `U0`, `U1`, `V`, etc. are its parameter and return types.
>
> Of course, any member function of the nativescript type satisfies this requirement, as long as its first parameter has the type `T.Delegate`.

We can declare an interface for `MySwiftClass` as follows: 

```swift 
// basic-usage.swift

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
```

> **Note:** The `bar(delegate:x:)` expression on the left hand side of the `<-` operator in the method list is a [curried function](https://en.wikipedia.org/wiki/Currying) of type `(MySwiftClass) -> (Godot.Unmanaged.Spatial, Int) -> Int`.

If we recompile, we can observe that *Godot Swift* is now picking up one property and one method: 

```text 
found 1 nativescript interface(s):
[0]: Examples.MySwiftClass <- (Godot::MyExportedSwiftClass)
{
    (1 property)
    (1 method)
    (0 signals)
}
```

#### installing library resources

The next step is to install our binary library products in our Godot game project. You can do this manually, as you would when using a framework like [`godot-cpp`](https://github.com/godotengine/godot-cpp), or you can use the [`build`](../build) python script (available in the repository root), which will compile the library and generate the necessary `.gdnlib` and `.gdns` resource files for you.

> **Note:** The `build` script currently only works on Linux. You can help port it to MacOS! (This should only require changing a few paths and file extensions.)

To use the `build` script, pass it an installation path, which should be a directory in your Godot project. 

```bash 
./build -c debug --install game/libraries
```
```text 
installing to 'res://libraries/' in project 'game'
```

On script termination, you should now see the Swift library files installed in the `game` project at the specified path: 

```text 
.
└── game/
    ├── project.godot 
    └── libraries/
        ├── godot-swift-examples/ 
        │   ├── library.gdnlib 
        │   └── MyExportedSwiftClass.gdns
        ├── libgodot-swift-examples.so
        └── libSwiftPM.so
```

Now, let’s open up the Godot editor, and create a simple scene `main.tscn`, and a script `main.gd`.

```text 
.
└── game/
    ├── main.tscn 
    ├── main.gd 
    ├── project.godot 
    └── libraries/
        ├── godot-swift-examples/ 
        │   ├── library.gdnlib 
        │   └── MyExportedSwiftClass.gdns
        ├── libgodot-swift-examples.so
        └── libSwiftPM.so
```

In the `main.tscn` scene, create two nodes: a root node `root`, and a child node `root/delegate`, of type `Godot::Spatial`:

```text 
○ root:Node 
└── ○ delegate:Spatial 
```

Attach the `MyExportedSwiftClass.gdns` nativescript to the `root/delegate` node, and attach the `main.gd` script to the `root` node. 

```text 
○ root:Node             (main.gd)
└── ○ delegate:Spatial  (MyExportedSwiftClass.gdns)
```

In the `main.gd` script, add the following code, which interacts with its `delegate` child: 

```gdscript 
extends Node

func _ready():
    print($delegate.foo)
    
    print($delegate.bar(2))
    
    $delegate.foo += 1
    
    print($delegate.foo)
    print($delegate.bar(3))
```

If we run the game, we can now see the Swift library working as expected.

```text 
(swift) registering MySwiftClass as nativescript 'Godot::MyExportedSwiftClass'
(swift) registering (function) as method 'Godot::MyExportedSwiftClass::bar'
(swift) registering (function) as property 'Godot::MyExportedSwiftClass::foo'
5
10
6
18
```

## advanced methods 

[`sources`](swift/advanced-methods.swift)

> **Key terms:** 
> - **tuple splatting**

> This tutorial assumes you already have the project from the [basic usage](#basic-usage) tutorial set up.

Add a new source file, `advanced-methods.swift`, to the Swift library.

```text 
.
├── Package.swift
├── game/
│   ├── project.godot 
│   ├── main.tscn 
│   ├── main.gd 
│   ├── libraries/ 
│   └── ...
└── swift/
    ├── library.swift
    ├── basic-usage.swift
    └── advanced-methods.swift
```

Define a new nativescript class, `SwiftAdvancedMethods`, and add it to the library interface in `library.swift`

```swift 
// advanced-methods.swift 

final class SwiftAdvancedMethods:Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Spatial) {}
}
```

```swift 
// library.swift 

extension Godot.Library {
    @Interface static var interface:Interface {
        MySwiftClass.self           <- "MyExportedSwiftClass"
        SwiftAdvancedMethods.self   <- "SwiftAdvancedMethods"
    }
}
```

Now, let’s explore some of the kinds of nativescript methods we can write using *Godot Swift*.

#### `Void` parameters

Although there aren’t many good use cases for this, you can define a method that takes a `Godot::null` parameter by specifying its type in Swift as `Void` (sometimes written as the empty tuple `()`).

```swift 
    func voidArgument(delegate _: Godot.Unmanaged.Spatial, void _: Void) {
        Godot.print("hello from \(#function)")
    }
```

A `Void` argument does not mean “no argument”; you must call such a function from GDScript by explicitly passing `null`.

```gdscript 
    $delegate.void_argument(null)
```

#### `Optional` parameters

Any [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) type can be used as a method parameter type. For example, `Optional<Int>` is variant-representable (by the union type of `Godot::null` and `Godot::int`), which means we can define the following method: 

```swift 
    func optionalArgument(delegate _: Godot.Unmanaged.Spatial, int: Int?)  {
        Godot.print("hello from \(#function), received \(int as Any)")
    }
```

Such a method can be called from GDScript with either an integer argument, or `null`. 

```gdscript 
    $delegate.optional_argument(10)
    $delegate.optional_argument(null)
```

#### multiple parameters 

Methods can take any number of parameters, as long as the first parameter is [`Self.Delegate`](https://kelvin13.github.io/godot-swift/Godot/NativeScript/Delegate). The trailing parameters must be [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable), but there is no requirement that they be of the same type. *Godot Swift* will generate the necessary variadic generic templates for you.

```swift 
    func multipleArguments(
        delegate _: Godot.Unmanaged.Spatial, 
        bool: Bool,
        int: Int16,
        vector: Vector2<Float64>
    ) {
        Godot.print("hello from \(#function), received \(bool), \(int), \(vector)")
    }
```

You can find a list of all the built-in [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) types you can use in the [API reference](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable).

#### tuple splatting

*Godot Swift* supports **tuple splatting**. This feature allows you to automatically destructure `Godot::Array` parameters into strongly-typed tuple forms. 

```swift 
    func tupleArgument(delegate _: Godot.Unmanaged.Spatial, tuple: (String, (String, String))) {
        Godot.print("hello from \(#function), received \(tuple)")
    }
```

To call such a function from GDScript, pass it a `Godot::Array` of the expected form:

```gdscript 
    var strings:Array = [
            'element (0)', [
                'element (1, 0)', 
                'element (1, 1)'
            ]
        ]
    
    $delegate.tuple_argument(strings)
```

You can also specify the Swift type of a `Godot::Array` parameter as [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List), to receive variable-length, type-erased Godot lists: 

```swift 
    func listArgument(delegate _: Godot.Unmanaged.Spatial, list: Godot.List) {
        Godot.print("hello from \(#function), received list (\(list.count) elements)")
        for (i, element): (Int, Godot.Variant?) in list.enumerated() {
            Godot.print("[\(i)]: \(element as Any)")
        }
    }
```

Both forms are called in the exact same way from GDScript.

#### `inout` parameters

*Godot Swift* supports `inout` parameters. 

```swift 
    func inoutArgument(delegate _: Godot.Unmanaged.Spatial, int: inout Int) {
        Godot.print("hello from \(#function)")
        int += 2
    }
```

When called from GDScript, the integer argument passed to this function will be updated when the method returns.

Tuple splatting also works with `inout`. 

```swift 
    func inoutTupleArgument(delegate _:Godot.Unmanaged.Spatial, tuple:inout (String, (String, String))) {
        Godot.print("hello from \(#function), received \(tuple)")
        tuple.1.0 = "new string"
    }
```

The list elements are updated individually. Overwriting the entire tuple aggregate does not replace the `Godot::Array` instance itself.

> **Warning:** GDScript has no concept of `inout` parameters, which means that modifying passed arguments may constitute unexpected behavior. Swift methods that modify their arguments should be clearly documented as such.

#### return values 

Any [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) type can be used as a method return type. For example, we can return an `Optional<Int>` as follows: 

```swift 
    func optionalReturn(delegate _: Godot.Unmanaged.Spatial, int: Int) -> Int? {
        int < 0 ? nil : int
    }
```

Tuple splatting also works with return values. The following nativescript method produces a two-element `Godot::Array` when called from GDScript: 

```swift 
    func tupleReturn(delegate _: Godot.Unmanaged.Spatial) -> (Float32, Float64?) {
        return (.pi, nil)
    }
}
```

The first element will become a `Godot::float` in GDScript, and the second element will become either a `Godot::float`, or `Godot::null`.

#### putting it together 

Before we can test our *Godot Swift* methods in GDScript, we need to add them to `SwiftAdvancedMethods`’s nativescript interface. 

```swift 
// advanced-methods.swift 

extension SwiftAdvancedMethods {
    @Interface static var interface: Interface {
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
```

Compile and install the Swift library using the `build` script: 

```bash 
$ ./build -c debug -i examples/game/libraries
```

```text 
...
inspecting sub-build product 'libgodot-swift-examples.so'
note: in directory '.build/plugins/outputs/godot-swift/examples/GodotNativeScript/.build/debug'
note: through entrypoint '__inspector_entrypoint_loader__'
found 2 nativescript interface(s):
[0]: Examples.MySwiftClass <- (Godot::MyExportedSwiftClass)
{
    (1 property)
    (1 method)
    (0 signals)
}
[1]: Examples.SwiftAdvancedMethods <- (Godot::SwiftAdvancedMethods)
{
    (0 properties)
    (9 methods)
    (0 signals)
}
generating file 'registration.swift'
note: in directory '.build/plugins/outputs/godot-swift/examples/GodotNativeScript'
synthesizing variadic templates (8 signatures)
[0]: (T.Delegate) -> (V0, V1)
[1]: (T.Delegate, (U0, (U1, U2))) -> Void
[2]: (T.Delegate, U0) -> V0
[3]: (T.Delegate, U0) -> Void
[4]: (T.Delegate, U0, U1, U2) -> Void
[5]: (T.Delegate, Void) -> Void
[6]: (T.Delegate, inout (U0, (U1, U2))) -> Void
[7]: (T.Delegate, inout U0) -> Void
synthesizing Godot.NativeScript conformances (2 types)
[0]: Examples.MySwiftClass
[1]: Examples.SwiftAdvancedMethods
...
installing to 'res://libraries/' in project 'game'
```

We can observe that *Godot Swift* generated eight generic templates, covering the signatures of the nine methods we defined on `SwiftAdvancedMethods`. (The `optionalArgument(delegate:int:)` and `listArgument(delegate:list:)` methods share a single template.)

Add a new scene, `advanced-methods.tscn`, to the Godot project, and give it a root node `root` and a child node `delegate` of type `Godot::Spatial`. Create a GDScript script `advanced-methods.gd`, and attach it to the root node.

```text 
.
└── game/
    ├── project.godot 
    ├── main.tscn 
    ├── main.gd 
    ├── advanced-methods.tscn 
    ├── advanced-methods.gd 
    └── libraries/
        ├── godot-swift-examples/ 
        │   ├── library.gdnlib 
        │   ├── MyExportedSwiftClass.gdns
        │   └── SwiftAdvancedMethods.gdns
        ├── libgodot-swift-examples.so
        └── libSwiftPM.so
```

Attach the `SwiftAdvancedMethods` nativescript to the `delegate` node.

```text 
// advanced-methods.tscn

○ root:Node             (advanced-methods.gd)
└── ○ delegate:Spatial  (SwiftAdvancedMethods.gdns)
```

Add the following demo code to the `advanced-methods.gd` script: 

```gdscript 
extends Node

func _ready():
    $delegate.void_argument(null)
    
    $delegate.optional_argument(10)
    $delegate.optional_argument(null)
    
    $delegate.multiple_arguments(true, 3, Vector2(0.5, 0.75))
    
    var strings:Array = [
        'element (0)', [
            'element (1, 0)', 
            'element (1, 1)'
        ]
    ]
    
    $delegate.tuple_argument(strings)
    $delegate.list_argument(strings)
    
    var x:int = 5 
    print('old value of `x`: ', x)
    $delegate.inout_argument(x)
    print('new value of `x`: ', x)
    
    print('old value of `strings`: ', strings)
    $delegate.inout_tuple_argument(strings)
    print('new value of `strings`: ', strings)
    
    print('non-negative: ', $delegate.optional_return( 1))
    print('non-negative: ', $delegate.optional_return(-1))

    print('returned tuple: ', $delegate.tuple_return())
```

If we launch the `advanced-methods.tscn` scene from the Godot editor, we can see the Swift methods in action. Output printed from Swift is prefixed with the string `'(swift)'`; output printed from GDScript is emitted as-is.

```text 
(swift) registering MySwiftClass as nativescript 'Godot::MyExportedSwiftClass'
(swift) registering (function) as method 'Godot::MyExportedSwiftClass::bar'
(swift) registering (function) as property 'Godot::MyExportedSwiftClass::foo'
(swift) registering SwiftAdvancedMethods as nativescript 'Godot::SwiftAdvancedMethods'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::void_argument'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::optional_argument'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::multiple_arguments'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::tuple_argument'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::list_argument'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::inout_argument'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::inout_tuple_argument'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::optional_return'
(swift) registering (function) as method 'Godot::SwiftAdvancedMethods::tuple_return'
(swift) hello from voidArgument(delegate:void:)
(swift) hello from optionalArgument(delegate:int:), received Optional(10)
(swift) hello from optionalArgument(delegate:int:), received nil
(swift) hello from multipleArguments(delegate:bool:int:vector:), received true, 3, Vector(0.5, 0.75)
(swift) hello from tupleArgument(delegate:tuple:), received ("element (0)", ("element (1, 0)", "element (1, 1)"))
(swift) hello from listArgument(delegate:list:), received list (2 elements)
(swift) [0]: Optional(Examples.Godot.String)
(swift) [1]: Optional(Examples.Godot.List)
old value of `x`: 5
(swift) hello from inoutArgument(delegate:int:)
new value of `x`: 7
old value of `strings`: [element (0), [element (1, 0), element (1, 1)]]
(swift) hello from inoutTupleArgument(delegate:tuple:), received ("element (0)", ("element (1, 0)", "element (1, 1)"))
new value of `strings`: [element (0), [new string, element (1, 1)]]
non-negative: 1
non-negative: Null
returned tuple: [3.141593, Null]
```

## advanced properties

[`sources`](swift/advanced-properties.swift)

> This tutorial assumes you already have the project from the [basic usage](#basic-usage) tutorial set up.

Define a new nativescript class, `SwiftAdvancedProperties`, in `advanced-properties.swift`, and add it to the library interface in `library.swift`.

```text 
.
├── Package.swift
├── game/
│   ├── project.godot 
│   ├── main.tscn 
│   ├── main.gd 
│   ├── advanced-methods.tscn 
│   ├── advanced-methods.gd 
│   ├── libraries/ 
│   └── ...
└── swift/
    ├── library.swift
    ├── basic-usage.swift
    ├── advanced-methods.swift
    └── advanced-properties.swift
```

```swift 
// advanced-properties.swift 

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
```

```swift 
// library.swift 

extension Godot.Library {
    @Interface static var interface: Interface {
        MySwiftClass.self               <- "MyExportedSwiftClass"
        SwiftAdvancedMethods.self       <- "SwiftAdvancedMethods"
        SwiftAdvancedProperties.self    <- "SwiftAdvancedProperties"
    }
}
```

We already saw in the [basic usage](#basic-usage) tutorial how to register a settable property, by using a [`ReferenceWritableKeyPath`](https://developer.apple.com/documentation/swift/ReferenceWritableKeyPath).

```swift 
// advanced-properties.swift 

extension SwiftAdvancedProperties {
    @Interface static var interface:Interface {
        Interface.properties {
            \.radians   <- "radians"
```

We can also export a get-only property, by using an ordinary, immutable [`KeyPath`](https://developer.apple.com/documentation/swift/KeyPath). 

```swift 
            \.degrees   <- "degrees"
```

Attempting to set to a get-only property from GDScript is an error. 

```gdscript 
    $delegate.degrees = 5
```

```text 
ERROR: <-(_:_:): (swift) cannot assign to get-only property 'degrees'
```

> **Note:** The Swift type inferencer will prefer [`ReferenceWritableKeyPath`](https://developer.apple.com/documentation/swift/ReferenceWritableKeyPath) over [`KeyPath`](https://developer.apple.com/documentation/swift/KeyPath) if the target property is settable.

Any valid Swift keypath can be used as a GDScript property accessor. For example, we can expose elements in `self.array` by using subscript keypaths:

```swift 
            \.array[0]  <- "elements_0"
            \.array[1]  <- "elements_1"
            \.array[2]  <- "elements_2"
        }
    }
}
```

> **Note:** Indexed GDScript properties are not supported (yet).

We can build, install, and demo the `SwiftAdvancedProperties` nativescript in a new scene `advanced-properties.tscn`.

```text 
.
└── game/
    ├── project.godot 
    ├── main.tscn 
    ├── main.gd 
    ├── advanced-methods.tscn 
    ├── advanced-methods.gd 
    ├── advanced-properties.tscn 
    ├── advanced-properties.gd 
    └── libraries/
        ├── godot-swift-examples/ 
        │   ├── library.gdnlib 
        │   ├── MyExportedSwiftClass.gdns
        │   └── SwiftAdvancedMethods.gdns
        │   └── SwiftAdvancedProperties.gdns
        ├── libgodot-swift-examples.so
        └── libSwiftPM.so
```

```text 
// advanced-properties.tscn

○ root:Node             (advanced-properties.gd)
└── ○ delegate:Spatial  (SwiftAdvancedProperties.gdns)
```

```gdscript 
# advanced-properties.gd

extends Node

func _ready():
    print('radians: ', $delegate.radians)
    print('degrees: ', $delegate.degrees)
    $delegate.radians = 0.678 * PI
    print('radians: ', $delegate.radians)
    print('degrees: ', $delegate.degrees)
    
    # $delegate.degrees = 5
    
    print('element 0: ', $delegate.elements_0)
    print('element 1: ', $delegate.elements_1)
    print('element 2: ', $delegate.elements_2)
```

```text 
... 
(swift) registering SwiftAdvancedProperties as nativescript 'Godot::SwiftAdvancedProperties'
(swift) registering (function) as property 'Godot::SwiftAdvancedProperties::radians'
(swift) registering (function) as property 'Godot::SwiftAdvancedProperties::degrees'
(swift) registering (function) as property 'Godot::SwiftAdvancedProperties::elements_0'
(swift) registering (function) as property 'Godot::SwiftAdvancedProperties::elements_1'
(swift) registering (function) as property 'Godot::SwiftAdvancedProperties::elements_2'
radians: 1.570796
degrees: 90
radians: 2.13
degrees: 122.04
element 0: 10
element 1: 11
element 2: 12
```

## signals 

[`sources`](swift/signals.swift)

> **Key terms:** 
> - **signal definition**
> - **signal interface**
> - **signal value**

> This tutorial assumes you already have the project from the [basic usage](#basic-usage) tutorial set up.

Assuming you completed any of the previous three tutorials, you should already know how to define and declare a Swift nativescript, so we won’t go over that again.

To create a **signal definition**, declare a type `MySignal`, and conform it to the protocol [`Godot.Signal`](https://kelvin13.github.io/godot-swift/Godot/Signal).

```swift 
final class SwiftSignals:Godot.NativeScript {
    enum MySignal:Godot.Signal {
```

The signal definition type has an `associatedtype` [`Value`](https://kelvin13.github.io/godot-swift/Godot/Signal/Value), which specifies the **signal value** type. In this example, we will set the [`Value`](https://kelvin13.github.io/godot-swift/Godot/Signal/Value) type to `(foo:Int, bar:Float64)`.

```swift 
        typealias Value = (foo: Int, bar: Float64)
```

> **Note:** The signal definition type does not need to actually *store* the signal value; its purpose is simply to specify the name and format of the signal. In general, a signal definition type should simply be an uninhabited `enum`. This lets you abstract signal formats from signal values, for example, to reuse the same signal value type for multiple signals.

The [`Godot.Signal`](https://kelvin13.github.io/godot-swift/Godot/Signal) protocol requires you to specify a **signal interface**, which specifies the order and names of the fields in the signal.

```swift 
        @Interface static var interface: Interface {
            \.foo <- "foo"
            \.bar <- "bar"
        }
```

Finally, we must specify the signal’s name through the required static [`name`](https://kelvin13.github.io/godot-swift/Godot/Signal/name) property: 

```swift 
        static var name: String {
            "my_signal"
        }
```

To emit a signal, pass a value for it, and a signal definition type to the [`emit(signal:as:)`](https://kelvin13.github.io/godot-swift/Godot/AnyDelegate/emit(signal:as:)) method on the delegate.

```swift 
    init(delegate _: Godot.Unmanaged.Spatial) {
    }

    func baz(delegate: Godot.Unmanaged.Spatial) {
        delegate.emit(signal: (6, 5.55), as: MySignal.self)
    }
```

Any delegate can emit any signal, but if we want anything to be able to listen for it, we need to add it to the nativescript interface. Here, we have also added the `baz(delegate:)` trigger method to the interface, for demonstration purposes. 

```swift 
    @Interface static var interface:Interface {
        Interface.signals {
            MySignal.self 
        }
        Interface.methods {
            baz(delegate:) <- "baz"
        }
    }
}
```

To demo the signal, set up a new scene `signals.tscn`, with a root node, delegate node, and this time, a listener node. 

```text 
// signals.tscn

○ root:Node             (signals.gd)
├── ○ listener:Node     (signals-listener.gd)
└── ○ delegate:Spatial  (SwiftSignals.gdns)
```

After attaching the `SwiftSignals` nativescript to the `delegate` node in the Godot editor, we can see that it now has a signal `my_signal(foo:int:)`. 

```text 
○ SwiftSignals.gdns 
└── [→ my_signal(foo: int, bar: float)
```

Connect the signal to the `listener` node in the editor.

```text 
○ SwiftSignals.gdns 
└── [→ my_signal(foo: int, bar: float)
    └── →] ../listener :: _on_delegate_my_signal()
```

Fill out the `signals.gd` and `signals-listener.gd` scripts, and launch the `signals.tscn` scene to see the Swift signal in action:

```gdscript
# signals.gd 

extends Node

func _ready():
    $delegate.baz()
```

```gdscript
# signals-listener.gd 

extends Node

func _ready():
    pass 

func _on_delegate_my_signal(foo, bar):
    print('received signal: (foo: ', foo, ', bar: ', bar, ')')
```

```text 
...
(swift) registering SwiftSignals as nativescript 'Godot::SwiftSignals'
(swift) registering (function) as method 'Godot::SwiftSignals::baz'
(swift) registering MySignal as signal 'Godot::SwiftSignals::my_signal'
received signal: (foo: 6, bar: 5.55)
```

## life cycle management

[`sources`](swift/life-cycle-management.swift)

All Swift nativescripts are memory-managed by *Godot Swift*. However, their life cycles are dependent on the life cycles of the delegates they are attached to, which means that if a nativescript’s delegate owner leaks, so will the nativescript.

To demonstrate this, let’s define two nativescript classes, `SwiftUnmanaged`, and `SwiftManaged`. The `SwiftUnmanaged` nativescript will be attached to a `Godot::Node` ([`Godot.Unmanaged.Node`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Node)) delegate, which is an unmanaged delegate type, and the `SwiftManaged` nativescript will be attached to a `Godot::Reference` ([`Godot.AnyObject`](https://kelvin13.github.io/godot-swift/Godot/AnyObject)) delegate, which is a managed delegate type. 

```swift 
// life-cycle-management.swift

final class SwiftUnmanaged: Godot.NativeScript {
    init(delegate _: Godot.Unmanaged.Node) {
        Godot.print("initialized instance of '\(Self.self)'")
    }
    deinit {
        Godot.print("deinitialized instance of '\(Self.self)'")
    }
}
final class SwiftManaged:Godot.NativeScript {
    init(delegate _: Godot.AnyObject) {
        Godot.print("initialized instance of '\(Self.self)'")
    }
    deinit {
        Godot.print("deinitialized instance of '\(Self.self)'")
    }
}
```

> **Note:** *All* Swift nativescripts are memory-managed, even if they are `struct`s or `enum`s. In this example, we have defined `SwiftUnmanaged` and `SwiftManaged` as Swift `class`es, so that we can observe their deinitializations through the `deinit` observer.

You may already be aware that a dynamically-allocated `Godot::Node` instance will leak if not manually freed later: 

```gdscript 
# life-cycle-management.gd

extends Node

const SwiftUnmanaged    = preload("res://libraries/godot-swift-examples/SwiftUnmanaged.gdns")
const SwiftManaged      = preload("res://libraries/godot-swift-examples/SwiftManaged.gdns")

func _ready():
    var unmanaged:Node = SwiftUnmanaged.new()
```

*Godot Swift* has a built-in ARC sanitizer which is enabled if you run the `build` script in `debug` mode. It will track and report leaked Swift nativescripts on game termination. As of Godot 3.3.0, the game engine also has its own ARC sanitizer, which reports leaked delegates.

```text 
WARNING: deinit: (swift) detected 1 leaked instance of Examples.SwiftUnmanaged:
    1 leaked instance of 'SwiftUnmanaged'
   At: .build/plugins/outputs/godot-swift/examples/GodotNativeScript/classes.swift:845.
WARNING: cleanup: ObjectDB instances leaked at exit (run with --verbose for details).
   At: core/object.cpp:2132.
```

> **Note:** The *Godot Swift* ARC sanitizer only tracks Swift nativescripts. It will not track delegates; the Godot engine’s own ARC sanitizer handles that.

To prevent this issue, manually free the the unmanaged node with `queue_free()`. 

```gdscript 
    unmanaged.queue_free()
```

Delegate types that inherit from [`Godot.AnyObject`](https://kelvin13.github.io/godot-swift/Godot/AnyObject) (`Godot::Reference`) are memory-managed by Godot, which means nativescripts attached to them are also memory-managed. The `SwiftManaged` instances in the following code will be automatically deinitialized when exiting the `_ready()` function scope.

```gdscript 
    var managed_instances:Array = [
        SwiftManaged.new(),
        SwiftManaged.new(),
        SwiftManaged.new(),
    ]

    print(managed_instances)

    managed_instances = []
```

```text 
...
(swift) registering SwiftManaged as nativescript 'Godot::SwiftManaged'
...
(swift) registering SwiftUnmanaged as nativescript 'Godot::SwiftUnmanaged'
(swift) initialized instance of 'SwiftUnmanaged'
(swift) initialized instance of 'SwiftManaged'
(swift) initialized instance of 'SwiftManaged'
(swift) initialized instance of 'SwiftManaged'
[[Reference:1209], [Reference:1210], [Reference:1211]]
(swift) deinitialized instance of 'SwiftManaged'
(swift) deinitialized instance of 'SwiftManaged'
(swift) deinitialized instance of 'SwiftManaged'
(swift) deinitialized instance of 'SwiftUnmanaged'
```

## using custom types 

[`sources`](swift/custom-types.swift)

> This tutorial assumes you already have the project from the [basic usage](#basic-usage) tutorial set up.

So far, we have only used *Godot Swift*’s built-in [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) types. In this tutorial, we will define and use custom types conforming to this protocol.

#### one-to-one types

To start, let’s define a type `InputEvents` which holds two Godot objects — an instance of [`Godot.InputEventMouseButton`](https://kelvin13.github.io/godot-swift/Godot/InputEventMouseButton), and an instance of [`Godot.InputEventKey`](https://kelvin13.github.io/godot-swift/Godot/InputEventKey). 

```swift 
// custom-types.swift 

struct InputEvents:Godot.VariantRepresentable {
    let events:(mouse: Godot.InputEventMouseButton, key: Godot.InputEventKey)
```

The [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) protocol has the following requirements:

```swift 
protocol Godot.VariantRepresentable {
    static var variantType:Godot.VariantType { get }
    
    static func takeUnretained(_: Godot.Unmanaged.Variant) -> Self?
    func passRetained() -> Godot.Unmanaged.Variant 
}
```

The static [`variantType`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/variantType) property requirement is the simplest. It specifies a type hint for the conforming Swift type’s GDScript representation. It supports the following predefined cases:

| Case                  | GDScript type             |
| --------------------- | ------------------------- | 
| [`void`](https://kelvin13.github.io/godot-swift/Godot/VariantType/void)                               | `Godot::null`             |
| [`bool`](https://kelvin13.github.io/godot-swift/Godot/VariantType/bool)                               | `Godot::bool`             |
| [`int`](https://kelvin13.github.io/godot-swift/Godot/VariantType/int)                                 | `Godot::int`              |
| [`float`](https://kelvin13.github.io/godot-swift/Godot/VariantType/float)                             | `Godot::float`            |
| [`string`](https://kelvin13.github.io/godot-swift/Godot/VariantType/string)                           | `Godot::String`           |
| [`list`](https://kelvin13.github.io/godot-swift/Godot/VariantType/list)                               | `Godot::Array`            |
| [`map`](https://kelvin13.github.io/godot-swift/Godot/VariantType/map)                                 | `Godot::Dictionary`       |
| [`vector2`](https://kelvin13.github.io/godot-swift/Godot/VariantType/vector2)                         | `Godot::Vector2`          |
| [`vector3`](https://kelvin13.github.io/godot-swift/Godot/VariantType/vector3)                         | `Godot::Vector3`          |
| [`vector4`](https://kelvin13.github.io/godot-swift/Godot/VariantType/vector4)                         | `Godot::Color`            |
| [`rectangle2`](https://kelvin13.github.io/godot-swift/Godot/VariantType/rectangle2)                   | `Godot::Rect2`            |
| [`rectangle3`](https://kelvin13.github.io/godot-swift/Godot/VariantType/rectangle3)                   | `Godot::AABB`             |
| [`quaternion`](https://kelvin13.github.io/godot-swift/Godot/VariantType/quaternion)                   | `Godot::Quat`             |
| [`plane3`](https://kelvin13.github.io/godot-swift/Godot/VariantType/plane3)                           | `Godot::Plane`            |
| [`affine2`](https://kelvin13.github.io/godot-swift/Godot/VariantType/affine2)                         | `Godot::Transform2D`      |
| [`affine3`](https://kelvin13.github.io/godot-swift/Godot/VariantType/affine3)                         | `Godot::Transform`        |
| [`linear3`](https://kelvin13.github.io/godot-swift/Godot/VariantType/linear3)                         | `Godot::Basis`            |
| [`nodePath`](https://kelvin13.github.io/godot-swift/Godot/VariantType/nodePath)                       | `Godot::NodePath`         |
| [`resourceIdentifier`](https://kelvin13.github.io/godot-swift/Godot/VariantType/resourceIdentifier)   | `Godot::RID`              |
| [`delegate`](https://kelvin13.github.io/godot-swift/Godot/VariantType/delegate)                       | `Godot::Object`           |
| [`uint8Array`](https://kelvin13.github.io/godot-swift/Godot/VariantType/uint8Array)                   | `Godot::PoolByteArray`    |
| [`int32Array`](https://kelvin13.github.io/godot-swift/Godot/VariantType/int32Array)                   | `Godot::PoolIntArray`     |
| [`float32Array`](https://kelvin13.github.io/godot-swift/Godot/VariantType/float32Array)               | `Godot::PoolRealArray`    |
| [`stringArray`](https://kelvin13.github.io/godot-swift/Godot/VariantType/stringArray)                 | `Godot::PoolStringArray`  |
| [`vector2Array`](https://kelvin13.github.io/godot-swift/Godot/VariantType/vector2Array)               | `Godot::PoolVector2Array` |
| [`vector3Array`](https://kelvin13.github.io/godot-swift/Godot/VariantType/vector3Array)               | `Godot::PoolVector3Array` |
| [`vector4Array`](https://kelvin13.github.io/godot-swift/Godot/VariantType/vector4Array)               | `Godot::PoolColorArray`   |

If there is more than one possible GDScript type that can represent the conforming Swift type, it is acceptable to set [`variantType`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/variantType) to the [`void`](https://kelvin13.github.io/godot-swift/Godot/VariantType/void) case.

We want `InputEvents` to be represented by a two-element [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) (`Godot::Array`) in GDScript, so we set the type hint to the [`list`](https://kelvin13.github.io/godot-swift/Godot/VariantType/list) case.

```swift 
    static var variantType:Godot.VariantType {
        .list
    }
```

The next step is to implement the static [`takeUnretained(_:)`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/takeUnretained(_:)) method. It takes a parameter of type [`Godot.Unmanaged.Variant`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant), which, as its name suggests, is a type storing an unmanaged Godot variant.

If you are familiar with the Swift standard library type [`Unmanaged<T>`](https://developer.apple.com/documentation/swift/Unmanaged), the semantics here are exactly the same. That is, [`takeUnretained(_:)`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/takeUnretained(_:)) is expected to load a memory-managed instance of `Self` from the [`Godot.Unmanaged.Variant`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant) value, performing an unbalanced retain, if applicable. If the original [`Godot.Unmanaged.Variant`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant) is later deinitialized, the newly-loaded instance of `Self` should still be valid. If it is not possible to load an instance of `Self` from the variant data, this function should return `nil`.

```swift 
    static func takeUnretained(_ value:Godot.Unmanaged.Variant) -> Self? {
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
```

Let’s break down what’s happening in this implementation. 

*  `guard   let list:Godot.List = value.take(unretained: Godot.List.self), `
    
    This line loads a (memory-managed) instance of [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) from the unmanaged variant value using the [`take(unretained:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-take(unretained:)) method on [`Godot.Unmanaged.Variant`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant). It calls the [`takeUnretained(_:)`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/takeUnretained(_:)) implementation from the specified type, and can be used with any [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) type. This allows new [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) implementations to piggyback off of existing [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) implementations.
    
    It is also possible to call the [`takeUnretained(_:)`](https://kelvin13.github.io/godot-swift/Godot/List/takeUnretained(_:)) static method on [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) directly, but calling the [`take(unretained:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-take(unretained:)) method on [`Godot.Unmanaged.Variant`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant) is the preferred form. 
    
> **Warning:** Take care not to accidentally call [`take(unretained:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-take(unretained:)) with `Self.self` — this will cause infinite recursion.

*  `let mouse:Godot.InputEventMouseButton = list[0] as? Godot.InputEventMouseButton,`
    
    This line retrieves the first element of `list`, which has static type [`Godot.Variant`](https://kelvin13.github.io/godot-swift/Godot/Variant)`?`. Its *dynamic type* might be [`Godot.AnyDelegate`](https://kelvin13.github.io/godot-swift/Godot/AnyDelegate), which in turn, might be [`Godot.InputEventMouseButton`](https://kelvin13.github.io/godot-swift/Godot/InputEventMouseButton), so we use the `as?` operator to downcast to [`Godot.InputEventMouseButton`](https://kelvin13.github.io/godot-swift/Godot/InputEventMouseButton).
    
    The [`Godot.Variant`](https://kelvin13.github.io/godot-swift/Godot/Variant)`?` existentials are memory-managed by Swift, so we don’t have to do any manual cleanup if the dynamic downcast fails.

*  `let key:Godot.InputEventKey = list[1] as? Godot.InputEventKey`

    This line does essentially the same thing as the one above it, except it attempts to downcast to [`Godot.InputEventKey`](https://kelvin13.github.io/godot-swift/Godot/InputEventKey).

> **Note:** [`Godot.InputEventMouseButton`](https://kelvin13.github.io/godot-swift/Godot/InputEventMouseButton) and [`Godot.InputEventKey`](https://kelvin13.github.io/godot-swift/Godot/InputEventKey) are reference-counted delegates. The same code would still work for unmanaged delegate types, but their reference counts would not get incremented when loaded by [`take(unretained:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-take(unretained:)) or the [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) [subscript](https://kelvin13.github.io/godot-swift/Godot/List/[_:]), since they do not have reference counts in the first place. This means it would be the GDScript caller’s responsibility to guarantee that the delegates are alive for the duration of the nativescript call.

The [`passRetained()`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/passRetained()) instance method is the inverse of [`takeUnretained(_:)`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable/takeUnretained(_:)). Here, we create a [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) literal, and convert it to an unmanaged variant using the [`pass(retaining:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-pass(retaining:)/) constructor. Like the [`take(unretained:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-take(unretained:)) method, [`pass(retaining:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-pass(retaining:)/) can be used with any existing [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) type.

It is also possible to call the [`passRetained()`](https://kelvin13.github.io/godot-swift/Godot/List/passRetained()) instance method on [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) directly, but calling the [`pass(retaining:)`](https://kelvin13.github.io/godot-swift/Godot/Unmanaged/Variant/0-pass(retaining:)/) constructor is the preferred form.

```swift 
    func passRetained() -> Godot.Unmanaged.Variant {
        .pass(retaining: [self.events.mouse, self.events.key] as Godot.List)
    }
}
```

As with [`Unmanaged<T>`](https://developer.apple.com/documentation/swift/Unmanaged), the words “retained” and “retaining” indicate that an unbalanced retain will be performed, if applicable. In this example, the [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) literal expression creates a temporary [`Godot.List`](https://kelvin13.github.io/godot-swift/Godot/List) instance, which will be deinitialized as soon as it is no longer in use. However, the list itself will still be alive, with the unmanaged variant value storing a handle to it, which GDScript can use to retrieve it later.

#### union types

It is also possible to define custom Swift types that are representable by more than one GDScript type. Let’s define a type `UnitRangeElement<T>`, which models a floating point value in the range `0 ... 1`. In the typical Swift fashion, we will make it generic over [`BinaryFloatingPoint`](https://developer.apple.com/documentation/swift/binaryfloatingpoint). 

We want `UnitRangeElement<T>` to be representable by both `Godot::int` and `Godot::float`, so we set the type hint to `void`, which in this case means “any type”.

```swift 
struct UnitRangeElement<T>:Godot.VariantRepresentable where T:BinaryFloatingPoint {
    let value: T 
    
    static var variantType:Godot.VariantType {
        .void 
    }
```

The `takeUnretained(_:)` implementation accepts the integer values `0` and `1`, and any floating point value in the range `0 ... 1`. We could attempt to load `Int64` and `Float64` values in a series of `if let`/`else if let` bindings, similar to what we did in the `InputEvents` example, but we can also load a [`Godot.Variant`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable)`?` existential, and switch over its type cases:

```swift 
    static func takeUnretained(_ value: Godot.Unmanaged.Variant) -> Self? {
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
```

> **Note:** `Godot.Variant?.self` is a metatype object of type `Optional<Godot.Variant>.Type`. This type can be thought of as an optionalized version of `Godot.Variant.Protocol`. Don’t confuse it with `Optional<Godot.Variant.Protocol>`, which is an optional metatype, not a metatype of an optional protocol type. (This is a subtle but extremely important distinction.)

The `passRetained()` implementation can produce either a `Godot::int`, if possible, or a `Godot::float` otherwise. 

```swift 
    func passRetained() -> Godot.Unmanaged.Variant {
        switch self.value {
        case 0:         return .pass(retaining: 0 as Int64)
        case 1:         return .pass(retaining: 1 as Int64)
        case let value: return .pass(retaining: Float64.init(value))
        }
    }
```

We can now define a nativescript `SwiftCustomTypes` to demonstrate the usage of our custom [`Godot.VariantRepresentable`](https://kelvin13.github.io/godot-swift/Godot/VariantRepresentable) types: 

```swift 
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
```

If we test it from GDScript, we can see `InputEvents` and `UnitRangeElement<Float32>` in action. (The commented-out lines are invalid conversions, which would raise runtime type conversion errors, according to our custom type implementations.)

```gdscript 
# custom-types.gd 

extends Node

func _ready():
    var mouse:InputEventMouseButton = InputEventMouseButton.new()
    var key:InputEventKey           = InputEventKey.new()
    
    $delegate.push_inputs([mouse, key])
    # $delegate.push_inputs([mouse])
    
    var zero:int = 0 
    var one:int  = 1
    $delegate.x = zero
    $delegate.x = one
    $delegate.x = 0.75 
    # $delegate.x = 1.5
    
    $delegate.x = 1.0 
    print(typeof($delegate.x) == TYPE_INT)
```

```text 
(swift) registering SwiftCustomTypes as nativescript 'Godot::SwiftCustomTypes'
(swift) registering (function) as method 'Godot::SwiftCustomTypes::push_inputs'
(swift) registering (function) as property 'Godot::SwiftCustomTypes::x'
(swift) push(delegate:inputs:) received inputs 
    InputEvents(events: (mouse: Examples.Godot.InputEventMouseButton, key: Examples.Godot.InputEventKey))
(swift) set `x` to 0.0
(swift) set `x` to 1.0
(swift) set `x` to 0.75
(swift) set `x` to 1.0
True
```

Observe that even when we set `x` to the floating point value `1.0`, it comes back as the integer value `1`, which is exactly what we expect, given our `UnitRangeElement<T>` implementation.
