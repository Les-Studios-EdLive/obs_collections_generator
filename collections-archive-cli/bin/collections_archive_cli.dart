import 'dart:io';
import 'package:args/args.dart';
import 'package:collections_archive_cli/collections_archive_cli.dart';
import 'package:collections_archive_cli/model/collection_configuration.dart';
import 'package:collections_archive_cli/model/configuration.dart';
import 'package:yaml/yaml.dart';

const outputDirectoryPath = "output";

void main(List<String> arguments) async {
  var parser = ArgParser();

  parser
    ..addFlag("verbose", abbr: "v", help: "Make the CLI a lot more talkative")
    ..addFlag("ignore-missing-files",
        abbr: "i",
        help:
            "By default when a file is missing in a collection the folder will not be zip, by using this flag all the folders will be zipped.")
    ..addOption("output",
        abbr: "o",
        aliases: ["output-dir"],
        help: "Where the collections will be built then zipped",
        defaultsTo: "output")
    ..addOption("config",
        abbr: "c",
        aliases: ["configuration-file", "config-file"],
        help:
            "Yaml configuration file path. This file contains the collections configuration, please refer to the README of the CLI for more information.",
        callback: (String? path) {
      if (path == null || !path.contains(RegExp(r'.(yaml|yml){1}$'))) {
        stderr.writeln("The configuration file need to be a YAML file");
        exit(2);
      } else if (!File(path).existsSync()) {
        stderr.writeln("Configuration file not found at $path.");
        exit(2);
      }
    }, mandatory: true)
    ..addOption("shared-dir-path",
        aliases: ["shared-dir"],
        help:
            "Path to the directory who contains the files shared between multiple collections",
        defaultsTo: "./shared", callback: (String? path) {
      if (path != null && !Directory(path).existsSync()) {
        stderr.writeln("Shared folder not found at $path.");
        exit(2);
      }
    })
    ..addOption("collections-dir-path",
        aliases: ["collections-dir"],
        help:
            "Path to the directory who contains the files specific to each collections",
        defaultsTo: "./collections", callback: (String? path) {
      if (path != null && !Directory(path).existsSync()) {
        stderr.writeln("Collections folder not found at $path.");
        exit(2);
      }
    });

  try {
    final parsedArgs = parser.parse(arguments);

    final verbose = parsedArgs["verbose"];
    final configFile = File(parsedArgs["config"]);

    // Load configuration file
    Configuration configuration =
    Configuration.fromYaml(loadYaml(configFile.readAsStringSync()));
    // If verbose
    if (verbose) {
      stdout.writeln(
          "Configuration file loaded, version: ${configuration.version}");
    }

    // Check folder architecture

    // Build collections scenes
    stdout.writeln("Processing collections...");
    for (CollectionConfiguration collection in configuration.collections) {
      processCollection(collection,
          sharedAssetsPath: parsedArgs["shared-dir-path"],
          collectionsPath: parsedArgs["collections-dir-path"],
          outputDirectoryPath: parsedArgs["output"],
          verbose: verbose);
    }

    stdout.writeln("Processing finished. Output is available at: ${parsedArgs["output"]}");

    exitCode = 0;
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    exit(2);
  }
}
