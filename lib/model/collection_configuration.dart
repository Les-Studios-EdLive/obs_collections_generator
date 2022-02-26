import 'dart:io';

import 'package:obs_collections_generator/utils.dart';
import 'package:yaml/yaml.dart';

class CollectionConfiguration {
  /// Name of the collection
  final String name;

  /// List of all the camera supported for this collection.
  final List<String> cameras;

  /// List of all the OS supported for this collection.
  final List<String> os;

  /// List of all the language supported for the collection.
  /// The language are supposed to be in this form: shortCodeLanguage_shortCodeCountry
  /// e.g.: fr_CA for canadian french
  final List<String> languageSupported;

  /// List of the shared assets used as backgrounds in the collection
  final List<String> backgrounds;

  /// List of the shared audio files used in the collection
  final List<String> audios;

  /// List of the shared stingers files used in the collection
  final List<String> stingers;

  CollectionConfiguration(
      {required this.name,
      required this.cameras,
      required this.os,
      required this.languageSupported,
      this.backgrounds = const [],
      this.audios = const [],
      this.stingers = const []});

  /// Generate the list of all the files needed for each variant of the collection
  /// The key is the destination path of the file while the value is the
  /// source path of the file.
  Map<String, String> getFilesList(
      String sharedAssetsPath, String collectionsPath, String version) {
    final Map<String, String> files = {};

    for (String currentOs in os) {
      for (String camera in cameras) {
        for (String language in languageSupported) {
          String baseOutputPath = "${name}_${currentOs}_${camera}_$language";
          String baseAssetsOutputPath = "$baseOutputPath/assets";

          // Add collection file
          files.putIfAbsent(
              "$baseOutputPath/${name}_${language}_v$version.json",
              () =>
                  "$collectionsPath/$name/$currentOs/$camera/${name}_$language.json");

          // Add colorimetry
          files.putIfAbsent("$baseAssetsOutputPath/colorimetry/LUT.png",
              () => "$sharedAssetsPath/colorimetry/$camera/$currentOs/LUT.png");

          // Add backgrounds files
          if (backgrounds.isNotEmpty) {
            for (String background in backgrounds) {
              files.putIfAbsent("$baseAssetsOutputPath/backgrounds/$background",
                  () => "$sharedAssetsPath/backgrounds/$background");
            }
          }

          // Add audio files
          if (audios.isNotEmpty) {
            for (String audio in audios) {
              files.putIfAbsent("$baseAssetsOutputPath/audios/$audio",
                  () => "$sharedAssetsPath/audios/$audio");
            }
          }

          // Add Stinger files
          if (stingers.isNotEmpty) {
            for (String stinger in stingers) {
              files.putIfAbsent("$baseAssetsOutputPath/stingers/$stinger",
                  () => "$sharedAssetsPath/stingers/$stinger");
            }
          }

          final collectionSharedAssetsDirectory =
              Directory("$collectionsPath/$name/shared");
          if (collectionSharedAssetsDirectory.existsSync()) {
            for (FileSystemEntity entity
                in collectionSharedAssetsDirectory.listSync(recursive: true)) {
              if (entity is File) {
                if (entity.path.contains(RegExp(languageCodeFileRegexp)) &&
                    entity.path
                        .contains(RegExp(language + r'.[a-zA-Z0-9]+$'))) {
                  files.putIfAbsent(
                      "$baseAssetsOutputPath${entity.path.substring(collectionSharedAssetsDirectory.path.length).replaceFirst(RegExp(languageCodeFileRegexp), '')}",
                      () => entity.path);
                }
              }
            }
          }
        }
      }
    }

    return files;
  }

  /// Get the names of each variant for this collection.
  List<String> getListVariant() {
    final List<String> variants = [];

    for (String currentOs in os) {
      for (String camera in cameras) {
        for (String language in languageSupported) {
          variants.add("${name}_${currentOs}_${camera}_$language");
        }
      }
    }

    return variants;
  }

  factory CollectionConfiguration.fromYaml(
          String name, YamlMap map) =>
      CollectionConfiguration(
          name: name,
          cameras:
              (map['cameras']
                      as YamlList)
                  .map<String>((element) => element)
                  .toList(growable: false),
          os:
              (map['os'] as YamlList).map<String>((element) => element).toList(
                  growable: false),
          languageSupported: (map['langs'] as YamlList)
              .map<String>((element) => element)
              .toList(growable: false),
          backgrounds: (map['backgrounds'] as YamlList)
              .map<String>((element) => element)
              .toList(growable: false),
          audios: (map['audios'] as YamlList)
              .map<String>((element) => element)
              .toList(growable: false),
          stingers: (map['stingers'] as YamlList)
              .map<String>((element) => element)
              .toList(growable: false));
}
