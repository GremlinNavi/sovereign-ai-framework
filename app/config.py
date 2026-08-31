"""Application-facing import of the project-root configuration."""
from config import BackendConfig, ROOT, Settings, is_local_endpoint, settings, validate_configuration

__all__ = ["BackendConfig", "ROOT", "Settings", "is_local_endpoint", "settings", "validate_configuration"]
