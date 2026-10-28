<p align="center">
  <img src="assets/mascot_head.png" alt="Poltergæist-chan's face" width="150">
</p>

<h1 align="center">Poltergæist</h1>

<p align="center">
  A cute ghost for your Windows PC, with a local open-weight AI at its core.<br>
  It builds slowly over the first hour, then stays at its peak until you stop it.
</p>

<p align="center">
  <a href="https://github.com/Brage1025/Poltergaeist/releases/latest"><b>Download the latest release</b></a>
  &nbsp;|&nbsp;
  <a href="#demo">Watch the demo</a>
  &nbsp;|&nbsp;
  <a href="#build-from-source">Build from source</a>
  &nbsp;|&nbsp;
  <a href="LICENSE">MIT License</a>
</p>

<p align="center">
  <a href="https://github.com/Brage1025/Poltergaeist/actions/workflows/build.yml"><img src="https://github.com/Brage1025/Poltergaeist/actions/workflows/build.yml/badge.svg" alt="Build status"></a>
  <a href="https://github.com/Brage1025/Poltergaeist/releases/latest"><img src="https://img.shields.io/github/v/release/Brage1025/Poltergaeist" alt="Latest release"></a>
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue" alt="MIT License"></a>
  <img src="https://img.shields.io/badge/platform-Windows%2010%20%7C%2011-lightgrey" alt="Windows 10 and 11">
</p>

---

Poltergæist haunts the computer it is installed on. When you pause in the
middle of a sentence, the ghost types a whisper into your window and erases it.
Over the first hour, ghost text drifts across the screen, footsteps cross the
room, the display dims, and a heartbeat starts. At random moments a flashbang
goes off with a tinnitus ring.

