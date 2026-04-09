# Settings Read/Write Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the inverter settings endpoints (`GET /settings`, `POST /settings/{id}/read`, `POST /settings/{id}/write`) so users can read and control their inverter's charge/discharge schedules, eco mode, battery limits, and other settings through the cloud-compatible API.

**Architecture:** A YAML-based settings map translates between cloud API setting IDs and Modbus holding register names. The settings map is loaded at startup from bundled YAML files (one per inverter model). Read requests return the current value from the in-memory plant register cache. Write requests use the givenergy-modbus-async `WriteHoldingRegisterRequest` to send the value to the inverter, then refresh the cache.

**Tech Stack:** Python 3.12+, FastAPI, givenergy-modbus-async (WriteHoldingRegisterRequest), PyYAML, pytest

**Existing codebase:** `/Users/jonw/givenergy/givenergy-local/`
**Run tests:** `cd /Users/jonw/givenergy/givenergy-local && PYTHONPATH=src:. .venv/bin/pytest tests/ -v`

---

## File Map

```
src/givenergy_local/
├── settings_map.py          # NEW: load YAML, lookup setting ID ↔ register
├── api/
│   └── inverter_control.py  # NEW: settings list, read, write endpoints
settings/
└── models/
    └── hybrid_gen3.yaml     # NEW: setting ID map for Gen3 hybrids (model 2001)
tests/
├── test_settings_map.py     # NEW
└── test_api/
    └── test_inverter_control.py  # NEW
```

---

### Task 1: Settings Map YAML + Loader

**Files:**
- Create: `settings/models/hybrid_gen3.yaml`
- Create: `src/givenergy_local/settings_map.py`
- Create: `tests/test_settings_map.py`

- [ ] **Step 1: Create the settings YAML file**

This maps cloud API setting IDs to Modbus register names from the givenergy-modbus-async library. Based on the cloud dump from `/Users/jonw/givenergy/cloud-data-dump/inverters/FA2424G403/settings.json` cross-referenced with the `BaseInverter.REGISTER_LUT`.

