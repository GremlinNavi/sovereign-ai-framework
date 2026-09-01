# SPDX-FileCopyrightText: 2026 Nemi Prowse
# SPDX-License-Identifier: Apache-2.0

"""Application-facing import of the project-root configuration."""
from config import (
    BackendConfig,
    ROOT,
    Settings,
    backend_unavailable_message,
    is_local_endpoint,
    settings,
    validate_configuration,
)

__all__ = [
    "BackendConfig",
    "ROOT",
    "Settings",
    "backend_unavailable_message",
    "is_local_endpoint",
    "settings",
    "validate_configuration",
]
