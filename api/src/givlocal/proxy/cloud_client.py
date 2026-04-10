"""Asyncio TCP client that connects to the real GivEnergy cloud."""

from __future__ import annotations

import asyncio
import logging

logger = logging.getLogger("givlocal.proxy")


class CloudClient:
    def __init__(self, hosts: list[str], port: int = 7654) -> None:
        self.hosts = hosts
        self.port = port
        self.reader: asyncio.StreamReader | None = None
        self.writer: asyncio.StreamWriter | None = None
        self.connected: bool = False

    async def connect(self) -> bool:
        """Try each host in order with a 5-second timeout. Return True on success."""
        for host in self.hosts:
            try:
                self.reader, self.writer = await asyncio.wait_for(
                    asyncio.open_connection(host, self.port),
                    timeout=5.0,
                )
                self.connected = True
                logger.info(f"Connected to cloud {host}:{self.port}")
                return True
            except (asyncio.TimeoutError, OSError) as exc:
                logger.warning(f"Failed to connect to cloud {host}:{self.port}: {exc}")

        self.connected = False
        logger.error("Could not connect to any cloud host")
        return False

    async def send(self, data: bytes) -> None:
        """Write raw bytes to the cloud connection."""
        if self.writer is None:
            return
        self.writer.write(data)
        await self.writer.drain()

    async def read(self, n: int = 4096) -> bytes:
        """Read up to n bytes. Returns empty bytes on EOF or error."""
        if self.reader is None:
            return b""
        try:
            data = await self.reader.read(n)
            return data
        except (ConnectionError, OSError):
            return b""

    async def close(self) -> None:
        """Clean shutdown of the cloud connection."""
        self.connected = False
        if self.writer is not None:
            try:
                self.writer.close()
                await self.writer.wait_closed()
            except OSError:
                pass
            finally:
                self.writer = None
                self.reader = None