```yaml
# settings/models/hybrid_gen3.yaml
# GivEnergy Cloud API Setting ID → Modbus register mapping
# Model: 2001 (Hybrid Gen3 5kW)
# Source: cloud API dump + givenergy-modbus-async register definitions

model: "2001"
settings:
  17:
    name: "Enable AC Charge Upper % Limit"
    register: enable_charge_target
    type: bool
    validation: "in:true,false"
  24:
    name: "Enable Eco Mode"
    register: eco_mode
    type: bool
    validation: "in:true,false"
  41:
    name: "DC Discharge 2 Start Time"
    register: discharge_slot_2_start
    type: time
    validation: "date_format:H:i"
  42:
    name: "DC Discharge 2 End Time"
    register: discharge_slot_2_end
    type: time
    validation: "date_format:H:i"
  47:
    name: "Inverter Max Output Active Power Percent"
    register: active_power_rate
    type: int
    validation: "between:0,100"
    hr_override: 50
  53:
    name: "DC Discharge 1 Start Time"
    register: discharge_slot_1_start
    type: time
    validation: "date_format:H:i"
  54:
    name: "DC Discharge 1 End Time"
    register: discharge_slot_1_end
    type: time
    validation: "date_format:H:i"
  56:
    name: "Enable DC Discharge"
    register: enable_discharge
    type: bool
    validation: "in:true,false"
    hr_override: 59
  64:
    name: "AC Charge 1 Start Time"
    register: charge_slot_1_start
    type: time
    validation: "date_format:H:i"
  65:
    name: "AC Charge 1 End Time"
    register: charge_slot_1_end
    type: time
    validation: "date_format:H:i"
  66:
    name: "AC Charge Enable"
    register: enable_charge
    type: bool
    validation: "in:true,false"
    hr_override: 96
  71:
    name: "Battery Reserve % Limit"
    register: battery_soc_reserve
    type: int
    validation: "between:4,100"
    hr_override: 110
  72:
    name: "Battery Charge Power"
    register: battery_charge_limit
    type: int
    validation: "between:0,3600"
  73:
    name: "Battery Discharge Power"
    register: battery_discharge_limit
    type: int
    validation: "between:0,3600"
  75:
    name: "Battery Cutoff % Limit"
    register: battery_discharge_min_power_reserve
    type: int
    validation: "between:4,100"
  77:
    name: "AC Charge Upper % Limit"
    register: charge_target_soc
    type: int
    validation: "between:0,100"
  83:
    name: "Restart Inverter"
    register: inverter_reboot
    type: int
    validation: "in:100"
    hr_override: 163
  96:
    name: "Pause Battery"
    register: battery_pause_mode
    type: int
    validation: "in:0,1,2,3"
  101:
    name: "AC Charge 1 Upper SOC % Limit"
    register: charge_target_soc_1
    type: int
    validation: "between:0,100"
  102:
    name: "AC Charge 2 Start Time"
    register: charge_slot_2_start
    type: time
    validation: "date_format:H:i"
  103:
    name: "AC Charge 2 End Time"
    register: charge_slot_2_end
    type: time
    validation: "date_format:H:i"
  104:
    name: "AC Charge 2 Upper SOC % Limit"
    register: charge_target_soc_2
    type: int
    validation: "between:0,100"
  129:
    name: "DC Discharge 1 Lower SOC % Limit"
    register: discharge_target_soc_1
    type: int
    validation: "between:4,100"
  130:
    name: "DC Discharge 2 Lower SOC % Limit"
    register: discharge_target_soc_2
    type: int
    validation: "between:4,100"
  131:
    name: "DC Discharge 3 Start Time"
    register: discharge_slot_3_start
    type: time
    validation: "date_format:H:i"
  132:
    name: "DC Discharge 3 End Time"
    register: discharge_slot_3_end
    type: time
    validation: "date_format:H:i"
  133:
    name: "DC Discharge 3 Lower SOC % Limit"
    register: discharge_target_soc_3
    type: int
    validation: "between:4,100"
  155:
    name: "Pause Battery Start Time"
    register: battery_pause_slot_1_start
    type: time
    validation: "date_format:H:i"
  156:
    name: "Pause Battery End Time"
    register: battery_pause_slot_1_end
    type: time
    validation: "date_format:H:i"
  267:
    name: "Inverter Charge Power Percentage"
    register: battery_charge_limit_ac
    type: int
    validation: "between:1,100"
  268:
    name: "Inverter Discharge Power Percentage"
    register: battery_discharge_limit_ac
    type: int
    validation: "between:1,100"
```

Note: This is a subset of the full 79 settings. Additional charge/discharge slots 3-10 follow the same pattern and should be added, but the core settings are covered. The `hr_override` field is used when the register exists in the LUT but doesn't have `valid` set (the library considers it non-writable but it is writable in practice).

- [ ] **Step 2: Write failing tests for settings_map.py**

