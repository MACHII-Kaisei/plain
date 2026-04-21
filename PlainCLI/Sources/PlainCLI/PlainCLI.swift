import ArgumentParser

@main
struct PlainCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "plain",
        abstract: "Plain — macOS TODO アプリの CLI",
        subcommands: [
            AddCommand.self,
            ListCommand.self,
            DoneCommand.self,
            UndoneCommand.self,
            EditCommand.self,
            DeleteCommand.self,
            TagCommand.self,
        ]
    )
}

