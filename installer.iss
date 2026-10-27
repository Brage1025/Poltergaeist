#!/usr/bin/env python3
"""
POLTERGÆIST - a local-LLM ghost that haunts your PC.

The haunting is a slow burn. It builds for one hour, quietly at first and
faster toward the end, then stays at its peak until you quit the program or
the PC shuts down. A hidden "dread" level climbs from 0 to 1 over the first
hour (--ramp). It unlocks more, and more frequent, events, and every effect
(cursor shake, dimming, sounds, ghost text) grows stronger as dread rises:

  dread 0.00  ghost types a whisper when you stop typing, then erases it
  dread 0.10  ghost text drifts across the screen and fades
  dread 0.15  breathing in the speakers
  dread 0.30  the mouse cursor shivers
  dread 0.35  footsteps
  dread 0.40  the screen dims, slowly, as if a cloud passed over
  dread 0.50  a heartbeat

The FLASHBANG is separate. It is not tied to dread or to how long the program
has been running. It goes off at random intervals (default 4 to 20 minutes)
from the moment the program starts, while you are using the PC.

The whispers are written by an open-weight model running on YOUR machine via
Ollama, and their tone changes with the dread level. Nothing leaves the box.

Try it without waiting:
  python haunt.py --preview          print a session timeline, no effects
  python haunt.py --demo             time-lapse: the full hour in 2 minutes

It cannot be paused. To stop it: restart the PC (it starts again at sign-in
and the hour begins over), end it in Task Manager, or uninstall it. A tray icon
shows that it is running. Esc dismisses any visual effect, and Ctrl+Alt+Q is an
emergency exit (turn it off with "panic_hotkey": false in config.json).
Only run this on your own machine, and warn anyone who shares it.
"""
import argparse
import ctypes
import json
import os
import queue
import random
import socket
import sys
import threading
import time
import urllib.request
from pathlib import Path

try:  # heavy / GUI deps are optional so --preview works anywhere
    import tkinter as tk
    import numpy as np
    import sounddevice as sd
    from pynput import keyboard, mouse
except Exception:  # noqa: BLE001
    tk = np = sd = keyboard = mouse = None

try:
    from PIL import Image, ImageDraw
except Exception:  # noqa: BLE001
    Image = ImageDraw = None

try:
    import pystray
except Exception:  # noqa: BLE001
    pystray = None

APP_NAME = "Poltergaeist"
APP_DIR = Path(os.environ.get("APPDATA") or (Path.home() / ".config")) / APP_NAME
CONFIG_PATH = APP_DIR / "config.json"
LOG_PATH = APP_DIR / "poltergaeist.log"
LOCK_PORT = 47653
SR = 44100

DEFAULTS = {
    "model": "llama3.2:3b",
    "host": "http://localhost:11434",
    "ramp": 60,            # minutes until the haunting reaches its peak
    "volume": 0.3,         # 0 to 0.8
    "idle_min": 4,         # seconds of pause before a typed whisper (at peak)
    "idle_max": 9,
    "flash_min": 4,        # minutes between flashbangs, random in this range
    "flash_max": 20,
    "no_flash": False,
    "no_type": False,
    "no_mouse": False,
    "no_tray": False,
    "warn": False,         # play a heartbeat before the flashbang
    "eavesdrop": False,    # let the ghost twist the last word you typed
    "panic_hotkey": True,  # Ctrl+Alt+Q ends the program (until the next sign-in)
}

FALLBACK = [
    "Boo!", "behind you", "i see you", "still here", "don't turn around",
    "it's cold", "typing... always typing", "look up", "who's there?",
    "you are not alone", "wooOOoo", "i was here first",
    "close the door", "why did you stay so late", "i can see the screen",
]

TIERS = [
    (0.00, "subtle and quiet, almost friendly"),
    (0.35, "uneasy and watchful"),
    (0.65, "menacing and intimate"),
    (0.85, "terrifying, urgent, final"),
]

PROMPT = (
    "You are a ghost haunting someone's computer. Tone: {tone}. "
    "Reply with ONLY one short whisper of 1 to 5 words. "
    "No quotes, no explanation. Vary it. {ctx}"
)