```python
# tests/test_settings_map.py
from pathlib import Path


def test_load_settings_map():
    from givenergy_local.settings_map import load_settings_map

    settings = load_settings_map("settings/models")
    assert "2001" in settings
    model_settings = settings["2001"]
    assert 17 in model_settings
    assert model_settings[17]["name"] == "Enable AC Charge Upper % Limit"
    assert model_settings[17]["register"] == "enable_charge_target"
    assert model_settings[17]["type"] == "bool"


def test_get_setting_by_id():
    from givenergy_local.settings_map import load_settings_map, get_setting

    settings = load_settings_map("settings/models")
    setting = get_setting(settings, "2001", 64)
    assert setting is not None
    assert setting["name"] == "AC Charge 1 Start Time"
    assert setting["register"] == "charge_slot_1_start"
    assert setting["type"] == "time"


def test_get_setting_unknown_id():
    from givenergy_local.settings_map import load_settings_map, get_setting

    settings = load_settings_map("settings/models")
    setting = get_setting(settings, "2001", 99999)
    assert setting is None


def test_list_settings_for_model():
    from givenergy_local.settings_map import load_settings_map, list_settings

    settings = load_settings_map("settings/models")
    result = list_settings(settings, "2001")
    assert len(result) > 20
    assert all("id" in s and "name" in s and "validation" in s for s in result)


def test_validate_bool_setting():
    from givenergy_local.settings_map import validate_setting_value

    assert validate_setting_value({"type": "bool", "validation": "in:true,false"}, True) is True
    assert validate_setting_value({"type": "bool", "validation": "in:true,false"}, False) is True
    assert validate_setting_value({"type": "bool", "validation": "in:true,false"}, "yes") is False


def test_validate_int_setting():
    from givenergy_local.settings_map import validate_setting_value

    assert validate_setting_value({"type": "int", "validation": "between:4,100"}, 50) is True
    assert validate_setting_value({"type": "int", "validation": "between:4,100"}, 3) is False
    assert validate_setting_value({"type": "int", "validation": "between:4,100"}, 101) is False


def test_validate_time_setting():
    from givenergy_local.settings_map import validate_setting_value

    assert validate_setting_value({"type": "time", "validation": "date_format:H:i"}, "23:30") is True
    assert validate_setting_value({"type": "time", "validation": "date_format:H:i"}, "25:00") is False
    assert validate_setting_value({"type": "time", "validation": "date_format:H:i"}, "abc") is False


def test_convert_time_to_register_value():
    from givenergy_local.settings_map import convert_to_register_value

    assert convert_to_register_value({"type": "time"}, "23:30") == 2330
    assert convert_to_register_value({"type": "time"}, "05:30") == 530
    assert convert_to_register_value({"type": "time"}, "00:00") == 0


def test_convert_bool_to_register_value():
    from givenergy_local.settings_map import convert_to_register_value

    assert convert_to_register_value({"type": "bool"}, True) == 1
    assert convert_to_register_value({"type": "bool"}, False) == 0


def test_convert_register_to_display_value():
    from givenergy_local.settings_map import convert_from_register_value

    assert convert_from_register_value({"type": "time"}, 2330) == "23:30"
    assert convert_from_register_value({"type": "time"}, 530) == "05:30"
    assert convert_from_register_value({"type": "bool"}, 1) is True
    assert convert_from_register_value({"type": "bool"}, 0) is False
    assert convert_from_register_value({"type": "int"}, 50) == 50
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
PYTHONPATH=src:. .venv/bin/pytest tests/test_settings_map.py -v
```
Expected: FAIL - `ModuleNotFoundError`

- [ ] **Step 4: Implement settings_map.py**

```python
# src/givenergy_local/settings_map.py
"""Load and query cloud API setting ID ↔ Modbus register mappings."""

from __future__ import annotations

from pathlib import Path

import yaml


SettingsMap = dict[str, dict[int, dict]]


def load_settings_map(settings_dir: str) -> SettingsMap:
    """Load all model YAML files from settings_dir into a dict keyed by model code."""
    result: SettingsMap = {}
    settings_path = Path(settings_dir)
    if not settings_path.exists():
        return result
    for yaml_file in settings_path.glob("*.yaml"):
        with open(yaml_file) as f:
            data = yaml.safe_load(f)
        model = str(data.get("model", ""))
        settings = {}
        for sid, info in data.get("settings", {}).items():
            settings[int(sid)] = info
        result[model] = settings
    return result


def get_setting(settings_map: SettingsMap, model: str, setting_id: int) -> dict | None:
    """Look up a single setting by model and cloud API setting ID."""
    model_settings = settings_map.get(model, {})
    return model_settings.get(setting_id)


def list_settings(settings_map: SettingsMap, model: str) -> list[dict]:
    """Return all settings for a model in cloud API response format."""
    model_settings = settings_map.get(model, {})
    return [
        {
            "id": sid,
            "name": info["name"],
            "validation": info.get("validation", ""),
            "validation_rules": [info.get("validation", "")],
        }
        for sid, info in sorted(model_settings.items())
    ]


def validate_setting_value(setting: dict, value) -> bool:
    """Validate a value against the setting's type and validation rules."""
    stype = setting.get("type", "int")
    validation = setting.get("validation", "")

    if stype == "bool":
        return isinstance(value, bool)
    elif stype == "time":
        if not isinstance(value, str):
            return False
        try:
            parts = value.split(":")
            h, m = int(parts[0]), int(parts[1])
            return 0 <= h <= 23 and 0 <= m <= 59
        except (ValueError, IndexError):
            return False
    elif stype == "int":
        if not isinstance(value, int):
            return False
        if validation.startswith("between:"):
            lo, hi = validation.split(":")[1].split(",")
            return int(lo) <= value <= int(hi)
        elif validation.startswith("in:"):
            allowed = [int(v) for v in validation.split(":")[1].split(",")]
            return value in allowed
        return True
    return False


def convert_to_register_value(setting: dict, value) -> int:
    """Convert a display value (e.g. '23:30', True) to a Modbus register int."""
    stype = setting.get("type", "int")
    if stype == "time":
        parts = value.split(":")
        return int(parts[0]) * 100 + int(parts[1])
    elif stype == "bool":
        return 1 if value else 0
    else:
        return int(value)


def convert_from_register_value(setting: dict, register_value: int):
    """Convert a Modbus register int to a display value."""
    stype = setting.get("type", "int")
    if stype == "time":
        h = register_value // 100
        m = register_value % 100
        return f"{h:02d}:{m:02d}"
    elif stype == "bool":
        return bool(register_value)
    else:
        return register_value
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
PYTHONPATH=src:. .venv/bin/pytest tests/test_settings_map.py -v
```
Expected: 11 PASSED

