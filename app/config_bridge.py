"""Application-facing bridge to the canonical project-root OSWAP configuration.

Application modules should import configuration through this bridge. Humans editing
configuration should edit ``oswap_config.py`` at the repository root.
"""
from oswap_config import BACKENDS, BackendConfig, ROOT, Settings, is_local_endpoint, settings, validate_configuration

__all__ = ["BACKENDS", "BackendConfig", "ROOT", "Settings", "is_local_endpoint", "settings", "validate_configuration"]
