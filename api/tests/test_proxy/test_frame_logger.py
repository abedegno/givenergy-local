"""Tests for the GivEnergy frame logger."""

import json

from givlocal.proxy.frame_logger import format_log_entry

HEARTBEAT_HEX = "59590001000d01015748323432344734303301"
TRANSPARENT_READ_HEX = "59590001001c000257483234323447343033000000000000000811030000003c474b"

HEARTBEAT_META = {
    "type": "heartbeat",
    "uid": 1,
    "serial": "WH2424G403",
    "adapter_type": 1,
}

TRANSPARENT_META = {
    "type": "transparent",
    "uid": 0,
    "serial": "WH2424G403",
    "addr": 0x11,
    "func": 0x03,
    "func_name": "ReadHR",
    "base_reg": 0,
    "count_or_value": 60,
}


def test_format_normal():
    """Normal heartbeat entry has ts, dir, type, serial; no 'hex' key."""
    raw = bytes.fromhex(HEARTBEAT_HEX)
    entry_str = format_log_entry("C→S", HEARTBEAT_META, raw, debug=False)
    entry = json.loads(entry_str)

    assert "ts" in entry
    assert entry["dir"] == "C→S"
    assert entry["type"] == "heartbeat"
    assert entry["serial"] == "WH2424G403"
    assert "hex" not in entry


def test_format_debug_includes_hex():
    """Debug mode adds 'hex' field starting with '5959'."""
    raw = bytes.fromhex(HEARTBEAT_HEX)
    entry_str = format_log_entry("C→S", HEARTBEAT_META, raw, debug=True)
    entry = json.loads(entry_str)

    assert "hex" in entry
    assert entry["hex"].startswith("5959")


def test_format_transparent():
    """Transparent entry includes func_name and addr as hex string."""
    raw = bytes.fromhex(TRANSPARENT_READ_HEX)
    entry_str = format_log_entry("C→S", TRANSPARENT_META, raw, debug=False)
    entry = json.loads(entry_str)

    assert entry["func_name"] == "ReadHR"
    assert entry["addr"] == "0x11"