- [ ] **Step 6: Commit**

```bash
git add settings/models/hybrid_gen3.yaml src/givenergy_local/settings_map.py tests/test_settings_map.py
git commit -m "feat: settings map loader with cloud API ID to Modbus register mapping"
```

---

### Task 2: Settings API Endpoints

**Files:**
- Create: `src/givenergy_local/api/inverter_control.py`
- Create: `tests/test_api/test_inverter_control.py`
- Modify: `src/givenergy_local/main.py` (add router, load settings map at startup)

- [ ] **Step 1: Write failing tests**

```python
# tests/test_api/test_inverter_control.py
import pytest
from fastapi.testclient import TestClient
from unittest.mock import MagicMock, AsyncMock


@pytest.fixture
def client(tmp_path):
    from givenergy_local.main import app, app_state, InverterState
    from givenergy_local.auth import TokenStore
    from givenergy_local.database import init_app_db
    from givenergy_local.settings_map import load_settings_map
    from tests.fixtures.register_data import make_inverter_cache
    from givenergy_modbus_async.model.inverter import Inverter

    app_state.auth_required = False
    conn = init_app_db(str(tmp_path / "app.db"))
    app_state.token_store = TokenStore(conn)
    app_state.settings_map = load_settings_map("settings/models")

    cache = make_inverter_cache()
    mock_plant = MagicMock()
    mock_plant.inverter = Inverter(cache)
    mock_plant.inverter_serial_number = "FA2424G403"

    mock_client = AsyncMock()
    mock_client.plant = mock_plant

    app_state.inverters = {
        "FA2424G403": InverterState(
            serial="FA2424G403", host="192.168.86.44", port=8899, plant=mock_plant, client=mock_client
        )
    }
    return TestClient(app, raise_server_exceptions=False)


def test_list_settings(client):
    resp = client.get("/v1/inverter/FA2424G403/settings")
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert len(data) > 20
    assert data[0]["id"] is not None
    assert data[0]["name"] is not None
    assert data[0]["validation"] is not None


def test_read_setting_bool(client):
    # Setting 24 = Enable Eco Mode -> eco_mode register
    resp = client.post("/v1/inverter/FA2424G403/settings/24/read")
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "value" in data


def test_read_setting_time(client):
    # Setting 64 = AC Charge 1 Start Time -> charge_slot_1_start
    resp = client.post("/v1/inverter/FA2424G403/settings/64/read")
    assert resp.status_code == 200
    data = resp.json()["data"]
    assert "value" in data
    # charge_slot_1_start = 2330 -> "23:30"
    assert data["value"] == "23:30"


def test_read_setting_unknown_id(client):
    resp = client.post("/v1/inverter/FA2424G403/settings/99999/read")
    assert resp.status_code == 404


def test_read_setting_unknown_inverter(client):
    resp = client.post("/v1/inverter/UNKNOWN/settings/24/read")
    assert resp.status_code == 404


def test_write_setting(client):
    # Setting 71 = Battery Reserve % Limit
    resp = client.post(
        "/v1/inverter/FA2424G403/settings/71/write",
        json={"value": 20},
    )
    assert resp.status_code in (200, 201)
    data = resp.json()["data"]
    assert data["success"] is True


def test_write_setting_invalid_value(client):
    # Setting 71 = Battery Reserve % Limit, valid range 4-100
    resp = client.post(
        "/v1/inverter/FA2424G403/settings/71/write",
        json={"value": 2},
    )
    assert resp.status_code == 422


def test_write_setting_time(client):
    # Setting 64 = AC Charge 1 Start Time
    resp = client.post(
        "/v1/inverter/FA2424G403/settings/64/write",
        json={"value": "01:30"},
    )
    assert resp.status_code in (200, 201)
    data = resp.json()["data"]
    assert data["success"] is True
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
PYTHONPATH=src:. .venv/bin/pytest tests/test_api/test_inverter_control.py -v
```
Expected: FAIL

