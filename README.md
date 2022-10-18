# FIVE fork info

This is a forked version of SwiftLint tool enforcing swift code style preferences of FIVE, an Endava Company, iOS team. For original repo reference, head over to [SwiftLint original repo](https://github.com/realm/SwiftLint). 

## Installation: 

### HomeBrew (compiled binary)

1. Make sure you have [Homebrew](https://brew.sh/) installed
2. Tap forked swiftlint repo
   ```
   brew tap fiveagency/five-swiftlint
   ```
3. Install forked swiftlint
   ```
   brew install fiveagency/five-swiftlint
   ```
4. Run it inside swift source code directory using:
   ```
   five-swiftlint lint (--no-cache)
   ```

### Manual
1. Clone this repo
   ```
   git clone https://github.com/fiveagency/Five-SwiftLint
   ```
2. Open cloned directory
   ```
   cd Five-SwiftLint
   ```
3. Build binary
   ```
   swift build -c release
   ```
4. Navigate to a project with swiftlint config and run
   ```
   path/to/.build/release/swiftlint lint
   ```

## Running on CI

### Using compiled binary

The simplest and most convenient way is using a prebuilt binary from *Manual installation* steps above. Push it to your remote repo and add it to .gitignore afterward. Then you can use the bash script below for the intermediate build step replacing relative path of pushed binary:

``` bash
#!/usr/bin/env bash

relative/path/to/five-swiftlint lint --no-cache --strict
result=$?
if [ "$result" = "2" ] || [ "$result" = "3" ]
then
    exit -1
else
    exit 0
fi
```

If your CI/CI environment supports Homebrew, you can fetch five-swiftlint from FIVE's tap repository using the script below:

``` bash
#!/usr/bin/env bash

brew tap fiveagency/five-swiftlint
brew install five-swiftlint
five-swiftlint lint --strict
result=$?
if [ "$result" = "2" ] || [ "$result" = "3" ]
then
    exit -1
else
    exit 0
fi
```

### Bitrise

For Bitrise integration, create a new script step and paste the contents of one of the scripts above, depending on your preference.

### Xcode Cloud

Xcode cloud supports custom build scripts as well, but runs them at a specific moment between steps. The name of a custom script’s corresponding file determines when Xcode Cloud runs the script:\
`ci_post_clone.sh` -> Runs after repository cloning\
`ci_pre_xcodebuild.sh` -> Runs before building project\
`ci_post_xcodebuild.sh` -> Runs after project has been built\

Create `ci_scripts` directory in the root directory of your Xcode project and create either post clone script file `ci_post_clone.sh` or pre-build script file `ci_pre_xcodebuild.sh`. 

As Xcode cloud doesn't run scripts in the workspace/project directory, pass `CI_WORKSPACE` environment variable as source files directory path to lint:

``` bash
#!/bin/sh
export PATH="$PATH:/usr/local/bin"

brew tap fiveagency/five-swiftlint
brew install five-swiftlint
five-swiftlint lint $CI_WORKSPACE --strict
result=$?
if [ "$result" = "2" ] || [ "$result" = "3" ]
then
    exit -1
else
    exit 0
fi

```
IMPORTANT! 
In Terminal, make the shell script an executable by running `chmod +x filename.sh`. Without this step, the script will not work!

## Contribution

1. git clone `https://github.com/realm/SwiftLint.git`
2. `cd SwiftLint`
3. `xed .` (Xcode Command Line Tools have to be installed as well)
4. Select the `'five-swiftlint'` scheme
5. `Press cmd + option + R` open the scheme options
6. Set the "Arguments Passed On Launch" you want in the "Arguments" tab. For list of possible arguments, you can pass --help command when running swiftlint in Terminal. The default mode is lint. 
7. Set the "Working Directory" in the "Options" tab to the path where you would like to execute SwiftLint. A folder that contains swift source files.
8. Hit "Run"

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

## Writing a custom rule

### Under the Hood

SwiftLint relies on two libraries for parsing and inspecting Swift source code: SourceKitten and SwiftSyntax.

SourceKitten is the open source community-maintained library that provides an abstract API layer for communicating with SourceKit (framework that Xcode uses under the hood) which parses and tokenizes the source code and provides its metadata.

SwiftSyntax is apple's library (part of the swift compiler) that provides a Swift abstraction on top of the libSyntax, exposing a set of APIs that makes it possible to do things like visiting, rewriting and retrieving information from the syntactic structure of a swift source.

Even though the majority of the SwiftLint rules are written with the help of SourceKitten library, some simpler syntax-only rules are being rewritten with SwiftSyntax protocols which give finer syntax node control and parsing precision. 

SwiftSyntax provides this representation in the form of Syntax nodes and we can navigate through it using Visitors and also make changes to this structure using Rewriters. Each kind of structure has a type representation e.g. `struct_decl` has the SwiftSyntax struct `StructDeclSyntax` type that represents it as a syntax node.

The good thing about SwiftSyntax is that it invokes swift compiler in-process, so it doesn't need SourceKit to retrieve AST data for the source file. 

SourceKitten rules should conform to either the `Rule` or `ASTRule`, while SwiftSyntax rules should conform to `SourceKitFreeRule` or  `SwiftSyntaxRule` protocols.

If a rule is required to be mandatory and applied out of the box in this fork, include it in `PrimaryRuleList.swift` file. Otherwise, it should conform to `OptInRule` protocol. Opt-in rules have to be declared in `.swiftlin.yml` configuration file (`under opt_in_rules`) to be included in the linting process.

### Rule declaration

Every rule is a public struct that conforms to one of the above mentioned protocols. Conforming to one of the protocols, the rule has to have a public var named description. Rule description is struct value that contains basic info about the rule like rule identifier, name, description string, kind (lint, idiomatic, performance, style or metrics) and triggering/non-triggering examples which are unit test sources. 

```swift
 public static let description = RuleDescription(
    identifier: "trailing_newline",
    name: "Trailing Newline",
    description: "Files should have a single trailing newline.",
    kind: .style,
    nonTriggeringExamples: [
        Example("let a = 0\n")
    ],
    triggeringExamples: [
        Example("let a = 0"),
        Example("let a = 0\n\n")
    ].skipWrappingInCommentTests().skipWrappingInStringTests(),
    corrections: [
        Example("let a = 0"): Example("let a = 0\n"),
        Example("let b = 0\n\n"): Example("let b = 0\n"),
        Example("let c = 0\n\n\n\n"): Example("let c = 0\n")
    ]
)
```

### SwiftSyntax

To implement a custom rule that relies on SwiftSyntax, you have to conform it to `SwiftSyntaxRule` or `SourceKitFreeRule`.

`SourceKitFree` protocol is the same as basic `Rule` protocol which means conforming to it you have to implement `validate` method which returns an array of `StyleViolation`s. It is a rule that does not need SourceKit to operate and can still operate even after SourceKit has crashed, just as its name says.

``` swift
    func validate(file: SwiftLintFile) -> [StyleViolation]
```

Following example is the implementation of validate method for TrailingNewlineRule. Use `SourceKitFree` rule when validating logic is dependent on file properties, not syntax structures.

```swift
 public func validate(file: SwiftLintFile) -> [StyleViolation] {
    if file.contents.trailingNewlineCount() == 1 {
        return []
    }

    return [
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file.path, line: max(file.lines.count, 1)))]
}
```

If there is a need for more information about code structure and nested expressions to enforce swift code style, conforming to `SwiftSyntaxRule` allows us to get all the metadata about one expression, declaration or any kind of syntax element.

Conforming to `SwiftSyntaxRule`, we have to implement factory method `makeVisitor` that receives source file struct value as a parameter and returns a custom instance of `ViolationsSyntaxVisitor` which we have to create.

```swift
public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
    Visitor(viewMode: .sourceAccurate)
}
```

Below is the implementation of custom `SyntaxVisitor` class. The open class `SyntaxVisitor` contains multiple overloaded open `visit` and `visitPost` methods that differ in the type of syntax node they receive. Overriding these methods, we can implement custom validation logic for our swiftlint rule. Method `visit` relates to the syntax node that is being currently visited, while `visitPost` method gets called after visiting mentioned node. Every node type has different properties that expose more information about the code syntax. List of all types of nodes can be found in [SwiftSyntax library here](https://github.com/apple/swift-syntax/tree/main/Sources/SwiftSyntax/gyb_generated/syntax_nodes) 

```swift
final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {

    private(set) var violationPositions: [AbsolutePosition] = []

    override func visitPost(_ node: TryExprSyntax) {
        guard node.questionOrExclamationMark?.tokenKind == .exclamationMark else { return }
        
        violationPositions.append(node.positionAfterSkippingLeadingTrivia)
    }

}
```

The general rule of thumb is to use `SourceKitFreeRule` protocol over `SwiftSyntaxRule` if your validation logic is not dependent on syntax nodes but on general file structure (lines count, comments etc.). Otherwise, if the linting target is some kind of specific expression or declaration, use `SwiftSyntaxRule`.

### SourceKitten 

Just like SwiftSyntax based protocols, SwiftLint original rule protocols were written with the support of SourceKitten. SwiftLint offers basic `Rule` protocol for file-based inspections and `ASTRule` protocol for recursively validating complex nested code syntax. 

Implementation of ForceTryRule with SourceKitten `Rule` protocol approach:

```swift
public func validate(file: SwiftLintFile) -> [StyleViolation] {
    file.match(pattern: "try!", with: [.keyword]).map {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file, characterOffset: $0.location))
}
```

`ASTRule` uses clang's Abstract Syntax Tree serialized data through SourceKit requests and presents syntax information in form of a dictionary. `SourceKittenDictionary` contains all data about parsed file: access modifiers, declarations, identifiers, inherited types and any other nested structures within. 

Conforming to `ASTRule`, `validate` method has to be implemented:

```swift
public func validate(file: SwiftLintFile, kind: SwiftDeclarationKind, dictionary: SourceKittenDictionary) -> [StyleViolation]
```

`file` corresponds to parsed swift file struct, kind represents one of the SourceKitten syntax groups (SwiftDeclarationKind, SwiftExpressionKind and StatementKind) and dictionary represents syntax metadata for code structures in the given file.

```swift
public func validate(
    file: SwiftLintFile,
    kind: SwiftDeclarationKind,
    dictionary: SourceKittenDictionary
) -> [StyleViolation] {
    let definitionKinds = SwiftDeclarationKind.typeKinds
        .union(SwiftDeclarationKind.extensionKinds)
        .union([.protocol])

    guard
        definitionKinds.contains(kind),
        dictionary.substructure.isNotEmpty,
        let bodyOffset = dictionary.bodyOffset
    else { return [] }

    guard !containsOpeningBraceViolation(in: file, offset: bodyOffset) else { return [] }

    return [
        StyleViolation(
            ruleDescription: NewLineAfterDefinitionBracesRule.description,
            location: Location(file: file, byteOffset: bodyOffset))]
}
```

Whenever possible, prefer adding tests via the `triggeringExamples` and `nonTriggeringExamples` properties of a rule's `description` rather than adding those test cases in the unit tests directly. This makes it easier to understand what rules do by reading their source and simplifies adding more test cases over time. This way adding a unit test for your new Rule is just a matter of adding a test case in `RulesTests.swift` which simply calls `verifyRule(YourNewRule.description)`.

### Rule configuration

If you want your rule to be configurable in `.swiftlint.yml`, your rule needs to conform to `ConfigurationProviderRule` protocol and have `configuration` property:

* The object provided must conform to `RuleConfiguration`.
* Several provided RuleConfigurations cover common patterns like
  configuring violation severity, violation severity levels, and evaluating
  names.
* If none of the provided `RuleConfiguration`s are applicable, you can create one
  specifically for your rule.

See [`ForceCastRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Rules/Idiomatic/ForceCastRule.swift)
for a rule that allows severity configuration,
[`FileLengthRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Rules/Metrics/FileLengthRule.swift)
for a rule that has multiple severity levels,
[`IdentifierNameRule`](https://github.com/realm/SwiftLint/blob/main/Source/SwiftLintFramework/Rules/Style/IdentifierNameRule.swift)
for a rule that allows name evaluation configuration:

``` yaml
force_cast: warning

file_length:
  warning: 800
  error: 1200

identifier_name:
  min_length:
    warning: 3
    error: 2
  max_length: 20
  excluded: id
```

If your rule is configurable, but does not fit the pattern of `ConfigurationProviderRule`, you can conform directly to `Rule`:

* `init(configuration: AnyObject) throws` will be passed as the result of parsing the
  value from `.swiftlint.yml` associated with your rule's `identifier` as a key
  (if present).
* `configuration` may be of any type supported by YAML (e.g. `Int`, `String`, `Array`,
  `Dictionary`, etc.).
* This initializer must throw if it does not understand the configuration, or
  it cannot be fully initialized with the configuration and default values.
* By convention, a failing initializer throws
  `ConfigurationError.UnknownConfiguration`.
* If this initializer fails, your rule will be initialized with its default
  values by calling `init()`.
  
## Benchmark

| Run  | swiftlint (vanilla) | fork  | swiftlint (custom regex) --no-cache | swiftlint --no-cache | fork --no-cache |
| :--- | :-----------------: | :---: | :---------------------------------: | :------------------: | :-------------: |
| 1.   |        5.012        | 5.054 |               33.643                |        4.825         |      4.986      |
| 2.   |        1.279        | 0.616 |               32.561                |        4.675         |      5.013      |
| 3.   |        0.700        | 0.625 |               32.253                |        4.680         |      4.933      |
| 4.   |        0.675        | 0.622 |               32.745                |        4.684         |      4.947      |
| 5.   |        0.682        | 0.613 |               32.447                |        4.832         |      5.049      |
| avg. |        1.670        | 1.506 |               32.732                |        4.739         |      4.986      |

Note: fork config has 4 new custom rules added to the default list (newline after opening brace, newline before opening brace, viewcontroller length & file length)

Custom SwiftLint fork found 4020 violations, 411 serious in 3369 files while vanilla SwiftLint with custom regex found 3624 violations, 413 serious in 3369 files.