# ambient events: name: (minimum dread, weight). The flashbang is separate.
EVENTS = {
    "overlay":   (0.10, 3),
    "breath":    (0.15, 3),
    "shiver":    (0.30, 2),
    "footsteps": (0.35, 2),
    "dim":       (0.40, 2),
    "heartbeat": (0.50, 2),
}


# ---------------------------------------------------------------- config
def load_config():
    cfg = dict(DEFAULTS)
    try:
        user = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
        cfg.update({k: v for k, v in user.items() if k in DEFAULTS})
    except FileNotFoundError:
        pass
    except Exception as e:  # noqa: BLE001
        print(f"[config] could not read {CONFIG_PATH}: {e}")
    return cfg


def ensure_config():
    if not CONFIG_PATH.exists():
        try:
            APP_DIR.mkdir(parents=True, exist_ok=True)
            CONFIG_PATH.write_text(json.dumps(DEFAULTS, indent=2), encoding="utf-8")
        except Exception as e:  # noqa: BLE001
            print(f"[config] could not create {CONFIG_PATH}: {e}")


def setup_logging():
    """Packaged without a console: send output to a log file instead."""
    if getattr(sys, "frozen", False) and sys.stdout is None:
        try:
            APP_DIR.mkdir(parents=True, exist_ok=True)
            if LOG_PATH.exists() and LOG_PATH.stat().st_size > 1_000_000:
                LOG_PATH.unlink()
            sys.stdout = sys.stderr = open(LOG_PATH, "a", buffering=1, encoding="utf-8")
        except Exception:  # noqa: BLE001
            pass


# ---------------------------------------------------------------- director
class Director:
    """Decides WHAT haunts and WHEN. Pure logic, no side effects."""

    def __init__(self, ramp_minutes, rng=random):
        self.ramp = ramp_minutes
        self.rng = rng
        self._bag = []
        self._bag_key = None

    def dread(self, vmin):
        """0 to 1 over the ramp, then stays at 1 forever.
        Eased: it builds slowly at first and faster toward the end (a slow burn)."""
        x = max(0.0, min(1.0, vmin / self.ramp))
        return x ** 1.5

    def interval(self, dread):
        """Virtual minutes until the next ambient event."""
        return (9.0 - 7.5 * dread) * self.rng.uniform(0.6, 1.4)

    def pick(self, vmin):
        """Shuffle-bag pick: every unlocked event shows up regularly, in a
        random order, so none is starved by bad luck."""
        d = self.dread(vmin)
        opts = [(n, w) for n, (m, w) in EVENTS.items() if d >= m]
        if not opts:
            return None
        key = tuple(n for n, _ in opts)
        if key != self._bag_key or not self._bag:
            self._bag_key = key
            self._bag = [n for n, w in opts for _ in range(w)]
            self.rng.shuffle(self._bag)
        return self._bag.pop()


def preview(args):
    rng = random.Random(args.seed)
    d = Director(args.ramp, rng)
    frng = random.Random(args.seed + 1)
    rows, t = [], 0.0
    while True:
        t += d.interval(d.dread(t))
        if t >= args.preview:
            break
        ev = d.pick(t)
        if ev:
            rows.append((t, ev))
    t = 0.0
    while not args.no_flash:
        t += frng.uniform(args.flash_min, args.flash_max)
        if t >= args.preview:
            break
        rows.append((t, "FLASHBANG"))
    rows.sort()
    print(f"Simulated {args.preview:.0f} minute session "
          f"(peak after {args.ramp:.0f} min, seed {args.seed})\n")
    for t, ev in rows:
        print(f"  +{int(t // 60):02d}:{int(t % 60):02d}   dread {d.dread(t):.2f}   {ev}")
    print("\nTotals:")
    for name in list(EVENTS) + ["FLASHBANG"]:
        print(f"  {name:<10} {sum(1 for _, e in rows if e == name)}")
    print("\nPlus a typed whisper every time you pause while typing.")
    print("After the peak the haunting stays at that level until the program quits.")


