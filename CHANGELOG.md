# Changelog

All notable changes to Poltergæist are listed here. The format follows
[Keep a Changelog](https://keepachangelog.com), and versions follow
[Semantic Versioning](https://semver.org).

## [1.0.0] - 2026-10-27

First public release.

### Added
- Typed whispers when you pause typing, written by a local model through Ollama
  (with a built-in fallback list), then erased.
- A one-hour slow burn on an eased curve that stays at its peak until the
  program ends: ghost text, breathing, cursor shake, footsteps, screen dimming
  and a heartbeat, each growing stronger as dread rises.
- A flashbang with a synthesized ringing sound at random times, independent of
  dread and elapsed time.
- Effects on every monitor, and a sound mixer so effects never cut each other off.
- No pause option. It starts at sign-in, and stops with Task Manager, a restart
  (the hour begins over) or uninstalling. Esc dismisses effects and Ctrl+Alt+Q
  is an emergency exit.
- System tray icon with an About popup showing the mascot, Poltergæist-chan.
- Windows installer (with an optional start-up entry and a clean uninstaller)
  and a portable zip, both built by GitHub Actions.
- `--preview`, `--demo` and `--selftest` modes.