- [ ] **Step 3: Implement inverter_control.py**

```python
# src/givenergy_local/api/inverter_control.py
"""API routes for inverter settings read/write."""

from __future__ import annotations

import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel

from givenergy_local.api.dependencies import require_auth
from givenergy_local.api.schemas import DataResponse
from givenergy_local.settings_map import (
    convert_from_register_value,
    convert_to_register_value,
    get_setting,
    list_settings,
    validate_setting_value,
)

logger = logging.getLogger(__name__)

router = APIRouter(tags=["Inverter Control"])


def _get_inverter_and_setting(serial: str, setting_id: int):
    from givenergy_local.main import app_state

    inv_state = app_state.inverters.get(serial)
    if not inv_state or not inv_state.plant or not inv_state.plant.inverter:
        raise HTTPException(status_code=404, detail="Inverter not found")

    dtc = inv_state.plant.inverter.get("device_type_code")
    model = str(dtc) if dtc else "2001"

    setting = get_setting(app_state.settings_map, model, setting_id)
    if not setting:
        raise HTTPException(status_code=404, detail="Setting not found")

    return inv_state, setting, model


@router.get("/inverter/{inverter_serial_number}/settings", dependencies=[Depends(require_auth)])
async def get_settings_list(inverter_serial_number: str):
    """Return the list of available settings for this inverter."""
    from givenergy_local.main import app_state

    inv_state = app_state.inverters.get(inverter_serial_number)
    if not inv_state or not inv_state.plant or not inv_state.plant.inverter:
        raise HTTPException(status_code=404, detail="Inverter not found")

    dtc = inv_state.plant.inverter.get("device_type_code")
    model = str(dtc) if dtc else "2001"

    result = list_settings(app_state.settings_map, model)
    return DataResponse(data=result)


@router.post("/inverter/{inverter_serial_number}/settings/{setting_id}/read", dependencies=[Depends(require_auth)])
async def read_setting(inverter_serial_number: str, setting_id: int):
    """Read the current value of a setting from the inverter's register cache."""
    inv_state, setting, model = _get_inverter_and_setting(inverter_serial_number, setting_id)

    inv = inv_state.plant.inverter
    register_name = setting["register"]
    raw_value = inv.get(register_name)

    if raw_value is None and "hr_override" in setting:
        from givenergy_modbus_async.model.register import HR

        raw_value = inv_state.plant.inverter.cache.get(HR(setting["hr_override"]))

    if raw_value is None:
        return DataResponse(data={"value": None})

    display_value = convert_from_register_value(setting, raw_value)
    return DataResponse(data={"value": display_value})


class WriteSettingRequest(BaseModel):
    value: bool | int | str
    context: str | None = None


@router.post("/inverter/{inverter_serial_number}/settings/{setting_id}/write", dependencies=[Depends(require_auth)])
async def write_setting(inverter_serial_number: str, setting_id: int, body: WriteSettingRequest):
    """Write a value to a setting on the inverter."""
    inv_state, setting, model = _get_inverter_and_setting(inverter_serial_number, setting_id)

    if not validate_setting_value(setting, body.value):
        raise HTTPException(status_code=422, detail=f"Invalid value for setting '{setting['name']}'")

    register_value = convert_to_register_value(setting, body.value)

    # Determine the HR index to write to
    if "hr_override" in setting:
        hr_index = setting["hr_override"]
    else:
        from givenergy_modbus_async.model.baseinverter import BaseInverter

        reg_name = setting["register"]
        regdef = BaseInverter.REGISTER_LUT.get(reg_name)
        if not regdef:
            raise HTTPException(status_code=500, detail=f"Register '{reg_name}' not found in inverter model")
        hr_index = regdef.registers[0]._idx

    # Send the write command
    from givenergy_modbus_async.pdu import WriteHoldingRegisterRequest

    request = WriteHoldingRegisterRequest(hr_index, register_value)
    try:
        await inv_state.client.execute([request], timeout=3.0, retries=1)
        logger.info("Wrote setting %d (%s) = %s (HR(%d) = %d)", setting_id, setting["name"], body.value, hr_index, register_value)
        return DataResponse(data={"value": register_value, "success": True, "message": "Written Successfully"})
    except Exception as e:
        logger.error("Failed to write setting %d: %s", setting_id, e)
        return DataResponse(data={"value": register_value, "success": False, "message": str(e)})
```

