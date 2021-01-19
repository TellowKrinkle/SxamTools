import ArgumentParser

struct SxamCLI: ParsableCommand {
	static var configuration = CommandConfiguration(
		commandName: CommandLine.arguments[0],
		abstract: "A tool for reading Higurashi Mei's resource files",
		subcommands: [SxamExtract.self, SxamDecode.self]
	)
}