It is a prank, a game and a Halloween decoration for a machine you own. The
whispers are written by an open-weight language model running locally through
[Ollama](https://ollama.com). No cloud, no account, no internet connection.

> **Warning:** the flash is very bright and the ring is loud. Install it only on
> your own computer, never where someone with photosensitive epilepsy may be
> using it, and do not use headphones. See [Safety](#safety).

## Download and install

1. Open the [latest release](https://github.com/Brage1025/Poltergaeist/releases/latest).
2. Download **`Poltergaeist-Setup.exe`** and run it.
3. Windows SmartScreen may warn that the publisher is unknown, because the
   installer is not code-signed. Choose **More info**, then **Run anyway**.
4. Leave "Start Poltergaeist whenever I sign in to Windows" ticked and finish
   the installer. It starts right away.

A ghost icon appears in the system tray. Right-click it to meet her.

Prefer not to install? Download **`Poltergaeist-portable.zip`** instead, unzip
it to a folder and run `Poltergaeist.exe`. The portable version does not start
with Windows and has no uninstaller; delete the folder to remove it.

Requires Windows 10 or 11. The optional AI-written whispers need
[Ollama](#optional-ai-written-whispers); without it the ghost uses a built-in
list of whispers.

## What to expect

The haunting is a slow burn. A hidden dread level climbs from 0 to 1 over the
first hour, quiet for a long while and faster toward the end, and then stays at
the peak until the program ends. Each effect appears at a certain point, comes
more often as dread rises, and gets stronger over time.

| Effect                              | Appears at about | How it grows                                         |
| ----------------------------------- | ---------------- | ---------------------------------------------------- |
| Typed whisper when you pause        | immediately      | comes sooner after you pause; the text gets darker   |
| Ghost text drifts across the screen | minute 13        | bigger and longer; on any monitor                    |
| Breathing in the speakers           | minute 17        | louder                                               |
| Cursor shake                        | minute 27        | from a faint tremor to a convulsion                  |
| Footsteps                           | minute 30        | louder                                               |
| Screen dims, as if a cloud passed   | minute 33        | from a slight shade to nearly dark, on every monitor |
| Heartbeat                           | minute 38        | longer and faster                                    |

At the start an event arrives roughly every 9 minutes; at peak, about every
minute and a half. Sounds mix together, so one never cuts off another.

**The flashbang is separate.** It does not depend on dread or on how long the
program has been running. From the moment it starts, it goes off at random
intervals between 4 and 20 minutes, while you are using the PC, on every
monitor.

## Stopping it

There is no pause button, by design. You can stop it in three ways:

- **End it in Task Manager.** Find `Poltergaeist.exe` and choose End task. It
  stays off until the next time you sign in.
- **Restart the PC.** It starts again at sign-in and the hour begins over.
- **Uninstall it** from Windows Settings, Installed apps. This removes it
  completely, including its start-up entry and settings.

Two small extras: **Esc** dismisses any effect on screen, and **Ctrl+Alt+Q** is
an emergency exit. To disable the hotkey, set `"panic_hotkey": false` in the
settings file.

Because it starts itself, it is never hidden: the tray icon is always there, and
the program is listed in Task Manager and in Settings, Apps, Startup.

## Safety

- The flash is a single bright fade with no strobing, but it is still very
  bright. Do not run it near anyone with photosensitive epilepsy.
- Keep the volume low and do not use headphones.
- Install it only on a computer you own, and tell anyone who shares it. Do not
  use it to scare someone who has not agreed to it.
- Ghost text is erased after about 2 seconds. Do not run it over anything you
  cannot afford to have a stray character in.

## Demo

<p align="center">
  <a href="https://youtu.be/BMeRXXoPa2w">
    <img src="https://img.youtube.com/vi/BMeRXXoPa2w/maxresdefault.jpg" alt="Watch the Poltergæist demo on YouTube" width="640">
  </a>
</p>

<p align="center">
  <a href="https://youtu.be/BMeRXXoPa2w"><b>Watch the demo on YouTube</b></a>
</p>

The demo runs in time-lapse mode (`--demo`), which plays the full hour of
escalation in about two minutes. The real thing is a much slower burn.

> The video contains a bright flash and a loud sound.

## Privacy

Everything runs on your computer and nothing is sent to the internet. The
program watches keyboard activity only to know when you pause typing, and typed
text is never saved. The optional AI whispers come from a model on your own
machine.

## Settings

A settings file is created on first run at `%APPDATA%\Poltergaeist\config.json`.
Edit it and restart the program.

| Setting                  | Default     | Meaning                                             |
| ------------------------ | ----------- | --------------------------------------------------- |
| `ramp`                   | 60          | minutes until the haunting reaches its peak         |
| `flash_min`, `flash_max` | 4, 20       | random minutes between flashbangs                   |
| `volume`                 | 0.3         | sound volume, 0 to 0.8                              |
| `idle_min`, `idle_max`   | 4, 9        | seconds of pause before a typed whisper (at peak)   |
| `model`                  | llama3.2:3b | any Ollama model                                    |
| `no_flash`               | false       | never flashbang                                     |
| `no_type`                | false       | no typed whispers                                   |
| `no_mouse`               | false       | no cursor shake                                     |
| `no_tray`                | false       | no tray icon                                        |
| `warn`                   | false       | a 6 second heartbeat before each flashbang          |
| `eavesdrop`              | false       | the ghost twists the last word you typed (RAM only) |
| `panic_hotkey`           | true        | Ctrl+Alt+Q ends the program                         |

The program writes a log to `%APPDATA%\Poltergaeist\poltergaeist.log`.

## Optional: AI-written whispers

Poltergæist works without any setup, but with [Ollama](https://ollama.com) the
whispers are written fresh by a model on your PC, and their tone follows the
dread level: friendly at first, then uneasy, menacing and finally urgent.

```bash
ollama pull llama3.2:3b
```

That is all. Poltergæist finds Ollama automatically. Use a different model with
the `model` setting.

## Why open models matter here

- **Privacy:** the `eavesdrop` option reads your keystrokes. With a closed API
  that would mean shipping your typing to someone else's server; here it never
  leaves RAM on your machine.
- **Offline:** it works with the Wi-Fi unplugged.
- **Swappable personality:** change `model`, or the tone tiers and `PROMPT` in
  the source, to make it a Victorian ghost, a dead programming language, or a
  passive-aggressive coworker.
- **Free:** zero per-call cost, so it can whisper all day.
- **No vendor kill switch:** it cannot be deprecated out from under you.

---

# Build from source

Everything below is for developers. If you only want to run Poltergæist, use the
[download](#download-and-install) above.

## Run from source

Requires Python 3.9 or newer.

```bash
pip install -r requirements.txt

python haunt.py --preview          # print a session timeline, no effects
python haunt.py --demo             # time-lapse: the full hour in 2 minutes
python haunt.py                    # the real thing, in real time
```

Command line options override the settings file: `--model`, `--ramp`,
`--volume`, `--flash-min`, `--flash-max`, `--no-flash`, `--no-type`,
`--no-mouse`, `--no-tray`, `--warn`, `--eavesdrop`, `--timescale N`, `--seed N`.
Run `python haunt.py --help` for the full list.

### Seeing the long run without waiting

- `--preview [minutes]` simulates a session and prints every event with its
  timestamp and dread level, then totals. Add `--seed 7` to repeat a run.
- `--demo` runs time at 30x, so the full hour plays in 2 minutes, and events
  fire even if you are not typing. Every event is printed to the console with
  its dread level. The real thing is a much slower burn than the demo.
- `--selftest` checks that every component is present and exits. The build runs
  this on the packaged app.

## Build the Windows app yourself

1. Install Python 3.9+ (tick "Add python.exe to PATH") and
   [Inno Setup](https://jrsoftware.org/isinfo.php).
2. Double-click `build.bat`. This produces `dist\Poltergaeist\Poltergaeist.exe`.
3. Open `installer.iss` in Inno Setup and press Compile. This produces
   `installer_output\Poltergaeist-Setup.exe`.

If `build.bat` fails because of a special character in the folder name, copy
the project to a plain path such as `C:\poltergaeist` and build there.

The build is a folder rather than a single file on purpose: it starts faster and
is flagged by antivirus far less often. A program that listens to the keyboard
and types text can look suspicious to scanners, so if SmartScreen or Defender
complains about your own build, allow it.

## Let GitHub build it

The workflow in `.github/workflows/build.yml` builds, tests and packages the app
on a Windows machine at GitHub. No local setup is needed.

- Every push to `main` and every pull request runs the build, including a
  self-test of the packaged program. A broken build never reaches you quietly.
  The installer and portable zip are available from the run's **Artifacts**.
- **To publish a release**, tag a version:

  ```bash
  git tag v1.0.0
  git push origin v1.0.0
  ```

  The workflow builds again, stamps the version into the installer, and attaches
  `Poltergaeist-Setup.exe` and `Poltergaeist-portable.zip` to a new GitHub
  Release with generated release notes.

See [CHANGELOG.md](CHANGELOG.md) for what changed in each version.

## Project layout

```
poltergaeist/
  haunt.py                  the program
  assets/
    mascot_head.png         program icon and tray icon
    mascot_full.png         shown when you right-click the tray icon
    README.md               where the artwork came from, and its terms
  make_icon.py              builds icon.ico from the head
  build.bat                 builds the Windows app
  installer.iss             Inno Setup script for the installer
  requirements.txt
  CHANGELOG.md  NOTICE.txt  LICENSE  THIRD_PARTY_NOTICES.md
  .github/workflows/build.yml   builds, tests and releases on GitHub
```

The `assets` folder must sit next to `haunt.py`; `build.bat` bundles it into the
app.

## How it works

- **Director.** `dread = (minutes / ramp) ^ 1.5`, capped at 1. Events are picked
  from a shuffled bag so none repeats too soon, and the gap between events
  shrinks from about 9 minutes to about 1.5 as dread rises.
- **Overlays.** One borderless, click-through window per monitor, so effects
  cover every screen and never steal input.
- **Typing.** `pynput` watches for pauses and ignores keys the program injects
  itself.
- **Sound.** All sounds (heartbeat, breath, footsteps and the ring) are
  synthesized with NumPy and played through a mixing stream, so they overlap
  instead of cutting each other off. No copyrighted game audio is used.
- **Whispers.** Text comes from Ollama's HTTP API on `localhost`, with a built-in
  list as a fallback.

## Poltergæist-chan

Every year around Halloween, she moves into a few unsuspecting PCs and haunts
them until someone finally closes the lid. This year, she can move into yours.

<p align="center">
  <img src="assets/mascot_full.png" alt="Poltergæist-chan" height="750">
</p>

### About Poltergæist-chan

Poltergæist-chan is the resident ghost of Poltergæist: elegant, unhurried and
very sure of herself. She plays the teasing older sister, the kind who finds
your panic charming and your typing habits even more so.

She is patient above all. She does not rush a scare; she would rather wait for
the moment you stop typing, or the quiet in a room, and let you underestimate
her for a while. Her repertoire is small and she knows how to use it: a whisper,
a set of footsteps, a long pause, and now and then a flashbang, because even a
refined ghost enjoys a little drama. If you work up the nerve to press Esc she
will step away, without taking it personally. She has never once stayed away.

Her age is unknown, and the last record of her is a program compiling in 1998.
Her feelings about Task Manager, uninstallers and being told she cannot stay are
best left unmentioned. You will find her in the system tray; right-click the
icon to say hello.

### Lore

Nobody remembers who she was. The story starts in a dormitory in 1998, where a
student stayed up past three every night finishing a program that never seemed
to compile. Her last log entry reads: _"Almost done. Someone keeps reading over
my shoulder."_ She was never found. Her computer was still on.

The machine was sold, then sold again, then wiped and wiped again. But she had
been typing for so long that a little of her had soaked into the keyboard. Every
new owner noticed the same small things:

- **The pause.** She only speaks when you stop. She has spent twenty-five years
  waiting for someone to look away, and she has learned that the best moment is
  the middle of a sentence.
- **The slow burn.** She is patient. In the first minutes she is only a whisper.
  By minute thirty you hear footsteps in a room with no floor to walk on. By
  minute thirty-eight you notice a heartbeat, and you cannot tell whose it is.
- **The flash.** Nobody has worked out why she does it, or why at those moments.
  The ringing that follows is not the speakers. It is the sound of her having
  been very close.
- **The hour.** She needs about an hour to get comfortable. After that she
  stays. Restarting the machine only sends her back to the start, and she has had
  plenty of practice at starting again.

The cursor is the thing people mention last, and with the most reluctance. It is
not a glitch. It shakes the way a hand shakes when it is trying to reach through
something.

She will tell you she is only here to keep you company, and she means it. She is
fond of you. That is the worst part.

You can close the window, end the process, even uninstall her, and the room
stays a little colder for a day. She does not mind. She knows where you live.
She is, after all, in the system.

### Lurking in the taskbar

Her head is the program icon (taskbar, installer, Task Manager) and the
tray icon. Right-click the tray icon and a small popup appears with the full-body
mascot, a line of dialogue, and a credit that links to this repository. Right-click
again, press Esc, click the x, or click anywhere outside to close it. The link
target is `REPO_URL` near the top of `haunt.py`.

### Creation of Poltergæist-chan

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

To use your own mascot, replace the two PNG files in `assets/` and keep the
names. Use transparent backgrounds; the head should be roughly square.

## License

The code is released under the [MIT License](LICENSE). It builds on other
open-source components, listed with their licenses in
[THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md). The language model you run has
its own license; check it before you redistribute anything.

The mascot artwork in `assets/` is not covered by the MIT License. It is
AI-generated and owned by no one; see [Creation of Poltergæist-chan](#creation-of-poltergæist-chan) above and
[assets/README.md](assets/README.md).

---

<div align="center">

_"To &lt;div&gt; or not to &lt;div&gt;, that is the question."_
— [Brage1025](https://github.com/Brage1025)

</div>
