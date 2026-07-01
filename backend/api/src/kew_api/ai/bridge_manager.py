"""Manage an external Cursor bridge daemon subprocess (Windows-safe)."""

from __future__ import annotations

import json
import logging
import subprocess
import sys
import threading
from dataclasses import dataclass

from kew_api.ai.errors import AiRunnerError

logger = logging.getLogger(__name__)

_lock = threading.Lock()


@dataclass(frozen=True)
class BridgeEndpoint:
    url: str
    auth_token: str


_daemon: subprocess.Popen[str] | None = None
_endpoint: BridgeEndpoint | None = None


def get_bridge_endpoint(workspace: str) -> BridgeEndpoint:
    """Start or reuse the bridge daemon and return its Connect endpoint."""
    global _daemon, _endpoint

    with _lock:
        if _endpoint is not None and _daemon is not None and _daemon.poll() is None:
            return _endpoint

        shutdown_bridge_daemon()

        command = [sys.executable, "-m", "kew_api.ai.bridge_daemon", workspace]
        logger.info("Starting Cursor bridge daemon for workspace=%s", workspace)

        try:
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                cwd=workspace,
            )
        except OSError as exc:
            raise AiRunnerError(
                "Could not start Cursor bridge. Install Cursor IDE and restart the API."
            ) from exc

        assert process.stdout is not None
        line = process.stdout.readline()
        if not line.strip():
            stderr = process.stderr.read() if process.stderr else ""
            process.terminate()
            detail = stderr.strip() or "no output from bridge daemon"
            if "Missing value for --tool-callback-auth-token" in detail:
                detail = (
                    "Bridge auth token was rejected by the CLI parser (known cursor-sdk issue). "
                    "Restart the API after updating — this build patches token generation."
                )
            raise AiRunnerError(
                f"Cursor bridge daemon failed to start. Ensure Cursor IDE is installed. ({detail})"
            )

        try:
            payload = json.loads(line)
            endpoint = BridgeEndpoint(
                url=str(payload["url"]),
                auth_token=str(payload["auth_token"]),
            )
        except (KeyError, TypeError, json.JSONDecodeError) as exc:
            process.terminate()
            raise AiRunnerError("Cursor bridge returned invalid discovery payload.") from exc

        _daemon = process
        _endpoint = endpoint
        return endpoint


def shutdown_bridge_daemon() -> None:
    """Terminate the bridge daemon if running."""
    global _daemon, _endpoint

    process = _daemon
    _daemon = None
    _endpoint = None

    if process is None:
        return

    if process.poll() is None:
        process.terminate()
        try:
            process.wait(timeout=5)
        except subprocess.TimeoutExpired:
            process.kill()
            process.wait(timeout=5)
