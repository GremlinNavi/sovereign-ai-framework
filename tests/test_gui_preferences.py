# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

from __future__ import annotations

import json
from pathlib import Path

from app.gui_preferences import GuiPreferences, load_gui_preferences, preference_path


def test_gui_preferences_default_to_a_bounded_system_layout(tmp_path: Path):
    assert load_gui_preferences(tmp_path) == GuiPreferences()
    assert preference_path(tmp_path) == tmp_path / "gui_preferences.json"


def test_gui_preferences_load_valid_local_choices(tmp_path: Path):
    preference_path(tmp_path).write_text(
        json.dumps(
            {
                "theme": "high_contrast",
                "font_scale": 125,
                "window_width": 1280,
                "window_height": 900,
            }
        ),
        encoding="utf-8",
    )

    assert load_gui_preferences(tmp_path) == GuiPreferences(
        theme="high_contrast", font_scale=125, window_width=1280, window_height=900
    )


def test_gui_preferences_reject_invalid_values_without_breaking_the_gui(tmp_path: Path):
    preference_path(tmp_path).write_text(
        json.dumps(
            {"theme": "neon", "font_scale": 999, "window_width": 10, "window_height": "bad"}
        ),
        encoding="utf-8",
    )

    assert load_gui_preferences(tmp_path) == GuiPreferences()
