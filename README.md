# EdLive Collections

![GitHub release (latest by date)](https://img.shields.io/github/v/release/Les-Studios-EdLive/obs_collections_generator?label=Latest%20version)

## Introduction

This project is a CLI (Command Line Interface) used to easily assemble the assets of a OBS collections. 
The goal was to facilitate the creation of multiple OBS collections for multiple language and multiple camera. 
This CLI is built for Windows, Mac and Linux, please use the `help` command to see the usage of the CLI.

## Getting started

### Folder architecture used to generate the collections

```
├── config.yml
├── collections
│   └── <collection_name>
│       ├── shared
│       ├── linux
│       ├── macos
│       └── windows
│           └── <camera_name>
│               └── <collection_name>_<lang_code>_<country_code>.json
└── shared
    ├── backgrounds
    │   └── <generic_background>.<extension>
    ├── colorimetry
    │   └── <camera_name>
    │       ├── macos
    │       └── windows
    │           └── LUT_file.png
    ├── audios
    │   └── <generic_music>.mp3
    └── stingers
        └── <generic_stinger>.<extension>
```

The `config.yml` file contains the configuration of every collection offered in this repository. The usage of this file
will be explained later in the README.

Under the `collections` folder are stored one folder by collection offered in the repository. Under this folder
you should find one folder by collection we offer, each collection folder contains one folder.

Please follow these naming rules:

- if the file (image, video, collection, etc.) contains localized text (text in a specific language), the naming convention is:
  - ``<name>_<language_short_code>_<country_code>.<extension>`` for example: `blue_background_fr_CA.jpg`

#### config.yaml

Here is an example of config.yaml

```yaml
# Semantic version
version: 0.2.6
# Each camera supported. This name represents the camera and the folder associated with it.
# Be aware, a camera name should not contain any underscore (_) or hyphen (-).
cameras:
 - v180 # Panasonics v180
# Each collection available, these names are associated with a folder inside the 'collections' folder.
# This is used to build the archive with the complete OBS collections. The options available are:
# - 'cameras': REQUIRED every camera available for the collection, should contain a list of camera name or shortname (e.g.: t71)
# - 'langs': REQUIRED every language available for the collection, should contain a list of l10n code (e.g.: fr_CA)
# - 'os': REQUIRED every OS available for the collection, should contain a list of OS name between: macos, windows or linux
# - 'backgrounds': list of every backgrounds used in the collection.
# - 'musics': list of all the audio files used in the collection.
# - 'stingers': list of all the video files used as stingers in the collection.
collections:
 default:
  cameras:
   - v180
  langs:
   - fr_CA
   - en_CA
  os:
   - macos
   - windows
  backgrounds:
   - Hexagons.mp4
  audios:
   - Generic.mp3
  stingers:
   - Stinger - Balayage Oblique.webm
   - Stinger - Balayage Vertical.webm
```
