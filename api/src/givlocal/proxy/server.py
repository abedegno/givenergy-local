"""Core GivLocal proxy server."""

from __future__ import annotations

import asyncio
import logging
from typing import Callable, Coroutine

from .cloud_client import CloudClient
from .config import ProxyConfig
from .frame_logger import log_frame, setup_logging
from .frame_parser import extract_frames, parse_frame_metadata

logger = logging.getLogger("givlocal.proxy")


async def _forward_with_logging(
    reader: asyncio.StreamReader,
    send_fn: Callable[[bytes], Coroutine],
    direction: str,
    debug: bool = False,
) -> None:
    """Read from reader, log frames, and forward raw bytes via send_fn.

    Runs until EOF or a ConnectionError.
    """
    buf = b""
    while True:
        try:
            chunk = await reader.read(4096)
        except (ConnectionError, OSError):
            break

        if not chunk:
            # EOF
            break

        buf += chunk
        frames, buf = extract_frames(buf)

        for frame in frames:
            meta = parse_frame_metadata(frame)
            log_frame(direction, meta, frame, debug=debug)

        # Forward the raw chunk (not reconstructed frames) to preserve exact bytes
        try:
            await send_fn(chunk)
        except (ConnectionError, OSError):
            break


async def handle_inverter_connection(
    inv_reader: asyncio.StreamReader,
    inv_writer: asyncio.StreamWriter,
    config: ProxyConfig,
) -> None:
    """Handle a single inverter TCP connection."""
    peer = inv_writer.get_extra_info("peername")
    logger.info(f"Inverter connected from {peer}")

    debug = config.log_level == "debug"

    try:
        if config.mode == "proxy":
            cloud = CloudClient(config.cloud_hosts, port=config.cloud_port)
            if not await cloud.connect():
                logger.error("Aborting: could not connect to cloud")
                return

            # inv → cloud
            async def send_to_cloud(data: bytes) -> None:
                await cloud.send(data)

            # cloud → inv
            async def send_to_inv(data: bytes) -> None:
                inv_writer.write(data)
                await inv_writer.drain()

            assert cloud.reader is not None

            task_inv_to_cloud = asyncio.create_task(
                _forward_with_logging(inv_reader, send_to_cloud, "C→S", debug=debug)
            )
            task_cloud_to_inv = asyncio.create_task(
                _forward_with_logging(cloud.reader, send_to_inv, "S→C", debug=debug)
            )

            done, pending = await asyncio.wait(
                {task_inv_to_cloud, task_cloud_to_inv},
                return_when=asyncio.FIRST_COMPLETED,
            )

            for task in pending:
                task.cancel()
                try:
                    await task
                except asyncio.CancelledError:
                    pass

            await cloud.close()

        else:
            # Standalone mode: log frames, no forwarding
            buf = b""
            while True:
                try:
                    chunk = await inv_reader.read(4096)
                except (ConnectionError, OSError):
                    break

                if not chunk:
                    break

                buf += chunk
                frames, buf = extract_frames(buf)

                for frame in frames:
                    meta = parse_frame_metadata(frame)
                    log_frame("C→S", meta, frame, debug=debug)

    finally:
        logger.info(f"Inverter disconnected from {peer}")
        try:
            inv_writer.close()
            await inv_writer.wait_closed()
        except OSError:
            pass


async def run_proxy(config: ProxyConfig) -> None:
    """Start the asyncio TCP proxy server and serve forever."""
    debug = config.log_level == "debug"
    setup_logging(log_file=config.log_file, debug=debug)

    logger.info(
        f"Starting GivLocal proxy | mode={config.mode} "
        f"listen={config.listen_host}:{config.listen_port} "
        f"cloud_hosts={config.cloud_hosts}"
    )

    def client_connected(reader: asyncio.StreamReader, writer: asyncio.StreamWriter) -> None:
        asyncio.create_task(handle_inverter_connection(reader, writer, config))

    server = await asyncio.start_server(
        client_connected,
        config.listen_host,
        config.listen_port,
    )

    async with server:
        await server.serve_forever()
