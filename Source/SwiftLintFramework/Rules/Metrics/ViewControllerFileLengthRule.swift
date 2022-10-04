import SourceKittenFramework

public struct ViewControllerFileLengthRule: ConfigurationProviderRule {
    public var configuration = FileLengthRuleConfiguration(warning: 400, error: 1000)

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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let isViewController = file.structureDictionary.isViewController()

        guard isViewController else { return [] }

        var lineCount = file.lines.count
        let hasViolation = configuration.severityConfiguration.params.contains {
            $0.value < lineCount
        }

        if hasViolation && configuration.ignoreCommentOnlyLines {
            lineCount = file.lineCountWithoutComments()
        }

        let match = configuration
            .severityConfiguration
            .params
            .first(where: { $0.value < lineCount })

        guard let match = match else { return [] }

        let reason = "ViewController file should contain \(configuration.severityConfiguration.warning)" +
        " lines or less" + (configuration.ignoreCommentOnlyLines ? " excluding comments and whitespaces" : "")
        + ": currently contains \(lineCount)"

        return [
            StyleViolation(
                ruleDescription: Self.description,
                severity: match.severity,
                location: Location(file: file.path, line: file.lines.count),
                reason: reason)]
    }

}
