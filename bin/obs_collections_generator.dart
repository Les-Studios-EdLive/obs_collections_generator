import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:obs_collections_generator/commands/generate_command.dart';
import 'package:obs_collections_generator/commands/verify_command.dart';

const outputDirectoryPath = "output";

void main(List<String> arguments) async {
  var runner = CommandRunner(
      "obs_collections_generator", "Add a description here please")
    ..argParser.addFlag("verbose",
        abbr: "v",
        help: "Make the CLI a lot more verbose",
        defaultsTo: false,
        negatable: false)
    ..addCommand(GenerateCommand())
    ..addCommand(VerifyCommand());

  await runner.run(arguments).catchError((error) {
    if (error is! UsageException) throw error;
    exit(64); // Exit code 64 indicates a usage error.
  });
}
