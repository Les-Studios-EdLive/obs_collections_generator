import 'dart:io';
import 'package:args/args.dart';
import 'package:args/command_runner.dart';
import 'package:collections_archive_cli/collections_archive_cli.dart';
import 'package:collections_archive_cli/commands/generate_command.dart';
import 'package:collections_archive_cli/model/collection_configuration.dart';
import 'package:collections_archive_cli/model/configuration.dart';
import 'package:yaml/yaml.dart';

const outputDirectoryPath = "output";

void main(List<String> arguments) async {
  var runner = CommandRunner(
      "obs_collections_generator", "Add a description here please");

  runner.addCommand(GenerateCommand());
  runner.argParser
      .addFlag("verbose", abbr: "v", help: "Make the CLI a lot more verbose", negatable: false);

  runner.run(arguments);
}
