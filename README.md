# Poltergæist: a local-LLM ghost that haunts your PC

Poltergæist haunts your computer while you work. When you pause mid-sentence,
the ghost types a whisper into your window and erases it. In the background,
ghost text drifts across the screen, footsteps cross the room, the display
dims, and at random moments a flashbang goes off with a tinnitus ring.

The haunting builds for the first hour, then stays at its peak until you quit
the program or the PC shuts down.

The whispers are written by an open-weight model running locally through
[Ollama](https://ollama.com). No cloud, no API key, no internet required.

## Quick start (from source)

```bash
# 1. Install Ollama, then pull a small open-weight model
ollama pull llama3.2:3b

# 2. Install deps (Python 3.9+)
pip install -r requirements.txt

# 3. See what a long session looks like
python haunt.py --preview          # prints a session timeline, no effects
python haunt.py --demo             # time-lapse: the full hour in 2 minutes
python haunt.py                    # the real thing, real time
```

Ollama is optional. Without it the ghost uses a built-in list of whispers.

## Let GitHub build the .exe

No Python or Inno Setup needed on your PC. The workflow in
`.github/workflows/build.yml` builds everything on a Windows machine at GitHub.

1. Push this project to a GitHub repository (keep the `.github` folder).
2. Open the **Actions** tab. Every push to `main` builds the app. You can also
   press **Run workflow** to build on demand.
3. When the run finishes, download `Poltergaeist-windows` from the **Artifacts**
   section of the run. It contains `Poltergaeist-Setup.exe` (the installer) and
   `Poltergaeist-portable.zip` (unzip and run, no install).
4. To publish a proper download page, tag a version:

   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

   The workflow then attaches both files to a GitHub Release automatically.

Each build also runs a self-test on the built program (`--selftest`) and fails
if any component was not bundled, so a broken build never reaches you quietly.
The installer's version number comes from the tag.

## Or build it yourself (Windows)

1. Install Python 3.9+ (tick "Add python.exe to PATH") and
   [Inno Setup](https://jrsoftware.org/isinfo.php).
2. Double-click `build.bat`. This produces `dist\Poltergaeist\Poltergaeist.exe`.
3. Open `installer.iss` in Inno Setup and press Compile. This produces
   `installer_output\Poltergaeist-Setup.exe`, a normal installer with a Start
   menu entry, an optional desktop shortcut, a "start whenever I sign in to
   Windows" choice (ticked by default), and an uninstaller that removes
   everything.

If `build.bat` fails because of the special character in the folder name,
copy the project to a plain path such as `C:\poltergaeist` and build there.

Notes:

- The build is a folder rather than a single file on purpose. It starts faster
  and is flagged by antivirus far less often. A program that listens to the
  keyboard and types text can look suspicious to scanners, so if Windows
  SmartScreen or Defender complains about your own build, allow it.
- Ollama and its model are installed separately; they are not bundled.

## Project layout

```
poltergaeist/
  haunt.py                  the program
  assets/
    mascot_head.png         program icon and tray icon
    mascot_full.png         shown when you right-click the tray icon
    README.md               where the artwork came from, and its terms (free to use)
  make_icon.py              builds icon.ico from the head
  build.bat                 builds the Windows app
  installer.iss             Inno Setup script for the installer
  requirements.txt
  NOTICE.txt  LICENSE  THIRD_PARTY_NOTICES.md
  .github/workflows/build.yml   lets GitHub build the .exe
```

The `assets` folder must sit next to `haunt.py`; `build.bat` bundles it into the
app. Replace the two PNG files (keep the names) to change the mascot. Use
transparent backgrounds. The head should be roughly square.

## The mascot

The mascot's head is the program icon (taskbar, installer, Task Manager) and
the tray icon. Right-click the tray icon and a small popup appears with the
full-body mascot, a line of dialogue, and a credit that links to this
repository. Right-click again, press Esc, click the x, or click anywhere
outside to close it. The link target is `REPO_URL` near the top of `haunt.py`.

### About Poltergæist-chan

Poltergæist-chan was generated with an AI image generator. I chose to generate
her because I did not have the time or the funds to commission a proper mascot
for this project.

Because she was generated and not drawn by a human artist, nobody owns her, and
I do not claim copyright in her. You are free to use, modify, remix and
redistribute her, including commercially, with no permission needed. Credit is
appreciated but not required. To the extent any rights do exist, I dedicate them
to the public domain under
[CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/). (Whether AI
images can be copyrighted varies by country, so this is a statement of intent,
not legal advice.)

If I commission a mascot in the future, the copyright and license of the new
artwork would be different, and this section and `assets/README.md` would be
updated to say so.

## How the haunting works

It is a slow burn. A hidden dread level climbs from 0 to 1 over the first hour
(`ramp`) and then stays at 1 until you quit the program or the PC shuts down.
The climb is eased: quiet for a long while, then faster toward the end. Each
effect unlocks at a dread level, events come more often as dread rises, and
**every effect gets stronger as dread rises**.

| Effect                              | Unlocks at (default ramp) | How it grows                                                                               |
| ----------------------------------- | ------------------------- | ------------------------------------------------------------------------------------------ |
| Typed whisper when you pause        | immediately               | comes sooner after you pause; text from the local model gets darker                        |
| Ghost text drifts across the screen | about minute 13           | bigger, stays longer; up to 3 at once, on any monitor                                      |
| Breathing in the speakers           | about minute 17           | louder                                                                                     |
| Cursor shake                        | about minute 27           | from a faint tremor (about 14 px) to a convulsion (about 130 px), sometimes twice in a row |
| Footsteps                           | about minute 30           | louder                                                                                     |
| Screen dims, as if a cloud passed   | about minute 33           | from a slight shade to nearly dark, held longer, on every monitor                          |
| Heartbeat                           | about minute 38           | longer and faster                                                                          |

At the start an event arrives roughly every 9 minutes. At peak it is about
every 1.5 minutes. Sounds mix together, so a heartbeat never cuts off footsteps.

**The flashbang is separate.** It does not depend on dread or on how long the
program has been running. From the moment it starts, it goes off at random
intervals between `flash_min` and `flash_max` minutes (default 4 to 20), while
you are actively using the PC, on every monitor. A flash overrides any other
visual effect. Set `warn` to true for a 6 second heartbeat before each one.

The model's tone follows the dread level: friendly at first, then uneasy,
menacing, and finally urgent.

## Settings

On first run a settings file is created at
`%APPDATA%\Poltergaeist\config.json`. Edit it and restart the program. Command
line flags override it.

| Setting                  | Default     | Meaning                                           |
| ------------------------ | ----------- | ------------------------------------------------- |
| `ramp`                   | 60          | minutes until the haunting reaches its peak       |
| `flash_min`, `flash_max` | 4, 20       | random minutes between flashbangs                 |
| `volume`                 | 0.3         | sound volume, 0 to 0.8                            |
| `idle_min`, `idle_max`   | 4, 9        | seconds of pause before a typed whisper (at peak) |
| `model`                  | llama3.2:3b | any Ollama model                                  |
| `no_flash`               | false       | never flashbang                                   |
| `no_type`                | false       | no typed whispers                                 |
| `no_mouse`               | false       | no cursor shiver                                  |
| `no_tray`                | false       | no tray icon                                      |
| `warn`                   | false       | heartbeat before each flashbang                   |
| `eavesdrop`              | false       | ghost twists the last word you typed (RAM only)   |
| `panic_hotkey`           | true        | Ctrl+Alt+Q ends the program                       |

Extra command line options: `--demo`, `--timescale N`, `--preview [minutes]`,
`--seed N`.

## Seeing the long run without waiting

- `--preview [minutes]` simulates a session and prints every event with its
  timestamp and dread level, then totals. Add `--seed 7` to repeat a run.
- `--demo` runs time at 30x, so the full hour plays in 2 minutes, and events
  fire even if you are not typing. Every event is printed to the console with
  its dread level. The real thing is a much slower burn than the demo.

## Stopping it

There is no pause button, by design. The ways to stop it are:

- **End it in Task Manager.** Find `Poltergaeist.exe` and choose End task. It
  stays off until the next time you sign in.
- **Restart the PC.** It starts again at sign-in and the slow burn begins over
  from zero.
- **Uninstall it** from Windows "Installed apps". This removes it completely,
  including its start-up entry and its settings folder.

Two small extras: **Esc** dismisses any effect on screen, and **Ctrl+Alt+Q** is
an emergency exit that ends the program. If you do not want that one, set
`"panic_hotkey": false` in `config.json`.

The installer's "start whenever I sign in" option is ticked by default. Because
the program starts itself, it is always visible: the mascot's head sits in the
tray (right-click it to meet her), and the program is listed in Task Manager
and in Settings > Apps > Startup.

## Safety

- The flash is a single bright fade, no strobing, but it is still very bright.
  Do not run it near anyone with photosensitive epilepsy, and do not install it
  on a PC that someone else uses unless they agreed.
- Keep the volume low and do not use headphones.
- Only install it on your own machine. It is visible, listed in the usual
  places, and has a clean uninstaller. Keep it that way.
- Ghost text is erased after about 2 seconds, but do not run it over anything
  you cannot afford to have a stray character in.
- Logs are written to `%APPDATA%\Poltergaeist\poltergaeist.log` in the
  packaged app.

## Why open models matter here

- **Privacy:** `eavesdrop` reads your keystrokes. With a closed API that would
  mean shipping your typing to someone else's server; here it never leaves RAM
  on your machine.
- **Offline:** works with the Wi-Fi unplugged, so it can haunt on a train or
  in a cabin.
- **Swappable personality:** change `model`, the tone tiers or `PROMPT` to
  make it a Victorian ghost, a dead programming language, or a
  passive-aggressive coworker. Fine-tune it on your own ghost stories if you
  like.
- **Free:** zero per-call cost, so it can whisper all day.
- **No vendor kill switch:** it cannot be deprecated out from under you.

All sounds (heartbeat, breath, footsteps, the ring) are synthesized with
NumPy, so no copyrighted game audio is used.

## License

The code is released under the [MIT License](LICENSE). It builds on other
open-source components, listed with their licenses in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The language model you run has
its own license; check it before you redistribute anything.

The mascot artwork in `assets/` is not covered by the MIT License. It is
AI-generated and owned by no one; see [The mascot](#the-mascot) below and
[assets/README.md](assets/README.md).
