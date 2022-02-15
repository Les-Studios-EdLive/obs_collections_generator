import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:args/args.dart';
import 'package:collections_archive_cli/model/collection_configuration.dart';
import 'package:yaml/yaml.dart';

import 'model/configuration.dart';

const missingFilesTag = "MISSING_FILES";
const missingFilesFileName = "missing_files";

/// Archiving the [directoryToArchive].
/// The folders archived will be named without any camera and OS name
/// (e.g. archive name: default_linux_v180_fr_CA, folder inside the archive: default_fr_CA)
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
    final directoryRenamed = directoryToArchive.renameSync(
        "${directoryToArchive.parent.parent.path}/${folderName.replaceFirst(RegExp(r'(windows|macos|linux)_'), "")}");
    encoder.zipDirectory(directoryRenamed, filename: folderName);

    if (verbose) {
      stdout.writeln("Archive finished, deleting $folderName folder...");
    }
    // Delete the Zipped directory
    directoryRenamed.deleteSync(recursive: true);
  }
}
