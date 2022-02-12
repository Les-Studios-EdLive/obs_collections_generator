import 'package:collections_archive_cli/model/collection_configuration.dart';
import 'package:yaml/yaml.dart';

class Configuration {
  /// Current version of the file
  final String version;

  /// List of all the camera supported.
  final List<String> cameras;

  ///
  final List<CollectionConfiguration> collections;

  Configuration(
      {required this.version,
      required this.cameras,
      required this.collections});

  factory Configuration.fromYaml(YamlMap map) => Configuration(
      version: map['version'] as String,
      cameras: (map['cameras'] as YamlList).map<String>((element) => element).toList(growable: false),
      collections: (map['collections'] as YamlMap)
          .entries
          .map((e) => CollectionConfiguration.fromYaml(
              e.key, e.value))
          .toList(growable: false));
}
