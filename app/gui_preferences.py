# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

"""Small, local-only accessibility preferences for the Tk desktop interface."""

from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
import tkinter.font as tkfont
from tkinter import ttk


PREFERENCES_FILENAME = "gui_preferences.json"
THEMES = frozenset({"system", "light", "dark", "high_contrast"})


@dataclass(frozen=True)
class GuiPreferences:
    theme: str = "system"
    font_scale: int = 100
    window_width: int = 1100
    window_height: int = 760


def preference_path(data_root: Path) -> Path:
    """Keep user-controlled visual preferences beside other local application data."""
    return data_root / PREFERENCES_FILENAME


def _bounded_int(value: object, default: int, minimum: int, maximum: int) -> int:
    try:
        number = int(value)
    except (TypeError, ValueError):
        return default
    return number if minimum <= number <= maximum else default


def load_gui_preferences(data_root: Path) -> GuiPreferences:
    """Read a small preference file defensively; invalid data safely falls back."""
    path = preference_path(data_root)
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return GuiPreferences()
    if not isinstance(raw, dict):
        return GuiPreferences()

    theme = str(raw.get("theme", "system")).strip().lower()
    if theme not in THEMES:
        theme = "system"
    return GuiPreferences(
        theme=theme,
        font_scale=_bounded_int(raw.get("font_scale"), 100, 80, 200),
        window_width=_bounded_int(raw.get("window_width"), 1100, 760, 3840),
        window_height=_bounded_int(raw.get("window_height"), 760, 500, 2160),
    )


def _palette(theme: str) -> dict[str, str] | None:
    if theme == "dark":
        return {
            "background": "#202124",
            "foreground": "#f1f3f4",
            "field": "#303134",
            "accent": "#8ab4f8",
            "button": "#3c4043",
        }
    if theme == "high_contrast":
        return {
            "background": "#000000",
            "foreground": "#ffffff",
            "field": "#000000",
            "accent": "#ffff00",
            "button": "#000000",
        }
    if theme == "light":
        return {
            "background": "#ffffff",
            "foreground": "#1f1f1f",
            "field": "#ffffff",
            "accent": "#005a9c",
            "button": "#f3f3f3",
        }
    return None


def apply_root_preferences(root: object, preferences: GuiPreferences) -> dict[str, str] | None:
    """Apply bounded visual choices to a Tk root and return its optional palette."""
    root.geometry(f"{preferences.window_width}x{preferences.window_height}")

    for font_name in ("TkDefaultFont", "TkTextFont", "TkMenuFont", "TkHeadingFont", "TkCaptionFont"):
        try:
            font = tkfont.nametofont(font_name)
        except Exception:
            continue
        current_size = int(font.cget("size"))
        sign = -1 if current_size < 0 else 1
        scaled_size = max(6, round(abs(current_size) * preferences.font_scale / 100))
        font.configure(size=sign * scaled_size)

    palette = _palette(preferences.theme)
    if palette is None:
        return None

    root.configure(background=palette["background"])
    style = ttk.Style(root)
    style.configure("TFrame", background=palette["background"])
    style.configure("TLabel", background=palette["background"], foreground=palette["foreground"])
    style.configure("TButton", background=palette["button"], foreground=palette["foreground"])
    style.map(
        "TButton",
        background=[("active", palette["accent"])],
        foreground=[("active", palette["background"])],
    )
    return palette
