import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:collections_archive_cli/model/collection_configuration.dart';

const missingFilesTag = "MISSING_FILES";
const missingFilesFileName = "missing_files";

void processCollection(CollectionConfiguration collection,
    {required String sharedAssetsPath,
    required String collectionsPath,
    required String outputDirectoryPath,
    bool dryRun = false,
    bool verbose = false}) {
  stdout.writeln("Building ${collection.name} collection files...");

  final outputDirectory = Directory(outputDirectoryPath);
  final listFiles = collection.getFilesList(sharedAssetsPath, collectionsPath);

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

/// Archiving the [directoryToArchive].
void archive(Directory directoryToArchive,
    [bool ignoreMissingFiles = false, bool verbose = false]) {
  final ZipFileEncoder encoder = ZipFileEncoder();
  final explodedPath = directoryToArchive.path.split("/");
  final folderName = explodedPath.last;

  if (folderName.contains(RegExp(r"^" + missingFilesTag)) &&
      !ignoreMissingFiles) {
    if (verbose) {
      stdout.writeln(
          "Skipping ${folderName.substring(missingFilesTag.length + 1)} folder because some files are missing...");
    }
  } else {
    if (verbose) {
      stdout.writeln("Archiving $folderName folder...");
    }
    encoder.zipDirectory(directoryToArchive);

    if (verbose) {
      stdout.writeln("Archive finished, deleting $folderName folder...");
    }
    // Delete the Zipped directory
    directoryToArchive.deleteSync(recursive: true);
  }
}
