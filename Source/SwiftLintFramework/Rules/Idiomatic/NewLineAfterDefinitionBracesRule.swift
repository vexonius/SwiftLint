import SourceKittenFramework
import Foundation

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

        guard containsOpeningBraceViolation(in: file, offset: bodyOffset) else { return [] }

        return [
            StyleViolation(
                ruleDescription: NewLineAfterDefinitionBracesRule.description,
                location: Location(file: file, byteOffset: bodyOffset))]
    }
    
}

extension NewLineAfterDefinitionBracesRule {

    func containsOpeningBraceViolation(in file: SwiftLintFile, offset: ByteCount) -> Bool {
        let twoLinesLength: ByteCount = 2
        let matchingPattern = "\n\n"
        let range = ByteRange(location: offset, length: twoLinesLength)

        guard let nsRange = file.stringView.byteRangeToNSRange(range) else { return false }

        let matches = file.match(pattern: matchingPattern, range: nsRange)

        return matches.isEmpty
    }

}
