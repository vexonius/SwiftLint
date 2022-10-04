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
   path/to/.build/release/swiftlint lint
   ```

## Running on CI

### Using compiled binary

Simplest and most convenient way is using a prebuilt binary form Manual installation steps above. Push it to you remote repo and add it to .gitignore afterwards. Then you can use the bash script below for intermediate build step replacing relative path of pushed binary:

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

If your CI/CI environment supports Homebrew, you can fetch five-swiftlint from FIVE's tap repository using script below:

``` bash
#!/usr/bin/env bash

brew tap vexonius/five-swiftlint
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

For Bitrise integration, create a new script step and paste the contents one of the scripts above, depending on your preference.

### Xcode Cloud

Xcode cloud supports custom build scripts as well, but runs them at a specific moment between steps. The name of a custom script’s corresponding file determines when Xcode Cloud runs the script:\
`ci_post_clone.sh` -> Runs after repository cloning\
`ci_pre_xcodebuild.sh` -> Runs before building project\
`ci_post_xcodebuild.sh` -> Runs after project has been built\

Create `ci_scripts` directory in the root directory of your Xcode project and create either post clone script file `ci_post_clone.sh` or prebuild script file `ci_pre_xcodebuild.sh`. 

As Xcode cloud doesn't run scripts in workspace/project directory, we have to pass CI_WORKSPACE environment variable as source files directory path to lint:

``` bash
#!/bin/sh
export PATH="$PATH:/usr/local/bin"

brew tap vexonius/five-swiftlint
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
In Terminal, make the shell script an executable by running `chmod +x filename.sh`. Without this step script will not work!

## Contribution

1. git clone `https://github.com/realm/SwiftLint.git`
2. `cd SwiftLint`
3. `xed .` (Xcode Command Line Tools have to be installed as well)
4. Select the `'swiftlint'` scheme
5. `Press cmd + option + R` open the scheme options
6. Set the "Arguments Passed On Launch" you want in the "Arguments" tab. For list of possible arguments, you can pass --help command when running swiftlint in Terminal. Default mode is lint. 
7. Set the "Working Directory" in the "Options" tab to the path where you would like to execute SwiftLint. A folder that contains swift source files.
8. Hit "Run"

New rules should be added in the `Source/SwiftLintFramework/Rules` directory.

Rules should conform to either the `Rule` or `ASTRule` protocols.

Whenever possible, prefer adding tests via the `triggeringExamples` and `nonTriggeringExamples` properties of a rule's `description` rather than adding those test cases in the unit tests directly. This makes it easier to understand what rules do by reading their source, and simplifies adding more test cases over time. This way adding a unit test for your new Rule is just a matter of adding a test case in `RulesTests.swift` which simply calls `verifyRule(YourNewRule.description)`.

## Rule configuration

If you want your rule to be configurable in `.swiftlint.yml`, your rule needs to conform to `ConfigurationProviderRule` protocol and have `configuration` property:

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

Note: fork config has 4 new custom rules added to default list (newline after opening brace, newline before opening brace, viewcontroller length & file length)

Custom SwiftLint fork found 4020 violations, 411 serious in 3369 files while vanilla SwiftLint with custom regex found 3624 violations, 413 serious in 3369 files.
