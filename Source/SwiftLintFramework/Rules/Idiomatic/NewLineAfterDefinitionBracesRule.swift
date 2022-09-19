import SourceKittenFramework

public struct NewLineAfterDefinitionBracesRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "newline_after_definition_opening_brances",
        name: "Newline After Definition Opening Braces",
        description: "There should be an empty line after the definition opening braces",
        kind: .style,
        nonTriggeringExamples: [
            Example("""
            struct Five {

              let highFive = true

            }
            """)
        ],
        triggeringExamples: [
            Example("""
            enum Math {
              public static let pi = 3.14

            }
            """),
            Example("""
            struct Basic {
                let name = "SwiftLint"
            }
            """),

            Example("""
            extension ViewController {
                viewWillAppear() {
                    super.viewWillAppear()
                }
            }
            """)
        ])

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

        let twoLinesLength: ByteCount = 2
        let range = ByteRange(location: bodyOffset, length: twoLinesLength)

        guard
            let contents = file.stringView.substringWithByteRange(range),
            contents.trimmingCharacters(in: .whitespaces).isNotEmpty
        else { return [] }

        return [
            StyleViolation(
                ruleDescription: NewLineAfterDefinitionBracesRule.description,
                location: Location(file: file, byteOffset: bodyOffset))]
    }

}
