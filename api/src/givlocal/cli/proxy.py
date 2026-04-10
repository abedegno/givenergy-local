"""CLI entry point for the GivLocal cloud proxy."""

from __future__ import annotations

import argparse
import asyncio

from givlocal.proxy.config import load_proxy_config
from givlocal.proxy.server import run_proxy


def main() -> None:
    parser = argparse.ArgumentParser(
        description="GivLocal Cloud Proxy — sit between an inverter and GivEnergy cloud",
    )
    parser.add_argument(
        "--config",
        default="proxy-config.yaml",
        help="Path to proxy config YAML file (default: proxy-config.yaml)",
    )
    parser.add_argument(
        "--debug",
        action="store_true",
        help="Enable debug logging (hex dumps of frames)",
    )
    parser.add_argument(
        "--mode",
        choices=["proxy", "standalone"],
        help="Override proxy mode from config",
    )
    parser.add_argument(
        "--port",
        type=int,
        help="Override listen port from config",
    )

    args = parser.parse_args()

    config = load_proxy_config(args.config)

    # Apply CLI overrides
    if args.debug:
        config.log_level = "debug"
    if args.mode is not None:
        config.mode = args.mode
    if args.port is not None:
        config.listen_port = args.port

    asyncio.run(run_proxy(config))


if __name__ == "__main__":
    main()
