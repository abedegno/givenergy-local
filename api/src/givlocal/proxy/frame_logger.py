"""Structured JSON frame logger for the GivEnergy proxy."""

import json
import logging
import sys
from datetime import datetime, timezone


def format_log_entry(direction: str, meta: dict, raw: bytes, debug: bool = False) -> str:
    """Build a JSON log entry from frame metadata.

    Args:
        direction: "C→S" or "S→C" etc.
        meta: parsed frame metadata dict from parse_frame_metadata()
        raw: raw frame bytes
        debug: if True, include hex dump of raw bytes

    Returns:
        JSON string
    """
    entry: dict = {
        "ts": datetime.now(timezone.utc).isoformat(),
        "dir": direction,
        "type": meta.get("type", "unknown"),
        "serial": meta.get("serial"),
        "uid": meta.get("uid"),
    }

    frame_type = meta.get("type", "")

    if frame_type == "heartbeat":
        entry["adapter_type"] = meta.get("adapter_type")

    elif frame_type == "transparent":
        addr = meta.get("addr")
        entry["addr"] = f"{addr:#04x}" if addr is not None else None
        entry["func"] = meta.get("func")
        entry["func_name"] = meta.get("func_name")
        if "base_reg" in meta:
            entry["base_reg"] = meta["base_reg"]
        if "count_or_value" in meta:
            entry["count_or_value"] = meta["count_or_value"]

    if debug:
        entry["hex"] = raw.hex()

    return json.dumps(entry)


def setup_logging(log_file: str = "stdout", debug: bool = False) -> None:
    """Configure the givlocal.proxy logger.

    Args:
        log_file: path to log file, or "stdout"
        debug: if True, set level to DEBUG; otherwise INFO
    """
    logger = logging.getLogger("givlocal.proxy")
    logger.setLevel(logging.DEBUG if debug else logging.INFO)

    # Remove existing handlers
    logger.handlers.clear()

    if log_file == "stdout":
        handler = logging.StreamHandler(sys.stdout)
    else:
        handler = logging.FileHandler(log_file)

    handler.setLevel(logging.DEBUG if debug else logging.INFO)
    handler.setFormatter(logging.Formatter("%(message)s"))
    logger.addHandler(handler)


def log_frame(direction: str, meta: dict, raw: bytes, debug: bool = False) -> None:
    """Log a frame using the givlocal.proxy logger.

    Heartbeats are logged at DEBUG; all others at INFO.
    """
    logger = logging.getLogger("givlocal.proxy")
    entry = format_log_entry(direction, meta, raw, debug=debug)

    frame_type = meta.get("type", "unknown")
    if frame_type == "heartbeat":
        logger.debug(entry)
    else:
        logger.info(entry)