# ---------------------------------------------------------------- helpers
def click_through(win):
    """Windows: make the window ignore mouse clicks and never take focus."""
    if sys.platform != "win32":
        return
    try:
        win.update_idletasks()
        user32 = ctypes.windll.user32
        hwnd = user32.GetParent(win.winfo_id())
        style = user32.GetWindowLongW(hwnd, -20)
        user32.SetWindowLongW(hwnd, -20, style | 0x80000 | 0x20 | 0x08000000)
    except Exception:  # noqa: BLE001
        pass


def monitor_rects():
    """(x, y, width, height) of every monitor. Empty list if unknown."""
    rects = []
    if sys.platform != "win32":
        return rects
    try:
        from ctypes import wintypes
        proc = ctypes.WINFUNCTYPE(ctypes.c_int, wintypes.HANDLE, wintypes.HANDLE,
                                  ctypes.POINTER(wintypes.RECT), wintypes.LPARAM)

        def cb(hmon, hdc, rect, lparam):
            r = rect.contents
            rects.append((r.left, r.top, r.right - r.left, r.bottom - r.top))
            return 1

        ctypes.windll.user32.EnumDisplayMonitors(None, None, proc(cb), 0)
    except Exception as e:  # noqa: BLE001
        print(f"[ghost] monitor detection failed: {e}")
    return rects


def make_icon_image(size=64):
    s = size / 64.0
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    body = (235, 235, 245, 255)
    d.ellipse([12 * s, 6 * s, 52 * s, 46 * s], fill=body)
    d.rectangle([12 * s, 26 * s, 52 * s, 56 * s], fill=body)
    for i in range(4):
        x = 12 + i * 10
        d.polygon([(x * s, 57 * s), ((x + 5) * s, 48 * s), ((x + 10) * s, 57 * s)],
                  fill=(0, 0, 0, 0))
    eye = (30, 30, 50, 255)
    d.ellipse([21 * s, 22 * s, 29 * s, 32 * s], fill=eye)
    d.ellipse([35 * s, 22 * s, 43 * s, 32 * s], fill=eye)
    d.ellipse([29 * s, 36 * s, 35 * s, 44 * s], fill=eye)
    return img


def lowpass(x, n):
    return np.convolve(x, np.ones(n) / n, mode="same")


def snd_thump(dur=0.35, freq=80.0, amp=1.0):
    """A thump with harmonics and a click, so ordinary speakers and headphones
    can actually play it (a bare 50 Hz sine is nearly inaudible on most gear)."""
    t = np.linspace(0, dur, int(SR * dur), endpoint=False)
    body = (np.sin(2 * np.pi * freq * t) +
            0.7 * np.sin(2 * np.pi * freq * 2 * t) +
            0.45 * np.sin(2 * np.pi * freq * 3 * t) +
            0.25 * np.sin(2 * np.pi * freq * 4.5 * t))
    click = np.random.randn(len(t)) * np.exp(-t / 0.006) * 0.35
    return (body * np.exp(-t / 0.09) + click) * amp


def snd_heartbeat(beats, bpm_start, bpm_end):
    """Lub-dub pairs, speeding up from bpm_start to bpm_end."""
    times, t = [], 0.0
    for i in range(beats):
        bpm = bpm_start + (bpm_end - bpm_start) * i / max(1, beats - 1)
        times.append(t)
        t += 60.0 / bpm
    buf = np.zeros(int(SR * (t + 0.8)))
    for bt in times:
        for off, amp, f in ((0.0, 1.0, 85.0), (0.22, 0.75, 70.0)):
            th = snd_thump(freq=f, amp=amp)
            i = int(SR * (bt + off))
            buf[i:i + len(th)] += th[: len(buf) - i]
    return buf


def snd_breath():
    dur = 3.0
    n = int(SR * dur)
    t = np.linspace(0, dur, n, endpoint=False)
    noise = lowpass(np.random.randn(n), 60)
    return noise * np.sin(np.pi * t / dur) ** 2


def snd_footsteps():
    steps = random.randint(4, 7)
    buf = np.zeros(int(SR * (steps * 0.7 + 0.6)))
    t = 0.2
    for i in range(steps):
        th = snd_thump(0.25, random.uniform(70, 95), 0.5 + 0.5 * i / steps)
        click = np.random.randn(len(th)) * np.exp(-np.linspace(0, 0.25, len(th)) / 0.01) * 0.3
        s = th + click
        k = int(SR * t)
        buf[k:k + len(s)] += s[: len(buf) - k]
        t += random.uniform(0.55, 0.8)
    return buf


