# EdLive Collections

![GitHub release (latest by date)](https://img.shields.io/github/v/release/Les-Studios-EdLive/obs_collections_generator?label=Latest%20version)

## Introduction



## Getting started

### Folder architecture

Here is the folder architecture of this repository.
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

### CLI usage 

Under the ``cli-compiled`` folder you can find the 
