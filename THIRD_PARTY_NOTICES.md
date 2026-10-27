# Third-party notices

Poltergæist is released under the MIT License (see `LICENSE`). It is built on
the open-source components below, each under its own license. Please check each
project for the current license text before you redistribute a build.

## Libraries bundled in the packaged app

| Component | Used for | License |
|---|---|---|
| [pynput](https://github.com/moses-palmer/pynput) | keyboard listener, typing, mouse | LGPL-3.0 |
| [pystray](https://github.com/moses-palmer/pystray) | system tray icon | LGPL-3.0 |
| [sounddevice](https://github.com/spatialaudio/python-sounddevice) (with PortAudio) | audio output | MIT |
| [NumPy](https://numpy.org) | synthesizing sounds | BSD-3-Clause |
| [Pillow](https://python-pillow.org) | drawing the tray and app icon | MIT-CMU (HPND) |
| [Python](https://www.python.org) and Tk | runtime, overlay windows | PSF License |

pynput and pystray are LGPL libraries. Poltergæist uses them unmodified, and
the complete source for this project is public, so anyone can rebuild the app
with a modified version of either library using `build.bat`.

## Build tools (not part of the app)

| Component | Used for | License |
|---|---|---|
| [PyInstaller](https://pyinstaller.org) | building the Windows app | GPL-2.0-or-later with an exception that allows the apps it builds to use any license |
| [Inno Setup](https://jrsoftware.org/isinfo.php) | building the installer | Inno Setup License (free to use) |

## Runtime services and models (installed separately, not bundled)

| Component | Used for | License |
|---|---|---|
| [Ollama](https://ollama.com) | running models locally | MIT |
| The language model you choose | writing the whispers | Varies by model |

The default model, `llama3.2:3b`, is released by Meta under the Llama 3.2
Community License, which is an open-weight license with its own terms (it is
not an OSI-approved open-source license). If you want a fully open-source
license for the whole stack, pick a model released under Apache-2.0 or MIT, set
it as `model` in `config.json`, and check its license page first.

All sounds are synthesized at runtime. No third-party audio, images or game
assets are included.
