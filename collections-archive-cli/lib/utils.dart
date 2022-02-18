/// RegExp for gitKeep files
final gitKeepRegExp =
RegExp(r'\.gitKeep|.gitkeep$');

/// RegExp for the colorimetry path directory.
final colorimetryPathConvention =
    RegExp(r'\/colorimetry\/');

/// RegExp for the LUT files.
final lutFilepathConvention =
    RegExp(r'colorimetry\/[a-zA-Z0-9_\-]+\/(windows|macos|linux)\/LUT.png$');

/// RegExp for the LUT files.
final sharedFilepathConvention =
    RegExp(r'.+\/.+(_[a-z]{2}_[A-Z]{2})?(\.[a-zA-Z0-9]+)?$');

final collectionRootPathConvention =
    RegExp(r'[a-zA-Z0-9_\-]+\/(windows|macos|linux|shared)');

/// RegExp of a file that end with a language code (e.g.: _fr_FR.json)
final languageCodeFileRegexp = RegExp(r'_[a-z]{2}_[A-Z]{2}\.[a-zA-Z0-9]+$');
