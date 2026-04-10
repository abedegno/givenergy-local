"""Lightweight GivEnergy frame parser for proxy logging."""

MAGIC = b"\x59\x59\x00\x01"

FUNC_NAMES = {
    0x03: "ReadHR",
    0x04: "ReadIR",
    0x06: "WriteHR",
    0x16: "ReadBatIR",
}


def extract_frames(buf: bytes) -> tuple[list[bytes], bytes]:
    """Scan buffer for MAGIC markers and extract complete frames.

    Returns (complete_frames, remaining_bytes).
    """
    frames = []

    # Skip garbage before first MAGIC
    start = buf.find(MAGIC)
    if start == -1:
        return [], buf

    buf = buf[start:]

    while len(buf) >= 6:
        if not buf.startswith(MAGIC):
            # Find next MAGIC
            next_magic = buf.find(MAGIC, 1)
            if next_magic == -1:
                break
            buf = buf[next_magic:]
            continue

        # Read length field at offset 4-6 (big-endian)
        length = int.from_bytes(buf[4:6], "big")
        frame_len = length + 6

        if len(buf) < frame_len:
            # Incomplete frame, stop
            break

        frames.append(buf[:frame_len])
        buf = buf[frame_len:]

    return frames, buf


def parse_frame_metadata(frame: bytes) -> dict:
    """Parse frame metadata for logging. Never raises exceptions."""
    try:
        if len(frame) < 8:
            return {"type": "unknown", "length": len(frame)}

        uid = frame[6]
        fid = frame[7]

        if fid == 0x01:
            # Heartbeat
            serial = frame[8:18].decode("ascii", errors="replace").rstrip("\x00")
            adapter_type = frame[18] if len(frame) > 18 else 0
            return {
                "type": "heartbeat",
                "uid": uid,
                "serial": serial,
                "adapter_type": adapter_type,
            }

        elif fid == 0x02:
            # Transparent
            serial = frame[8:18].decode("ascii", errors="replace").rstrip("\x00")
            addr = frame[26] if len(frame) > 26 else 0
            func = frame[27] if len(frame) > 27 else 0
            func_name = FUNC_NAMES.get(func, f"Unknown_{func:#04x}")

            result = {
                "type": "transparent",
                "uid": uid,
                "serial": serial,
                "addr": addr,
                "func": func,
                "func_name": func_name,
            }

            if len(frame) >= 32:
                base_reg = int.from_bytes(frame[28:30], "big")
                count_or_value = int.from_bytes(frame[30:32], "big")
                result["base_reg"] = base_reg
                result["count_or_value"] = count_or_value

            return result

        else:
            return {"type": f"unknown_fid_{fid:#04x}", "uid": uid}

    except Exception:
        return {"type": "unknown", "length": len(frame)}
