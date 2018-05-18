# SwiftCompilationDatabase

SwiftCompilationDatabase produces a `compile_commands.json` from the Swift compiler.

For tools, like [iCompleteMe](https://github.com/jerrymarino/iCompleteMe), that need to invoke the swift compiler outside of a build, [JSONCompilationDatabase](https://clang.llvm.org/docs/JSONCompilationDatabase.html) makes it easy to get all arguments for a file.

## Usage

First, build from source
```
make
```

SwiftCompilationDatabase relies on the parseable output feature of Swift. Simply run the swift compiler with parseable output enabled ( `-parseable-output` ), and send the result to SwiftCompilationDatabase.

In practice, this means doing a clean build so all of the frontend invocations are recorded into the database.

```
swiftc main.swift -parseable-output 2>&1 | swift-compilation-database
```

### SwiftPM / Swift Build

SwiftCompilationDatabase works great with SwiftPM and `swift build`.

Do a clean build and pipe results

```
swift build -v -Xswiftc -parseable-output --build-path .build-comp-db 2>&1 | swift-compilation-database
```

## Xcode Usage

To make a compilation database from Xcode, I recommend checking out [XcodeCompilationDatabase](https://github.com/jerrymarino/XcodeCompilationDatabase)