- [ ] **Step 4: Add settings_map to AppState and load at startup**

Add to `src/givenergy_local/main.py`:

In the `AppState` dataclass, add:
```python
    settings_map: dict = field(default_factory=dict)
```

In the `lifespan` function, after token setup and before inverter connection, add:
```python
    # Load settings map
    from .settings_map import load_settings_map
    app_state.settings_map = load_settings_map("settings/models")
    logger.info("Loaded settings map for %d model(s)", len(app_state.settings_map))
```

At the bottom of `main.py` where routers are registered, add:
```python
from .api.inverter_control import router as inverter_control_router  # noqa: E402
app.include_router(inverter_control_router, prefix="/v1")
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
PYTHONPATH=src:. .venv/bin/pytest tests/test_api/test_inverter_control.py -v
```
Expected: 8 PASSED

- [ ] **Step 6: Run the full test suite**

```bash
PYTHONPATH=src:. .venv/bin/pytest tests/ -v
```
Expected: All tests pass (52 existing + 11 settings_map + 8 control = 71)

- [ ] **Step 7: Commit**

```bash
git add -A
git commit -m "feat: settings read/write endpoints with cloud API ID mapping"
```

---

### Task 3: Live Verification

**Files:** None (manual testing)

- [ ] **Step 1: Start the server**

```bash
PYTHONPATH=src:. .venv/bin/python3 -m uvicorn givenergy_local.main:app --port 8099
```

Note the admin token from the logs.

- [ ] **Step 2: List settings**

```bash
curl -H "Authorization: Bearer TOKEN" http://localhost:8099/v1/inverter/FA2424G403/settings | python3 -m json.tool | head -20
```

Expected: JSON array of settings with id, name, validation.

- [ ] **Step 3: Read a setting**

```bash
# Read eco mode (setting 24)
curl -X POST -H "Authorization: Bearer TOKEN" http://localhost:8099/v1/inverter/FA2424G403/settings/24/read

# Read charge slot 1 start time (setting 64)
curl -X POST -H "Authorization: Bearer TOKEN" http://localhost:8099/v1/inverter/FA2424G403/settings/64/read
```

Expected: `{"data": {"value": true}}` and `{"data": {"value": "23:30"}}`

- [ ] **Step 4: Write a setting (read-only test first)**

```bash
# Read battery reserve (setting 71)
curl -X POST -H "Authorization: Bearer TOKEN" http://localhost:8099/v1/inverter/FA2424G403/settings/71/read

# Write it to the same value (safe - no actual change)
curl -X POST -H "Authorization: Bearer TOKEN" -H "Content-Type: application/json" \
  -d '{"value": 4}' http://localhost:8099/v1/inverter/FA2424G403/settings/71/write
```

Expected: `{"data": {"value": 4, "success": true, "message": "Written Successfully"}}`

- [ ] **Step 5: Push to GitHub**

```bash
git push
```

---

## Summary

| Task | Component | Tests | Commits |
|------|-----------|-------|---------|
| 1 | Settings YAML + loader | 11 | 1 |
| 2 | API endpoints (list, read, write) | 8 | 1 |
| 3 | Live verification | 0 (manual) | 0 |
| **Total** | | **19 tests** | **2 commits** |
