import textwrap

from givlocal.proxy.config import ProxyConfig, load_proxy_config


def test_load_proxy_config_defaults(tmp_path):
    """Empty YAML file returns all default values."""
    config_file = tmp_path / "proxy-config.yaml"
    config_file.write_text("")

    config = load_proxy_config(str(config_file))

    assert config.mode == "proxy"
    assert config.listen_host == "0.0.0.0"
    assert config.listen_port == 7654
    assert config.cloud_hosts == [
        "13.42.129.212",
        "18.170.183.170",
        "35.178.236.174",
    ]
    assert config.cloud_port == 7654
    assert config.api_url == "http://localhost:8099"
    assert config.api_token == ""
    assert config.ingest_enabled is False
    assert config.log_level == "normal"
    assert config.log_file == "stdout"


def test_load_proxy_config_override(tmp_path):
    """YAML values override defaults."""
    config_file = tmp_path / "proxy-config.yaml"
    config_file.write_text(
        textwrap.dedent("""\
            mode: standalone
            listen:
              port: 9999
            logging:
              level: debug
        """)
    )

    config = load_proxy_config(str(config_file))

    assert config.mode == "standalone"
    assert config.listen_port == 9999
    assert config.log_level == "debug"
    # Unspecified values stay at defaults
    assert config.listen_host == "0.0.0.0"
    assert config.cloud_port == 7654


def test_load_proxy_config_missing_file(tmp_path):
    """Nonexistent path returns defaults without error."""
    missing = str(tmp_path / "does-not-exist.yaml")

    config = load_proxy_config(missing)

    assert isinstance(config, ProxyConfig)
    assert config.mode == "proxy"
    assert config.listen_port == 7654
    assert config.log_level == "normal"
