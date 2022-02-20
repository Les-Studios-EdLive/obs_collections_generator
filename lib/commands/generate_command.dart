import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:obs_collections_generator/obs_collections_generator.dart';
import 'package:obs_collections_generator/model/collection_configuration.dart';
import 'package:obs_collections_generator/model/configuration.dart';
import 'package:yaml/yaml.dart';

class GenerateCommand extends Command {
  @override
  final name = "generate";

  @override
  final description =
      "Generate all the OBS collection variant and zip them all";

  GenerateCommand() {
    argParser
      ..addFlag("ignore-missing-files",
          abbr: "i",
          negatable: false,
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
          exit(64);
        } else if (!File(path).existsSync()) {
          stderr.writeln("Configuration file not found at $path.");
          exit(64);
        }
      }, mandatory: true)
      ..addOption("shared-dir-path",
          aliases: ["shared-dir"],
          help:
              "Path to the directory who contains the files shared between multiple collections",
          defaultsTo: "./shared", callback: (String? path) {
        if (path != null && !Directory(path).existsSync()) {
          stderr.writeln("Shared folder not found at $path.");
          exit(64);
        }
      })
      ..addOption("collections-dir-path",
          aliases: ["collections-dir"],
          help:
              "Path to the directory who contains the files specific to each collections",
          defaultsTo: "./collections", callback: (String? path) {
        if (path != null && !Directory(path).existsSync()) {
          stderr.writeln("Collections folder not found at $path.");
          exit(64);
        }
      });
  }

  @override
  void run() {
    final verbose = globalResults!["verbose"];
    final configFile = File(argResults!["config"]);

    // Load configuration file
    Configuration configuration =
        Configuration.fromYaml(loadYaml(configFile.readAsStringSync()));
    // If verbose
    if (verbose) {
      stdout.writeln(
          "Configuration file loaded, version: ${configuration.version}");
    }

    // Build collections scenes
    stdout.writeln("Processing collections...");
    for (CollectionConfiguration collection in configuration.collections) {
      processCollection(collection,
          sharedAssetsPath: argResults!["shared-dir-path"],
          collectionsPath: argResults!["collections-dir-path"],
          outputDirectoryPath: argResults!["output"],
          verbose: verbose);
    }

    stdout.writeln(
        "Processing finished. Output is available at: ${argResults!["output"]}");
    exit(0);
  }

  void processCollection(CollectionConfiguration collection,
      {required String sharedAssetsPath,
      required String collectionsPath,
      required String outputDirectoryPath,
      bool dryRun = false,
      bool verbose = false}) {
    stdout.writeln("Building ${collection.name} collection files...");

    final outputDirectory = Directory(outputDirectoryPath);
    final listFiles =
        collection.getFilesList(sharedAssetsPath, collectionsPath);

    // Create missing files text file.
    final missingFilesByFolders =
        copyFiles(listFiles, outputDirectory.path, verbose);
    File file;

    missingFilesByFolders.forEach((folderName, missingFiles) {
      file =
          File("${outputDirectory.path}/$folderName/$missingFilesFileName.txt");
      for (String missingFilePath in missingFiles) {
        file.writeAsStringSync(missingFilePath + "\n", mode: FileMode.append);
      }
      file.parent
          .renameSync("${outputDirectory.path}/${missingFilesTag}_$folderName");
    });

    // Archive collections
    stdout.writeln("Start archiving ${collection.name} folders...");
    for (FileSystemEntity entity
        in outputDirectory.listSync(followLinks: false)) {
      if (entity is Directory) {
        archive(entity, dryRun, verbose);
      }
    }
  }

  /// Copying [files] from point A to point B in the [outputDirectory].
  /// The key to files should be the destination path while the value is the
  /// source file path
  Map<String, List<String>> copyFiles(
      Map<String, String> files, String outputDirectory,
      [bool verbose = false]) {
    File fileSource;
    File fileDestination;

    Map<String, List<String>> missingFiles = {};

    files.forEach((fileDestinationPath, fileSourcePath) {
      fileSource = File(fileSourcePath);

      if (fileSource.existsSync()) {
        if (verbose) {
          stdout.writeln(
              "Copying $fileSourcePath to $outputDirectory/$fileDestinationPath...");
        }
        fileDestination = File("$outputDirectory/$fileDestinationPath");
        fileDestination.createSync(recursive: true);
        fileSource.copySync(fileDestination.path);
      } else {
        stderr.writeln("Missing $fileSourcePath file.");
        missingFiles.update(fileDestinationPath.split("/")[0], (value) {
          value.add(fileSourcePath);
          return value;
        }, ifAbsent: () => [fileSourcePath]);
      }
    });

    return missingFiles;
  }
}
