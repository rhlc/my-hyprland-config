#!/usr/bin/env python3
"""Dropdown to pick the default audio output; visually mirrors #power-menu in style.css."""
import json, re, subprocess

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("Gdk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gdk, Gtk, GtkLayerShell

BAR_HEIGHT = 34
MENU_WIDTH = 230

CSS = b"""
window#audio-backdrop { background: transparent; }
#audio-menu {
  background: rgba(246, 238, 242, 0.89);
  border: 1px solid rgba(255, 255, 255, 0.45);
  border-radius: 10px;
  padding: 5px;
}
#audio-menu button {
  background: transparent;
  border: none;
  box-shadow: none;
  border-radius: 5px;
  padding: 4px 14px 4px 10px;
  min-height: 20px;
  min-width: 170px;
  color: rgba(0, 0, 0, 0.85);
  transition: background-color 0.1s ease;
}
#audio-menu button label {
  color: rgba(0, 0, 0, 0.85);
  font-family: "SF Pro Text", "SF Pro", sans-serif;
  font-size: 14px;
  font-weight: 400;
}
#audio-menu button:hover, #audio-menu button:focus { background: #0a84ff; }
#audio-menu button:hover label, #audio-menu button:focus label { color: #ffffff; }
"""


def sh(*cmd):
    return subprocess.run(cmd, capture_output=True, text=True).stdout


def short_name(desc):
    desc = re.sub(r"^.*?Audio Controller ", "", desc)
    bracket = re.search(r"\[(.+?)\]", desc)
    if bracket:  # e.g. "HDMI / DisplayPort 1 Output [BenQ GW2480]" -> "BenQ GW2480"
        return bracket.group(1)
    desc = re.sub(r"\s*\((Stereo|Mono|Surround.*?)\)", "", desc)
    return re.sub(r"\s+Output$", "", desc).strip()


def sinks():
    default = sh("pactl", "get-default-sink").strip()
    out = []
    for s in json.loads(sh("pactl", "-f", "json", "list", "sinks") or "[]"):
        ports = s.get("ports") or []
        active = next((p for p in ports if p["name"] == s.get("active_port")), None)
        if active and active.get("availability") == "not available":
            continue  # unplugged HDMI / jack
        desc = short_name(s["description"])
        out.append((s["name"], desc, s["name"] == default))
    return out


def cursor_x():
    try:
        return int(sh("hyprctl", "cursorpos").split(",")[0])
    except ValueError:
        return 0


def choose(name):
    subprocess.run(["pactl", "set-default-sink", name])
    for line in sh("pactl", "list", "short", "sink-inputs").splitlines():
        subprocess.run(["pactl", "move-sink-input", line.split()[0], name])
    Gtk.main_quit()


def main():
    items = sinks()
    if not items:
        return
    Gtk.StyleContext.add_provider_for_screen(
        Gdk.Screen.get_default(), _css(), Gtk.STYLE_PROVIDER_PRIORITY_USER)

    win = Gtk.Window()
    win.set_name("audio-backdrop")
    win.set_app_paintable(True)
    win.set_visual(win.get_screen().get_rgba_visual())
    GtkLayerShell.init_for_window(win)
    GtkLayerShell.set_layer(win, GtkLayerShell.Layer.OVERLAY)
    GtkLayerShell.set_keyboard_mode(win, GtkLayerShell.KeyboardMode.ON_DEMAND)
    GtkLayerShell.set_exclusive_zone(win, -1)
    for edge in (GtkLayerShell.Edge.TOP, GtkLayerShell.Edge.BOTTOM,
                 GtkLayerShell.Edge.LEFT, GtkLayerShell.Edge.RIGHT):
        GtkLayerShell.set_anchor(win, edge, True)

    # click outside the menu / Esc closes
    backdrop = Gtk.EventBox()
    backdrop.set_visible_window(False)
    backdrop.connect("button-press-event", lambda *_: Gtk.main_quit())
    win.connect("key-press-event",
                lambda _w, e: Gtk.main_quit() if e.keyval == Gdk.KEY_Escape else None)

    mon = Gdk.Display.get_default().get_primary_monitor() or Gdk.Display.get_default().get_monitor(0)
    max_x = mon.get_geometry().width - MENU_WIDTH - 8
    box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
    box.set_name("audio-menu")
    box.set_halign(Gtk.Align.START)
    box.set_valign(Gtk.Align.START)
    box.set_margin_start(max(8, min(cursor_x() - MENU_WIDTH // 2, max_x)))
    box.set_margin_top(BAR_HEIGHT)
    for name, desc, is_default in items:
        btn = Gtk.Button(label=("✓  " if is_default else "") + desc)
        btn.set_relief(Gtk.ReliefStyle.NONE)
        btn.set_can_focus(False)
        btn.get_child().set_xalign(0)
        btn.connect("clicked", lambda _b, n=name: choose(n))
        box.pack_start(btn, False, False, 0)

    # menu clicks must not reach the backdrop
    overlay = Gtk.Overlay()
    overlay.add(backdrop)
    overlay.add_overlay(box)
    win.add(overlay)
    win.show_all()
    Gtk.main()


def _css():
    p = Gtk.CssProvider()
    p.load_from_data(CSS)
    return p


main()
