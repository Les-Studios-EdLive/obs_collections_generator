import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:collections_archive_cli/model/collection_configuration.dart';
import 'package:collections_archive_cli/model/configuration.dart';
import 'package:yaml/yaml.dart';

import '../utils.dart';

class VerifyCommand extends Command {
  @override
  final name = "verify";

  @override
  final description =
      "Verify every files and the specified configuration file. "
      "This will check the name, path and position of every files used by any"
      "collection specified in the configuration file";

  VerifyCommand() {
    argParser
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
          defaultsTo: "./shared")
      ..addOption("collections-dir-path",
          aliases: ["collections-dir"],
          help:
              "Path to the directory who contains the files specific to each collections",
          defaultsTo: "./collections");
  }

  @override
  void run() {
    final verbose = globalResults!["verbose"];
    final configFile = File(argResults!["config"]);

    // Load configuration file
    Configuration configuration =
        Configuration.fromYaml(loadYaml(configFile.readAsStringSync()));

    if (verbose) {
      stdout.writeln(
          "Configuration file loaded, version: ${configuration.version}");
    }

    final sharedDirectory = Directory(argResults!["shared-dir-path"]);
    final collectionsDirectory = Directory(argResults!["collections-dir-path"]);

    // Check if shared and collection directories exists
    if (!sharedDirectory.existsSync()) {
      stderr.writeln("Shared directory not found or doesn't exists");
      exit(2);
    }
    if (!collectionsDirectory.existsSync()) {
      stderr.writeln("Collections directory not found or doesn't exists");
      exit(2);
    }

    final Map<String, String> errorFiles = {};

    // Check the shared and collections directories integrity
    errorFiles
        .addAll(_validateFilesName(sharedDirectory, collectionsDirectory));

    final List<String> filesToCheck = [];

    // Check that every variant of collections as all its files
    for (CollectionConfiguration collection in configuration.collections) {
      filesToCheck.addAll(collection
          .getFilesList(sharedDirectory.path, collectionsDirectory.path)
          .values);
    }

    errorFiles.addAll(
        {for (var e in _checkFilesExists(filesToCheck)) e: "Missing file"});

    if (errorFiles.isNotEmpty) {
      stderr.writeln("Error found:");

      errorFiles.forEach((key, value) {
        stderr.writeln("$key - Error: $value");
      });
      exit(2);
    }
    exit(0);
  }

  /// Check the name of every files in [sharedDirectory] and [collectionsDirectory]
  /// then give back a map of all the files wrongly named.
  /// The key is the file path that has the bad name and the value is the name
  /// expected.
  Map<String, String> _validateFilesName(
      Directory sharedDirectory, Directory collectionsDirectory) {
    final Map<String, String> wrongFiles = {};
    File tmp;

    for (FileSystemEntity entity in sharedDirectory.listSync(recursive: true)) {
      if (entity is File) {
        tmp = entity;

        if (tmp.path.contains(gitKeepRegExp)) {
          continue;
        }

        if (tmp.path.contains(colorimetryPathConvention) &&
            !tmp.path.contains(lutFilepathConvention)) {
          wrongFiles.putIfAbsent(
              tmp.path,
              () =>
                  'LUT file should follow: "colorimetry/<camera_name>/<os_name>/LUT.png"');
        } else if (!tmp.path.contains(sharedFilepathConvention)) {
          wrongFiles.putIfAbsent(
              tmp.path,
              () =>
                  'Shared file should follow the following pattern: "<folder_name>/<file_name>.<extension>" (example: stinger/transition.webm)');
        } else if (tmp.path.contains(languageCodeFileRegexp)) {
          wrongFiles.putIfAbsent(
              tmp.path, () => 'Shared file should not be localized.');
        }
      }
    }

    // TODO check collections directory

    return wrongFiles;
  }

  /// Verify that every single [files] exists.
  List<String> _checkFilesExists(List<String> files) {
    final List<String> missingFiles = [];

    File file;

    for (String filePath in files) {
      file = File(filePath);

      if (!file.existsSync() && !missingFiles.contains(filePath)) {
        missingFiles.add(filePath);
      }
    }

    return missingFiles;
  }
}
