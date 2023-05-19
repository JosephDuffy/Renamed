# Renamed

Renamed is a macro to ease the renaming of symbols. For example, say you have

```swift
struct MyType {
    let propertyName: String
}
```

but you rename `MyType.propertyName` to `MyType.newName`. To avoid introducing a breaking change you can add a computed property named `propertyName` decorated with `@available(*, deprecated, renamed: "newName")`, but this can be cumbersome.

With Renamed this can be done with a single attribute.

```swift
struct MyType {
    @Renamed(from: "propertyName")
    let newProperty: String
}
```

This generates the Swift code:

```swift
struct MyType {
    let newName: String

    @available(*, deprecated, renamed: "newName")
    var propertyName: String {
        newName
    }
}
```

(this isn't _exactly_ how the macro gets expanded, but that's not important here).

`Renamed` uses the same naming syntax as the `renamed` parameter of the `@available` attribute. For example, renaming a function is also supported.

```swift
@Renamed(from: "oldFunctionName(argument:_)")
func newFunctionName(_ variableName: String, argumentName: Int) -> Bool {}
```

produces:

```swift
func oldFunctionName(argument arg0: String, _ arg1: Int) -> Bool {
    newFunctionName(arg0, argumentName: arg1)
}
```

Functions without parameters can omit the

This works for:

- [x] Structs
- [x] Classes
- [x] Enums
- [x] Type aliases
- [x] Immutable properties
- [x] Mutable properties
- [x] Functions

## FAQ

**Q: How ready is this?**

This is past the proof-of-concept phase, but since official support for macros is not available this is still an alpha. There are probably more cases that can be supported and most descriptive errors that could be thrown in some cases (e.g. rather than producing invalid code).

With all that said, all supported use-cases have associated tests that prove this works.

**Q: Why is CI failing?**

**A:** I have no idea! Everything Works On My Machine™ and the error doesn't make sense to me. If you have any ideas please tell me!

**Q: I found something that doesn't work. What can I do?**

**A:** Please open an issue or, better yet, a PR with a failing or implementation. I'm sure there are some edge cases I've not thought of!

**Q: Will this be slow?**

**A:** There is a small compile-time hit but it's minimal. The code produced is often identical to what would be written by hand. No runtime dependencies are added.

**Q: Do I have to add a whole dependency just to save myself some typing?**

**A:** Yes. Personally I would only consider using this project for a big refactor.

**Q: Is this type-safe?**

**A:** To a degree. Swift will check the code generated by this marco, so if you enter an invalid name, e.g. `@Renamed(from: "1nvalid")` the compiler will throw an error. The macro will also produce a compile-time error when used on unsupported symbols, such as a variable without an explicit type. These errors are being worked on and some more situations will be supported. 

**Q: Where can I find more about macros?**

**A:** [Swift Macros Dashboard](https://gist.github.com/DougGregor/de840fcf6d6f307792121eee11c0da85)

## Installation

To use macros you need to use a recent Swift toolchain. Because Xcode does not support building a package with a toolchain development is being done in Visual Studio Code. Check the [settings.json](./.vscode/settings.json) file to see which snapshot the project is being developed against.

## License

[MIT](./LICENSE)
