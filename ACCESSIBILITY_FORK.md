# Accessibility-first distribution fork

`distro/accessibility-first` is a separate distribution-focused branch of Eternal
Thread. Its purpose is to make the Windows package easier to understand and use for
people who do not want to navigate a developer-oriented source tree.

## What this fork changes

The Windows build places only the application, a plain-language start guide, and an
optional configuration template at the package top level. Supporting materials are
grouped once, at a shallow depth:

```text
EternalThread/
├── EternalThread.exe
├── START_HERE.txt
├── .env.example
├── Documentation/
├── Tools/
└── Licences_and_Notices/
```

`START_HERE.txt` is the first document a non-technical user should open. It explains
what the package does, where to find help, why the folder should stay together, and
what is intentionally not included.

`Tools/` contains only optional, inspectable user helpers. In this fork it contains
the PowerShell GUI-preference helper; it is separate from both the application and
the documentation so a user never needs to run it to start the app.

## What this fork does not change

This is a packaging and usability fork, not a claim of new model capability. It does
not bundle or install an inference runtime, download models, choose a cloud backend,
change consent defaults, move user data into the package, or make a Windows build
universal across devices.

The developer-oriented source layout remains intact for maintainers. The simpler
layout is created only in the Windows distribution folder after the build completes.

## Optional visual preferences

`tools/Set-EternalThreadGuiPreferences.ps1` writes a local, non-secret preference
file for the desktop application. It can set a light, dark, system, or high-contrast
theme; a bounded text scale; and an opening-window size. It uses PowerShell's
`-WhatIf` support and does not edit source files, `.env`, runtime/model settings,
Git repositories, or Windows-wide accessibility settings.

This fork is source-only until a maintainer deliberately validates and releases a
separate build. It does not create a tag, ZIP, executable, checksum, or hosted
release by itself.
