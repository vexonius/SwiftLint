import SourceKittenFramework
import Foundation

struct NewLineBeforeDefinitionBracesRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "newline_before_definition_closing_brances",
        name: "Newline Before Definition Closing Braces",
        description: "There should be an empty line before the definition closing braces",
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
            class ViewController {
                let view = UIView()
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
        let targetLineOffset = 2

        let definitionKinds = SwiftDeclarationKind.typeKinds
            .union(SwiftDeclarationKind.extensionKinds)
            .union([.protocol])

        guard
            definitionKinds.contains(kind),
            dictionary.substructure.isNotEmpty,
            let bodyRange = dictionary.bodyByteRange
        else { return [] }

        guard
            let lineIndex = file.stringView.lineAndCharacter(forByteOffset: bodyRange.upperBound)?.line
        else { return [] }

        let lines = file.stringView.lines
        let targetLine = lines[lineIndex-targetLineOffset] // lines index start at 1

        guard targetLine.content.trimmingCharacters(in: .whitespaces).isNotEmpty else { return [] }

        return [
            StyleViolation(
                ruleDescription: NewLineBeforeDefinitionBracesRule.description,
                location: Location(file: file, byteOffset: bodyRange.upperBound))]
    }

}
