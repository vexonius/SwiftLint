# FIVE fork info

This is a forked version of SwiftLint tool enforcing swift code style preferences of FIVE, an Endava Company, iOS team. For original repo reference, head over to [SwiftLint original repo](https://github.com/realm/SwiftLint). 

## Installation: 

### HomeBrew (compiled binary)

1. Make sure you have [Homebrew](https://brew.sh/) installed
2. Tap forked swiftlint repo
  ```
  brew tap vexonius/five-swiftlint
  ```
3. Install forked swiftlint
   ```
   brew install vexonius/five-swiftlint
   ```
4. Run it inside swift source code directory using:
   ```
   five-swiftlint lint (--no-cache)
   ```

### Manual
1. Clone this repo
   ```
   git clone https://github.com/vexonius/SwiftLint
   ```
2. Open cloned directory
   ```
   cd SwiftLint
   ```
3. Build binary
   ```
   swift build -c release
   ```
4. Navigate to a project with swiftlint config and run
   ```
   .build/release/swiftlint lint
   ```

## Contribution

1. git clone `https://github.com/realm/SwiftLint.git`
2. `cd SwiftLint`
3. `xed .` (XCode Command Line Tools have to be installed as well)
4. Select the `'swiftlint'` scheme
5. `Press cmd + option + R` open the scheme options
6. Set the "Arguments Passed On Launch" you want in the "Arguments" tab. For list of possible arguments, you can pass --help command when running swiftlint in Terminal. Default mode is lint. 
7. Set the "Working Directory" in the "Options" tab to the path where you would like to execute SwiftLint. A folder that contains swift source files.
8. Hit "Run"

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

Rules should conform to either the `Rule` or `ASTRule` protocols.

Whenever possible, prefer adding tests via the `triggeringExamples` and `nonTriggeringExamples` properties of a rule's `description` rather than adding those test cases in the unit tests directly. This makes it easier to understand what rules do by reading their source, and simplifies adding more test cases over time. This way adding a unit test for your new Rule is just a matter of adding a test case in `RulesTests.swift` which simply calls `verifyRule(YourNewRule.description)`.

## Rule configuration

If your rule supports user-configurable options via `.swiftlint.yml`, you can accomplish this by conforming to `ConfigurationProviderRule`. You must provide a configuration object via the `configuration` property:

* The object provided must conform to `RuleConfiguration`.
* There are several provided `RuleConfiguration`s that cover the common patterns like
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

* `init(configuration: AnyObject) throws` will be passed the result of parsing the
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

| Run  | swiftlint | custom | swiftlint --no-cache | custom --no-cache |
| :--- | :-------: | :----: | :------------------: | :---------------: |
| 1.   |   5.012   | 5.054  |        4.825         |       4.986       |
| 2.   |   1.279   | 0.616  |        4.675         |       5.013       |
| 3.   |   0.700   | 0.625  |        4.680         |       4.933       |
| 4.   |   0.675   | 0.622  |        4.684         |       4.947       |
| 5.   |   0.682   | 0.613  |        4.832         |       5.049       |

Custom SwiftLint fork found 4020 violations, 411 serious in 3369 files while vanilla SwiftLint with custom regex found 3624 violations, 413 serious in 3369 files.