def snd_ring(dur=7.0):
    t = np.linspace(0, dur, int(SR * dur), endpoint=False)
    env = np.exp(-t / 2.4)
    tone = (np.sin(2 * np.pi * 4100 * t) * 0.6 +
            np.sin(2 * np.pi * 2870 * t) * 0.3 +
            np.sin(2 * np.pi * 6200 * t) * 0.1)
    thump = np.random.randn(len(t)) * np.exp(-t / 0.08) * 0.8
    sig = tone * env + thump
    sig *= np.clip(t / 0.005, 0, 1)
    return sig


# ---------------------------------------------------------------- the ghost
class Mixer:
    """Plays any number of sounds at once by summing them in one output stream.
    (sd.play() stops whatever is already playing, which cut sounds off.)
    The stream closes by itself when nothing is playing, so the audio device
    is only held while the ghost is actually making noise."""

    def __init__(self):
        self.lock = threading.Lock()
        self.voices = []          # [samples, position]
        self.stream = None
        self.dead = True          # True when no stream is running
        self.failed = False

    def _callback(self, outdata, frames, time_info, status):
        out = np.zeros(frames, dtype=np.float32)
        with self.lock:
            keep = []
            for v in self.voices:
                sig, pos = v
                chunk = sig[pos:pos + frames]
                out[:len(chunk)] += chunk
                v[1] = pos + frames
                if v[1] < len(sig):
                    keep.append(v)
            self.voices = keep
            finished = not keep
            if finished:
                self.dead = True
        np.clip(out, -1.0, 1.0, out=out)
        outdata[:, 0] = out
        if finished:
            raise sd.CallbackStop

    def add(self, sig):
        if sd is None or self.failed:
            return
        with self.lock:
            self.voices.append([np.asarray(sig, dtype=np.float32), 0])
            if not self.dead:
                return            # the running stream will pick it up
            old, self.stream = self.stream, None
            try:
                self.stream = sd.OutputStream(samplerate=SR, channels=1, dtype="float32",
                                              callback=self._callback)
                self.stream.start()
                self.dead = False
            except Exception as e:  # noqa: BLE001
                print(f"[ghost] audio unavailable: {e}")
                self.voices.clear()
                self.failed = True
        if old is not None:
            try:
                old.close()
            except Exception:  # noqa: BLE001
                pass

    def stop(self):
        with self.lock:
            self.voices.clear()


