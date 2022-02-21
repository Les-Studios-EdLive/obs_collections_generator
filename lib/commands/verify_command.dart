import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:obs_collections_generator/model/collection_configuration.dart';
import 'package:obs_collections_generator/model/configuration.dart';
import 'package:obs_collections_generator/utils.dart';
import 'package:yaml/yaml.dart';

class VerifyCommand extends Command {
  @override
  final name = "verify";

  @override
  final description =
      "Verify every files and the specified configuration file. "
      "This will check the name, path and position of every files used by any"
      "collection specified in the configuration file";

  bool _verbose = false;

  late Configuration _configuration;

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
          defaultsTo: "./shared")
      ..addOption("collections-dir-path",
          aliases: ["collections-dir"],
          help:
              "Path to the directory who contains the files specific to each collections",
          defaultsTo: "./collections")
      ..addOption("output",
          abbr: "o",
          help:
              "Path to the output directory which will contains a text file with the list of error");
  }

  @override
  void run() {
    _verbose = globalResults!["verbose"];
    final configFile = File(argResults!["config"]);
    File? output;

    // Load configuration file
    _configuration =
        Configuration.fromYaml(loadYaml(configFile.readAsStringSync()));

    if (_verbose) {
      stdout.writeln(
          "Configuration file loaded, version: ${_configuration.version}");
    }

    final sharedDirectory = Directory(argResults!["shared-dir-path"]);
    final collectionsDirectory = Directory(argResults!["collections-dir-path"]);

    // Check if shared and collection directories exists
    if (!sharedDirectory.existsSync()) {
      stderr.writeln("Shared directory not found or doesn't exists");
      exit(64);
    }
    if (!collectionsDirectory.existsSync()) {
      stderr.writeln("Collections directory not found or doesn't exists");
      exit(64);
    }

    if (argResults!.wasParsed('output')) {
      final String outputDir = argResults!["output"];

      if (outputDir.contains(RegExp(fileExtensionRegExp))) {
        stderr.writeln("Output should be a directory not a file.");
        exit(64);
      }
      output = File("$outputDir/errors.yml");
    }

    // Check the shared directory and the collections directory integrity
    final Map<String, String> sharedErrors =
        _validateSharedDirectory(sharedDirectory);
    final Map<String, String> collectionsErrors = _validateCollectionsDirectory(
        collectionsDirectory, _configuration.collections);

    stdout.writeln("Searching for missing files...");
    final List<String> filesToCheck = [];

    // Check that every variant of collections as all its files
    for (CollectionConfiguration collection in _configuration.collections) {
      filesToCheck.addAll(collection
          .getFilesList(sharedDirectory.path, collectionsDirectory.path)
          .values);
    }

    final List<String> missingFiles = _checkFilesExists(filesToCheck);

    stdout.writeln("Verification finished!");

    if (sharedErrors.isNotEmpty) {
      stderr.writeln("\n\nShared directory errors and warnings:");

      sharedErrors.forEach((key, value) {
        stderr.writeln("  - $key - $value");
      });

      if (output != null) {
        output.writeAsStringSync("Shared directory errors and warnings:",
            mode: FileMode.write);
        sharedErrors.forEach((key, value) {
          output!.writeAsStringSync("\n- file: $key\n  description: \"$value\"",
              mode: FileMode.writeOnlyAppend);
        });
      }
    }

    if (collectionsErrors.isNotEmpty) {
      stderr.writeln("\nCollections directory errors and warnings:");

      collectionsErrors.forEach((key, value) {
        stderr.writeln("  - $key - $value");
      });

      if (output != null) {
        output.writeAsStringSync("\nCollections directory errors and warnings:",
            mode: FileMode.writeOnlyAppend);
        collectionsErrors.forEach((key, value) {
          output!.writeAsStringSync("\n- file: $key\n  description: \"$value\"",
              mode: FileMode.writeOnlyAppend);
        });
      }
    }

    if (missingFiles.isNotEmpty) {
      stderr.writeln("\nMissing files:");

      if (output != null) {
        output.writeAsStringSync("\nMissing files:",
            mode: FileMode.writeOnlyAppend);
      }

      for (var value in missingFiles) {
        stderr.writeln("  - $value");
        if (output != null) {
          output.writeAsStringSync("\n- \"$value\"",
              mode: FileMode.writeOnlyAppend);
        }
      }
    }

    if (sharedErrors.isNotEmpty ||
        collectionsErrors.isNotEmpty ||
        missingFiles.isNotEmpty) {
      exit(2);
    }

    stdout.writeln("No errors or warnings found");
    exit(0);
  }

  /// Check the name of every files in [sharedDirectory]
  /// then give back a map of all the files wrongly named.
  /// The key is the file path that has the bad name and the value is the name
  /// expected.
  Map<String, String> _validateSharedDirectory(Directory sharedDirectory) {
    final Map<String, String> wrongFiles = {};
    final List<String> processedFiles = [];

    bool added;

    stdout.writeln("Processing shared directory...");

    /// Testing colorimetry directory
    Directory colorimetryDir =
        Directory("${sharedDirectory.path}/${colorimetryPathConvention.replaceAll(RegExp(r'[/\\]'), '')}");

    if (_checkExists(
        entity: colorimetryDir,
        errorKey: colorimetryDir.path,
        currentErrors: wrongFiles)) {
      final cameras = List.from(_configuration.cameras);
      for (FileSystemEntity entity in colorimetryDir.listSync()) {
        if (entity is Directory) {
          final folderName = entity.path.split('/').last;
          if (!cameras.contains(folderName)) {
            wrongFiles.putIfAbsent(
                entity.path,
                () =>
                    "WARNING - Camera not referenced in the configuration file.");
          } else {
            cameras.remove(folderName);
          }
        }
      }
    }

    for (FileSystemEntity entity in sharedDirectory.listSync(recursive: true)) {
      if (entity is File) {
        if (processedFiles.contains(entity.path)) {
          if (_verbose) {
            stdout.writeln("Skipping ${entity.path} because already processed");
          }
          continue;
        }
        added = false;

        if (entity.path.contains(gitKeepRegExp)) {
          if (_verbose) {
            stdout.writeln("Skipping .gitKeep ${entity.path}");
          }
          continue;
        }

        if (_verbose) {
          stdout.writeln("Checking ${entity.path}...");
        }

        if (entity.path.contains(RegExp(colorimetryPathConvention)) &&
            !entity.path.contains(lutFilepathConvention)) {
          added = true;
          wrongFiles.putIfAbsent(
              entity.path,
              () =>
                  "LUT file should follow: 'colorimetry/<camera_name>/<os_name>/LUT.png'");
        } else if (!entity.path.contains(sharedFilepathConvention)) {
          added = true;
          wrongFiles.putIfAbsent(
              entity.path,
              () => "Shared file should follow the following pattern: "
                  "'<folder_name>/<file_name>.<extension>' (example: stinger/transition.webm)");
        } else if (entity.path.contains(languageCodeFileRegexp)) {
          added = true;
          wrongFiles.putIfAbsent(
              entity.path, () => 'Shared file should not be localized.');
        }

        if (_verbose && added) {
          stderr.writeln(
              "File: ${entity.path} Error: ${wrongFiles[entity.path]}");
        }

        processedFiles.add(entity.path);
      }
    }

    if (_verbose) {
      stdout.writeln("Processing of shared directory finished");
    }

    return wrongFiles;
  }

  /// Validate the [collectionsDirectory] for each [collectionConfigurations].
  /// Each warning or error are added in the returned map, the value being a
  /// description of the error/warning.
  Map<String, String> _validateCollectionsDirectory(
      Directory collectionsDirectory,
      List<CollectionConfiguration> collectionConfigurations) {
    final Map<String, String> errors = {};

    stdout.writeln("Processing collections directory...");

    final List<String> collectionNames = collectionConfigurations
        .map<String>((CollectionConfiguration e) => e.name)
        .toList();

    if (_verbose) {
      stdout.writeln("Validating root collections directories...");
    }

    // Retrieving directories of known collections.
    // Adding a warning for each unknown directories
    for (FileSystemEntity entity in collectionsDirectory.listSync()) {
      if (entity is Directory) {
        // Extract folder name.
        String folderName = entity.path.split('/').last;

        if (!collectionNames.contains(folderName)) {
          if (_verbose) {
            stdout.writeln(
                "WARNING - $folderName collection folder isn't referenced in "
                "the configuration file. (Directory location: ${entity.path})");
          }
          errors.putIfAbsent(
              entity.path,
              () =>
                  "WARNING - Collection $folderName not referenced in the configuration file");
        } else {
          if (_verbose) {
            stdout.writeln("Checking $folderName collection...");
          }
          errors.addAll(_validateCollectionDirectoryIntegrity(
              entity,
              collectionConfigurations
                  .singleWhere((element) => element.name == folderName)));
          collectionNames.remove(folderName);
        }
      }
    }

    for (String missingCollection in collectionNames) {
      if (_verbose) {
        stderr.writeln(
            "Collection directory for $missingCollection collection doesn't exists.");
      }
      errors.putIfAbsent(
          missingCollection,
          () =>
              "ERROR - Collection directory for this collection doesn't exists."
              " Should be ${collectionsDirectory.path}/$missingCollection");
    }

    return errors;
  }

  /// Validate the [directory] for a [configuration] of a collection.
  /// Each warning or error are added in the returned map, the value being a
  /// description of the error/warning.
  Map<String, String> _validateCollectionDirectoryIntegrity(
      Directory directory, CollectionConfiguration configuration) {
    final Map<String, String> errors = {};

    for (String os in configuration.os) {
      // Check existence of os folders
      if (!_checkExists(
          entity: Directory("${directory.path}/$os"),
          errorKey: "${directory.path}/$os",
          currentErrors: errors)) {
        continue;
      }

      // Check for each camera supported if the directory exists
      for (String camera in configuration.cameras) {
        if (!_checkExists(
            entity: Directory("${directory.path}/$os/$camera"),
            errorKey: "${directory.path}/$os/$camera",
            currentErrors: errors)) {
          continue;
        }

        // Check existence of collection file for each language
        for (String language in configuration.languageSupported) {
          _checkExists(
              entity: File(
                  "${directory.path}/$os/$camera/${configuration.name}_$language.json"),
              errorKey:
                  "${directory.path}/$os/$camera/${configuration.name}_$language.json",
              currentErrors: errors);
        }
      }
    }

    return errors;
  }

  bool _checkExists(
      {required FileSystemEntity entity,
      required String errorKey,
      required Map<String, String> currentErrors}) {
    bool exists = true;
    if (!entity.existsSync()) {
      exists = false;
      if (_verbose) {
        stderr.writeln(
            "$errorKey doesn't exists but should. Skipping further validation");
      }
      currentErrors.putIfAbsent(
          errorKey, () => "ERROR - ${entity.path} doesn't exists but should.");
    }

    return exists;
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
