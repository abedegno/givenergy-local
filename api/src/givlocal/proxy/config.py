from __future__ import annotations

import os
from dataclasses import dataclass, field
from typing import List

import yaml


@dataclass
class ProxyConfig:
    mode: str = "proxy"
    listen_host: str = "0.0.0.0"
    listen_port: int = 7654
    cloud_hosts: List[str] = field(
        default_factory=lambda: [
            "13.42.129.212",
            "18.170.183.170",
            "35.178.236.174",
        ]
    )
    cloud_port: int = 7654
    api_url: str = "http://localhost:8099"
    api_token: str = ""
    ingest_enabled: bool = False
    log_level: str = "normal"
    log_file: str = "stdout"


def load_proxy_config(path: str) -> ProxyConfig:
    """Load proxy config from a YAML file.

    Returns a ProxyConfig with defaults if the file does not exist.
    """
    if not os.path.exists(path):
        return ProxyConfig()

    with open(path, "r") as fh:
        data = yaml.safe_load(fh) or {}

    listen = data.get("listen", {}) or {}
    cloud = data.get("cloud", {}) or {}
    api = data.get("api", {}) or {}
    logging = data.get("logging", {}) or {}

    defaults = ProxyConfig()

    return ProxyConfig(
        mode=data.get("mode", defaults.mode),
        listen_host=listen.get("host", defaults.listen_host),
        listen_port=listen.get("port", defaults.listen_port),
        cloud_hosts=cloud.get("hosts", defaults.cloud_hosts),
        cloud_port=cloud.get("port", defaults.cloud_port),
        api_url=api.get("url", defaults.api_url),
        api_token=api.get("token", defaults.api_token),
        ingest_enabled=api.get("ingest_enabled", defaults.ingest_enabled),
        log_level=logging.get("level", defaults.log_level),
        log_file=logging.get("file", defaults.log_file),
    )