class Ghost:
    def __init__(self, args):
        self.a = args
        self.mixer = Mixer()
        self.rng = random.Random(args.seed)
        self.dir = Director(args.ramp, self.rng)
        self.kb = keyboard.Controller()
        self.start = time.time()
        self.last_key = 0.0
        self.last_whisper = 0.0         # only typed whispers move this clock
        self.ignore_keys_until = 0.0
        self.ghost_typing = False
        self.tray = None
        self.typed_words = []           # RAM only, never written anywhere
        self.pool = queue.Queue()
        self.q = queue.Queue()          # work for the UI thread
        self.windows = set()
        self.stop = False
        self.next_idle = self.pick_idle()
        now = time.time()
        self.next_event = now + (6.0 if args.demo else self.dir.interval(0) * 60 / args.timescale)
        self.next_flash = now + (14.0 if args.demo else self.flash_gap())
        self.root = tk.Tk()
        self.root.withdraw()

    # ----- time / dread / logging
    def vmin(self):
        return (time.time() - self.start) * self.a.timescale / 60.0

    def dread(self):
        return self.dir.dread(self.vmin())

    def flash_gap(self):
        return self.rng.uniform(self.a.flash_min, self.a.flash_max) * 60 / self.a.timescale

    def pick_idle(self):
        """Pause length before a typed whisper. Shrinks as dread rises."""
        d = self.dir.dread(self.vmin())
        return random.uniform(self.a.idle_min, self.a.idle_max) * (1.6 - 0.9 * d)

    def log(self, kind, detail=""):
        v = self.vmin()
        stamp = f"+{int(v // 60):02d}:{int(v % 60):02d}"
        print(f"[{stamp} dread {self.dir.dread(v):.2f}] {kind} {detail}".rstrip(), flush=True)

    # ----- local LLM
    def tone(self):
        d = self.dread()
        return [desc for lo, desc in TIERS if d >= lo][-1]

    def _ask_model(self):
        ctx = ""
        if self.a.eavesdrop and self.typed_words:
            ctx = f"The user just typed the word '{self.typed_words[-1]}'. Twist it."
        body = json.dumps({
            "model": self.a.model,
            "prompt": PROMPT.format(tone=self.tone(), ctx=ctx),
            "stream": False,
            "options": {"num_predict": 16, "temperature": 1.1},
        }).encode()
        req = urllib.request.Request(
            f"{self.a.host}/api/generate", body, {"Content-Type": "application/json"})
        with urllib.request.urlopen(req, timeout=20) as r:
            text = json.loads(r.read())["response"]
        text = "".join(c for c in text if 32 <= ord(c) < 127).strip(" \"'\n")
        return text[:40] or None

    def refill_worker(self):
        warned = False
        while not self.stop:
            if self.pool.qsize() < 4:
                try:
                    p = self._ask_model()
                    if p:
                        self.pool.put(p)
                except Exception as e:  # noqa: BLE001
                    if not warned:
                        print(f"[ghost] Ollama unreachable ({e}); using stock whispers.")
                        warned = True
                    time.sleep(10)
            time.sleep(1)

    def whisper(self):
        try:
            return self.pool.get_nowait()
        except queue.Empty:
            return random.choice(FALLBACK)

    # ----- keyboard
    def on_press(self, key):
        if key == keyboard.Key.esc:
            self.q.put(self.dismiss_all)
        if self.ghost_typing or time.time() < self.ignore_keys_until:
            return
        self.last_key = time.time()
        if self.a.eavesdrop:
            try:
                ch = key.char
            except AttributeError:
                ch = " " if key == keyboard.Key.space else None
            if ch is None:
                return
            if ch == " ":
                self.typed_words = [w for w in self.typed_words if w][-3:] + [""]
            else:
                if not self.typed_words:
                    self.typed_words.append("")
                self.typed_words[-1] = (self.typed_words[-1] + ch)[-20:]

    # ----- audio
    def play(self, sig, gain=1.0, punch=False):
        try:
            sig = sig / (float(np.max(np.abs(sig))) or 1.0)
            if punch:
                # Sparse low sounds (heartbeat, footsteps) are mostly silence, so
                # peak-normalizing makes them quiet. Target the average level and
                # soft-clip the peaks instead: about 2.4x louder, same peak cap.
                r = float(np.sqrt(np.mean(sig ** 2))) or 1.0
                sig = np.tanh(sig / r * 0.9)
                sig = sig / (float(np.max(np.abs(sig))) or 1.0)
            sig = sig * min(self.a.volume, 0.8) * gain
            sig *= np.clip(np.arange(len(sig)) / (SR * 0.01), 0, 1)
            self.mixer.add(sig)
        except Exception as e:  # noqa: BLE001
            print(f"[ghost] audio failed: {e}")

    # ----- visuals
    def monitors(self):
        rects = monitor_rects()
        return rects or [(0, 0, self.root.winfo_screenwidth(), self.root.winfo_screenheight())]

    def _screen_windows(self, color):
        """One borderless full-screen window per monitor."""
        out = []
        for x, y, mw, mh in self.monitors():
            w = tk.Toplevel(self.root)
            w.overrideredirect(True)
            w.configure(bg=color)
            w.attributes("-topmost", True)
            w.attributes("-alpha", 0.0)
            w.geometry(f"{mw}x{mh}{x:+d}{y:+d}")
            click_through(w)
            out.append(w)
        return out

    def _animate(self, w, peak, in_ms, hold_ms, out_ms):
        self.windows.add(w)
        step, total = 40, in_ms + hold_ms + out_ms

        def frame(el=0):
            if w not in self.windows:
                return
            if el >= total:
                self._close(w)
                return
            if el < in_ms:
                a = peak * el / max(1, in_ms)
            elif el < in_ms + hold_ms:
                a = peak
            else:
                a = peak * (1 - (el - in_ms - hold_ms) / out_ms)
            w.attributes("-alpha", max(0.0, min(1.0, a)))
            w.after(step, frame, el + step)

        frame()

    def _close(self, w):
        if w in self.windows:
            self.windows.discard(w)
            try:
                w.destroy()
            except tk.TclError:
                pass

    def _close_all_windows(self):
        for w in list(self.windows):
            self._close(w)

    def dismiss_all(self):
        self._close_all_windows()
        self.mixer.stop()

    # ----- events
    def _spawn_overlay(self, text, d=1.0):
        key = "#010101"
        w = tk.Toplevel(self.root)
        w.overrideredirect(True)
        w.attributes("-topmost", True)
        w.attributes("-alpha", 0.0)
        w.configure(bg=key)
        try:
            w.attributes("-transparentcolor", key)
        except tk.TclError:
            pass
        size = random.randint(22, 28 + int(28 * d))         # bigger as dread rises
        tk.Label(w, text=text, font=("Georgia", size, "italic"),
                 fg="#c0392b", bg=key).pack(padx=20, pady=20)
        w.update_idletasks()
        mx, my, mw, mh = random.choice(self.monitors())      # any screen
        x = mx + random.randint(0, max(0, mw - w.winfo_width()))
        y = my + random.randint(0, max(0, mh - w.winfo_height()))
        w.geometry(f"{x:+d}{y:+d}")
        click_through(w)
        self._animate(w, 0.45 + 0.45 * d, 1400, 1500 + int(1000 * d), 1700)

    def ev_overlay(self):
        d = self.dread()
        n = 1 + (random.random() < d * 0.8) + (random.random() < d * 0.5)
        texts = [self.whisper() for _ in range(n)]
        self.log("overlay", repr(texts))
        for t in texts:
            self._spawn_overlay(t, d)

    def ev_breath(self):
        d = self.dread()
        self.log("breath")
        self.play(snd_breath(), 0.35 + 0.65 * d)

    def ev_footsteps(self):
        d = self.dread()
        self.log("footsteps")
        self.play(snd_footsteps(), 0.5 + 0.5 * d, punch=True)

    def ev_heartbeat(self):
        d = self.dread()
        self.log("heartbeat")
        # longer and faster as dread rises
        self.play(snd_heartbeat(4 + int(8 * d), 58 + 20 * d, 68 + 35 * d),
                  0.55 + 0.45 * d, punch=True)

    def ev_shiver(self):
        if self.a.no_mouse:
            return
        d = self.dread()
        amp0 = 10 + 120 * d ** 1.3            # a tremor at first, a convulsion at peak
        steps = int(30 + 60 * d)
        bursts = 2 if (d > 0.85 and random.random() < 0.5) else 1
        self.log("shiver", f"(cursor, {amp0:.0f}px, {bursts}x)")

        def shake():
            # Violent back-and-forth that dies away. Each step is relative to where
            # the cursor is NOW, so it never fights you if you move the mouse.
            m = mouse.Controller()
            ox = oy = 0
            sign = 1
            for i in range(steps):
                amp = amp0 * (1 - i / steps) ** 1.2 + 3
                sign = -sign
                nx = int(sign * amp * random.uniform(0.6, 1.0))
                ny = int(random.uniform(-amp, amp) * 0.6)
                cx, cy = m.position
                m.position = (cx + nx - ox, cy + ny - oy)
                ox, oy = nx, ny
                time.sleep(0.02)
            cx, cy = m.position
            m.position = (cx - ox, cy - oy)

        def run():
            try:
                for b in range(bursts):
                    if b:
                        time.sleep(0.35)
                    shake()
            except Exception as e:  # noqa: BLE001
                print(f"[ghost] cursor shiver failed: {e}")

        threading.Thread(target=run, daemon=True).start()

    def ev_dim(self):
        d = self.dread()
        self.log("dim", f"(depth {0.25 + 0.55 * d:.2f})")
        for w in self._screen_windows("black"):
            self._animate(w, 0.25 + 0.55 * d, 1800, 1000 + int(2000 * d), 2800)

    def ev_flashbang(self):
        if self.a.warn:
            self.log("flashbang", "(warning heartbeat, 6s)")
            self.play(snd_heartbeat(9, 70, 150), 1.0, punch=True)
            self.root.after(6000, self._flash)
        else:
            self._flash()

    def _flash(self):
        if self.stop:
            return
        self._close_all_windows()      # the flash overrides everything else
        self.log("FLASHBANG")
        windows = self._screen_windows("white")
        self.play(snd_ring(), 1.0)
        for w in windows:
            self._animate(w, 1.0, 0, 900, 4200)

    # ----- typed whisper (reactive)
    def haunt_type(self):
        text = self.whisper()
        self.log("whisper", repr(text))
        self.last_whisper = time.time()
        self.ghost_typing = True
        try:
            for ch in text:
                self.kb.type(ch)
                time.sleep(random.uniform(0.10, 0.32))
            time.sleep(1.6)
            for _ in text:
                self.kb.tap(keyboard.Key.backspace)
                time.sleep(0.04)
        except Exception as e:  # noqa: BLE001
            print(f"[ghost] typing failed: {e}")
        finally:
            self.ghost_typing = False
            # key events can arrive a moment late; never count our own as the user's
            self.ignore_keys_until = time.time() + 1.0
            self.last_whisper = time.time()

    # ----- scheduler
    def run_event(self, ev):
        if ev in ("overlay", "dim") and self.windows:
            return
        getattr(self, f"ev_{ev}")()

    def tick(self):
        while True:
            try:
                self.q.get_nowait()()
            except queue.Empty:
                break
        if self.stop:
            self.root.quit()
            return
        now = time.time()
        active = self.a.demo or now - self.last_key < 15
        if not self.ghost_typing:
            if (not self.a.no_type and self.last_key > self.last_whisper
                    and now - self.last_key > self.next_idle):
                self.next_idle = self.pick_idle()
                threading.Thread(target=self.haunt_type, daemon=True).start()
            if now >= self.next_flash and active:
                self.next_flash = now + self.flash_gap()
                if not self.a.no_flash:
                    self.ev_flashbang()
            if now >= self.next_event and active:
                ev = self.dir.pick(self.vmin())
                self.next_event = now + self.dir.interval(self.dread()) * 60 / self.a.timescale
                if ev:
                    self.run_event(ev)
        self.root.after(100, self.tick)

    def quit(self):
        def do():
            self.dismiss_all()
            if self.tray is not None:
                try:
                    self.tray.stop()
                except Exception:  # noqa: BLE001
                    pass
            self.stop = True
        self.q.put(do)

    # ----- tray icon
    def start_tray(self):
        if pystray is None or Image is None or self.a.no_tray:
            return
        try:
            # The tray icon is only an indicator so the app is never hidden.
            # There is deliberately no pause or quit here.
            def open_folder(icon, item):
                APP_DIR.mkdir(parents=True, exist_ok=True)
                if sys.platform == "win32":
                    os.startfile(APP_DIR)  # noqa: S606

            menu = pystray.Menu(
                pystray.MenuItem("Poltergaeist is running", lambda icon, item: None,
                                 enabled=False),
                pystray.MenuItem("To stop it: end it in Task Manager, or uninstall",
                                 lambda icon, item: None, enabled=False),
                pystray.Menu.SEPARATOR,
                pystray.MenuItem("Open settings folder", open_folder),
            )
            self.tray = pystray.Icon(APP_NAME, make_icon_image(64),
                                     "Poltergaeist (end it in Task Manager, or uninstall)", menu)
            self.tray.run_detached()
            try:
                self.tray.notify("Running. To stop it, end Poltergaeist in Task Manager "
                                 "or uninstall it.", "Poltergaeist")
            except Exception:  # noqa: BLE001
                pass
        except Exception as e:  # noqa: BLE001
            print(f"[tray] unavailable: {e}")

    def run(self):
        if self.a.panic_hotkey:
            print("Poltergaeist awake. Emergency exit: Ctrl+Alt+Q  |  Esc dismisses effects.")
        else:
            print("Poltergaeist awake. Esc dismisses effects.")
        if self.a.demo:
            print(f"DEMO: time runs {self.a.timescale:g}x. The {self.a.ramp:.0f} minute ramp "
                  f"plays in {self.a.ramp / self.a.timescale:.1f} minutes, then stays at peak. "
                  "Keep typing, then pause, to see the typed whispers.")
        listener_kw = {}
        if sys.platform == "win32":
            # drop keystrokes that software injected (including the ghost's own)
            listener_kw["win32_event_filter"] = lambda msg, data: not (data.flags & 0x10)
        keyboard.Listener(on_press=self.on_press, daemon=True, **listener_kw).start()
        if self.a.panic_hotkey:
            keyboard.GlobalHotKeys({"<ctrl>+<alt>+q": self.quit}).start()
        threading.Thread(target=self.refill_worker, daemon=True).start()
        self.start_tray()
        self.root.after(100, self.tick)
        self.root.mainloop()


