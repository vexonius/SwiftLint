import SourceKittenFramework

public struct ViewControllerFileLengthRule: ASTRule, ConfigurationProviderRule {
    public var configuration = FileLengthRuleConfiguration(warning: 400, error: 1000)

    private let viewControllerPattern = "ViewController"

    public init() {}

    public static let description = RuleDescription(
        identifier: "viewcontroller_file_length",
        name: "Viewcontroller File Length",
        description: "ViewControllers should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example(repeatElement("print(\"swiftlint\")\n", count: 399).joined())
        ],
        triggeringExamples: [
            Example(repeatElement("print(\"swiftlint\")\n", count: 601).joined()),
            Example((repeatElement("print(\"swiftlint\")\n", count: 600) + ["//\n"]).joined()),
            Example(repeatElement("print(\"swiftlint\")\n\n", count: 1001).joined())
        ].skipWrappingInCommentTests()
    )

    public func validate(
        file: SwiftLintFile,
        kind: SwiftDeclarationKind,
        dictionary: SourceKittenDictionary
    ) -> [StyleViolation] {

        guard
            dictionary.declarationKind == .class,
            dictionary.inheritedTypes.isNotEmpty
        else {
            return []
        }

        guard inheritsViewController(inheritedTypes: dictionary.inheritedTypes) else { return [] }

        var lineCount = file.lines.count
        let hasViolation = configuration.severityConfiguration.params.contains {
            $0.value < lineCount
        }

        if hasViolation && configuration.ignoreCommentOnlyLines {
            lineCount = lineCountWithoutComments(file: file)
        }

        for parameter in configuration.severityConfiguration.params where lineCount > parameter.value {
            let reason = "ViewController file should contain \(configuration.severityConfiguration.warning)" +
                "lines or less" + (configuration.ignoreCommentOnlyLines ? " excluding comments and whitespaces" : "") +
                ": currently contains \(lineCount)"

            return [StyleViolation(ruleDescription: Self.description,
                                   severity: parameter.severity,
                                   location: Location(file: file.path, line: file.lines.count),
                                   reason: reason)]
        }

        return []
    }
}


extension ViewControllerFileLengthRule {

    func lineCountWithoutComments(file: SwiftLintFile) -> Int {
        let commentKinds = SyntaxKind.commentKinds
        let lineCount = file.syntaxKindsByLines.filter { kinds in
            return !Set(kinds).isSubset(of: commentKinds)
        }.count

        return lineCount
    }

    func inheritsViewController(inheritedTypes: [String]) -> Bool {
        inheritedTypes
            .map { $0.contains(viewControllerPattern) }
            .reduce(false) { $0 || $1 }
    }

}
