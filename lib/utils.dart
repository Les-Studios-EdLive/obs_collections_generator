/// RegExp for gitKeep files
final gitKeepRegExp = RegExp(r'\.gitKeep|.gitkeep$');

/// RegExp for the colorimetry path directory.
final colorimetryPathConvention = r'\/colorimetry\/';

/// RegExp for the LUT files.
final lutFilepathConvention =
    RegExp(r'colorimetry\/[a-zA-Z0-9_\-]+\/(windows|macos|linux)\/LUT.png$');

/// RegExp for the LUT files.
final sharedFilepathConvention = RegExp(
    r'.+\/.+(' + languageCodeRegExp + r')?(' + fileExtensionRegExp + r')?$');

/// RegExp of a file that end with a language code (e.g.: _fr_FR.json)
final languageCodeFileRegexp =
    r'_' + languageCodeRegExp + fileExtensionRegExp + r'$';

final languageCodeRegExp = r'[a-z]{2}_[A-Z]{2}';

final fileExtensionRegExp = r'\.[a-zA-Z0-9]+';