def single_instance():
    s = socket.socket()
    try:
        s.bind(("127.0.0.1", LOCK_PORT))
    except OSError:
        return None
    return s


def main():
    setup_logging()
    cfg = load_config()
    p = argparse.ArgumentParser(description="A local-LLM ghost that haunts your PC.")
    p.add_argument("--model", help="any Ollama model tag")
    p.add_argument("--host")
    p.add_argument("--ramp", type=float, help="minutes for the haunting to reach its peak")
    p.add_argument("--volume", type=float, help="sound volume 0-0.8")
    p.add_argument("--idle-min", type=float, help="seconds of pause before a typed whisper")
    p.add_argument("--idle-max", type=float)
    p.add_argument("--flash-min", type=float, help="minimum minutes between flashbangs")
    p.add_argument("--flash-max", type=float, help="maximum minutes between flashbangs")
    p.add_argument("--no-flash", action="store_true", help="never flashbang")
    p.add_argument("--no-type", action="store_true", help="no typed whispers")
    p.add_argument("--no-mouse", action="store_true", help="no cursor shiver")
    p.add_argument("--no-tray", action="store_true", help="no tray icon")
    p.add_argument("--warn", action="store_true", help="play a heartbeat before each flashbang")
    p.add_argument("--eavesdrop", action="store_true",
                   help="let the ghost twist the last word you typed (kept in RAM only)")
    p.add_argument("--timescale", type=float, default=None,
                   help="speed up time (30 = the full hour in 2 minutes)")
    p.add_argument("--demo", action="store_true",
                   help="time-lapse (30x); events fire even if you are not typing")
    p.add_argument("--preview", type=float, nargs="?", const=120, default=None,
                   help="print a simulated timeline of N minutes (default 120) and exit")
    p.add_argument("--seed", type=int, default=None, help="random seed (repeatable sessions)")
    p.add_argument("--selftest", action="store_true",
                   help="check that all components loaded, then exit (used by the build)")
    p.set_defaults(**cfg)
    args = p.parse_args()
    if args.seed is None:
        args.seed = random.randrange(10000)
    if args.timescale is None:
        args.timescale = 30.0 if args.demo else 1.0
    if args.selftest:
        mods = {"tkinter": tk, "numpy": np, "sounddevice": sd, "pynput.keyboard": keyboard,
                "pynput.mouse": mouse, "PIL": Image, "pystray": pystray}
        missing = [n for n, m in mods.items() if m is None]
        print("selftest: missing components:", ", ".join(missing) or "none")
        sys.exit(1 if missing else 0)
    if args.preview is not None:
        preview(args)
        return
    if keyboard is None or tk is None:
        sys.exit("Missing dependencies: pip install -r requirements.txt")
    lock = single_instance()          # keep a reference so the port stays held
    if lock is None:
        print("Poltergaeist is already running.")
        return
    ensure_config()
    if sys.platform == "win32":
        for level in (2, 1):    # per-monitor, else system: real pixel sizes on every screen
            try:
                ctypes.windll.shcore.SetProcessDpiAwareness(level)
                break
            except Exception:  # noqa: BLE001
                continue
    Ghost(args).run()


if __name__ == "__main__":
    main()